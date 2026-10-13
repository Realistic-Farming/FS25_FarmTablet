// organic-barn-label-check.mjs - the Organic card names a barn, it does not print its uniqueId.
//
// WHY THIS BAR EXISTS. The barn card took its label straight from the row's barnId, which is a
// 32-character uniqueId. On screen that is a block of hex, and it tells the player nothing about which
// building they are looking at. No bar looked at the painted card, so the id read as a label for as
// long as it did.
//
// WHAT IT ASSERTS, drawing the real Organic page against a DairyCore fixture whose rows carry a
// uniqueId and NO name of their own, which is the case that went wrong:
//   1. the placeable's name is painted;
//   2. the raw uniqueId is NOT painted anywhere on the page;
//   3. a row whose placeable cannot be resolved still paints something a player can read, and still
//      not the whole raw id.
//
// Usage:  node tools/test/organic-barn-label-check.mjs [--ref <git ref>]
// Exit:   0 = barns are named, 1 = a raw uniqueId reached the screen.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";

const argv = process.argv.slice(2);
const ri = argv.indexOf("--ref");
const REF = ri >= 0 ? argv[ri + 1] : null;
const readFile = REF
  ? (rel) => execFileSync("git", ["-c", "core.autocrlf=false", "show", `${REF}:${rel}`],
                          { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 })
  : workingTree;

const UID = "a1b2c3d4e5f60718293a4b5c6d7e8f90";   // 32 characters, as the engine makes them
const UID2 = "ffeeddccbbaa99887766554433221100";
const NAME = "Northern barn";

const t = makeTablet(readFile);

const lua = `
local out = {}
local function add(s) out[#out + 1] = s end

local farmId = (g_localPlayer and g_localPlayer.farmId) or 1

-- The Organic page returns early unless Soil Fertilizer is present, so the fixture supplies the
-- one field it gates on. Shapes only; this bar is about the barn LABEL, not about soil.
g_currentMission.soilFertilityManager = {
  soilSystem = { getFieldState = function() return nil end },
}

g_currentMission.dairyCoreManager = {
  getBarnRows = function()
    return {
      -- a barn whose placeable resolves to a name
      { barnId = ${JSON.stringify(UID)}, farmId = farmId, health = 80, mycotoxin = 0 },
      -- a barn whose placeable does NOT resolve: the last resort still has to read as something
      { barnId = ${JSON.stringify(UID2)}, farmId = farmId, health = 50, mycotoxin = 0 },
    }
  end,
  feedProvenance = nil,
}
g_currentMission.placeableSystem = {
  placeables = {},
  getPlaceableByUniqueId = function(self, id)
    if id == ${JSON.stringify(UID)} then
      return { getName = function() return ${JSON.stringify(NAME)} end }
    end
    return nil
  end,
}

local ui = HARNESS.tablet("organic", false)
local drawer = FarmTabletUI._appDrawers and FarmTabletUI._appDrawers["organic"]
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
local joined = table.concat(texts, "\\1")

add("TEXTS " .. tostring(#texts))
add("NAMED " .. tostring(string.find(joined, ${JSON.stringify(NAME)}, 1, true) ~= nil))
add("RAWUID " .. tostring(string.find(joined, ${JSON.stringify(UID)}, 1, true) ~= nil))
add("RAWUID2 " .. tostring(string.find(joined, ${JSON.stringify(UID2)}, 1, true) ~= nil))

-- any 32-character hex run on the page at all
add("ANYHEX " .. tostring(string.find(joined, "%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x") ~= nil))

error(table.concat(out, "|"), 0)
`;

const msg = t.run(lua, "@organic-barn");
if (msg === null) { console.error("organic-barn-label: the chunk returned without signalling."); process.exit(1); }
const line = String(msg).trim();
if (line.startsWith("NODRAWER")) { console.error("organic-barn-label: the Organic drawer is not registered."); process.exit(1); }
if (line.startsWith("DRAWFAIL")) { console.error("organic-barn-label: the page did not draw: " + line.slice(9)); process.exit(1); }

const f = Object.fromEntries(line.split("|").map((p) => { const [k, ...v] = p.split(" "); return [k, v.join(" ")]; }));
const failures = [];
if (f.NAMED !== "true") failures.push(`the barn's placeable is named "${NAME}" and the card does not paint it.`);
if (f.RAWUID === "true") failures.push(`the raw 32-character uniqueId ${UID} is painted on the card.`);
if (f.RAWUID2 === "true") failures.push(`the raw 32-character uniqueId ${UID2} is painted for the barn whose placeable does not resolve.`);
if (f.ANYHEX === "true") failures.push(`a 32-character hex run reached the screen, which is a uniqueId however it got there.`);

for (const x of failures) console.error("  FAIL " + x);
if (failures.length > 0) {
  console.error(`\norganic-barn-label: ${failures.length} failure(s) over ${f.TEXTS} painted texts.`);
  process.exit(1);
}
console.log(`organic-barn-label: PASS - the barn is named, no raw uniqueId reaches the screen, and the ` +
            `unresolvable barn still reads as something (${f.TEXTS} painted texts).`);
