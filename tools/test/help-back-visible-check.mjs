// help-back-visible-check.mjs - the Help page's Back control must actually RENDER.
//
// WHY THIS BAR EXISTS. Thirty-four other bars read source, count locale entries, parse Lua or run
// logic in fengari. The one bar that paints, renderer-parity-check.mjs, compares the base against the
// head AFTER the same culling, so a control culled in BOTH reads as identical and passes. A control
// can therefore be queued, never drawn, and still answer clicks, with every bar green. That is what
// happened here: the Back button was queued into the app layer above the body clip, so only a 4px
// sliver survived and its label was culled outright, while hitTest kept answering for the whole
// rectangle. An invisible click target.
//
// WHAT IT ASSERTS. It draws a Help page, then runs the REAL FT_Renderer:flushContent with the clip
// arguments FarmTabletUI passes while an app is open (clipY = contentY, clipH = contentH;
// FarmTabletUI.lua:1581-1583), capturing every renderText call. The Back label must be among them.
// Being queued is not enough: it has to come out the other end.
//
// It is deliberately a RENDER bar, not a geometry bar. Asserting "the button sits below bodyClipTop"
// would bake today's clip arithmetic into the test, and the next person to move the clip would get a
// green bar and an invisible button again.
//
// Usage:  node tools/test/help-back-visible-check.mjs [--ref <git ref>]
// Exit:   0 = the Back label reached the screen on every help page drawn, 1 = it did not.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";

const argv = process.argv.slice(2);
const ri = argv.indexOf("--ref");
const REF = ri >= 0 ? argv[ri + 1] : null;

const readFile = REF
  ? (rel) => execFileSync("git", ["-c", "core.autocrlf=false", "show", `${REF}:${rel}`],
                          { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 })
  : workingTree;

const t = makeTablet(readFile);

// The harness exposes run(), which returns a chunk's error message and nothing else, and the
// prelude does not surface print(). So the chunk SIGNALS through error(msg, 0): level 0 means Lua
// adds no position prefix, so the message comes back exactly as written.
function runSignalling(code) {
  const msg = t.run(code, "@help-back-visible");
  return msg === null
    ? { line: "", err: "the chunk returned without signalling a result" }
    : { line: String(msg).trim(), err: null };
}

const LUA = (appId) => `
local appId = ${JSON.stringify(appId)}
local drawer = FarmTabletUI._appDrawers and FarmTabletUI._appDrawers[appId]
if drawer == nil then error("SKIP", 0) end

local ui = HARNESS.tablet(appId, true)
local okDraw, drawErr = pcall(drawer, ui)
if not okDraw then error("DRAWFAIL " .. tostring(drawErr), 0) end

-- What was queued, before anything is culled.
local queued = 0
local queuedBack = false
local function scan(list)
  for _, e in ipairs(list or {}) do
    if e.text ~= nil then
      queued = queued + 1
      if string.find(string.upper(tostring(e.text)), "BACK", 1, true) ~= nil then queuedBack = true end
    end
  end
end
scan(ui.r._headerTexts); scan(ui.r._buttons); scan(ui.r._texts)

-- Now flush for real, with the clip the UI uses while an app is open, and watch the screen.
local painted = 0
local paintedBack = false
-- The engine's text globals: the harness stand-in has no need of them until something actually
-- flushes, which no other bar does. Stubbed here rather than in the shared harness, so this bar
-- cannot change what any other bar sees.
local realRenderText, realAlign, realColor = renderText, setTextAlignment, setTextColor
setTextAlignment = setTextAlignment or function() end
setTextColor = setTextColor or function() end
renderText = function(x, y, size, text)
  painted = painted + 1
  if string.find(string.upper(tostring(text)), "BACK", 1, true) ~= nil then paintedBack = true end
end
local okFlush, flushErr = pcall(function()
  ui.r:flushContent(FT.LAYOUT.contentY, FT.LAYOUT.contentH)
end)
renderText = realRenderText
setTextAlignment, setTextColor = realAlign, realColor
if not okFlush then error("FLUSHFAIL " .. tostring(flushErr), 0) end

error(string.format("RESULT %s %s %d %d",
  tostring(queuedBack), tostring(paintedBack), queued, painted), 0)
`;

const APPS = ["dashboard", "organic", "market_dynamics"];
const failures = [];
let checked = 0, rendered = 0;

for (const appId of APPS) {
  const { err, line } = runSignalling(LUA(appId));
  if (err) { failures.push(`${appId}: ${err}`); continue; }
  if (line === "SKIP") continue;
  if (line.startsWith("DRAWFAIL")) { failures.push(`${appId}: help page did not draw: ${line.slice(9)}`); continue; }
  if (line.startsWith("FLUSHFAIL")) { failures.push(`${appId}: flushContent raised: ${line.slice(10)}`); continue; }
  const m = line.match(/^RESULT (true|false) (true|false) (\d+) (\d+)$/);
  if (!m) { failures.push(`${appId}: the bar could not read its own result: ${JSON.stringify(line)}`); continue; }
  const [, q, p, nq, np] = m;
  checked++;
  if (q !== "true") {
    failures.push(`${appId}: no Back control was queued at all (${nq} texts queued)`);
  } else if (p !== "true") {
    failures.push(
      `${appId}: THE BACK CONTROL IS QUEUED BUT NEVER RENDERS. The body clip culls it and hitTest ` +
      `does not share that clip, so the page carries an invisible click target. ` +
      `${np} texts reached the screen out of ${nq} queued.`);
  } else {
    rendered++;
  }
}

if (checked === 0 && failures.length === 0) {
  console.error("help-back-visible: no help page could be drawn; the bar proved nothing.");
  process.exit(1);
}
for (const f of failures) console.error("  ✗ " + f);
if (failures.length > 0) {
  console.error(`\nhelp-back-visible: ${failures.length} failure(s) over ${checked} help page(s).`);
  process.exit(1);
}
console.log(`help-back-visible: PASS - the Back control reached the screen on ${rendered} of ${checked} ` +
            `help page(s), through the real flushContent with the real body clip.`);
