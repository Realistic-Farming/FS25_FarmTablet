// renderer-literal-flag-check.mjs - MAINTENANCE row 154's standing bar: RSF-F166's literalText switch.
//
// The renderer translated everything it queued, text a caller had already localized included, and the
// second FT.l10nAuto reshaped it ("06:00" drew as "06: 00", "OK" as "ok", "PIN HIER SETZEN" as "Anheften
// HIER SETZEN", French lost the space before ":"). RSF-F166's switch fixes it where the caller knows: a
// final optional literalText argument, and only boolean true draws the text as handed. Absent or false keeps
// FT.l10nAuto, so the default is the old behaviour; this bar watches it everywhere.
//
// Rows:
//   T  the switch, on the real FT_Renderer: appText, text, appHeaderText and button draw a text exactly as
//      handed when the final argument is true, and through FT.l10nAuto (a button through it twice, as
//      before) when it is absent, false, a colour table, the string "true" or 1.
//   H  the helpers pass it down, part by part: sectionHeader, badge, drawSection, drawAppHeader (title and
//      subtitle apart), row and drawRow (label and value apart), drawButton, drawButtonPair (A and B apart),
//      drawHelpPage (its header, and each entry's literalTitle and literalBody apart: a raw English title
//      still translates while the entry's resolved body is drawn as handed).
//   F  every drawer (main page and help page) and the chrome (home, lock, status bar, repair, battery,
//      provider, toast, offline banner, edit overlay), in all 26 locales, through tools/test/tablet-harness.mjs
//      (the real files, the real registry, the real FT_Renderer). A renderer call from app code WITHOUT the
//      flag whose text equals a resolver's output of that draw, or holds one of 4 or more characters, fails
//      (FLAG). FT.l10nAuto handed a resolver's output outside the renderer fails too (PASS: a second
//      translation where the text is written). Resolver outputs are FT.l10n, FT.l10nFormat, g_i18n:getText
//      (every file-local resolver ends there), a call-site FT.l10nAuto, and a string.format or string.gsub of
//      one, each line of each. English source (an FT.AUTO_L10N key, or a literal the code writes) is never
//      counted. F_ALLOW names an exception with its reason.
//   K  "OK" draws "OK" in English: the dead ["ok"] map entry (the signal bar's internal state id) is gone.
//   E  the named cases draw their file text, reached through the real drawers, with the fixture each needs
//      (owned fields, a Soil Fertilizer manager, a selected field, a queued toast, a job started by pressing
//      the real Field Jobs buttons).
//
// Usage:  node tools/test/renderer-literal-flag-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { createRequire } from "node:module";
import { makeTablet, workingTree, localeTexts, ROOT } from "./tablet-harness.mjs";

const req = createRequire(join(ROOT, "tools", "test", "package.json"));
const luaparse = req("luaparse");
const failures = [];
const locales = readdirSync(join(ROOT, "translations")).map((f) => f.match(/^translation_([a-z]{2})\.xml$/)).filter(Boolean).map((m) => m[1]).sort();
if (locales.length !== 26) { console.log(`expected 26 locale files, found ${locales.length}`); process.exit(1); }

// Exceptions to the F row: "<FLAG|PASS> <file:line>" -> reason.
const F_ALLOW = {

};

// English source: every string literal the code writes, and each line of it.
const tree = (dir) => readdirSync(join(ROOT, dir)).flatMap((f) => { const rel = dir + "/" + f; return statSync(join(ROOT, rel)).isDirectory() ? tree(rel) : rel.endsWith(".lua") ? [rel] : []; });
const dec = (s) => Buffer.from(s, "latin1").toString("utf8");
const SRC = new Set();
for (const rel of tree("src")) {
  (function w(n) {
    if (!n || typeof n !== "object") return;
    if (Array.isArray(n)) { n.forEach(w); return; }
    if (n.type === "StringLiteral") { const v = dec(n.value); SRC.add(v); for (const l of v.split("\n")) SRC.add(l); }
    for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]);
  })(luaparse.parse(readFileSync(join(ROOT, rel), "latin1"), { luaVersion: "5.1", encodingMode: "pseudo-latin1" }).body);
}

