// market-movers-unit-check.mjs - Market Movers must not scale a per-head price by 1,000.
//
// WHY THIS BAR EXISTS. Market Dynamics stores per-litre prices, and the Movers list multiplies by
// 1,000 to show a per 1,000 L figure. An animal fill type is priced PER HEAD, so that multiply was
// applied to a number that was already final: an animal at roughly twelve thousand a head printed as
// roughly twelve million. Nothing looked at the painted row, so the figure was wrong on screen for as
// long as it was.
//
// WHAT IT ASSERTS, drawing the real Market Dynamics page against a fixture with one crop mover and
// one animal mover:
//   1. the crop's figure is its per-litre price times 1,000;
//   2. the animal's figure is its per-head price, NOT times 1,000;
//   3. no painted figure is the animal price times 1,000, which is the bug's signature.
//
// Usage:  node tools/test/market-movers-unit-check.mjs [--ref <git ref>]
// Exit:   0 = both figures are right, 1 = otherwise.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";

const argv = process.argv.slice(2);
const ri = argv.indexOf("--ref");
const REF = ri >= 0 ? argv[ri + 1] : null;
const readFile = REF
  ? (rel) => execFileSync("git", ["-c", "core.autocrlf=false", "show", `${REF}:${rel}`],
                          { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 })
  : workingTree;

const CROP_IDX = 11, ANIMAL_IDX = 42;
const CROP_PRICE = 0.432;        // per litre -> 432 per 1,000 L
const ANIMAL_PRICE = 12000;      // per head  -> 12000, and 12000000 if wrongly scaled

const t = makeTablet(readFile);

const lua = `
local out = {}
local function add(s) out[#out + 1] = s end

-- The fill types the movers name. getFillTypeByIndex is what mdmFillTypeTitle reads.
local TITLES = { [${CROP_IDX}] = "Wheat", [${ANIMAL_IDX}] = "Angus" }
g_fillTypeManager = g_fillTypeManager or {}
g_fillTypeManager.getFillTypeByIndex = function(self, idx)
  if TITLES[idx] == nil then return nil end
  return { title = TITLES[idx], name = string.upper(TITLES[idx]) }
end

-- One crop mover and one animal mover, both moved enough to be listed.
g_currentMission.MarketDynamics = {
  marketEngine = {
    volatilityScale = 1.0,
    prices = {
      [${CROP_IDX}]   = { base = 0.400, current = ${CROP_PRICE} },
      [${ANIMAL_IDX}] = { base = 11000, current = ${ANIMAL_PRICE} },
    },
  },
}

-- The engine's animal system: a subtype for the animal index, nil for the crop.
g_currentMission.animalSystem = {
  getSubTypeByFillTypeIndex = function(self, idx)
    if idx == ${ANIMAL_IDX} then return { subTypeIndex = 1, name = "ANGUS" } end
    return nil
  end,
}

local ui = HARNESS.tablet("market_dynamics", false)
local drawer = FarmTabletUI._appDrawers and FarmTabletUI._appDrawers["market_dynamics"]
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

-- Digits only, so a thousands separator or a currency symbol cannot decide the answer.
local digits = string.gsub(joined, "[^%d\\1]", "")

add("TEXTS " .. tostring(#texts))
add("CROPROW " .. tostring(string.find(joined, "Wheat", 1, true) ~= nil))
add("ANIMALROW " .. tostring(string.find(joined, "Angus", 1, true) ~= nil))
add("CROPFIG " .. tostring(string.find(digits, "432", 1, true) ~= nil))
add("ANIMALFIG " .. tostring(string.find(digits, "12000", 1, true) ~= nil))
add("SCALED " .. tostring(string.find(digits, "12000000", 1, true) ~= nil))

error(table.concat(out, "|"), 0)
`;

const msg = t.run(lua, "@market-movers");
if (msg === null) { console.error("market-movers-unit: the chunk returned without signalling."); process.exit(1); }
const line = String(msg).trim();
if (line.startsWith("NODRAWER")) { console.error("market-movers-unit: the Market Dynamics drawer is not registered."); process.exit(1); }
if (line.startsWith("DRAWFAIL")) { console.error("market-movers-unit: the page did not draw: " + line.slice(9)); process.exit(1); }

const f = Object.fromEntries(line.split("|").map((p) => { const [k, ...v] = p.split(" "); return [k, v.join(" ")]; }));
const failures = [];
if (f.CROPROW !== "true") failures.push("the crop mover is not listed, so the bar proved nothing about it.");
if (f.ANIMALROW !== "true") failures.push("the animal mover is not listed, so the bar proved nothing about it.");
if (f.SCALED === "true") {
  failures.push(`the animal's per-head price was multiplied by 1,000: ${ANIMAL_PRICE} a head printed as ${ANIMAL_PRICE * 1000}.`);
}
if (f.ANIMALFIG !== "true") failures.push(`the animal's figure is not its per-head price (${ANIMAL_PRICE}).`);
if (f.CROPFIG !== "true") failures.push(`the crop's figure is not its per-litre price times 1,000 (${Math.round(CROP_PRICE * 1000)}).`);

for (const x of failures) console.error("  FAIL " + x);
if (failures.length > 0) {
  console.error(`\nmarket-movers-unit: ${failures.length} failure(s) over ${f.TEXTS} painted texts.`);
  process.exit(1);
}
console.log(`market-movers-unit: PASS - the crop scales to 1,000 L and the animal does not, so a per-head ` +
            `price reaches the screen as itself (${f.TEXTS} painted texts).`);
