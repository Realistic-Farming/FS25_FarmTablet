// soil-target-block-check.mjs - SF-73 section 7, W1c: the Soil Fertilizer app's AUTO target block.
//
// Built on Bob's W1 intake addendum, section (a) (Desk Office/Drafts/BOB-INTAKE-W1-SF73-SECTION7-SURFACE-2026-10-02.md).
// Each owned field's card shows, only when Soil answers: the crop window as a field report, the reading where
// the player stands with its soil cell size, the field's last confirmed AUTO target pass (its kind, note and
// litres) and a pause one of the farm's own machines is in now; beside a confirmed dose the treatment plan is
// labelled an estimate. Locked (Soil's reads answer nil) or on an older Soil (no reads), the card is today's.
//
// THE ENTRY-POINT BAR is row E: the tablet loaded the way the game loads it (tools/test/tablet-harness.mjs: every
// file src/main.lua sources, in its order), the app drawn the way FarmTabletUI:draw reaches it, through
// FarmTabletUI._appDrawers, which SoilNutrientApp.lua fills at load with the real registerDrawer. The tablet's own
// reads run as they do in game: the owned-field roster (FT_DataProvider:getOwnedFields over the farmland manager
// and Soil's published merge), the player's farm, the vehicle list, the player's position. Soil itself is a
// recorder on the mission handle (g_currentMission.soilFertilityManager.soilSystem) that answers with the shapes
// Soil's own reads return (SoilFertilizer src/target/TargetApplication.lua setResult and
// getCropNutrientRelationship, src/target/TargetNutrientCore.lua primaryReason, src/SoilFertilitySystem.lua's
// guarded reads, at development ebe20f77), and records every call. The values through Soil's real code are a
// joined run outside this repo, named in the PR.
//
// Rows:
//   E  the entry bar: a farm machine paused on field 7 with no growing crop, and the field's last pass
//   L  locked: no block, the card is exactly an older Soil's card; Soil was asked and answered nil
//   B  (BASE_REF=<git ref> set) the locked card is exactly the card at that ref
//   R  every pause reason in the host's words; an inactive result, another farm's machine, two machines,
//      a pause naming a field this farm does not own
//   P  the last pass: kinds and notes, another crop's pass, a merged field's members, a Soil without the read
//   H  the local line: only on the player's field (a member counts), no reading, off every farmland
//   W  no crop window
//   X  a Soil read that throws is caught
//   N  nothing written: only Soil's reads are called, and Soil's state is unchanged
//   D  another locale draws its file's text
//   F  every block line is drawn with the literal flag
//
// Usage:  node tools/test/soil-target-block-check.mjs        Exit: 0 clean, 1 any failure.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, localeTexts, ROOT } from "./tablet-harness.mjs";

const APP = "soil_fertilizer";
// The host's English (SoilFertilizer translations/translation_en.xml at ebe20f77), for the rows that name it.
const HOST = {
  UNSUPPORTED_CROP: "AUTO paused: no growing crop", UNKNOWN_GROUND: "AUTO paused: target unavailable",
  OUTSIDE_MAP: "AUTO paused: target unavailable", MIXED_CROP: "AUTO paused: crop boundary",
  MIXED_FIELD: "AUTO paused: field boundary", FARM_ACCESS: "AUTO paused: no access to this land",
  UNKNOWN_PRODUCT: "AUTO paused: invalid product", SOWABILITY_UNKNOWN: "AUTO paused: sowing without target fertilizer",
  NOZZLE_PARTIAL: "AUTO paused: not all boom sections on", CELL_OVERLAP: "AUTO paused: work areas overlap",
  CULTIVATION_NO_TARGET: "AUTO paused: no target on a cultivator",
  SOURCE_CONTRACT_UNAVAILABLE: "AUTO paused: supply route not supported",
  DOUBLED_AMOUNT_ACTIVE: "AUTO paused: double rate is on", FOOTPRINT_PRIMING: "AUTO: preparing the footprint",
};

