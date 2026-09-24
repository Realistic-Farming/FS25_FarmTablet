# RSF-F357 section 9b, the tablet's NPC drawer mutation battery: src/apps/IncomeApp.lua's NPC
# FAVOR drawer (the shared work page, the watch and its release, the roster view, the
# compatibility read). Rows live in RSF-F357-tablet_drawer_spec_test.lua.
#
# KILLED* means killed only by a Lua error: a weak kill, treated as a failure.
#
# NOT RUN, and why:
#   - the pcall around each adapter read: a host adapter that throws is the host's defect; the
#     drawer's pcall only turns it into the unavailable row. No host in the spec throws, so the
#     mutation would read the same. Declared defence in depth, not run.
#
# Anchors are written with "\n"; in a CRLF file they are matched after normalising.
#
# RUN IT ALONE, through the test lock. A battery edits production files in place.
#
# Usage: py tools/test/mutate_rsf_f357_tablet.py [id-prefix ...]
import hashlib, os, subprocess, sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def p(rel): return os.path.join(ROOT, rel)

APP = "src/apps/IncomeApp.lua"

MUTATIONS = [
 ("T01-watch-never-registered", APP,
  [("        self._npcWorkWatching = true\n        self._npcWorkHost = npcSys\n        pcall(npcSys.watchPersonalWork, npcSys, true)\n",
    "        self._npcWorkWatching = true\n        self._npcWorkHost = npcSys\n", 1)],
  "the tablet reads the page but never registers as a reader, so the adapter never refreshes it"),
 ("T02-watch-not-released", APP,
  [("    if self._npcWorkWatching and (not self.isOpen or self.system == nil or self.system.currentApp ~= FT.APP.NPC_FAVOR) then\n        npcWorkWatch(self, nil, false)\n    end\n",
    "", 1)],
  "the poll outlives the app and the tablet"),
 ("T03-no-refresh-on-open", APP,
  [("        pcall(npcSys.requestPersonalWorkView, npcSys, \"\")\n", "", 1)],
  "opening the screen asks for nothing"),
 ("T04-pending-page-drawn", APP,
  [("    if not ok or type(view) ~= \"table\" or (view.state ~= \"CURRENT\" and view.state ~= \"LAST_CONFIRMED\") then\n",
    "    if not ok or type(view) ~= \"table\" or view.state == \"UNAVAILABLE\" then\n", 1)],
  "a page still out is drawn as an empty list"),
 ("T05-last-confirmed-unlabelled", APP,
  [("    local note = (view.state == \"LAST_CONFIRMED\") and \"  (last confirmed)\" or \"\"\n",
    "    local note = \"\"\n", 1)],
  "a last-confirmed page passes for current"),
 ("T06-completed-unknown-as-zero", APP,
  [("    if view.completedKnown then\n        y = self:drawRow(y, \"Completed\", tostring(view.completedCount or 0))\n    else\n        y = self:drawRow(y, \"Completed\", \"unavailable\", nil, FT.C.TEXT_DIM)\n    end\n",
    "    y = self:drawRow(y, \"Completed\", tostring(view.completedCount or 0))\n", 1)],
  "an absent summary is invented as zero"),
 ("T07-time-unknown-as-zero-hours", APP,
  [("                if f.timeKnown then\n                    right = string.format(\"%d%%  %dh left\", progress, math.floor((f.timeRemainingMs or 0) / 3600000))\n                else\n                    right = string.format(\"%d%%  time unknown\", progress)\n                end\n",
    "                right = string.format(\"%d%%  %dh left\", progress, math.floor((f.timeRemainingMs or 0) / 3600000))\n", 1)],
  "an unknown remaining time reads as zero hours"),
 ("T08-repaired-host-reads-raw-model", APP,
  [("    return type(npcSys) == \"table\"\n        and type(npcSys.getPersonalWorkView) == \"function\"\n",
    "    return false and type(npcSys) == \"table\"\n        and type(npcSys.getPersonalWorkView) == \"function\"\n", 1)],
  "the repaired host is read through the raw favour model"),
 ("T09-waiting-rows-get-a-number", APP,
  [("            if r.kind == \"LIVE\" and type(r.trust) == \"number\" then live[#live + 1] = r else others[#others + 1] = r end\n",
    "            r.trust = r.trust or 0\n            live[#live + 1] = r\n", 1)],
  "a waiting person or a worker is listed with a zero trust"),
 ("T10-header-counts-every-row", APP,
  [("        y = self:drawSection(y, \"RELATIONSHIPS  (\" .. #live .. \")\")\n",
    "        y = self:drawSection(y, \"RELATIONSHIPS  (\" .. #roster.rows .. \")\")\n", 1)],
  "the header counts waiting and observed rows as neighbours"),
 ("T11-roster-not-ready-still-listed", APP,
  [("        if roster.personLoadState ~= \"READY\" or roster.snapshotState == \"UNAVAILABLE\" then\n",
    "        if false then\n", 1)],
  "a roster that is not ready is drawn as an empty town"),
 ("T12-old-host-loses-compatibility", APP,
  [("        and type(npcSys.watchPersonalWork) == \"function\"\nend\n",
    "        and type(npcSys.watchPersonalWork) == \"function\" or true\nend\n", 1)],
  "an old host is treated as repaired and its work reads unavailable"),
 ("T13-double-watch", APP,
  [("    if on then\n        if self._npcWorkWatching then return end\n",
    "    if on then\n", 1)],
  "every frame registers the reader again"),
 ("T14-release-without-letting-go", APP,
  [("        if type(host) == \"table\" and type(host.watchPersonalWork) == \"function\" then\n            pcall(host.watchPersonalWork, host, false)\n        end\n",
    "", 1)],
  "the tablet forgets it watched but the adapter keeps polling for it"),
]

