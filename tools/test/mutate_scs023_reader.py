# SCS-023 v2.2 §2a, the Irrigation Suite reader rebind: targeted mutation battery.
# The work in this PR: Operations, Usage and the coverage outline read one strict-farm private snapshot of the farm's
# systems and sources (nil is Unavailable, never an empty farm), the source rows through the host's canonical keys, the
# stop reason from each private row, and a fitted pivot on its own rain-key path. Each mutation undoes one piece, and a
# bar must FAIL on a named row: tools/test/renderer-literal-flag-check.mjs, whose rebind case runs Seasonal Crop
# Stress's own read code (tools/test/fixtures/scs-irrigation-3d80544.lua) over a two-farm world and scans the source
# for alias and public-list reads, and tools/test/l10n-irrigation-suite-check.mjs for the text rows. Both bars run for
# every mutation. Each file is restored byte-identical (sha256-checked) after each run. The bars must be green before
# any run. Usage: py tools/test/mutate_scs023_reader.py [id-prefix ...]
import hashlib, os, subprocess, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs"),
        os.path.join(ROOT, "tools", "test", "l10n-irrigation-suite-check.mjs")]
APP = "src/apps/IrrigationSuiteApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("R1-public-list-back", APP,
     one("return scs:getIrrigationSystems(farmId) end)", "return scs:getIrrigationSystems() end)"),
     "the no-argument public list read for the private detail: farm 2 is drawn (E), and the static row"),
    ("R2-nil-coerced-to-empty", APP,
     one('    if type(systems) ~= "table" or type(sources) ~= "table" then return nil, nil end\n',
         '    if type(systems) ~= "table" then systems = {} end\n    if type(sources) ~= "table" then sources = {} end\n'),
     "an unsynchronized snapshot read as a current empty farm: the pure client (E)"),
    ("R3-alias-read", APP,
     one("if src.isUnlimited == true then", "if src.unlimited == true then"),
     "a legacy alias read (the host publishes it too, so only the static row can see it)"),
    ("R4-stop-reason-not-read", APP,
     one("local stopTxt = _stopWords(sys.stopReason)", "local stopTxt = _stopWords(nil)"),
     "the private row's stopReason not read: dry source and no source vanish (E)"),
    ("R5-non-strict-farm", APP,
     one("    local farmId = data:getPlayerFarmIdStrict()\n    if farmId == nil then return nil, nil end\n    if type(scs.getIrrigationSystems)",
         "    local farmId = data:getPlayerFarmId()\n    if farmId == nil then return nil, nil end\n    if type(scs.getIrrigationSystems)"),
     "the non-strict farm id (falls back to farm 1 with no local player): no strict farm (E), and the static row"),
    ("R6-fitted-shows-source-stop", APP,
     one("                    if nextTxt ~= nil then bits[#bits + 1] = nextTxt end\n                    if #bits > 0 then",
         "                    if nextTxt ~= nil then bits[#bits + 1] = nextTxt end\n"
         "                    local srcStop = _stopWords(sys.stopReason)\n"
         "                    if srcStop ~= nil then bits[#bits + 1] = srcStop end\n                    if #bits > 0 then"),
     "a fitted pivot shown as ordinary scheduled service from its dry source (E: two lines say dry)"),
    ("R7-zero-remainder-not-dry", APP,
     one('if rem <= 0 or src.hasWater == false then return _T("ft_water_dry", "Dry") end',
         'if false then return _T("ft_water_dry", "Dry") end'),
     "a finite source at a readable zero shown as hours, not Dry (E)"),
    ("R8-coverage-fed-every-farm", APP,
     one("local polyCache = _cacheCoveragePolys(scs, systems)", "local polyCache = _cacheCoveragePolys(scs, scs.getIrrigationSystems(scs))"),
     "Bob's MAJOR: the coverage outline fed every farm's systems (E: farm 2's field outlined), and the static call row"),
    ("R9-owned-fields-non-strict", APP,
     one("    local farmId = data:getPlayerFarmIdStrict()\n    if farmId == nil then return nil, nil end\n    return data:getOwnedFields(farmId)",
         "    local farmId = data:getPlayerFarmId()\n    if farmId == nil then return nil, nil end\n    return data:getOwnedFields(farmId)"),
     "Bob's MINOR: the owned-field lists on the non-strict farm id (E: farm 1's field listed with no local player), and the static row"),
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