// The world: Soil as a recorder, three farm-1 fields (7 alone; 8 and 11 one merged outline, lead 8), farm 2's
// field 9, two vehicles per farm, the player on field 7.
const WORLD = `
FieldState = nil
FIX = { calls = {}, locked = false, older = false, noPassRead = false, results = {}, passes = {}, rel = {}, localRel = {},
        info = {}, px = 1, pz = 1, merge = true }
local OUTCOME = { REACHED = true, SHORT_BINDING = true, SHORT_HARDWARE = true, SHORT_SUPPLY = true,
                  SHORT_QUANTIZED = true, APPLICATION_FAILED = true }
-- TargetNutrientCore.REASON_DISPLAY_ORDER and primaryReason (SoilFertilizer ebe20f77)
local DISPLAY = { "FARM_ACCESS", "UNKNOWN_PRODUCT", "OUTSIDE_MAP", "UNKNOWN_GROUND", "MIXED_FIELD", "MIXED_CROP",
  "UNSUPPORTED_CROP", "CULTIVATION_NO_TARGET", "SOURCE_CONTRACT_UNAVAILABLE", "DOUBLED_AMOUNT_ACTIVE",
  "NOZZLE_PARTIAL", "CELL_OVERLAP", "SOWABILITY_UNKNOWN", "FOOTPRINT_PRIMING" }
local function primaryReason(r)
  if type(r) ~= "table" or OUTCOME[r.doseState] then return nil end
  local has = {}
  for _, x in ipairs(r.reasons or {}) do has[x] = true end
  for _, x in ipairs(DISPLAY) do if has[x] then return x end end
  return nil
end
local function copy(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = copy(v) end
  return o
end
FIX.copy = copy
local function rec(name) FIX.calls[#FIX.calls + 1] = name end
-- A nutrient record as getCropNutrientRelationship builds it
function FIX.nut(rel, known, grain)
  return { value = 50, lower = 40, upper = 60, relationship = rel, knowledgeState = known and "KNOWN" or "UNAVAILABLE",
           grainMetres = grain }
end
function FIX.report(fieldId, cropKey, n, p, k)
  return { schema = 1, fieldId = fieldId, scope = "FIELD_REPORT", quality = "ANALYSIS", cropKey = cropKey,
           nutrients = { N = FIX.nut(n, true), P = FIX.nut(p, true), K = FIX.nut(k, true) } }
end
function FIX.localReading(fieldId, cropKey, n, p, k, grain, known)
  return { schema = 1, fieldId = fieldId, scope = "LOCAL", quality = "TRUTH", cropKey = cropKey,
           nutrients = { N = FIX.nut(n, known, known and grain or nil), P = FIX.nut(p, known, known and grain or nil),
                         K = FIX.nut(k, known, known and grain or nil) } }
end
-- A result as TA:setResult stores it (an outcome, or a refusal naming a field)
function FIX.result(doseState, fieldId, cropKey, reasons, active, extra)
  local r = { schema = 1, epoch = "1", sequence = "4", active = active ~= false, scope = "FOOTPRINT", quality = "ANALYSIS",
              productFillType = 101, productName = "LIQUID_DAP", cropFruitIndex = cropKey and 1 or nil, cropKey = cropKey,
              fieldId = fieldId, grainMetres = 2, knowledgeState = "KNOWN", nutrients = {}, binding = nil,
              doseState = doseState, reasons = reasons or {}, plannedLitres = 0, physicalLitres = 0 }
  for k2, v in pairs(extra or {}) do r[k2] = v end
  return r
end
local SOIL = {}
function SOIL:getFieldInfo(id) rec("getFieldInfo") return copy(FIX.info[id]) end
function SOIL:getFieldUrgency(id) rec("getFieldUrgency") return 0 end
local READS = {}
function READS:getCropNutrientRelationship(fieldId, x, z)
  rec("getCropNutrientRelationship")
  if FIX.locked then return nil end
  if type(x) == "number" and type(z) == "number" then return copy(FIX.localRel[fieldId]) end
  return copy(FIX.rel[fieldId])
end
function READS:getApplicationTargetResult(vehicle)
  rec("getApplicationTargetResult")
  if FIX.locked then return nil end
  return copy(FIX.results[vehicle])
end
function READS:getLastTargetPassForField(fieldId)
  rec("getLastTargetPassForField")
  if FIX.throwPass then error("a Soil read failed") end
  if FIX.locked then return nil end
  return copy(FIX.passes[fieldId])
end
function READS:getTargetPrimaryReason(result)
  rec("getTargetPrimaryReason")
  if FIX.locked then return nil end
  return primaryReason(result)
end
-- Build the soil system the way the current fixture flags say Soil is (rebuilt before every draw)
function FIX.install()
  local cls = {}
  for k, v in pairs(SOIL) do cls[k] = v end
  if not FIX.older then
    for k, v in pairs(READS) do cls[k] = v end
    if FIX.noPassRead then cls.getLastTargetPassForField = nil end
  end
  FIX.ss = setmetatable({ isInitialized = true }, { __index = cls })
  g_currentMission.soilFertilityManager = { settings = { enabled = true }, soilSystem = FIX.ss }
  g_currentMission.RfPdaSoilMerge = FIX.merge and { buildGroups = function(ids)
    local out, seen = {}, {}
    for _, id in ipairs(ids) do
      if (id == 8 or id == 11) then
        if not seen.m then seen.m = true; out[#out + 1] = { id = 8, memberIds = { 8, 11 } } end
      else
        out[#out + 1] = { id = id, memberIds = { id } }
      end
    end
    return out
  end } or nil
end
local function field(cx, cz, ha)
  return { getCenterOfFieldWorldPosition = function() return cx, cz end, getAreaHa = function() return ha end }
end
g_farmlandManager = {
  farmlands = { { id = 7, farmId = 1, field = field(0, 0, 4.5) }, { id = 8, farmId = 1, field = field(100, 0, 3) },
                { id = 11, farmId = 1, field = field(140, 0, 2) }, { id = 9, farmId = 2, field = field(300, 0, 6) } },
  getFarmlandIdAtWorldPosition = function(_, x, z)
    if x >= -50 and x < 50 then return 7 end
    if x >= 50 and x < 120 then return 8 end
    if x >= 120 and x < 200 then return 11 end
    if x >= 250 and x < 350 then return 9 end
    return 0
  end,
  getFarmlandOwner = function(_, id) return (id == 9) and 2 or 1 end,
}
g_localPlayer = { farmId = 1, getPosition = function() return FIX.px, 0, FIX.pz end }
local function vehicle(name, owner) return { name = name, getOwnerFarmId = function() return owner end } end
FIX.v = { a = vehicle("sprayer A", 1), b = vehicle("sprayer B", 1), c = vehicle("farm 2 sprayer", 2) }
g_currentMission.vehicleSystem = { vehicles = { FIX.v.a, FIX.v.b, FIX.v.c } }
for _, id in ipairs({ 7, 8, 11, 9 }) do
  FIX.info[id] = { fieldArea = 4, needsFertilization = false, lastCrop = nil, pH = 6.5, organicMatter = 3.6,
                   nitrogen = { value = 40, status = "Fair" }, phosphorus = { value = 35, status = "Good" },
                   potassium = { value = 45, status = "Good" }, weedPressure = 5, pestPressure = 5,
                   shownDiseasePressure = 5, cropTargets = { N = { opt = 50 }, P = { opt = 35 }, K = { opt = 40 } } }
end
FIX.rel[7] = FIX.report(7, "wheat", "BELOW", "IDEAL", "ABOVE")
FIX.rel[8] = FIX.report(8, "barley", "IDEAL", "IDEAL", "IDEAL")
FIX.rel[11] = FIX.report(11, "barley", "IDEAL", "APPROACHING", "IDEAL")
FIX.rel[9] = FIX.report(9, "barley", "IDEAL", "IDEAL", "IDEAL")
FIX.localRel[7] = FIX.localReading(7, "wheat", "APPROACHING", "IDEAL", "IDEAL", 2, true)
FIX.localRel[11] = FIX.localReading(11, "barley", "BELOW", "IDEAL", "IDEAL", 2, true)
-- Before each row: the default world, then the row's own changes
function FIX.reset()
  FIX.calls, FIX.locked, FIX.older, FIX.noPassRead, FIX.merge, FIX.throwPass = {}, false, false, false, true, false
  FIX.results, FIX.passes, FIX.px, FIX.pz = {}, {}, 1, 1
end
-- Soil's whole state, as text, for the no-write row
function FIX.state()
  local parts = {}
  local function dump(t, pre)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
      local v = t[k]
      if type(v) == "table" then dump(v, pre .. tostring(k) .. ".") elseif type(v) ~= "function" then
        parts[#parts + 1] = pre .. tostring(k) .. "=" .. tostring(v)
      end
    end
  end
  dump(FIX.info, "info."); dump(FIX.rel, "rel."); dump(FIX.localRel, "local."); dump(FIX.passes, "passes.")
  for name, v in pairs(FIX.v) do if FIX.results[v] then dump(FIX.results[v], "result." .. name .. ".") end end
  local keys = {}
  for k in pairs(FIX.ss) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  parts[#parts + 1] = "ss:" .. table.concat(keys, ",")
  table.sort(parts)
  return table.concat(parts, "\\n")
end
`;

