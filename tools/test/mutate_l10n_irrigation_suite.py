# MAINTENANCE row 105, batch 17 (Irrigation Suite): targeted mutation battery.
# The work in this PR: every drawn English text of IrrigationSuiteApp.lua on a key (60 new keys, verbatim), the suite's
# 105 keys in all 26 files (278 existing values the import had stripped get their accents back, German's digraphs
# included), the lock lines' code fallback taking Wizard's English, and RSF-F166's flag on the resolved draws
# (row 158's seventh site, the advisory's field line, among them). Each mutation undoes one piece, and a bar must FAIL
# on a named row: tools/test/l10n-irrigation-suite-check.mjs for the text rows, tools/test/renderer-literal-flag-
# check.mjs for the drawer (its Irrigation E case walks the three views through the real buttons on a CropStressManager
# stand-in in SCS's own shapes), tools/test/l10n-tree-check.mjs for the tree-wide rows. All three bars run for every
# mutation. Each file is restored byte-identical (sha256-checked) after each run. The bars must be green before any run.
# Usage: py tools/test/mutate_l10n_irrigation_suite.py [id-prefix ...]
import hashlib, os, subprocess, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "l10n-irrigation-suite-check.mjs"),
        os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs"),
        os.path.join(ROOT, "tools", "test", "l10n-tree-check.mjs")]
APP = "src/apps/IrrigationSuiteApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("C1-forward-call-line-flag-dropped", APP,
     one("                        _T(callK, callF)),\n                    RenderText.ALIGN_LEFT, FT.C.TEXT, true)",
         "                        _T(callK, callF)),\n                    RenderText.ALIGN_LEFT, FT.C.TEXT)"),
     "the advisory's field line (row 158's seventh site) handed to the second pass: E (forward call)"),
    ("C2-moisture-line-flag-dropped", APP,
     one("tostring(fid), tag),\n                    RenderText.ALIGN_LEFT, FT.C.TEXT, true)",
         "tostring(fid), tag),\n                    RenderText.ALIGN_LEFT, FT.C.TEXT)"),
     "a moisture line (the field tag and its state word) handed to the second pass: E (moisture line)"),
    ("C3-app-title-flag-dropped", APP,
     one('self:drawAppHeader(appTitle, "", true, true)', 'self:drawAppHeader(appTitle, "", nil, true)'),
     "the app's name, the file's text, handed to the second pass: E (FLAG at the header)"),
    ("C4-lock-fallback-back-to-scs009", APP,
     one('_T("ft_irr_advisory_locked_l7", "Unlocks with Pro Staff Co-Op at level 7")',
         '_T("ft_irr_advisory_locked_l7", "Unlocks at co-op level 7")'),
     "the lock line's code fallback back to SCS-009's words while English reads Wizard's: FALLBACK"),
    ("C5-mode-label-unkeyed", APP,
     one('operations = { key = "ft_irr_mode_operations", fallback = "Operations" },',
         'operations = { key = "ft_irr_mode_ops", fallback = "Operations" },'),
     "a mode tab's key no file carries: S1 (keyTables), E (the Operations tab)"),
    ("C6-systems-header-raw-english", APP,
     one('_T("ft_irr_systems", "SYSTEMS")', '"SYSTEMS"'),
     "a keyed header back to a raw English literal: S4, E"),
    ("C7-scs-source-label-flagged", APP,
     one("RenderText.ALIGN_LEFT, FT.C.TEXT, src.label == nil)", "RenderText.ALIGN_LEFT, FT.C.TEXT, true)"),
     "SCS's own water-source label drawn with the flag, losing the pass the ruling keeps for mod text: E (source label)"),
    ("T1-german-digraph-stripped", "translations/translation_de.xml",
     one('text="außerhalb des Zeitplans"', 'text="ausserhalb des Zeitplans"'),
     "a German value back to the import's digraph: ACCENT"),
    ("T2-czech-accent-stripped", "translations/translation_cz.xml",
     one('<text name="ft_rainKey_unknown" text="neznámo" />', '<text name="ft_rainKey_unknown" text="neznamo" />'),
     "a Czech value back to the import's stripped text: ACCENT"),
    ("T3-new-key-missing", "translations/translation_pl.xml",
     one('        <text name="ft_irr_mode_usage" text="Zużycie" />\n', ''),
     "a file without one of the 60 new keys: the text rows, E"),
    ("T4-new-key-english", "translations/translation_it.xml",
     one('text="Nessun sistema di irrigazione registrato."', 'text="No irrigation systems registered."'),
     "an Italian value as the English copy: the text rows"),
    ("T5-german-header-title-case", "translations/translation_de.xml",
     one('<text name="ft_water_header" text="WASSERQUELLEN" />', '<text name="ft_water_header" text="Wasserquellen" />'),
     "a German header in title case: CASE"),
    ("T6-placeholder-dropped", "translations/translation_fr.xml",
     one('text="%s  ·  parcelles %d  ·  débit %.2f/h"', 'text="%s  ·  parcelles  ·  débit %.2f/h"'),
     "a French line without one of English's placeholders: the placeholder row, X1"),
    ("T7-french-canadian-chinese", "translations/translation_fc.xml",
     one('<text name="ft_irr_idle" text="inactif" />', '<text name="ft_irr_idle" text="空闲" />'),
     "a French Canadian value in Chinese: SCRIPT-OUT"),
    ("T8-en-marker-back", "translations/translation_de.xml",
     one('<text name="ft_irr_advisory_locked_l18" text="Freigeschaltet mit der Pro Staff Co-Op ab Level 18" />',
         '<text name="ft_irr_advisory_locked_l18" text="[EN] Unlocks with Pro Staff Co-Op at level 18" />'),
     "a lock line stamped \"[EN]\" again: MARKER, the text rows"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bars():
    rc, out = 0, []
    for bar in BARS:
        r = subprocess.run(["node", bar], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
        rc = rc or r.returncode
        out += (r.stdout + r.stderr).strip().splitlines()
    return rc, out

only = sys.argv[1:]
rc, out = run_bars()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", " / ".join(l[:70] for l in out if ": PASS" in l))
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
    if t2 == t:
        print("  BAD EDIT %s (the edit changed nothing)" % mid); bad += 1; continue
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bars()
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
        print("  CRASHED  %s: a bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
