// settings-enum-value-check.mjs - System Settings must paint an enum's value, not its float32.
//
// WHY THIS BAR EXISTS. The Settings Hub returns a live value as float32, so the 0.80 a schema
// declares arrives as 0.800000011920929. The System Settings page printed whatever it got, so a row
// the player set to 80% read as "0.800000011920929" on screen. Nothing in the repo looked at a
// painted settings row, so nothing caught it.
//
// WHAT IT ASSERTS, by drawing the real System Settings page against a Settings Hub fixture whose
// getValue returns exactly the float32 the real hub returns:
//   1. a ratio enum set to 0.80 paints as a percentage, not as a long decimal;
//   2. no painted row carries a float32 tail (a run of digits long enough to be one);
//   3. a non-ratio enum, {0, 1, 2}, is NOT turned into a percentage;
//   4. a module group starts CLOSED, and one tap opens it. The toggle is
//      `collapsed[modId] = not collapsed[modId]`, and `not nil` is true, so without a seeded entry
//      the first tap on a never-opened group sets it to true and leaves the group shut.
//
// Usage:  node tools/test/settings-enum-value-check.mjs [--ref <git ref>]
// Exit:   0 = the page paints the chosen values, 1 = otherwise.
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

// 0.80 as the hub hands it back: a float32 round trip, which is what the page actually receives.
const FLOAT32_80 = "0.800000011920929";

const lua = `
local out = {}
local function add(s) out[#out + 1] = s end

-- The Settings Hub fixture. Shapes only, as SystemSettingsApp reads them: getModules, getValue,
-- isLocalAdmin. Two modules, so the group behaviour is testable, and three settings covering the
-- ratio enum, the non-ratio enum and a plain boolean.
local HUB = {
  getModules = function()
    return {
      { modId = "FS25_Example", title = "Example", settings = {
          { id = "share", type = "enum", values = { 0.25, 0.5, 0.8, 1.0 }, default = 0.8,
            title = "Share" },
          { id = "mode", type = "enum", values = { 0, 1, 2 }, default = 1, title = "Mode" },
          { id = "flag", type = "bool", default = true, title = "Flag" },
      } },
      { modId = "FS25_Other", title = "Other", settings = {
          { id = "pick", type = "enum", values = { 0, 1 }, default = 0, title = "Pick" },
      } },
    }
  end,
  getValue = function(self, modId, id)
    if id == "share" then return ${FLOAT32_80} end
    if id == "mode" then return 2 end
    if id == "flag" then return true end
    if id == "pick" then return 1 end
    return nil
  end,
  isLocalAdmin = function() return true end,
}

local function paint()
  local ui = HARNESS.tablet("system_settings", false)
  g_currentMission.settingsHub = HUB
  local drawer = FarmTabletUI._appDrawers and FarmTabletUI._appDrawers["system_settings"]
  if drawer == nil then error("NODRAWER", 0) end
  local ok, err = pcall(drawer, ui)
  if not ok then error("DRAWFAIL " .. tostring(err), 0) end
  local texts = {}
  local function scan(list)
    for _, e in ipairs(list or {}) do
      if e.text ~= nil then texts[#texts + 1] = tostring(e.text) end
    end
  end
  scan(ui.r._headerTexts); scan(ui.r._buttons); scan(ui.r._texts)
  return ui, texts
end

-- First paint: groups start closed, so the rows are not drawn yet. That IS the new behaviour, so
-- the bar opens a group the way a tap does, paints again, and reads the rows from that.
local ui, firstTexts = paint()
local collapsed = ui._sysCollapsed or {}
local seeded = 0
for _, v in pairs(collapsed) do if v == true then seeded = seeded + 1 end end

-- one tap on a never-opened group
collapsed["FS25_Example"] = not collapsed["FS25_Example"]
local afterTap = collapsed["FS25_Example"]

-- paint again on the SAME ui with a fresh renderer, so the open group's rows are drawn
ui.r = FT_Renderer.new()
local redrawer = FarmTabletUI._appDrawers["system_settings"]
local okRedraw, redrawErr = pcall(redrawer, ui)
if not okRedraw then error("DRAWFAIL " .. tostring(redrawErr), 0) end
local texts = {}
local function scan2(list)
  for _, e in ipairs(list or {}) do
    if e.text ~= nil then texts[#texts + 1] = tostring(e.text) end
  end
end
scan2(ui.r._headerTexts); scan2(ui.r._buttons); scan2(ui.r._texts)
local joined = table.concat(texts, "\\1")
add("TEXTS " .. tostring(#texts))
add("SAMPLE " .. string.sub(joined, 1, 300))
add("HAS80 " .. tostring(string.find(joined, "80%", 1, true) ~= nil))
-- a float32 tail: a decimal point followed by eight or more digits
add("FLOAT32 " .. tostring(string.find(joined, "%.%d%d%d%d%d%d%d%d") ~= nil))
-- the non-ratio enum must not be painted as a percentage
add("MODEPCT " .. tostring(string.find(joined, "200%", 1, true) ~= nil))

add("SEEDED " .. tostring(seeded))
add("AFTERTAP " .. tostring(afterTap))
add("FIRSTTEXTS " .. tostring(#firstTexts))

error(table.concat(out, "|"), 0)
`;

const msg = t.run(lua, "@settings-enum");
if (msg === null) { console.error("settings-enum-value: the chunk returned without signalling."); process.exit(1); }
const line = String(msg).trim();
if (line.startsWith("NODRAWER")) { console.error("settings-enum-value: the System Settings drawer is not registered."); process.exit(1); }
if (line.startsWith("DRAWFAIL")) { console.error("settings-enum-value: the page did not draw: " + line.slice(9)); process.exit(1); }

const f = Object.fromEntries(line.split("|").map((p) => { const [k, ...v] = p.split(" "); return [k, v.join(" ")]; }));
const failures = [];

if (f.HAS80 !== "true") {
  failures.push(`a ratio enum set to 0.80 does not paint as "80%". The page shows the hub's float32 instead of the option the player chose.`);
}
if (f.FLOAT32 === "true") {
  failures.push(`a painted row carries a float32 tail (a decimal point followed by eight or more digits), so the raw hub value reached the screen.`);
}
if (f.MODEPCT === "true") {
  failures.push(`a non-ratio enum {0, 1, 2} was painted as a percentage. Only a set of ratios may be shown that way.`);
}
if (f.SEEDED === "0") {
  failures.push(`no module group was seeded closed, so the first tap on a never-opened group sets collapsed to true and leaves it shut (not nil is true).`);
}
if (f.AFTERTAP !== "false") {
  failures.push(`one tap on a closed group left it collapsed=${f.AFTERTAP}; it should open.`);
}

for (const x of failures) console.error("  ✗ " + x);
if (failures.length > 0) {
  console.error(`\nsettings-enum-value: ${failures.length} failure(s) over ${f.TEXTS} painted texts.`);
  process.exit(1);
}
console.log(`settings-enum-value: PASS - the ratio enum paints as a percentage, no float32 tail reaches ` +
            `the screen, a plain enum is left alone, and a group starts closed and opens on one tap ` +
            `(${f.TEXTS} painted texts).`);