const failures = [];
let rows = 0;
const ok = (name, cond, detail) => { rows++; if (!cond) failures.push(`${name}${detail !== undefined ? " :: " + detail : ""}`); };
const eq = (name, got, want) => ok(name, JSON.stringify(got) === JSON.stringify(want), `got ${JSON.stringify(got)} want ${JSON.stringify(want)}`);

function tabletAt(readFile) {
  const t = makeTablet(readFile);
  if (t.loadErrors.length) failures.push("load: " + t.loadErrors.join("; "));
  const e = t.run(WORLD, "@world");
  if (e) throw new Error("world: " + e);
  t.setLocale("en");
  return t;
}
const T = tabletAt(workingTree);
const lua = (code) => { const e = T.run(code, "@row"); if (e) throw new Error("row code: " + e + "\n" + code); };
function draw(code, t = T) {
  const e = t.run(`FIX.reset()\n${code || ""}\nFIX.install()`, "@row");
  if (e) throw new Error("row code: " + e);
  const d = t.draw(APP, false);
  if (d.error) failures.push("draw error: " + d.error);
  return d;
}
// One card's texts and flags, from its title to the next title
function card(d, id) {
  const start = d.texts.findIndex((x) => x.startsWith(`Field #${id} `));
  if (start < 0) return { texts: [], flagged: [] };
  let end = d.texts.findIndex((x, i) => i > start && x.startsWith("Field #"));
  if (end < 0) end = d.texts.length;
  return { texts: d.texts.slice(start, end), flagged: d.flagged.slice(start, end) };
}
// The block's lines: after "AUTO target", up to the plan title
function block(c) {
  const a = c.texts.indexOf("AUTO target");
  if (a < 0) return null;
  const b = c.texts.findIndex((x, i) => i > a && x.startsWith("TREATMENT PLAN"));
  return c.texts.slice(a + 1, b < 0 ? c.texts.length : b);
}
const planTitle = (c) => c.texts.find((x) => x.startsWith("TREATMENT PLAN"));
const PASS_REACHED = `FIX.passes[7] = FIX.result("REACHED", 7, "wheat", {}, false, { plannedLitres = 0.15, physicalLitres = 0.15, notedAt = 5000 })`;

