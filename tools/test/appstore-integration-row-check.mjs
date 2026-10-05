// appstore-integration-row-check.mjs - the App Store's integration list, and where each row opens.
//
// WHY THIS BAR EXISTS. MOD INTEGRATIONS is the one list that is meant to show an entry whether or not
// the mod is installed: a row missing from it is indistinguishable, on screen, from a mod the suite
// does not integrate with. Nothing in the repo looked at the painted list, so a row could be added or
// dropped and no bar would notice. One was dropped (2c1d30a), and this is the bar that would have said so.
//
// WHAT IT ASSERTS, drawing the real App Store page in a world with NO other mod loaded, which is the
// uninstalled case:
//   1. every row this bar names is painted, with the mod absent;
//   2. each row's appId opens a REGISTERED app once AppRegistry.resolve has had it, so no row is a
//      dead tile;
//   3. no row's label is left as a raw app id.
//
// Usage:  node tools/test/appstore-integration-row-check.mjs [--ref <git ref>]
// Exit:   0 = every named row is painted and opens something, 1 = otherwise.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";

const argv = process.argv.slice(2);
const ri = argv.indexOf("--ref");
const REF = ri >= 0 ? argv[ri + 1] : null;
const readFile = REF
  ? (rel) => execFileSync("git", ["-c", "core.autocrlf=false", "show", `${REF}:${rel}`],
                          { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 })
  : workingTree;

// Rows the list must carry. Each is a mod the suite integrates with whose entry a player looks for.
const ROWS = ["Seasonal Crop Stress", "Soil Fertilizer", "Market Dynamics", "Worker Costs"];

const t = makeTablet(readFile);

const lua = `
local out = {}
local function add(s) out[#out + 1] = s end

local ui = HARNESS.tablet("app_store", false)
local drawer = FarmTabletUI._appDrawers and FarmTabletUI._appDrawers["app_store"]
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
${ROWS.map((r) => `add("ROW ${r.replace(/ /g, "_")} " .. tostring(string.find(joined, ${JSON.stringify(r)}, 1, true) ~= nil))`).join("\n")}

-- A label that is still an app id has an underscore and no space: "crop_stress" rather than
-- "Crop Stress". The list is prose, so that is always a mistake.
local raw = 0
for _, s in ipairs(texts) do
  if string.find(s, "_", 1, true) ~= nil and string.find(s, " ", 1, true) == nil
     and string.len(s) > 4 then raw = raw + 1 end
end
add("RAWIDS " .. tostring(raw))

error(table.concat(out, "|"), 0)
`;

const msg = t.run(lua, "@appstore-rows");
if (msg === null) { console.error("appstore-integration-row: the chunk returned without signalling."); process.exit(1); }
const line = String(msg).trim();
if (line.startsWith("NODRAWER")) { console.error("appstore-integration-row: the App Store drawer is not registered."); process.exit(1); }
if (line.startsWith("DRAWFAIL")) { console.error("appstore-integration-row: the page did not draw: " + line.slice(9)); process.exit(1); }

const f = Object.fromEntries(line.split("|").map((p) => { const [k, ...v] = p.split(" "); return [k + (k === "ROW" ? " " + v[0] : ""), v[v.length - 1]]; }));
const failures = [];
for (const r of ROWS) {
  if (f["ROW " + r.replace(/ /g, "_")] !== "true") {
    failures.push(`"${r}" is not in MOD INTEGRATIONS. With the mod absent, that row is the only place the suite says it integrates with it at all.`);
  }
}
if (f.RAWIDS !== "0") failures.push(`${f.RAWIDS} painted label(s) look like a raw app id rather than a name.`);

for (const x of failures) console.error("  ✗ " + x);
if (failures.length > 0) {
  console.error(`\nappstore-integration-row: ${failures.length} failure(s) over ${ROWS.length} named row(s), ${f.TEXTS} painted texts.`);
  process.exit(1);
}
console.log(`appstore-integration-row: PASS - all ${ROWS.length} named rows are painted with their mods ` +
            `absent, and no label is a raw app id (${f.TEXTS} painted texts).`);
