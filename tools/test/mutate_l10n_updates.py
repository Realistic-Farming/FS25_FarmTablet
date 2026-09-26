# MAINTENANCE row 105, batch 10 (Updates): targeted mutation battery.
# The logic in this PR: the eight 2.5.3.0 changelog lines get their keys in translation_en.xml (the app asked
# for keys the file did not carry, so every language fell back to English), and the header's fallback is
# English. Each mutation undoes one piece, breaks the app's own ftSafeText, or breaks one text row the
# translation leans on, and the bar tools/test/l10n-updates-check.mjs must FAIL on a named row. Each file is
# restored byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_updates.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-updates-check.mjs")
APP = "src/apps/UpdatesApp.lua"
EN = "translations/translation_en.xml"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("U1-253-key-dropped-from-en", EN,
     one('        <text name="ft_changelog_253_new_1" text="Rotation Planner app: plan crop rotations using Soil &amp; Fertilizer\'s own recommendations" />\n', ''),
     "a 2.5.3.0 line's key gone from translation_en.xml again: S1, the text rows"),
    ("U2-changelog-line-literal", APP,
     one('ftSafeText("ft_changelog_251_new_1", "Favorites page for frequently used apps")', '"Favorites page for frequently used apps"'),
     "a changelog line as an English literal: S4"),
    ("U3-help-body-literal", APP,
     one('body = ftSafeText("ft_updates_help_history_body", "Shows FarmTablet changes sorted by version.")', 'body = "Shows FarmTablet changes sorted by version."'),
     "a help body drawn as a literal again: S2, S4"),
    ("U4-helper-skips-l10n", APP,
     one('    if FT ~= nil and FT.l10n ~= nil then return FT.l10n(key, raw) end\n', ''),
     "the app's ftSafeText no longer asks FT.l10n, so every line falls back to English: X1"),
    ("U5-key-typo", APP,
     one('ftSafeText("ft_changelog_253_fix_1", ', 'ftSafeText("ft_changelog_253_fix_9", '),
     "a changelog line asks for a key no file carries: S1, S4"),
    ("T1-english-copy", "translations/translation_de.xml",
     one('<text name="ft_changelog_253_new_4" text="Finanzen-App: Zustand des ganzen Hofs, Live-Instrumente und Monatsverlauf" />',
         '<text name="ft_changelog_253_new_4" text="Financial Cockpit app: whole-farm health, live instruments and monthly history" />'),
     "a German value that is the English text: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_updates_new" text="新機能" />', '<text name="ft_updates_new" text="shinkinou" />'),
     "a Japanese value written in Latin letters: the script row, the CONTAINS row"),
    ("T3-help-misnames-section", "translations/translation_fr.xml",
     one('Nouveautés, Améliorations et Corrections.', 'Nouveautés, Améliorations et Correctifs.'),
     "a French help line naming a section the screen does not draw: the CONTAINS row"),
    ("T4-russian-key-missing", "translations/translation_ru.xml",
     one('        <text name="ft_changelog_253_imp_3" text="Приложение «Почва» переработано: более понятные карточки питательных веществ по полям" />\n', ''),
     "a Russian file without one of the new keys: the text rows"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", BAR], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:140])
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