// ---- E: the entry bar
{
  const d = draw(`
    FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)
    ${PASS_REACHED}`);
  const c = card(d, 7);
  eq("E1 NAMED: field 7's card draws the AUTO target block, in the host's words", block(c), [
    "Field report: N low, P ok, K high",
    "Here, 2.0 m cells: N near, P ok, K ok",
    "Last pass: target reached",
    "One footprint, not the whole field",
    "Planned 0.15 L, applied 0.15 L",
    "AUTO paused: no growing crop",
  ]);
  eq("E2 NAMED: beside the confirmed dose, the plan reads as the estimate it is", planTitle(c), "TREATMENT PLAN (estimate)");
  const metric = c.texts.indexOf("OM"), title = c.texts.indexOf("AUTO target"), plan = c.texts.indexOf("TREATMENT PLAN (estimate)");
  ok("E3 the block sits after the soil bars and before the plan", metric >= 0 && metric < title && title < plan, `${metric} ${title} ${plan}`);
  const c8 = card(d, 8);
  eq("E4 field 8's card: its own report, no local line (the player is on 7), no pass yet", block(c8),
     ["Field report: N ok, P ok, K ok", "Last pass: none on this crop"]);
  eq("E5 and its plan title is today's", planTitle(c8), "TREATMENT PLAN");
}

