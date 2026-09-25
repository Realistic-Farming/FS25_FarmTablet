# MAINTENANCE row 105, the App Store PR: targeted mutation battery for its draw-site change
# (Desk's rule for the wave: a literal the app draws and its FT.AUTO_L10N key change together,
# so a mutation that changes one side only must be killed by a row showing the lookup miss).
#
# Each mutation edits one file in place, runs tools/test/l10n-appstore-check.mjs and expects it
# to FAIL on a named row; the file is restored byte-identical (sha256-checked) after each one.
# The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_appstore.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REG = "src/core/AppRegistry.lua"
APP = "src/apps/AppStoreApp.lua"
CON = "src/core/Constants.lua"
FR = "translations/translation_fr.xml"
EM = chr(0x2014)
BS = chr(92)

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("A1-description-literal-only", REG,
     one('"Animal pens - food, water, cleanliness"', '"Animal pens %s food, water, cleanliness"' % EM),
     "the draw site goes back to the em dash, the map key does not: the lookup misses"),
    ("A2-description-map-key-only", CON,
     one('["Log field work sessions - field, vehicle, task, duration"]', '["Log field work sessions %s field, vehicle, task, duration"]' % EM),
     "the map key goes back to the em dash, the draw site does not: the lookup misses"),
    ("A3-help-line-literal-only", APP,
     one('"No setup needed - apps appear automatically when the' + BS + 'n"', '"No setup needed %s apps appear automatically when the' % EM + BS + 'n"'),
     "a help line's draw site goes back to the em dash: its line never resolves"),
    ("A4-help-line-map-key-only", CON,
     one('["This is a shortcut - you can also click the icon in' + BS + 'n"]', '["This is a shortcut %s you can also click the icon in' % EM + BS + 'n"]'),
     "a help line's map key goes back to the em dash: the retry finds nothing"),
    ("A5-new-description-entry-dropped", CON,
     one('FT.AUTO_L10N["Organic certification and practice advice"] = "ft_auto_organic_certification_and_practice_advice"\n', ''),
     "one of the eleven new description entries removed: that description reads English again"),
    ("A6-install-hint-concatenated", APP,
     one('desc = FT.l10nFormat("ft_appstore_install_to_enable", "Install %s to enable", known.mod)', 'desc = "Install " .. known.mod .. " to enable"'),
     "the install hint goes back to a concatenation no map can hold"),
    ("A7-installed-count-concatenated", APP,
     one('FT.l10nFormat("ft_appstore_installed_count", "%d installed", #apps)', 'tostring(#apps) .. " " .. FT.l10nAuto("installed")'),
     "the header's installed count goes back to a concatenation"),
    ("A8-dairy-label-entry-dropped", CON,
     one('FT.AUTO_L10N["Dairy"] = "ft_auto_dairy"\n', ''),
     "the Dairy row label loses its map entry"),
    ("A9-description-english-copied", FR,
     one('<text name="ft_auto_tablet_configuration" text="Configuration de la tablette" />', '<text name="ft_auto_tablet_configuration" text="Tablet configuration" />'),
     "a translated description replaced by the English text"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "l10n-appstore-check.mjs")],
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
    except AssertionError as e:
        print("  BAD EDIT %s (%s)" % (mid, e)); bad += 1; continue
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
    finally:
        open(path, "wb").write(raw)
        assert sha(path) == before, "restore failed for " + rel
    rows = [l.strip() for l in out if l.strip().startswith("FAIL ")]
    if rc != 0 and rows:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        for l in rows[:4]: print("        " + l[:170])
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: the bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
