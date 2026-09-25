# MAINTENANCE row 105, the FieldSentry PR: targeted mutation battery for its logic change.
# SoilFertilizerApp.lua drew two texts built from English literals at run time (the field count line,
# a string.format; the meadow tag, a concatenation), which FT.l10nAuto can never look up. They now go
# through named keys (ft_fieldsentry_count, ft_fieldsentry_meadow_tag). Each mutation puts one side
# back, or breaks the key the fix relies on, and must be killed by a named row of the bar.
#
# Each mutation edits one file in place, runs tools/test/l10n-field-sentry-check.mjs and expects it
# to FAIL on a named row; the file is restored byte-identical (sha256-checked) after each one. The
# bar must be green before any run.
# Usage: py tools/test/mutate_l10n_field_sentry.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

APP = "src/apps/SoilFertilizerApp.lua"

MUTATIONS = [
    ("F1-count-formatted-again", APP,
     one('FT.l10nFormat("ft_fieldsentry_count", "%d fields  ·  %d asleep", #fields, asleep),',
         'string.format("%d fields  ·  %d asleep", #fields, asleep),'),
     "the count line goes back to a string.format of an English literal"),
    ("F2-meadow-tag-literal-again", APP,
     one('reasonTxt .. " · " .. FT.l10n("ft_fieldsentry_meadow_tag", "meadow")',
         'reasonTxt .. " · meadow"'),
     "the meadow tag goes back to an English literal glued to the reason"),
    ("F3-count-key-renamed-in-code", APP,
     one('FT.l10nFormat("ft_fieldsentry_count",', 'FT.l10nFormat("ft_fieldsentry_counts",'),
     "the code asks for a key no locale file carries: every language reads the English fallback"),
    ("F4-count-key-dropped-from-en", "translations/translation_en.xml",
     one('        <text name="ft_fieldsentry_count" text="%d fields  ·  %d asleep" />\n', ''),
     "the English file loses the new key"),
    ("F5-count-placeholder-dropped", "translations/translation_fr.xml",
     one('<text name="ft_fieldsentry_count" text="%d champs  ·  %d en veille" />',
         '<text name="ft_fieldsentry_count" text="%d champs en veille" />'),
     "a translation loses one of the two numbers"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "l10n-field-sentry-check.mjs")],
                       capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:120])
killed = survived = bad = 0
for mid, rel, fn, why in MUTATIONS:
    if only and not any(mid.startswith(o) for o in only): continue
    path = os.path.join(ROOT, rel)
    before = sha(path)
    raw = open(path, "rb").read()
    crlf = b"\r\n" in raw
    t = raw.decode("utf-8").replace("\r\n", "\n")
    try:
        t2 = fn(t)
    except (AssertionError, ValueError) as e:
        print("  BAD EDIT %s (%s)" % (mid, e)); bad += 1; continue
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
    finally:
        open(path, "wb").write(raw)
        assert sha(path) == before, "restore failed for " + rel
    fails = [l.strip() for l in out if l.strip().startswith("FAIL ")]
    if rc != 0 and fails:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        for l in fails[:3]: print("        " + l[:170])
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: the bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
