# MAINTENANCE row 105, batch 16 (Financial Cockpit; FT-6, RSF-F130's debt rows): targeted mutation battery.
# The work in this PR: the cockpit's 98 keys in all 26 files, RSF-F130's seven keys added to every file (they existed
# only as code fallbacks), German's named defects and capitals, French's stripped accents, French Canadian from
# French; the heart's worst-vital label drawn with RSF-F166's flag. Each mutation undoes one piece, and a bar must
# FAIL on a named row: tools/test/l10n-financial-cockpit-check.mjs for the text rows, tools/test/renderer-literal-
# flag-check.mjs for the drawers (its E case walks the real home page and vital pocket through an IncomeManager
# stand-in shaped like IncomeMod's own view). Both bars run for every mutation. Each file is restored byte-identical
# (sha256-checked) after each run. Both bars must be green before any run.
# Usage: py tools/test/mutate_l10n_financial_cockpit.py [id-prefix ...]
import hashlib, os, subprocess, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "l10n-financial-cockpit-check.mjs"),
        os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs")]
APP = "src/apps/FinancialCockpitApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("C1-heart-label-flag-dropped", APP,
     one("FT_Renderer.truncate(worstLabel, 18), RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM, true)",
         "FT_Renderer.truncate(worstLabel, 18), RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)"),
     "the heart's worst-vital label handed to the renderer's second pass: F, E (FLAG)"),
    ("C2-emergency-row-reads-the-bank-loan-key", APP,
     one('y = self:drawRow(y, _T("ft_fc_emergency_loan", "Emergency loan"),\n            _money(snap.data, snap.emergencyOutstanding)',
         'y = self:drawRow(y, _T("ft_fc_loan", "Emergency loan"),\n            _money(snap.data, snap.emergencyOutstanding)'),
     "RSF-F130's emergency row labelled with the bank loan's key: E (emergency loan row)"),
    ("T1-f130-key-missing", "translations/translation_pl.xml",
     one('        <text name="ft_fc_emergency_loan" text="Pożyczka awaryjna" />\n', ''),
     "a file without one of RSF-F130's seven keys: the text rows, E"),
    ("T2-french-canadian-chinese", "translations/translation_fc.xml",
     one('text="GÉRER LE PRÊT" />', 'text="管理贷款" />'),
     "a French Canadian value in Simplified Chinese: SCRIPT-OUT"),
    ("T3-german-header-title-case", "translations/translation_de.xml",
     one('<text name="ft_fc_section_rhythm" text="RHYTHMUS" />', '<text name="ft_fc_section_rhythm" text="Rhythmus" />'),
     "a German section header in title case again: CASE"),
    ("T4-french-accent-stripped", "translations/translation_fr.xml",
     one('<text name="ft_fc_history_host_only" text="Hôte seulement en v1" />', '<text name="ft_fc_history_host_only" text="Hote seulement en v1" />'),
     "French's host-only text stripped again: ACCENT"),
    ("T5-forecast-help-misnames-the-badge", "translations/translation_de.xml",
     one('Teilweise, wenn Werte fehlen.', 'Unvollständig, wenn Werte fehlen.'),
     "the German forecast help names a badge the page does not draw: CONTAINS"),
    ("T6-english-copy", "translations/translation_it.xml",
     one('<text name="ft_fc_forecast_disclaimer" text="Solo una proiezione. I flussi mancanti non vengono inventati." />',
         '<text name="ft_fc_forecast_disclaimer" text="Projection only. Missing flows are not invented." />'),
     "an Italian value back to the English copy: the text rows"),
    ("F1-loan-back-to-ft6", "translations/translation_en.xml",
     one('<text name="ft_fc_loan" text="Bank loan" />', '<text name="ft_fc_loan" text="Loan" />'),
     "English's bank loan row back to FT-6's Loan, hiding RSF-F130's word (Bob's fold 1): FALLBACK"),
    ("F2-history-help-loses-time-guard", "translations/translation_en.xml",
     one('Needs Time Guard for the month clock. Host / single-player&#10;only in v1. Gaps stay gaps.',
         'Host / single-player only in v1. Gaps stay gaps.'),
     "English's history help without the code's Time Guard line: FALLBACK, the text rows"),
    ("F3-vital-detail-flag-dropped", APP,
     one('v.detail or "", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)', 'v.detail or "", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)'),
     "a vital's detail handed to the renderer's second pass (Bob's fold 2): E (FLAG)"),
    ("F4-forecast-note-flag-dropped", APP,
     one('tostring(line.note), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)', 'tostring(line.note), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)'),
     "a forecast note through the second pass: E (FLAG; IncomeMod's 07:00 split to 07: 00)"),
    ("F6-vital-row-flags-dropped", APP,
     one('y = self:drawRow(y, label, v.valueText, nil, _bandColor(v.band), true, true)', 'y = self:drawRow(y, label, v.valueText, nil, _bandColor(v.band))'),
     "a vital's label and value through the second pass (Bob's fold 2): E (FLAG)"),
    ("F7-forecast-row-flags-dropped", APP,
     one('y = self:drawRow(y, line.label, line.value, nil, FT.C.TEXT_NORMAL, true, true)', 'y = self:drawRow(y, line.label, line.value, nil, FT.C.TEXT_NORMAL)'),
     "a forecast line's label and value through the second pass (Bob's fold 2): E (FLAG)"),
    ("F5-pay-mode-raw", APP,
     one('local modeText, tabletWord = _payModeText(snap.income.mode)', 'local modeText, tabletWord = tostring(snap.income.mode), false'),
     "the flows pocket's pay mode back to IncomeMod's English: E (flows pay mode)"),
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