// ---- L / O / B: locked, an older Soil, the base
const lockedDraw = draw(`FIX.locked = true\n${PASS_REACHED}\nFIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)`);
{
  const olderDraw = draw(`FIX.older = true\n${PASS_REACHED}`);
  eq("L1 NAMED: locked, every card is exactly an older Soil's card", lockedDraw.texts, olderDraw.texts);
  ok("L2 NAMED: and no block text is drawn", !lockedDraw.texts.some((x) => x === "AUTO target" || x.startsWith("Field report:") || x.startsWith("Last pass:") || x.startsWith("AUTO paused") || x.includes("(estimate)")));
  ok("L3 [reached] the cards were drawn (field 7's title and its plan)", card(lockedDraw, 7).texts.includes("TREATMENT PLAN"));
}
{
  T.run(`FIX.reset()\nFIX.locked = true\nFIX.install()`, "@row");
  T.draw(APP, false);
  const e = T.run(`L4_CALLS = {} for _, c in ipairs(FIX.calls) do L4_CALLS[c] = true end
    assert(L4_CALLS.getCropNutrientRelationship, "Soil's report was not asked")`, "@row");
  ok("L4 [reached] locked, the tablet asked Soil and Soil answered nil", e === null, e);
}
if (process.env.BASE_REF) {
  const ref = process.env.BASE_REF;
  const atRef = (rel) => execFileSync("git", ["show", `${ref}:${rel}`], { cwd: ROOT, encoding: "utf8", maxBuffer: 1 << 26 });
  const B = tabletAt(atRef);
  const baseDraw = draw(`FIX.locked = true\n${PASS_REACHED}`, B);
  eq(`B1 NAMED: locked, every card is exactly the card at ${ref}`, lockedDraw.texts, baseDraw.texts);
  const baseNew = draw(`${PASS_REACHED}\nFIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)`, B);
  eq(`B2 at ${ref}, an unlocked Soil changes nothing either`, baseNew.texts, baseDraw.texts);
}

