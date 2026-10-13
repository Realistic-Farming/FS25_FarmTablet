# MAINTENANCE row 105, batch 3 (Farm Stats, Production Buildings, Random World Events, Market Dynamics):
# targeted mutation battery. The logic in this PR: five texts the apps built at run time from English
# (string.format, a concatenation) moved onto named keys (FT.l10nFormat), and two drawn help literals and
# their map entries without their em dashes. Each mutation undoes one piece, or breaks one text row the
# translation leans on, and the bar tools/test/l10n-farmstats-production-events-market-check.mjs must FAIL on
# a named row. Each file is restored byte-identical (sha256-checked) after each run. The bar must be green
# before any run.
# Usage: py tools/test/mutate_l10n_farmstats_production_events_market.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-farmstats-production-events-market-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("H1-hectares-back-to-format", "src/apps/FarmStatsApp.lua",
     one('FT.l10nFormat("ft_auto_1f_ha", "%.1f ha", farmArea)', 'string.format("%.1f ha", farmArea)'),
     "the area built from an English literal: S3, S4"),
    ("R1-duration-back-to-format", "src/apps/RandomWorldEventsApp.lua",
     one('FT.l10nFormat("ft_rwe_duration_fmt", "%dm / %dm", remMin, durMin)', 'string.format("%dm / %dm", remMin, durMin)'),
     "the event duration built from an English literal: S3, S4"),
    ("M1-events-heading-concat", "src/apps/MarketDynamicsApp.lua",
     one('FT.l10nFormat("ft_md_active_events_fmt", "ACTIVE EVENTS  (%d)", #activeEvents)', '"ACTIVE EVENTS  (" .. #activeEvents .. ")"'),
     "the active-events heading built from an English literal: S3, S4"),
    ("M2-intensity-back-to-format", "src/apps/MarketDynamicsApp.lua",
     one('FT.l10nFormat("ft_md_event_intensity_fmt", "%d%%  |  %dm", intPct, remMin)', 'string.format("%d%%  |  %dm", intPct, remMin)'),
     "the event's intensity and time built from an English literal: S3, S4"),
    ("M3-volatility-back-to-format", "src/apps/MarketDynamicsApp.lua",
     one('FT.l10nFormat("ft_md_volatility_fmt", "%.1fx", mgr.marketEngine.volatilityScale)', 'string.format("%.1fx", mgr.marketEngine.volatilityScale)'),
     "the volatility built by string.format again: S3, S4"),
    ("E1-em-dash-back", "src/apps/FarmStatsApp.lua",
     one('"Net Worth: balance minus loan - your true financial position." },', '"Net Worth: balance minus loan \u2014 your true financial position." },'),
     "a drawn help line with an em dash again: S2"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_rwe_duration_fmt" text="%d Min. / %d Min." />', '<text name="ft_rwe_duration_fmt" text="%d Min." />'),
     "a German value loses a placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_auto_building_list" text="建物リスト" />', '<text name="ft_auto_building_list" text="Tatemono risuto" />'),
     "a Japanese value written in Latin letters: the script row"),
    ("T3-english-copy", "translations/translation_es.xml",
     one('<text name="ft_auto_integration" text="Integración" />', '<text name="ft_auto_integration" text="Integration" />'),
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
