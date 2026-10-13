# #212: targeted mutation battery for the wheel scroll that redraws once per frame, run against
# tools/test/lua/FT-212-scroll_coalesce_spec_test.lua through run-tests.mjs (two Lua files, a few
# seconds). Each mutation breaks one part of the change in src/FarmTabletUI.lua, runs the bar, and
# expects it to FAIL on a named row; the file is restored byte-identical (sha256-checked) after each
# one. The bar must be green before any run.
#
# NOT RUN, and why:
#   - `_flushContentScroll`'s `isOpen` / `uiState` guard: update reaches the flush only for an open
#     tablet in the app state, and the click path only from the app view; R2 pins the closed case;
#   - the comment lines.
# Usage: py -u tools/test/mutate_ft212_scroll.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UI = "src/FarmTabletUI.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new, 1)
    return f

MUTATIONS = [
    ("S1-immediate-redraw", UI, one("    self._contentScrollDirty = true\n    return true\n",
                                    "    self._contentScrollDirty = true\n    self:_flushContentScroll()\n    return true\n"),
     "each notch redraws at once again (W1)"),
    ("S2-no-frame-flush", UI, one("        self:_updateContentScrollSmooth(dt)\n        self:_flushContentScroll()\n",
                                  "        self:_updateContentScrollSmooth(dt)\n"),
     "the frame never draws the scrolled page (W2, B2)"),
    ("S3-no-click-flush", UI, one("            self:_flushContentScroll()\n            -- Inert first", "            -- Inert first"),
     "a click right after the wheel hits the buttons where they were (C1, C2)"),
    ("S4-double-clear", UI, one("    -- here as well rebuilt the page's layer twice per redraw.\n    self:_drawContent()\n",
                                "    -- here as well rebuilt the page's layer twice per redraw.\n    self.r:clearAppLayer()\n    self:_drawContent()\n"),
     "one redraw clears the layer twice again (W2)"),
    ("S5-full-draw-keeps-pending", UI, one("    self._contentScrollDirty = false\n    self.r:clearAppLayer()\n", "    self.r:clearAppLayer()\n"),
     "a full draw leaves the scroll pending, so the frame draws it again (R1)"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "run-tests.mjs")],
                       capture_output=True, text=True, encoding="utf-8", cwd=os.path.join(ROOT, "tools", "test"))
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