// ---- R: pauses
{
  const got = {}, want = {};
  for (const [reason, text] of Object.entries(HOST)) {
    const c = card(draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "${reason}" }, true)`), 7);
    const b = block(c) || [];
    got[reason] = b[b.length - 1];
    want[reason] = text;
  }
  eq("R1 NAMED: each pause reason draws the host's own words", got, want);
  const distinct = new Set(Object.values(got));
  ok("R2 thirteen distinct lines for fourteen reasons (unread ground and the map edge share the host's line)", distinct.size === 13, distinct.size);
  const inactive = block(card(draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, false)`), 7));
  ok("R3 NAMED: a parked machine's last result is not drawn (only a current one)", inactive !== null && !inactive.some((x) => x.startsWith("AUTO paused")), JSON.stringify(inactive));
  const other = block(card(draw(`FIX.results[FIX.v.c] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)`), 7));
  ok("R4 NAMED: another farm's machine is never drawn on this farm's card", other !== null && !other.some((x) => x.startsWith("AUTO paused")), JSON.stringify(other));
  const ab = block(card(draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)
    FIX.results[FIX.v.b] = FIX.result("INACTIVE", 7, nil, { "MIXED_CROP" }, true)`), 7));
  const ba = block(card(draw(`g_currentMission.vehicleSystem.vehicles = { FIX.v.b, FIX.v.a, FIX.v.c }
    FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)
    FIX.results[FIX.v.b] = FIX.result("INACTIVE", 7, nil, { "MIXED_CROP" }, true)`), 7));
  lua(`g_currentMission.vehicleSystem.vehicles = { FIX.v.a, FIX.v.b, FIX.v.c }`);
  eq("R5 NAMED: two machines on one field: the reason earlier in Soil's display order, whatever the list order",
     [(ab || []).slice(-1)[0], (ba || []).slice(-1)[0]], [HOST.MIXED_CROP, HOST.MIXED_CROP]);
  const access = draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 9, "barley", { "FARM_ACCESS", "UNSUPPORTED_CROP" }, true)`);
  ok("R6 a pause naming a field this farm does not own reaches no card", block(card(access, 7)) !== null && !access.texts.some((x) => x.startsWith("AUTO paused")));
  const outcome = block(card(draw(`FIX.results[FIX.v.a] = FIX.result("REACHED", 7, "wheat", {}, true, { plannedLitres = 1, physicalLitres = 1 })`), 7));
  ok("R7 a machine's current outcome is not a pause line", outcome !== null && !outcome.some((x) => x.startsWith("AUTO")), JSON.stringify(outcome));
  const hold = block(card(draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, "wheat", {}, true)`), 7));
  ok("R8 a hold (no reason) is not a pause line", hold !== null && !hold.some((x) => x.startsWith("AUTO")), JSON.stringify(hold));
}

// ---- P: the last pass
{
  const kind = (state, extra) => {
    const b = block(card(draw(`FIX.passes[7] = FIX.result("${state}", 7, "wheat", {}, false, { plannedLitres = 12.5, physicalLitres = 3, notedAt = 100${extra || ""} })`), 7));
    return (b || []).slice(2, 5);
  };
  eq("P1 NAMED: a blend-limited pass names the nutrient it would overshoot", kind("SHORT_BINDING", ", binding = \"N\""),
     ["Last pass: short, blend limit", "More would overshoot N", "Planned 12.5 L, applied 3.00 L"]);
  eq("P2 a machine-limited pass", kind("SHORT_HARDWARE"), ["Last pass: short, machine limit", "One footprint, not the whole field", "Planned 12.5 L, applied 3.00 L"]);
  eq("P3 a supply-limited pass", kind("SHORT_SUPPLY"), ["Last pass: short, ran out", "One footprint, not the whole field", "Planned 12.5 L, applied 3.00 L"]);
  eq("P4 a quantized pass", kind("SHORT_QUANTIZED"), ["Last pass: short, under a map step", "One footprint, not the whole field", "Planned 12.5 L, applied 3.00 L"]);
  eq("P5 NAMED: a failed write: product spent, local N/P/K not confirmed", kind("APPLICATION_FAILED"),
     ["Last pass: product spent", "Local N/P/K is not confirmed.", "Planned 12.5 L, applied 3.00 L"]);
  const crop = card(draw(`FIX.passes[7] = FIX.result("REACHED", 7, "barley", {}, false, { plannedLitres = 1, physicalLitres = 1, notedAt = 100 })`), 7);
  eq("P6 NAMED: another crop's pass is not this crop's", (block(crop) || []).slice(2), ["Last pass: none on this crop"]);
  eq("P7 and without a confirmed dose the plan title is today's", planTitle(crop), "TREATMENT PLAN");
  const merged = card(draw(`FIX.passes[8] = FIX.result("SHORT_SUPPLY", 8, "barley", {}, false, { plannedLitres = 2, physicalLitres = 1, notedAt = 100 })
    FIX.passes[11] = FIX.result("REACHED", 11, "barley", {}, false, { plannedLitres = 4, physicalLitres = 4, notedAt = 200 })`), 8);
  eq("P8 NAMED: a merged field shows the newest pass over its farmlands (11's, on lead 8's card)",
     (block(merged) || []).slice(1, 4), ["Last pass: target reached", "One footprint, not the whole field", "Planned 4.00 L, applied 4.00 L"]);
  const pause11 = card(draw(`FIX.results[FIX.v.b] = FIX.result("INACTIVE", 11, nil, { "UNSUPPORTED_CROP" }, true)`), 8);
  eq("P9 and a machine paused on member 11 shows on lead 8's card", (block(pause11) || []).slice(-1), [HOST.UNSUPPORTED_CROP]);
  const twoMembers = card(draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 8, nil, { "UNSUPPORTED_CROP" }, true)
    FIX.results[FIX.v.b] = FIX.result("INACTIVE", 11, nil, { "MIXED_CROP" }, true)`), 8);
  eq("P12 two machines on a merged field's two farmlands: Soil's own read picks the reason it puts first",
     (block(twoMembers) || []).slice(-1), [HOST.MIXED_CROP]);
  const w1a = card(draw(`FIX.noPassRead = true\n${PASS_REACHED}`), 7);
  ok("P10 NAMED: a Soil with no pass read draws no pass line (never 'none' for a read it lacks)",
     block(w1a) !== null && !block(w1a).some((x) => x.startsWith("Last pass")), JSON.stringify(block(w1a)));
  eq("P11 and its plan title is today's", planTitle(w1a), "TREATMENT PLAN");
}

