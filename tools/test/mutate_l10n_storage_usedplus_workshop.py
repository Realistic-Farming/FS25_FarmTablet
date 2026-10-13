# MAINTENANCE row 105, batch 4 (Storage, Used Plus, Workshop): targeted mutation battery.
# The logic in this PR: texts the apps built at run time from English (string.format, concatenations,
# English plural endings) moved onto named keys (FT.l10n, FT.l10nFormat), and two drawn help literals
# lost their em dashes. Each mutation
# undoes one piece, or breaks one text row the translation leans on, and the bar
# tools/test/l10n-storage-usedplus-workshop-check.mjs must FAIL on a named row. Each file is
# restored byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_storage_usedplus_workshop.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-storage-usedplus-workshop-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("K1-workshop-subtitle-concat", "src/apps/WorkshopApp.lua",
     one('self:drawAppHeader("Workshop", shopsText .. "  |  " .. nearbyText)', 'self:drawAppHeader("Workshop", #workshops .. " shops  |  " .. #nearby .. " vehicles nearby")'),
     "the Workshop subtitle built from English again: S3"),
    ("K2-em-dash-back", "src/apps/WorkshopApp.lua",
     one('"breakdowns - repair before reaching 80%." },', '"breakdowns \u2014 repair before reaching 80%." },'),
     "a drawn help line with an em dash again: S2"),
    ("K3-nearby-heading-concat", "src/apps/WorkshopApp.lua",
     one('FT.l10nFormat("ft_workshop_nearby_fmt", "NEARBY  (%d)", #nearby)', '"NEARBY  (" .. #nearby .. ")"'),
     "the NEARBY heading built from English: S3, S4"),
    ("S1-peak-back-to-format", "src/apps/StorageApp.lua",
     one('"  " .. FT.l10nFormat("ft_storage_peak_fmt", "Peak: %s  (day %d)",', 'string.format("  Peak: %s  (day %d)",'),
     "the peak-price line built by string.format again: S4"),
    ("U1-days-left-back-to-format", "src/apps/UsedPlusApp.lua",
     one('FT.l10nFormat("ft_usedplus_days_left", "%d days remaining", daysLeft)', 'string.format("%d days remaining", daysLeft)'),
     "the days-remaining text built by string.format again: S4"),
    ("K4-fuel-back-to-format", "src/apps/WorkshopApp.lua",
     one('FT.l10nFormat("ft_workshop_fuel_fmt", "%.0f%%  (%.0fL / %.0fL)", fuelPct', 'string.format("%.0f%%  (%.0fL / %.0fL)", fuelPct'),
     "the fuel line built by string.format again: S3, S4"),
    ("S2-silo-count-concat", "src/apps/StorageApp.lua",
     one('FT.l10nFormat("ft_storage_silos", "%d silos", storage.siloCount)', '(storage.siloCount .. " silos")'),
     "the silo count with an English plural ending again: S4"),
    ("S3-em-dash-back", "src/apps/StorageApp.lua",
     one('"Single station - no comparison available"', '"Single station \u2014 no comparison available"'),
     "a drawn literal with an em dash again: S2"),
    ("U2-deal-line-back-to-format", "src/apps/UsedPlusApp.lua",
     one('FT.l10nFormat("ft_usedplus_deal_detail_fmt", "%s  \u2022  %s/mo  \u2022  %d mo left",', 'string.format("%s  \u2022  %s/mo  \u2022  %d mo left",'),
     "the finance deal line built by string.format again: S4"),
    ("U3-offer-label-raw", "src/apps/UsedPlusApp.lua",
     one('FT.l10n("ft_usedplus_offer", "OFFER")', '"  OFFER"'),
     "the OFFER label drawn without its key: S4"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_workshop_nearby_fmt" text="IN DER NÄHE  (%d)" />', '<text name="ft_workshop_nearby_fmt" text="IN DER NÄHE" />'),
     "a German value loses its placeholder: the text rows"),
    ("T2-romanised-korean", "translations/translation_kr.xml",
     one('<text name="ft_auto_repair_vehicle" text="차량 수리" />', '<text name="ft_auto_repair_vehicle" text="charyang suri" />'),
     "a Korean value written in Latin letters: the script row"),
    ("T3-english-copy", "translations/translation_es.xml",
     one('<text name="ft_auto_diagnostics" text="DIAGNÓSTICO" />', '<text name="ft_auto_diagnostics" text="DIAGNOSTICS" />'),
     "a Spanish value reverted to the English text: the text rows"),
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
