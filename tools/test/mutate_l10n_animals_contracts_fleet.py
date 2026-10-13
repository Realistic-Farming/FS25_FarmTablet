# MAINTENANCE row 105, batch 2 (Animal Husbandry, Contracts, Fleet Manager): targeted mutation battery.
# The logic in this PR: texts the apps build at run time moved onto named keys (FT.l10n / FT.l10nFormat),
# the Contracts type names and status label drawn through FT.l10nAuto, and the pen count's two forms as
# literal keys. Each mutation undoes one piece, or breaks one text row the translation leans on, and the
# bar tools/test/l10n-animals-contracts-fleet-check.mjs must FAIL on a named row.
# Each file is restored byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_animals_contracts_fleet.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-animals-contracts-fleet-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("A1-pen-count-one-key", "src/apps/AnimalHusbandryApp.lua",
     one('    local penCount = (#pens == 1) and FT.l10nFormat("ft_count_pen", "%d pen", #pens)\n        or FT.l10nFormat("ft_count_pens", "%d pens", #pens)\n',
         '    local penCount = FT.l10nFormat(#pens == 1 and "ft_count_pen" or "ft_count_pens", "%d pens", #pens)\n'),
     "the pen count's key chosen by an expression again: neither form is seen as drawn: S4"),
    ("C1-minutes-back-to-concat", "src/apps/ContractsApp.lua",
     one('FT.l10nFormat("ft_contracts_minutes_left", "%dm left", m)', 'm .. "m left"'),
     "the minutes-left text built from an English literal: S4"),
    ("C2-type-name-raw", "src/apps/ContractsApp.lua",
     one("    if name then return FT.l10nAuto(name) end\n", "    if name then return name end\n"),
     "the contract type name drawn in English: X3"),
    ("C3-status-drawn-raw", "src/apps/ContractsApp.lua",
     one("        local shownStatus = FT.l10nAuto(statusLabel)\n", "        local shownStatus = statusLabel\n"),
     "the status badge drawn in English: S5"),
    ("C4-active-count-concat", "src/apps/ContractsApp.lua",
     one('FT.l10nFormat("ft_contracts_n_active", "%d active", totalActive)', 'totalActive .. " active"'),
     "the subtitle's active count built from an English literal: S4"),
    ("C5-game-time-concat", "src/apps/ContractsApp.lua",
     one('FT.l10nFormat("ft_contracts_game_time", "Game time: %s", timeStr == "EXPIRED" and FT.l10nAuto("EXPIRED") or timeStr)',
         '"Game time: " .. timeStr'),
     "the game-time line built from an English literal: S3, S4"),
    ("F1-vehicles-count-concat", "src/apps/FleetManagerApp.lua",
     one('FT.l10nFormat("ft_fleet_vehicles_fmt", "%d vehicles", #fleet)', '#fleet .. " vehicles"'),
     "the vehicle count built from an English literal: S4"),
    ("F2-fleet-helper-fallback", "src/apps/FleetManagerApp.lua",
     one("    if FT_UI_TEXT ~= nil then return FT_UI_TEXT(key, fallback) end\n    if g_i18n and key and g_i18n:hasText(key) then return g_i18n:getText(key) end\n",
         ""),
     "Fleet Manager's own text helper never reads the file: X1"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_contracts_game_time" text="Spielzeit: %s" />', '<text name="ft_contracts_game_time" text="Spielzeit" />'),
     "a German value loses its placeholder: the text rows"),
    ("T2-romanised-russian", "translations/translation_ru.xml",
     one('<text name="ft_fleet_fuel" text="Топливо" />', '<text name="ft_fleet_fuel" text="Toplivo" />'),
     "a Russian value written in Latin letters: the script row"),
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
