# RSF-141 mutation battery for the Field Jobs text bar (tools/test/l10n-fieldjobs-check.mjs).
# Each mutation edits ONE locale file in place, runs the bar, and expects it to fail; the file is
# restored byte-identical (hash-checked) after each one. The bar must be green before any run.
#
# KILLED means the bar failed on the mutated file; SURVIVED means it stayed green (a bar gap).
# Usage: py tools/test/mutate_l10n_fieldjobs.py [id-prefix ...]
import hashlib, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def p(rel): return os.path.join(ROOT, rel)
FR = "translations/translation_fr.xml"
DE = "translations/translation_de.xml"

def entry(text, key):
    m = re.search(r'<text name="%s" text="([^"]*)" />' % re.escape(key), text)
    assert m, key
    return m.group(0), m.group(1)

MUTATIONS = [
 ("L1-key-dropped", FR, lambda t: t.replace(entry(t, "ft_fieldjobs_no_field")[0], "", 1),
  "one locale lacks a key: the player sees English there"),
 ("L2-placeholder-kind-swapped", FR, lambda t: t.replace(entry(t, "ft_fieldjobs_field_label")[0], entry(t, "ft_fieldjobs_field_label")[0].replace("%s, %s", "%d, %s"), 1),
  "a %s became %d: the format helper falls back to English"),
 ("L3-placeholder-dropped", FR, lambda t: t.replace(entry(t, "ft_fieldjobs_history_more")[0], entry(t, "ft_fieldjobs_history_more")[0].replace("%d ", ""), 1),
  "one placeholder fewer than English"),
 ("L4-key-duplicated", FR, lambda t: t.replace(entry(t, "ft_fieldjobs_no_field")[0], entry(t, "ft_fieldjobs_no_field")[0] + entry(t, "ft_fieldjobs_no_field")[0], 1),
  "a key declared twice in one file"),
 ("L5-line-break-dropped", FR, lambda t: t.replace(entry(t, "ft_fieldjobs_help_nav_body")[0], entry(t, "ft_fieldjobs_help_nav_body")[0].replace("\\n", " ", 1), 1),
  "one \\n fewer in a help body: the panel's layout changes"),
 ("L6-english-copied", FR, lambda t: t.replace(entry(t, "ft_fieldjobs_no_field")[0], '<text name="ft_fieldjobs_no_field" text="No field" />', 1),
  "the English text passed off as a translation (Tyson's ruling, row 80)"),
 ("L7-english-copied-common-key", FR, lambda t: t.replace(entry(t, "ft_common_history")[0], '<text name="ft_common_history" text="History" />', 1),
  "the History button's English text left in place"),
 ("L8-english-copied-de", DE, lambda t: t.replace(entry(t, "ft_fieldjobs_start_job")[0], '<text name="ft_fieldjobs_start_job" text="Start job" />', 1),
  "a locale the allowlist does not name gets the English text of the allowed Danish word"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", p("tools/test/l10n-fieldjobs-check.mjs")], capture_output=True, text=True, cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[:10]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1])
killed, survived, bad = 0, 0, 0
for mid, rel, fn, why in MUTATIONS:
    if only and not any(mid.startswith(o) for o in only): continue
    path = p(rel)
    before = sha(path)
    raw = open(path, "rb").read()
    crlf = b"\r\n" in raw
    t = raw.decode("utf-8").replace("\r\n", "\n")
    t2 = fn(t)
    if t2 == t:
        print("  BAD EDIT %s (no change)" % mid); bad += 1; continue
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
    finally:
        open(path, "wb").write(raw)
        assert sha(path) == before, "restore failed for " + rel
    if rc != 0:
        killed += 1
        print("  KILLED   %s  [%s]" % (mid, rel))
        for l in out:
            if l.strip().startswith("FAIL"): print("        " + l.strip())
    else:
        survived += 1
        print("  SURVIVED %s  [%s]  (%s)" % (mid, rel, why))
print("\n==== MUTATION RESULT ====")
print("killed   %d" % killed)
print("survived %d" % survived)
print("bad edit %d" % bad)
print("all files restored byte-identical (hash-checked per mutation)")
sys.exit(0 if survived == 0 and bad == 0 else 1)
