# MAINTENANCE row 138: targeted mutation battery for the character-based cuts, run against
# tools/test/utf8-cut-check.mjs. Each mutation puts one byte-based measure or cut back, runs the
# bar, and expects it to FAIL on a named row; the file is restored byte-identical (sha256-checked)
# after each one. The bar must be green before any run. One bar run takes about a minute.
# The sites: the four named in row 138 (the home grid label, FT_Renderer.truncate, the App Store
# description, SettingsApp's short()), the helpers they share, and two of the other drawn-text
# cuts (an IncomeApp name, the FarmTabletUI notice title), which only C4 can see.
# Usage: py -u tools/test/mutate_utf8_cut.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CON = "src/core/Constants.lua"
REN = "src/utils/Renderer.lua"
HOME = "src/ui/HomeScreen.lua"
SET = "src/apps/SettingsApp.lua"
INC = "src/apps/IncomeApp.lua"
UI = "src/FarmTabletUI.lua"
STORE = "src/apps/AppStoreApp.lua"
ELL = chr(0x2026)

def one(old, new):
    def f(t):
        assert t.count(old) >= 1, (old[:60], t.count(old))
        return t.replace(old, new, 1)
    return f

MUTATIONS = [
    ("U1-truncate-by-bytes", REN,
     one('    if FT.utf8Len(str) <= maxLen then return str end\n    return FT.utf8Sub(str, math.max(1, maxLen - 1)) .. "%s"' % ELL,
         '    if #str <= maxLen then return str end\n    return str:sub(1, math.max(1, maxLen - 1)) .. "%s"' % ELL),
     "FT_Renderer.truncate measures and cuts in bytes again"),
    ("U2-sub-counts-every-byte", CON,
     one('        if b < 128 or b >= 192 then\n            n = n + 1\n            if n > count then return string.sub(s, 1, i - 1) end',
         '        if true then\n            n = n + 1\n            if n > count then return string.sub(s, 1, i - 1) end'),
     "FT.utf8Sub counts continuation bytes as characters"),
    ("U3-len-counts-bytes", CON,
     one('        if b < 128 or b >= 192 then n = n + 1 end', '        n = n + 1'),
     "FT.utf8Len returns the byte count"),
    ("U4-cut-by-bytes", CON,
     one('    local cut = FT.utf8Sub(s, maxChars)', '    local cut = string.sub(s, 1, maxChars)'),
     "FT.utf8Cut cuts the label in bytes"),
    ("U5-home-label-by-bytes", HOME,
     one('    return FT.utf8Cut(name, maxChars, 4)', '    if #name <= maxChars then return name end\n    return string.sub(name, 1, maxChars)'),
     "the home grid's label cut goes back to bytes"),
    ("U7-settings-short-by-bytes", SET,
     one('    if FT.utf8Len(text) <= maxLen then return text end\n    return FT.utf8Sub(text, maxLen - 1) .. "."',
         '    if string.len(text) <= maxLen then return text end\n    return string.sub(text, 1, maxLen - 1) .. "."'),
     "SettingsApp's short() measures and cuts in bytes again"),
    ("U8-appstore-desc-by-bytes", STORE,
     one('if FT.utf8Len(desc) > 72 then desc = FT.utf8Sub(desc, 70) .. ">" end', 'if #desc > 72 then desc = desc:sub(1, 70) .. ">" end'),
     "the App Store's description cut goes back to bytes"),
    ("U6-one-app-site-by-bytes", INC,
     one('if FT.utf8Len(nm) > 16 then nm = FT.utf8Sub(nm, 14) .. ">" end', 'if #nm > 16 then nm = nm:sub(1,14) .. ">" end'),
     "one app's name cut (IncomeApp) goes back to bytes"),
    ("U9-notice-title-by-bytes", UI,
     one('if FT.utf8Len(tTitle) > 32 then tTitle = FT.utf8Sub(tTitle, 31) .. "." end', 'if string.len(tTitle) > 32 then tTitle = string.sub(tTitle, 1, 31) .. "." end'),
     "the notice title's cut (FarmTabletUI) goes back to bytes"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "utf8-cut-check.mjs")],
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
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
    finally:
        open(path, "wb").write(raw)
        assert sha(path) == before, "restore failed for " + rel
    summary = [l for l in out if l.startswith("utf8-cut:")]
    if rc != 0 and summary and "failure" in summary[-1]:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        print("        " + summary[-1])
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: the bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