const t = makeTablet(workingTree, { instrument: true });
if (t.loadErrors.length) { console.log("renderer-literal-flag: the tablet did not load: " + t.loadErrors.join("; ")); process.exit(1); }
t.setSources([...SRC].filter((s) => /\p{L}/u.test(s)));
const lua = (code) => { const e = t.run(code, "@bar"); if (e) failures.push("bar: " + e); };

// ---- T and H: the switch and its pass-through, run in German (so a translation shows).
t.setLocale("de");
lua(`
  BAR = {}
  local function fail(s) BAR[#BAR + 1] = s end
  local function last(r, list) local l = r[list]; return l[#l] and tostring(l[#l].text) end
  local SAMPLES = { "06:00", "OK", "   Status: ", "PIN HIER SETZEN", "start", "Champs : 5", "SKIP TO", "MONEY" }
  local OTHERS = { { "absent" }, { "false", false }, { "a colour table", { 1, 1, 1, 1 } }, { "the string true", "true" }, { "1", 1 } }
  for _, s in ipairs(SAMPLES) do
    for _, surf in ipairs({ { "appText", "_buttons" }, { "text", "_texts" }, { "appHeaderText", "_headerTexts" } }) do
      local r = FT_Renderer.new()
      r[surf[1]](r, 0, 0, 1, s, nil, nil, true)
      if last(r, surf[2]) ~= s then fail("T " .. surf[1] .. "(" .. s .. ", true) drew " .. tostring(last(r, surf[2]))) end
      for _, o in ipairs(OTHERS) do
        local r2 = FT_Renderer.new()
        if o[1] == "absent" then r2[surf[1]](r2, 0, 0, 1, s, nil, nil) else r2[surf[1]](r2, 0, 0, 1, s, nil, nil, o[2]) end
        if last(r2, surf[2]) ~= FT.l10nAuto(s) then fail("T " .. surf[1] .. "(" .. s .. ", " .. o[1] .. ") drew " .. tostring(last(r2, surf[2])) .. ", not FT.l10nAuto's " .. FT.l10nAuto(s)) end
      end
    end
    local rb = FT_Renderer.new()
    rb:button(0, 0, 1, 1, s, nil, {}, true)
    local tb = rb._buttons[#rb._buttons - 1]
    if not tb or tostring(tb.text) ~= s then fail("T button(" .. s .. ", true) drew " .. tostring(tb and tb.text)) end
    for _, o in ipairs(OTHERS) do
      local r2 = FT_Renderer.new()
      if o[1] == "absent" then r2:button(0, 0, 1, 1, s, nil, {}) else r2:button(0, 0, 1, 1, s, nil, {}, o[2]) end
      local t2 = r2._buttons[#r2._buttons - 1]
      local want = FT.l10nAuto(FT.l10nAuto(s))
      if not t2 or tostring(t2.text) ~= want then fail("T button(" .. s .. ", " .. o[1] .. ") drew " .. tostring(t2 and t2.text) .. ", not the old two passes " .. want) end
    end
  end
  -- H: helpers, part by part. "06:00" as handed; "SKIP TO" through FT.l10nAuto.
  local r = FT_Renderer.new()
  r:sectionHeader(0, 0, 1, "06:00", true); if last(r, "_buttons") ~= "06:00" then fail("H sectionHeader flag not passed") end
  r:sectionHeader(0, 0, 1, "SKIP TO"); if last(r, "_buttons") ~= FT.l10nAuto("SKIP TO") then fail("H sectionHeader without the flag no longer translates") end
  r:badge(0, 0, "06:00", nil, true); if last(r, "_buttons") ~= "06:00" then fail("H badge flag not passed") end
  r:row(0, 0, 1, "SKIP TO", "06:00", nil, nil, false, true)
  local n = #r._buttons
  if tostring(r._buttons[n - 1].text) ~= FT.l10nAuto("SKIP TO") or tostring(r._buttons[n].text) ~= "06:00" then fail("H row: label and value flags are not apart") end
  r:row(0, 0, 1, "06:00", "SKIP TO", nil, nil, true, false)
  n = #r._buttons
  if tostring(r._buttons[n - 1].text) ~= "06:00" or tostring(r._buttons[n].text) ~= FT.l10nAuto("SKIP TO") then fail("H row: label and value flags are not apart (the other way)") end
  local ui = HARNESS.tablet("farm_admin", false)
  ui:drawSection(0, "06:00", true); if last(ui.r, "_buttons") ~= "06:00" then fail("H drawSection flag not passed") end
  ui:drawRow(0, "SKIP TO", "06:00", nil, nil, nil, true)
  n = #ui.r._buttons
  if tostring(ui.r._buttons[n - 1].text) ~= FT.l10nAuto("SKIP TO") or tostring(ui.r._buttons[n].text) ~= "06:00" then fail("H drawRow: label and value flags are not apart") end
  ui:drawAppHeader("06:00", "SKIP TO", true, false)
  local h = ui.r._headerTexts
  if tostring(h[#h - 1].text) ~= "06:00" or tostring(h[#h].text) ~= FT.l10nAuto("SKIP TO") then fail("H drawAppHeader: title and subtitle flags are not apart") end
  ui:drawButton(0, "06:00", nil, {}, true); if tostring(ui.r._buttons[#ui.r._buttons - 1].text) ~= "06:00" then fail("H drawButton flag not passed") end
  ui:drawButtonPair(0, "06:00", nil, {}, "SKIP TO", nil, {}, true, false)
  local b = ui.r._buttons
  if tostring(b[#b - 3].text) ~= "06:00" or tostring(b[#b - 1].text) ~= FT.l10nAuto(FT.l10nAuto("SKIP TO")) then fail("H drawButtonPair: A and B flags are not apart") end
  -- drawHelpPage: a raw title translates, a resolved body is drawn as handed, line by line.
  local hu = HARNESS.tablet("farm_admin", true)
  hu:drawHelpPage("_adminHelp", "farm_admin", "06:00", nil, { { title = "MONEY", body = "06:00\\nChamps : 5", literalBody = true } }, true)
  local got = {}
  for _, e in ipairs(hu.r._buttons) do if e._isText then got[#got + 1] = tostring(e.text) end end
  local joined = table.concat(got, "|")
  if not joined:find(FT.l10nAuto("MONEY") .. "|06:00|Champs : 5", 1, true) then fail("H drawHelpPage: the title must translate and the flagged body draw as handed, got " .. joined) end
  if tostring(hu.r._headerTexts[1] and hu.r._headerTexts[1].text) ~= "06:00" then fail("H drawHelpPage: the header flag is not passed") end
  function HARNESS.bar() return table.concat(BAR, "\\n") end
`);
{
  const { lua: L, to_luastring } = req("fengari");
  L.lua_getglobal(t.L, to_luastring("HARNESS"));
  L.lua_getfield(t.L, -1, to_luastring("bar"));
  L.lua_pcall(t.L, 0, 1, 0);
  const out = L.lua_tojsstring(t.L, -1) || "";
  L.lua_pop(t.L, 2);
  for (const f of out.split("\n").filter(Boolean)) failures.push(f);
}