def sha(b): return hashlib.sha256(b).hexdigest()

def run_suite():
    r = subprocess.run(["node", "run-tests.mjs"], cwd=p("tools/test"),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = (r.stdout or "") + (r.stderr or "")
    fails = [l.strip() for l in out.splitlines() if "FAIL " in l and "##" not in l and l.strip().startswith("FAIL")]
    crashes = [l.strip() for l in out.splitlines() if "Lua error" in l or "attempt to" in l or "group crashed" in l]
    return r.returncode, fails, crashes

only = sys.argv[1:]
rc, fails, crashes = run_suite()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in fails[:10]: print("   " + l)
    for l in crashes[:5]: print("   " + l)
    sys.exit(2)
print("baseline green")

killed, survived, bad, weak = 0, 0, 0, 0
for mid, rel, edits, why in MUTATIONS:
    if only and not any(mid.startswith(o) for o in only): continue
    path = p(rel)
    original = open(path, "rb").read()
    before = sha(original)
    crlf = b"\r\n" in original
    text = original.decode("utf-8").replace("\r\n", "\n")
    ok = True
    for old, new, count in edits:
        if text.count(old) != count:
            print("  BAD EDIT %s: anchor found %d times, want %d" % (mid, text.count(old), count)); ok = False; break
        text = text.replace(old, new)
    if not ok: bad += 1; continue
    open(path, "wb").write((text.replace("\n", "\r\n") if crlf else text).encode("utf-8"))
    try:
        rc, fails, crashes = run_suite()
    finally:
        open(path, "wb").write(original)
        assert sha(open(path, "rb").read()) == before, "restore failed for " + rel
    if rc != 0:
        killed += 1
        ordinary = [l for l in fails if "[group crashed]" not in l]
        star = "*" if len(ordinary) == 0 else " "
        if star == "*": weak += 1
        print("  KILLED%s  %s  [%s]" % (star, mid, rel))
        for l in fails[:4]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  [%s]  (%s)" % (mid, rel, why))

print("\n==== MUTATION RESULT ====")
print("killed   %d (of which %d only by a Lua error, marked KILLED*)" % (killed, weak))
print("survived %d" % survived)
print("bad edit %d" % bad)
print("all files restored byte-identical (hash-checked per mutation)")
sys.exit(0 if survived == 0 and bad == 0 and weak == 0 else 1)
