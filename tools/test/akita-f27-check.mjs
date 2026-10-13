// akita-f27-check.mjs - MAINTENANCE row 156's bar: F27, the Akita drawers that reported the opposite of their own data.
//
// F27 (certified; seat-certified on its vet half, FT-APP-AKITA-DASHBOARD-ROLEPLAY-STANDARDIZATION-BRIEF.md:24) had three
// faults in src/apps/AkitaTabletIntegrationsApp.lua, each a check and a display reading different things:
//   - AnimalVetSystem listed avs.sickStables but gated on getActiveIllnessCount(), so a missing method printed "No sick
//     animal pens reported" over the cards it drew;
//   - RealisticDealer registers on the mod handle alone (AppRegistry.lua:545-548), but its drawer said "not detected"
//     whenever financeManager was missing, under a header that says Connected;
//   - Open Notices clamped to 1 (math.max(overdue, 1)) instead of counting (UI-3 SDS v5.3 section 3.4: a number
//     presented as a count must be a count).
// The fix (Bob's intake, row 156): the page counts what it draws. A vet case is a table entry of sickStables, and that
// one count feeds the header, the Active Illnesses row and the gate; the method is not read. The dealer says its finance
// data is not available when the handle is there without it. Open Notices is the sum of the missed installments the
// contract cards show; data.overdue is not read.
//
// Rows, through tools/test/tablet-harness.mjs (the real files, the real FT_Renderer, the real locale files):
//   E1  [entry point] the real FarmTabletSystem.new(...):initialize(), which runs the real AppRegistry:autoDetect(),
//       with nothing in the world but the mods' handles (a dealer with no financeManager, a vet system with no
//       getActiveIllnessCount): both apps register. Nothing is put in the registry by hand.
//   D1  a dealer handle without financeManager draws the new text, not "not detected"; the header says Connected.
//   D2  no dealer handle at all still draws "not detected".
//   N1  three contracts with 1, 2 and 3 missed installments: Open Notices reads 6, and the cards' "Notices: N" lines
//       are 1, 2 and 3. N2: data.overdue at 1, 99 or absent changes nothing. N3: no missed installments reads 0.
//   V1  two table cases and no method: the header reads 2 active cases, the Active Illnesses row 2, two case lines,
//       no "No sick" line. V2: the method present and returning 0 changes nothing. V3: a non-table entry is skipped
//       (not counted, no error). V4: one case reads the one-case header. V5, the declared residual (Bob): an empty list
//       with the method returning 3 reads 0 and "No sick animal pens reported"; the page counts only what it draws.
// Each row runs in en, de and fr, with each text taken from that locale's file.
//
// Usage:  node tools/test/akita-f27-check.mjs        Exit: 0 clean, 1 any failure.
import { join } from "node:path";
import { createRequire } from "node:module";
import { makeTablet, workingTree, localeTexts, ROOT } from "./tablet-harness.mjs";

const req = createRequire(join(ROOT, "tools", "test", "package.json"));
const { lua: L_API, to_luastring } = req("fengari");
const failures = [];
let checks = 0;

const t = makeTablet(workingTree);
if (t.loadErrors.length) { console.log("akita-f27: the tablet did not load: " + t.loadErrors.join("; ")); process.exit(1); }
const lua = (code) => { const e = t.run(code, "@bar"); if (e) failures.push("bar: " + e); };
const global = (name) => { L_API.lua_getglobal(t.L, to_luastring(name)); const v = L_API.lua_tojsstring(t.L, -1); L_API.lua_pop(t.L, 1); return v; };
const fmt = (s, ...a) => { if (s == null) return s; let i = 0; return s.replace(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g, () => String(a[i++])); };
const expect = (label, ok, detail) => { checks++; if (!ok) failures.push(`${label}${detail ? ": " + detail : ""}`); };
const has = (r, s) => r.texts.includes(s);
const after = (r, label) => { const i = r.texts.indexOf(label); return i < 0 ? undefined : r.texts[i + 1]; };
const show = (r) => JSON.stringify(r.texts.slice(0, 12)).slice(0, 170);

// The dealer and vet worlds, rebuilt for each case.
lua(`
  F27 = {}
  function F27.clear()
    g_currentMission.realisticDealer, g_currentMission.RealisticDealer, g_realisticDealer = nil, nil, nil
    g_currentMission.animalVetSystem, g_currentMission.animalVet = nil, nil
  end
  function F27.dealer(overdue, missed)
    local contracts = {}
    for i, m in ipairs(missed) do
      contracts[#contracts + 1] = { name = "Traktor " .. i, remainingAmount = 1000 * i, installmentAmount = 100,
        paidInstallments = 2, totalInstallments = 10, missedInstallments = m, status = m > 0 and "overdue" or "active" }
    end
    g_currentMission.realisticDealer = { financeManager = { getFarmOSData = function(self, farmId)
      return { overdue = overdue, contracts = contracts } end } }
  end
  function F27.vet(n, method, extra)
    local sick = {}
    for i = 1, n do sick["pen" .. i] = { stableName = "Stall " .. i, illnessName = "Grippe", remainingMs = 60000, animalCount = 2, vetCalled = true } end
    if extra then sick.bad = 5 end
    local avs = { vetBusy = false, sickStables = sick }
    if method ~= nil then avs.getActiveIllnessCount = function() return method end end
    g_currentMission.animalVetSystem = avs
  end
`);

