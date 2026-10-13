# MAINTENANCE row 236: targeted mutation battery for the version the tablet shows, run against
# tools/test/version-label-check.mjs. Each mutation breaks one condition of the lookup in
# src/core/Constants.lua, runs the bar, and expects it to FAIL on a named case; the file is restored
# byte-identical (sha256-checked) after each one. The bar must be green before any run. One bar run
# takes about two seconds.
#
# NOT RUN, and why:
#   - `if ok then mod = found end` without the `ok`: a failed pcall's second value is the error string,
#     never a table, so the record test refuses it either way (equivalent);
#   - the `FarmTabletModName ~= nil` guard: main.lua latches the name before it sources this file, and a
#     nil name finds no record anyway (getModByName(nil) is nameToMod[nil]); equivalent;
#   - the comment lines.
# Usage: py -u tools/test/mutate_version_label.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CON = "src/core/Constants.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new, 1)
    return f

GUARD = '    if g_modManager ~= nil and type(g_modManager.getModByName) == "function" and FarmTabletModName ~= nil then\n'
LOOKUP = '        local ok, found = pcall(g_modManager.getModByName, g_modManager, FarmTabletModName)\n'
RECORD = '    if type(mod) == "table" and type(mod.version) == "string" and mod.version ~= "" then\n'

MUTATIONS = [
    ("V1-never-assigned", CON, one('        FT.VERSION = mod.version\n', ''),
     "the record is read and never shown: the hand-kept copy again (A, G, H)"),
    ("V2-unprotected-lookup", CON, one(LOOKUP, '        local ok, found = true, g_modManager:getModByName(FarmTabletModName)\n'),
     "a lookup that throws stops the file loading (E)"),
    ("V3-empty-version-shown", CON, one(RECORD, '    if type(mod) == "table" and type(mod.version) == "string" then\n'),
     "an empty version is shown as the version (D)"),
    ("V4-any-version-type", CON, one(RECORD, '    if type(mod) == "table" and mod.version ~= "" then\n'),
     "a record with no version sets FT.VERSION to nil (F)"),
    ("V5-current-name-only", CON, one(LOOKUP, LOOKUP.replace("g_modManager, FarmTabletModName)", "g_modManager, g_currentModName)")),
     "a live re-source, with g_currentModName nil, finds no record (G)"),
    ("V6-hardcoded-name", CON, one(LOOKUP, LOOKUP.replace("g_modManager, FarmTabletModName)", 'g_modManager, "FS25_FarmTablet")')),
     "a mod installed under another name finds no record (H)"),
    ("V7-no-manager-guard", CON, one(GUARD, '    if FarmTabletModName ~= nil then\n'),
     "no mod manager stops the file loading (C)"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "version-label-check.mjs")],
                       capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-8:]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:110])
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
    if t2 == t:
        print("  BAD EDIT %s (the edit changed nothing)" % mid); bad += 1; continue
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
    finally:
        open(path, "wb").write(raw)
        assert sha(path) == before, "restore failed for " + rel
    named = [l.strip() for l in out if l.strip().startswith("FAIL ")]
    if rc != 0 and named:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        for l in named[:3]: print("        " + l[:200])
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: the bar failed without naming a case (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
