# MAINTENANCE row 105, batch 12 (Income, Tax, Worker Costs): targeted mutation battery.
# The logic in this PR: the help bodies moved onto keys; the companion mods' English words (pay mode, tax rate,
# wage level, cost mode, roster level and status) reach their keys through COMPANION_WORD; the Pro-Staff heading,
# the level counts and the worker's stats line no longer build English at run time. Each mutation undoes one
# piece, or breaks one text row the translation leans on, and the bar tools/test/l10n-income-tax-workers-check.mjs
# must FAIL on a named row. Each file is restored byte-identical (sha256-checked) after each run. The bar must be
# green before any run.
# Usage: py tools/test/mutate_l10n_income_tax_workers.py [id-prefix ...]
import hashlib, os, subprocess, sys

# Failure lines quote locale text (Korean, Cyrillic); a piped Windows console is cp1252.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-income-tax-workers-check.mjs")
APP = "src/apps/IncomeApp.lua"
EN = "translations/translation_en.xml"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("I1-help-body-literal", APP,
     one('body  = FT.l10n("ft_tax_help_total_body", ', 'body  = ('),
     "a help body drawn as a literal again: S2, S4"),
    ("I2-prostaff-heading-concat", APP,
     one('FT.l10nFormat("ft_wrk_prostaff_fmt", "PRO-STAFF  (%d)", tonumber(snap.count) or 0)', '"PRO-STAFF  (" .. tostring(snap.count) .. ")"'),
     "the Pro-Staff heading glued to English again: S3, S4"),
    ("I3-stats-line-format", APP,
     one('FT.l10nFormat("ft_wrk_worker_stats_fmt", ', 'string.format('),
     "the worker's stats line built by string.format again: S3, S4"),
    ("I4-companion-word-dropped", APP,
     one('    ["Per Hectare"]     = function() return FT.l10n("ft_companion_per_hectare", "Per Hectare") end,\n', ''),
     "a companion word without its key (WorkerCosts' Per Hectare drawn English): S4"),
    ("I5-levels-format", APP,
     one('FT.l10nFormat("ft_wrk_levels_fmt", ', 'string.format('),
     "the level counts built by string.format again: S3, S4"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_wrk_worker_stats_fmt" text="%.1f h  -  %d Aufträge  -  Erschöpfung %d%%" />', '<text name="ft_wrk_worker_stats_fmt" text="%.1f h  -  %d Aufträge  -  Erschöpfung" />'),
     "a German stats line loses a placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_companion_novice" text="初心者" />', '<text name="ft_companion_novice" text="shoshinsha" />'),
     "a Japanese level written in Latin letters: the script row, the CONTAINS row"),
    ("T3-help-misnames-level", "translations/translation_fr.xml",
     one('(Débutant / Expérimenté / Maître)', '(Apprenti / Expérimenté / Maître)'),
     "a French roster help naming a level the row does not draw: the CONTAINS row"),
    ("T4-percent-reads-as-placeholder", "translations/translation_fr.xml",
     one('remboursement de 20 %, vous payez', 'remboursement de 20 %de vous payez'),
     "a French percent that reads as a placeholder: the text rows"),
    ("T5-line-break-lost", "translations/translation_ru.xml",
     one('Включает или выключает мод без удаления.&#10;Изменения', 'Включает или выключает мод без удаления. Изменения'),
     "a Russian help body one line short: the text rows"),
    ("W1-weekly-line-back", "translations/translation_en.xml",
     one('Daily = once per in-game day." />', 'Daily = once per in-game day.&#10;Weekly = once per in-game week." />'),
     "Income's help names a Weekly mode IncomeMod does not have (row 155): MODE"),
    ("W2-monthly-line-back", "translations/translation_en.xml",
     one('Per Hectare = billed by area worked, settled at midnight." />', 'Monthly = accumulated and charged at month end." />'),
     "Worker Costs' help names a Monthly mode WorkerCosts does not have (row 155): MODE"),
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