// ---- F: every draw, every locale.
const CHROME = ["_drawHome", "_drawLock", "_drawStatusBar", "_drawRepairScreen", "_drawBatteryEmpty", "_drawProviderSelect", "_drawSignalToast", "_drawOfflineDataBanner", "_drawEditOverlay"];
const ids = t.appIds();
let draws = 0, flaggedTexts = 0, allTexts = 0;
const seen = new Map();
for (const loc of locales) {
  t.setLocale(loc);
  const jobs = [];
  for (const id of ids) for (const h of [false, true]) jobs.push([`${id}${h ? " (help)" : ""}`, () => t.draw(id, h)]);
  for (const c of CHROME) jobs.push([`chrome ${c}`, () => t.chrome(c)]);
  for (const [name, f] of jobs) {
    const r = f();
    draws++;
    allTexts += r.texts.length;
    flaggedTexts += r.flagged.filter(Boolean).length;
    for (const v of t.violations()) {
      const key = `${v[0]} ${v[1]}`;
      if (F_ALLOW[key]) continue;
      const msg = v[0] === "FLAG"
        ? `F ${loc} ${name}: ${v[1]} draws ${JSON.stringify(v[3]).slice(0, 80)} through ${v[2]} without the flag${v[4] ? `; it holds the resolved ${JSON.stringify(v[4])}` : ", and it is resolved text"}`
        : `F ${loc} ${name}: ${v[1]} hands the resolved ${JSON.stringify(v[2]).slice(0, 80)} to FT.l10nAuto, a second translation`;
      if (!seen.has(key)) seen.set(key, msg);
    }
  }
}
for (const m of seen.values()) failures.push(m);
if (ids.length < 40) failures.push(`F [reached] only ${ids.length} drawers are in the registry`);
if (flaggedTexts < 20000) failures.push(`F [reached] only ${flaggedTexts} texts were drawn with the flag: the migration is not reached`);