// ---- H: the local line
{
  const on11 = draw(`FIX.px = 150`);
  ok("H1 NAMED: the player on member 11 draws the local line on lead 8's card", (block(card(on11, 8)) || []).includes("Here, 2.0 m cells: N low, P ok, K ok"), JSON.stringify(block(card(on11, 8))));
  ok("H2 and none on field 7's card", block(card(on11, 7)) !== null && !block(card(on11, 7)).some((x) => x.startsWith("Here")));
  const unknown = draw(`FIX.localRel[7] = FIX.localReading(7, "wheat", "UNDETERMINED", "UNDETERMINED", "UNDETERMINED", nil, false)`);
  ok("H3 NAMED: no map reading where the player stands: said so, never a guessed cell", (block(card(unknown, 7)) || []).includes("Here: no soil reading"), JSON.stringify(block(card(unknown, 7))));
  const bare = draw(`FIX.localRel[7] = FIX.localReading(7, nil, "UNDETERMINED", "UNDETERMINED", "UNDETERMINED", 2, true)`);
  ok("H5 a map reading where nothing grows: the cell size, and no window words it cannot know",
     (block(card(bare, 7)) || []).includes("Here, 2.0 m cells: N ?, P ?, K ?"), JSON.stringify(block(card(bare, 7))));
  lua(`FIX.localRel[7] = FIX.localReading(7, "wheat", "APPROACHING", "IDEAL", "IDEAL", 2, true)`);
  const off = draw(`FIX.px = 500`);
  ok("H4 off every farmland: no local line on any card", block(card(off, 7)) !== null && !off.texts.some((x) => x.startsWith("Here")));
}

// ---- X: a Soil read that fails
{
  const c = card(draw(`${PASS_REACHED}
FIX.throwPass = true`), 7);
  eq("X1 NAMED: a Soil read that throws is caught: the card draws, the pass reads as none", (block(c) || []).slice(2, 3), ["Last pass: none on this crop"]);
}

// ---- W: no crop window
{
  const none = draw(`FIX.rel[7] = FIX.report(7, nil, "UNDETERMINED", "UNDETERMINED", "UNDETERMINED")`);
  eq("W1 NAMED: no crop window: said so", (block(card(none, 7)) || [])[0], "Field report: crop window unavailable");
  lua(`FIX.rel[7] = FIX.report(7, "wheat", "BELOW", "IDEAL", "ABOVE")`);
}

// ---- N: nothing written
{
  lua(`FIX.reset()
    FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)
    FIX.passes[7] = FIX.result("REACHED", 7, "wheat", {}, false, { plannedLitres = 0.15, physicalLitres = 0.15, notedAt = 5000 })
    FIX.install()
    N_BEFORE = FIX.state()`);
  T.draw(APP, false);
  T.draw(APP, false);
  const e = T.run(`
    assert(FIX.state() == N_BEFORE, "Soil's state changed")
    local READ = { getFieldInfo = true, getFieldUrgency = true, getCropNutrientRelationship = true,
                   getApplicationTargetResult = true, getLastTargetPassForField = true, getTargetPrimaryReason = true }
    for _, c in ipairs(FIX.calls) do assert(READ[c], "called " .. c) end`, "@row");
  ok("N1 NAMED: two draws call only Soil's reads and leave Soil's state exactly as it was", e === null, e);
}

// ---- D: another locale
{
  T.setLocale("de");
  const de = localeTexts(workingTree, "de");
  const d = draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)\n${PASS_REACHED}`);
  const i = d.texts.indexOf(de.get("ft_soiltgt_title"));
  const lines = i < 0 ? [] : d.texts.slice(i + 1, i + 7);
  ok("D1 [reached] German: the block's title is the de file's", i >= 0, de.get("ft_soiltgt_title"));
  eq("D2 NAMED: German: the reason and the pass read the de file's text",
     [i >= 0, lines[2], lines[5]], [true, de.get("ft_soiltgt_state_reached"), de.get("ft_soiltgt_r_unsupported_crop")]);
  T.setLocale("en");
}

// ---- F: the literal flag
{
  const c = card(draw(`FIX.results[FIX.v.a] = FIX.result("INACTIVE", 7, nil, { "UNSUPPORTED_CROP" }, true)\n${PASS_REACHED}`), 7);
  const a = c.texts.indexOf("AUTO target"), b = c.texts.indexOf("TREATMENT PLAN (estimate)");
  const unflagged = [];
  for (let i = a; i <= b && a >= 0; i++) if (!c.flagged[i]) unflagged.push(c.texts[i]);
  ok("F1 every block line and the plan title are drawn with the literal flag (resolved text, never looked up again)",
     a >= 0 && b > a && unflagged.length === 0, JSON.stringify(unflagged));
}

if (failures.length) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`soil-target-block: ${failures.length} failure(s) over ${rows} rows`);
  process.exit(1);
}
console.log(`soil-target-block: PASS - ${rows} rows${process.env.BASE_REF ? ` (base ${process.env.BASE_REF})` : ""}`);