// ---- E1: the entry point. The real system's initialize() runs the real autoDetect over the mods' handles only.
lua(`
  F27.clear()
  g_currentMission.realisticDealer = {}
  F27.vet(2, nil, false)
  local okNew, sys = pcall(FarmTabletSystem.new, Settings.new(SettingsManager.new()))
  if not okNew then F27_E1 = "new: " .. tostring(sys) else
    local okInit, e = pcall(sys.initialize, sys)
    if not okInit then F27_E1 = "initialize: " .. tostring(e)
    else F27_E1 = (sys.registry:has(FT.APP.REALISTIC_DEALER) and "D" or "-") .. (sys.registry:has(FT.APP.ANIMAL_VET) and "V" or "-") end
  end
`);
expect("E1 the real initialize() registers RealisticDealer on its handle alone and AnimalVetSystem without its method", global("F27_E1") === "DV", `got ${global("F27_E1")}`);

for (const loc of ["en", "de", "fr"]) {
  t.setLocale(loc);
  const L = localeTexts(workingTree, loc);
  const f = (k) => L.get(k);

  // ---- D1 / D2: the dealer's two messages.
  lua(`F27.clear(); g_currentMission.realisticDealer = {}`);
  let r = t.draw("realistic_dealer", false);
  expect(`D1 ${loc}: a dealer without finance data draws its own text`, has(r, f("ft_rd_no_finance")) && !has(r, f("ft_rd_not_detected")), show(r));
  expect(`D1 ${loc}: the header says Connected`, has(r, f("ft_common_connected")), show(r));
  lua(`F27.clear()`);
  r = t.draw("realistic_dealer", false);
  expect(`D2 ${loc}: no dealer at all is not detected`, has(r, f("ft_rd_not_detected")) && !has(r, f("ft_rd_no_finance")), show(r));

  // ---- N1 to N3: Open Notices is the cards' sum.
  for (const [row, overdue, missed, want] of [["N1", "1", "{ 1, 2, 3 }", "6"], ["N2", "99", "{ 1, 2, 3 }", "6"], ["N2", "nil", "{ 1, 2, 3 }", "6"], ["N3", "4", "{ 0, 0 }", "0"]]) {
    lua(`F27.clear(); F27.dealer(${overdue}, ${missed})`);
    r = t.draw("realistic_dealer", false);
    if (r.error) failures.push(`${row} ${loc}: the drawer stopped: ${r.error}`);
    expect(`${row} ${loc}: Open Notices reads ${want} (data.overdue ${overdue}, missed ${missed})`, after(r, f("ft_rd_open_notices")) === want, `drew ${after(r, f("ft_rd_open_notices"))}`);
  }
  lua(`F27.clear(); F27.dealer(1, { 1, 2, 3 })`);
  r = t.draw("realistic_dealer", false);
  for (const n of [1, 2, 3]) expect(`N1 ${loc}: a card shows Notices ${n}`, r.texts.some((s) => s.includes(fmt(f("ft_rd_notices_line"), n))), show(r));

  // ---- V1 to V5: the vet counts the cases it draws.
  for (const [row, n, method, extra] of [["V1", 2, "nil", false], ["V2", 2, "0", false], ["V3", 2, "nil", true]]) {
    lua(`F27.clear(); F27.vet(${n}, ${method}, ${extra})`);
    r = t.draw("animal_vet_system", false);
    if (r.error) failures.push(`${row} ${loc}: the drawer stopped: ${r.error}`);
    expect(`${row} ${loc}: the header reads 2 active cases`, has(r, fmt(f("ft_vet_active_cases"), 2)), show(r));
    expect(`${row} ${loc}: Active Illnesses reads 2`, after(r, f("ft_vet_active_illnesses")) === "2", `drew ${after(r, f("ft_vet_active_illnesses"))}`);
    expect(`${row} ${loc}: two case lines`, r.texts.filter((s) => s === fmt(f("ft_vet_case_line"), "Grippe", 2, 1)).length === 2, show(r));
    expect(`${row} ${loc}: no "No sick" line over the cards`, !has(r, f("ft_vet_no_sick_pens")), show(r));
  }
  lua(`F27.clear(); F27.vet(1, nil, false)`);
  r = t.draw("animal_vet_system", false);
  expect(`V4 ${loc}: one case reads the one-case header`, has(r, f("ft_vet_active_cases_one")), show(r));
  lua(`F27.clear(); F27.vet(0, 3, false)`);
  r = t.draw("animal_vet_system", false);
  expect(`V5 ${loc}: an empty list with the method at 3 reads 0 (the declared residual)`, has(r, fmt(f("ft_vet_active_cases"), 0)) && after(r, f("ft_vet_active_illnesses")) === "0", show(r));
  expect(`V5 ${loc}: and says no sick pens`, has(r, f("ft_vet_no_sick_pens")), show(r));
}
lua(`F27.clear()`);

if (failures.length) {
  for (const x of failures.slice(0, 40)) console.log("  FAIL " + x);
  console.log(`akita-f27: ${failures.length} failure(s) over ${checks} checks`);
  process.exit(1);
}
console.log(`akita-f27: PASS - ${checks} checks: the real initialize() registers both apps from their handles; the dealer without finance data says so; Open Notices is the cards' sum whatever data.overdue says; the vet counts the cases it draws, in en, de and fr`);