// ---- K: "OK" in English.
t.setLocale("en");
if (t.auto("OK") !== "OK") failures.push(`K "OK" draws ${JSON.stringify(t.auto("OK"))} in English`);

// ---- E: the named cases.
const fmt = (s, ...a) => { if (s == null) return s; let i = 0; return s.replace(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g, () => String(a[i++])); };
const file = (loc, key) => localeTexts(workingTree, loc).get(key);
const drawn = (res) => res.texts;
let eChecks = 0;
const expectIn = (label, list, want) => { eChecks++; if (!want || !list.includes(want)) failures.push(`E ${label}: ${JSON.stringify(want)} is not drawn (${JSON.stringify(list.slice(0, 8)).slice(0, 160)} ...)`); };
for (const loc of ["de", "nl", "cz"]) {
  t.setLocale(loc);
  const texts = drawn(t.draw("farm_admin", false));
  for (const k of ["ft_farmadmin_skip_6am", "ft_farmadmin_skip_noon", "ft_farmadmin_skip_6pm"]) expectIn(`${loc} Farm Admin skip button ${k}`, texts, file(loc, k));
}
for (const loc of ["ct", "fr"]) {
  t.setLocale(loc);
  expectIn(`${loc} Farm Admin time line`, drawn(t.draw("farm_admin", false)), fmt(file(loc, "ft_farmadmin_time_scale_fmt"), "06:30"));
}
for (const loc of ["ct", "jp", "fr"]) {
  t.setLocale(loc);
  const labels = ["ft_farmadmin_money_1k_fmt", "ft_farmadmin_money_10k_fmt", "ft_farmadmin_money_100k_fmt", "ft_farmadmin_money_1m_fmt"].map((k) => fmt(file(loc, k), "$"));
  const line = fmt(file(loc, "ft_farmadmin_help_money_fmt"), labels.join(" · ")).split("\n").pop();
  expectIn(`${loc} Farm Admin money help line`, drawn(t.draw("farm_admin", true)), line);
}
t.setLocale("de");
expectIn("de Hotspot Manager add-pin button", drawn(t.draw("hotspot_manager", false)), file("de", "ft_hotspot_add_pin"));
t.setLocale("en");
expectIn("en Excavator ACTIVE BUCKET", drawn(t.draw("excavator", false)), file("en", "ft_excavator_active_bucket"));
expectIn("en Weather WORLD WEATHER DIAL (help)", drawn(t.draw("weather", true)), file("en", "ft_weather_help_dial_title"));
// Fixture: five owned fields, a Soil Fertilizer manager, field 3 selected.
lua(`
  E_OWNED = FT_DataProvider.getOwnedFields
  FT_DataProvider.getOwnedFields = function() local out = {} for i = 1, 5 do out[i] = { id = i, area = 2.5, name = "Field " .. i } end return out end
  g_currentMission.soilFertilityManager = { soilSystem = { isInitialized = true, getFieldInfo = function() return nil end } }
  HARNESS.setup = function(ui) ui.system.rotationPlannerSelectedField = 3 end
`);
t.setLocale("fr");
{
  const rp = drawn(t.draw("rotation_planner", false));
  expectIn("fr Rotation Planner field count", rp, fmt(file("fr", "ft_rotation_field_count"), 5));
  expectIn("fr Rotation Planner what-if line", rp, fmt(file("fr", "ft_rotation_whatif_field"), "3"));
  expectIn("fr Field Status header", drawn(t.draw("field_status", false)), fmt(file("fr", "ft_fields_count"), 5));
}
t.setLocale("en");
expectIn("en Organic MARKET", drawn(t.draw("organic", false)), file("en", "ft_organic_market"));
// A job started by pressing the real Field Jobs buttons, then read in Danish.
if (t.press("field_jobs", "Start job") !== "1") failures.push("E Field Jobs: the Start job button was not pressed");
if (t.press("field_jobs", "START JOB TIMER") !== "1") failures.push("E Field Jobs: the START JOB TIMER button was not pressed");
t.setLocale("da");
expectIn("da Field Jobs START NEW button", drawn(t.draw("field_jobs", false)), file("da", "ft_auto_start_new"));
// A queued outage toast (two in-game hours), drawn in French: the drawer cuts the message at 58 characters.
lua(`
  HARNESS.setup = function(ui)
    ui.uiState = "app"
    -- As the signal code queues it (FarmTabletUI.lua's outage notice), resolved by the key it uses.
    ui._signalToast = { title = FT.l10n("ft_network_default_provider", "Realistic Farming Mobile"),
      msg = FT.l10nFormat("ft_network_outage_detected", "Network outage detected. Estimated duration: approx. %d in-game hours.", 2), time = 4000 }
  end
`);
t.setLocale("fr");
{
  const msg = fmt(file("fr", "ft_network_outage_detected"), 2);
  const chars = [...msg];
  const want = chars.length > 58 ? chars.slice(0, 57).join("") + "." : msg;
  expectIn("fr outage toast", drawn(t.chrome("_drawSignalToast")), want);
}
// Soil Nutrient cards (MAINTENANCE row 105, batch 9): a Soil Fertilizer manager whose fields need lime, urea
// (with Soil Fertilizer's rates), organic matter and herbicide, drawn in German through the real drawer.
// Every text of that draw must pass the FLAG and PASS rows too, which F cannot reach without the manager.
// One owned field: a second identical card hands FT.l10nAuto the same English rate string the first card's
// call already recorded, which the PASS row would count as a second translation.
lua(`
  HARNESS.setup = nil
  FT_DataProvider.getOwnedFields = function() return { { id = 1, area = 2.5, name = "Field 1" } } end
  g_currentMission.soilFertilityManager = {
    settings = { enabled = true },
    SoilConstants = {
      FERTILIZER_PROFILES = { UREA = { N = 0.5 }, UAN32 = { N = 0.4 } },
      SPRAYER_RATE = { BASE_RATES = { UREA = { unit = "dry" }, UAN32 = { unit = "liquid" } } },
    },
    soilSystem = {
      isInitialized = true,
      getFieldUrgency = function() return 0.8 end,
      getFieldInfo = function() return {
        nitrogen = { value = 10, status = "poor" }, phosphorus = { value = 30, status = "fair" },
        potassium = { value = 30, status = "fair" }, pH = 5.6, organicMatter = 2.5, weedPressure = 80,
        pestPressure = 10, needsFertilization = true, fieldArea = 2.5, lastCrop = "WHEAT" } end,
    },
  }
`);
t.setLocale("de");
{
  const sn = t.draw("soil_fertilizer", false);
  // Read before any expected value is computed: t.auto runs FT.l10nAuto in the same instrumented world.
  const v = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  const texts = drawn(sn);
  for (const k of ["ft_soilnut_tr_lime", "ft_soilnut_om", "ft_soilnut_urgent", "ft_soilnut_fert", "ft_soilnut_treatment_plan",
    "ft_soilnut_tr_om_low", "ft_soilnut_tr_herbicide", "ft_soilnut_weed", "ft_soilnut_tr_unscouted"]) expectIn(`de Soil Nutrient ${k}`, texts, file("de", k));
  expectIn("de Soil Nutrient FIELDS", texts, fmt(file("de", "ft_soilnut_fields_fmt"), 1));
  expectIn("de Soil Nutrient area", texts, fmt(file("de", "ft_auto_1f_ha"), "2.5"));
  expectIn("de Soil Nutrient urea rate", texts, t.auto("UREA 80000 kg/ha (200000 kg)"));
  expectIn("de Soil Nutrient UAN32 rate", texts, t.auto("UAN32 100000 L/ha (250000 L)"));
  expectIn("de Soil Nutrient card title", texts, fmt(file("de", "ft_soilnut_field_title_fmt"), "1", t.auto("WHEAT")));
  eChecks++;
  if (v.length) failures.push(`E de Soil Nutrient card: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
}
// Invoices (MAINTENANCE row 105, batch 11), built-in mode, in German. The invoice manager is installed as
// FarmTabletManager installs it (FT_InvoiceManager.new() on the mission); invoices come from the real
// addInvoice, three directly (overdue by 2 days, due in 1 day, paid) and one through the form a player walks:
// + NEU, +1.000, the due-date arrow once (7 days), ERSTELLEN. Each walk's last draw must pass FLAG and PASS.
lua(`
  HARNESS.setup = nil
  -- Day 10: a due line shows only for a due day above 0, so an overdue one needs a later today.
  E_DAY = g_currentMission.environment.currentDay
  g_currentMission.environment.currentDay = 10
  E_INV = FT_InvoiceManager.new()
  g_currentMission.ftInvoiceManager = E_INV
  local T, S = FT_InvoiceManager.TYPE, FT_InvoiceManager.STATUS
  E_INV:addInvoice({ invoiceType = T.INCOMING, party = "Grain Elevator", description = "Crop Sale", amount = 5000, status = S.PENDING, dueDay = 8 })
  E_INV:addInvoice({ invoiceType = T.OUTGOING, party = "Vet", description = "Animal Care", amount = 300, status = S.PENDING, dueDay = 11 })
  E_INV:addInvoice({ invoiceType = T.OUTGOING, party = "Bank", description = "Loan Payment", amount = 1200, status = S.PAID, dueDay = 0 })
`);
t.setLocale("de");
{
  const newBtn = file("de", "ft_auto_new"), k1 = file("de", "ft_auto_1k_2");
  const form = t.flow("roleplay_phone", [newBtn, k1]);
  const vForm = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  if (form.error) failures.push(`E de Invoices form: ${form.error}`);
  const made = t.flow("roleplay_phone", [newBtn, k1, "►#3", file("de", "ft_auto_create")]);
  const vList = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  if (made.error) failures.push(`E de Invoices list: ${made.error}`);
  eChecks += 2;
  for (const [what, v] of [["form", vForm], ["list", vList]]) {
    if (v.length) failures.push(`E de Invoices ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  }
  for (const k of ["ft_auto_party", "ft_auto_description", "ft_auto_amount_2", "ft_auto_due_date", "ft_auto_create", "ft_auto_cancel"]) expectIn(`de Invoices form ${k}`, form.texts, file("de", k));
  expectIn("de Invoices form party preset", form.texts, t.auto("Contractor"));
  expectIn("de Invoices form description preset", form.texts, t.auto("Equipment Rental"));
  expectIn("de Invoices form due preset", form.texts, t.auto("No due date"));
  expectIn("de Invoices overdue by 2 days", made.texts, fmt(file("de", "ft_rpphone_overdue_fmt"), 2));
  expectIn("de Invoices due in 1 day", made.texts, file("de", "ft_rpphone_due_in_one"));
  expectIn("de Invoices due in 7 days (made through the form)", made.texts, fmt(file("de", "ft_rpphone_due_in_fmt"), 7));
  expectIn("de Invoices party translated at the draw", made.texts, t.auto("Grain Elevator"));
  expectIn("de Invoices party made through the form", made.texts, t.auto("Contractor"));
  expectIn("de Invoices description", made.texts, t.auto("Crop Sale"));
  for (const k of ["ft_auto_paid", "ft_auto_pending_2", "ft_auto_pay", "ft_auto_delete", "ft_auto_receivable", "ft_auto_owed"]) expectIn(`de Invoices list ${k}`, made.texts, file("de", k));
}
lua(`g_currentMission.ftInvoiceManager = nil; g_currentMission.environment.currentDay = E_DAY`);
// Income, Tax and Worker Costs (MAINTENANCE row 105, batch 12), in German. The companion mods' managers are
// stand-ins whose getters return each mod's own English words, read from their sources: IncomeMod's
// Settings:getPayModeName ("Hourly"), TaxMod's settings.taxRate id ("medium"), WorkerCosts' getWageLevelName
// ("High") and getCostModeName ("Per Hectare"), and its getRosterSnapshot (WorkerRoster.levelName's "Experienced" /
// "Novice", WorkerManager's "working, pinned" / "idle"). Each drawer's draw must pass FLAG and PASS.
lua(`
  HARNESS.setup = nil
  g_currentMission.incomeManager = { settings = { enabled = true,
    getPayModeName = function() return "Hourly" end, getPaymentAmount = function() return 500 end } }
  g_currentMission.taxManager = { settings = { enabled = true, taxRate = "medium", returnPercentage = 20 },
    stats = { totalTaxesPaid = 1500 } }
  g_currentMission.workerCostsManager = {
    settings = { enabled = true, getWageLevelName = function() return "High" end, getCostModeName = function() return "Per Hectare" end },
    workerSystem = { getActiveWorkers = function() return {} end, monthlyCosts = {} },
    getRosterSnapshot = function() return { authoritative = true, count = 2, working = 1,
      levels = { novice = 1, experienced = 1, master = 0 },
      workers = {
        { name = "Anna", levelName = "Experienced", status = "working, pinned", totalHours = 12.5, totalJobs = 3, fatigue = 0.4, working = true },
        { name = "Ben", levelName = "Novice", status = "idle", totalHours = 2, totalJobs = 0, fatigue = 0, working = false },
      } } end,
  }
`);
t.setLocale("de");
{
  const inc = t.draw("income_mod", false); const vInc = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  const tax = t.draw("tax_mod", false); const vTax = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  const wrk = t.draw("worker_costs", false); const vWrk = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  eChecks += 3;
  for (const [what, r, v] of [["Income", inc, vInc], ["Tax", tax, vTax], ["Worker Costs", wrk, vWrk]]) {
    if (r.error) failures.push(`E de ${what}: ${r.error}`);
    if (v.length) failures.push(`E de ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  }
  const pct = (s) => (s == null ? s : s.replace(/%%/g, "%"));
  expectIn("de Income pay mode (IncomeMod's Hourly)", inc.texts, file("de", "ft_companion_hourly"));
  expectIn("de Tax rate (TaxMod's medium id)", tax.texts, file("de", "ft_companion_medium"));
  expectIn("de Worker Costs wage level (High)", wrk.texts, file("de", "ft_companion_high"));
  expectIn("de Worker Costs cost mode (Per Hectare)", wrk.texts, file("de", "ft_companion_per_hectare"));
  expectIn("de Worker Costs Pro-Staff heading", wrk.texts, fmt(file("de", "ft_wrk_prostaff_fmt"), 2));
  expectIn("de Worker Costs level counts", wrk.texts, fmt(file("de", "ft_wrk_levels_fmt"), 1, 1, 0));
  expectIn("de Worker Costs worker and level", wrk.texts, "Anna  [" + file("de", "ft_companion_experienced") + "]");
  expectIn("de Worker Costs pinned status", wrk.texts, file("de", "ft_companion_working_pinned"));
  expectIn("de Worker Costs idle status", wrk.texts, file("de", "ft_companion_idle"));
  expectIn("de Worker Costs stats line", wrk.texts, pct(fmt(file("de", "ft_wrk_worker_stats_fmt"), "12.5", 3, 40)));
}
lua(`g_currentMission.incomeManager = nil; g_currentMission.taxManager = nil; g_currentMission.workerCostsManager = nil`);
// NPC Favor (MAINTENANCE row 105, batch 13; RSF-F357's drawer), in German, on two hosts shaped like #168's spec
// world: an older host (the compatibility list from its live people and its favor system) and a repaired host (the
// work page through getPersonalWorkView and the roster view through getNeighbourRosterView). Each draw must pass
// FLAG and PASS.
lua(`
  HARNESS.setup = nil
  E_NPC_OLD = { townReputation = 75,
    favorSystem = { activeFavors = { { npcName = "Greta", description = "Fix fence", progress = 50, timeRemaining = 7200000 } },
      stats = { totalFavorsCompleted = 4, totalMoneyEarned = 1200 } },
    activeNPCs = { { name = "Anna", role = "farmer", relationship = 80, isActive = true },
      { name = "Ben", relationship = 30, isActive = true } } }
  E_NPC_NEW = { townReputation = 30,
    getPersonalWorkView = function() return { state = "CURRENT", completedKnown = true, completedCount = 4,
      rows = { { status = "active", npcName = "Greta", description = "Fix fence", progress = 50, timeKnown = true, timeRemainingMs = 7200000 } } } end,
    requestPersonalWorkView = function() end, watchPersonalWork = function() end,
    getNeighbourRosterView = function() return { personLoadState = "READY", snapshotState = "READY",
      rows = { { kind = "LIVE", trust = 80, name = "Anna", roleLabel = "farmer" }, { kind = "LIVE", trust = 55, name = "Ben" } } } end }
  g_currentMission.npcFavorSystem = E_NPC_OLD
`);
t.setLocale("de");
{
  const old = t.draw("npc_favor", false); const vOld = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  lua(`g_currentMission.npcFavorSystem = E_NPC_NEW`);
  const rep = t.draw("npc_favor", false); const vNew = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  eChecks += 2;
  for (const [what, r, v] of [["NPC Favor (older host)", old, vOld], ["NPC Favor (repaired host)", rep, vNew]]) {
    if (r.error) failures.push(`E de ${what}: ${r.error}`);
    if (v.length) failures.push(`E de ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  }
  const pct = (s) => (s == null ? s : s.replace(/%%/g, "%"));
  expectIn("de NPC Favor town reputation (older host)", old.texts, fmt(file("de", "ft_npc_town_rep_fmt"), file("de", "ft_auto_respected")));
  expectIn("de NPC Favor relationships heading (older host)", old.texts, fmt(file("de", "ft_npc_relationships_fmt"), 2));
  expectIn("de NPC Favor friend (older host)", old.texts, "80 " + file("de", "ft_auto_friend"));
  expectIn("de NPC Favor cold (older host)", old.texts, "30 " + file("de", "ft_npc_rel_cold"));
  expectIn("de NPC Favor progress line (older host)", old.texts, pct(fmt(file("de", "ft_npc_progress_left_fmt"), 50, 2)));
  expectIn("de NPC Favor town reputation (repaired host)", rep.texts, fmt(file("de", "ft_npc_town_rep_fmt"), file("de", "ft_auto_poor")));
  expectIn("de NPC Favor relationships heading (roster view)", rep.texts, fmt(file("de", "ft_npc_relationships_fmt"), 2));
  expectIn("de NPC Favor friend (roster view)", rep.texts, "80 " + file("de", "ft_auto_friend"));
  expectIn("de NPC Favor neutral (roster view)", rep.texts, "55 " + file("de", "ft_auto_neutral"));
  expectIn("de NPC Favor progress line (work page)", rep.texts, pct(fmt(file("de", "ft_npc_progress_left_fmt"), 50, 2)));
  expectIn("de NPC Favor FAVORS section", rep.texts, file("de", "ft_auto_favors"));
  expectIn("de NPC Favor role (older host)", old.texts, "Anna  [" + file("de", "ft_npc_role_farmer") + "]");
  expectIn("de NPC Favor unknown role (older host)", old.texts, "Ben  [?]");
  expectIn("de NPC Favor role (roster view)", rep.texts, "Anna  [" + file("de", "ft_npc_role_farmer") + "]");
}
lua(`g_currentMission.npcFavorSystem = nil`);
lua(`FT_DataProvider.getOwnedFields = E_OWNED; g_currentMission.soilFertilityManager = nil; HARNESS.setup = nil`);

console.log(`  T/H: 4 surfaces x 8 texts x 6 flag values, 9 helpers; F: ${draws} draws (${ids.length} drawers x main/help + ${CHROME.length} chrome x ${locales.length} locales), ${allTexts} texts, ${flaggedTexts} drawn with the flag; E: ${eChecks} named-case checks`);
if (failures.length) {
  for (const f of failures.slice(0, 80)) console.log("  FAIL " + f);
  if (failures.length > 80) console.log(`  ... and ${failures.length - 80} more`);
  console.log(`renderer-literal-flag: ${failures.length} failure(s)`);
  process.exit(1);
}
console.log(`renderer-literal-flag: PASS - the switch is exact on every surface and passed down part by part; no resolved text reaches the renderer without it in ${draws} draws; "OK" is "OK"; the named cases draw their file text`);
