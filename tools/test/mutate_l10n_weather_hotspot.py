# MAINTENANCE row 105, batch 5 (Weather, Hotspot Manager): targeted mutation battery.
# The logic in this PR: texts the apps built at run time from English (string.format, concatenations,
# English plural endings) moved onto named keys (FT.l10n, FT.l10nFormat); words the apps chose by
# expression or returned from a helper (the feel, cloud and forecast condition words, the hotspot
# categories) now go through FT.l10nAuto; the Weather dial's chip labels are literal key calls instead of
# an expression-chosen key; the Weather condition label SNOW gained its map entry and CLEAR its own key
# (the map sends "CLEAR" to the Field Jobs button word). Each mutation undoes one piece, or breaks one
# text row the translation leans on, and the bar tools/test/l10n-weather-hotspot-check.mjs must FAIL on
# a named row. Each file is restored byte-identical (sha256-checked) after each run. The bar must be
# green before any run.
# Usage: py tools/test/mutate_l10n_weather_hotspot.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-weather-hotspot-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("W1-feel-label-drawn-raw", "src/apps/WeatherApp.lua",
     one('local feelStr = FT.l10nAuto(w.temperature < 0 and "Freezing"', 'local feelStr = (w.temperature < 0 and "Freezing"'),
     "the temperature's feel word no longer looked up: S4"),
    ("W2-rain-word-concatenated", "src/apps/WeatherApp.lua",
     one('y = self:drawRow(y, "Precipitation", rainText, nil, FT.C.WEATHER_RAIN)', 'y = self:drawRow(y, "Precipitation", rainText .. " Rain", nil, FT.C.WEATHER_RAIN)'),
     "the rain text built from an English word again: S3"),
    ("W3-day-plus-concatenated", "src/apps/WeatherApp.lua",
     one('FT.l10nFormat("ft_weather_day_plus_fmt", "Day +%d", i)', '"Day +" .. i'),
     "the forecast day label built from English: S3, S4"),
    ("W4-chip-label-raw", "src/apps/WeatherApp.lua",
     one('FT.l10n("ft_weather_mode_wet", "Wet")', '"Wet"'),
     "a dial chip label drawn without its key: S4"),
    ("W5-wind-back-to-format", "src/apps/WeatherApp.lua",
     one('FT.l10nFormat("ft_weather_wind_kmh_fmt", "%.0f km/h", w.windSpeed)', 'string.format("%.0f km/h", w.windSpeed)'),
     "the wind speed built by string.format again: S3, S4"),
    ("W6-snow-map-entry-gone", "src/core/Constants.lua",
     one('FT.AUTO_L10N["SNOW"] = "ft_auto_snow_2"', '-- (no SNOW entry)'),
     "the condition label SNOW without its map entry: S2"),
    ("W7-clear-label-back-on-the-map", "src/apps/WeatherApp.lua",
     one('clear = FT.l10n("ft_weather_cond_clear", "CLEAR"),', 'clear = "CLEAR",'),
     "the clear-sky label on the Field Jobs button word again: S2, S4"),
    ("H1-category-label-raw", "src/apps/HotspotManagerApp.lua",
     one('then return FT.l10nAuto("Mission")', 'then return "Mission"'),
     "a hotspot category returned without its lookup: S4"),
    ("H2-removed-count-format", "src/apps/HotspotManagerApp.lua",
     one('FT.l10nFormat("ft_hotspot_removed", "Removed %d pins.", #toRemove)', 'string.format("Removed %d pin(s).", #toRemove)'),
     "the removed-pins message built by string.format again: S4"),
    ("H3-remove-label-format", "src/apps/HotspotManagerApp.lua",
     one('FT.l10nFormat("ft_hotspot_remove_fmt", "REMOVE (%d)", selectedCount)', 'string.format("REMOVE (%d)", selectedCount)'),
     "the REMOVE button's count built by string.format again: S4"),
    ("H4-subtitle-concat", "src/apps/HotspotManagerApp.lua",
     one('FT.l10nFormat("ft_hotspot_total_fmt", "%d total", total)', '(total .. " total")'),
     "the header count built from English again: S3, S4"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_hotspot_removed" text="%d Pins entfernt." />', '<text name="ft_hotspot_removed" text="Pins entfernt." />'),
     "a German value loses its placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_weather_rain_light" text="小雨" />', '<text name="ft_weather_rain_light" text="kosame" />'),
     "a Japanese value written in Latin letters: the script row"),
    ("T3-english-copy", "translations/translation_fr.xml",
     one('<text name="ft_hotspot_tick_first" text="Cochez des repères à supprimer d\'abord." />', '<text name="ft_hotspot_tick_first" text="Tick pins to remove first." />'),
     "a French value reverted to the English text: the text rows"),
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
