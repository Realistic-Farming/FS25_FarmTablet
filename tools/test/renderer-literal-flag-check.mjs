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
// Akita's animal apps (MAINTENANCE row 105, batch 14), on stand-ins shaped like the drawers' reads: an AnimalAutoCare
// core whose log lines are German (the mod writes them so; its "Status:" line is skipped), and an AnimalVetSystem with
// a pen the vet was called to, a pen of one animal a worker treats, and a pen on the mod's own treatment mode. In
// German, French, Polish and English each draw must pass FLAG and PASS, each log line reads the file's words (German's
// are the mod's own, so a German line is unchanged), and the counts take their one-case forms.
lua(`
  HARNESS.setup = nil
  E_AAC = { getMCCData = function() return { isEnabled = true, autoFutterEnabled = true, autoWasserEnabled = false,
      autoStrohEnabled = true, lastNotKaufCost = 1200, lastWorkerCost = 300,
      lines = { "Status: ok", "Gesamt: An", "Futter: Auffüllen ab 20% | Zielfüllung 90%", "Wasser: Aus",
        "Stroh: Priorität 2", "Letzte Aktion: 06:00", "Wasser: Anzahl 4", "Stroh: Aus (manuell)", "Futter: Anästhesie 1" } } end }
  E_AVS = { vetBusy = true,
    sickStables = { s1 = { stableName = "Kuhstall Nord", illnessName = "Mastitis", remainingMs = 600000, animalCount = 3, vetCalled = true },
      s2 = { stableName = "Schafe", illnessName = "Grippe", remainingMs = 120000, animalCount = 1, workerTreatment = true },
      s3 = { stableName = "Ziegen", illnessName = "Husten", remainingMs = 60000, animalCount = 4, treatmentMode = "Quarantaene" } } }
  -- The page counts the cases it draws (F27, MAINTENANCE row 156): one case is one entry.
  E_AVS_ALL = E_AVS.sickStables
  g_currentMission.animalAutoCareCore = E_AAC
  g_currentMission.animalVetSystem = E_AVS
`);
for (const loc of ["de", "fr", "pl", "en"]) {
  t.setLocale(loc);
  const f = (k) => file(loc, k);
  lua(`E_AVS.sickStables = E_AVS_ALL`);
  const aac = t.draw("animal_auto_care", false); const vA = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  const vet = t.draw("animal_vet_system", false); const vV = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  lua(`E_AVS.sickStables = { s2 = E_AVS_ALL.s2 }`);
  const one = t.draw("animal_vet_system", false); const vO = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  eChecks += 3;
  for (const [what, r, v] of [["AnimalAutoCare", aac, vA], ["AnimalVetSystem", vet, vV], ["AnimalVetSystem (one case)", one, vO]]) {
    if (r.error) failures.push(`E ${loc} ${what}: ${r.error}`);
    if (v.length) failures.push(`E ${loc} ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  }
  expectIn(`${loc} AutoCare overall line`, aac.texts, `${f("ft_aac_overall")}: ${f("ft_common_on")}`);
  expectIn(`${loc} AutoCare food line`, aac.texts, `${f("ft_aac_food")}: ${f("ft_aac_refill_below")} 20% | ${f("ft_aac_target_fill")} 90%`);
  expectIn(`${loc} AutoCare water line`, aac.texts, `${f("ft_aac_water")}: ${f("ft_common_off")}`);
  expectIn(`${loc} AutoCare straw line`, aac.texts, `${f("ft_aac_straw")}: ${f("ft_aac_priority")} 2`);
  expectIn(`${loc} AutoCare last action line`, aac.texts, `${f("ft_aac_last_action_line")}: 06:00`);
  expectIn(`${loc} AutoCare Anzahl stays a word (Bob's #201 MINOR)`, aac.texts, `${f("ft_aac_water")}: Anzahl 4`);
  expectIn(`${loc} AutoCare Aus before a space`, aac.texts, `${f("ft_aac_straw")}: ${f("ft_common_off")} (manuell)`);
  expectIn(`${loc} AutoCare Anästhesie stays a word (Bob's #202 MINOR: a UTF-8 lead byte is a letter)`, aac.texts, `${f("ft_aac_food")}: Anästhesie 1`);
  expectIn(`${loc} AutoCare LAST ACTION section`, aac.texts, f("ft_aac_last_action"));
  expectIn(`${loc} Vet header`, vet.texts, fmt(f("ft_vet_active_cases"), 3));
  expectIn(`${loc} Vet header (one case)`, one.texts, f("ft_vet_active_cases_one"));
  expectIn(`${loc} Vet busy`, vet.texts, f("ft_common_busy"));
  expectIn(`${loc} Vet case status (vet called)`, vet.texts, f("ft_vet_veterinarian"));
  expectIn(`${loc} Vet case status (worker)`, vet.texts, f("ft_vet_worker"));
  expectIn(`${loc} Vet case status (the mod's mode)`, vet.texts, "Quarantaene");
  expectIn(`${loc} Vet case line`, vet.texts, fmt(f("ft_vet_case_line"), "Mastitis", 3, 10));
  expectIn(`${loc} Vet case line (one animal)`, vet.texts, fmt(f("ft_vet_case_line_one"), "Grippe", 2));
}
if (!file("de", "ft_aac_refill_below") || file("de", "ft_aac_refill_below") !== "Auffüllen ab") failures.push(`E de: ft_aac_refill_below is not AnimalAutoCare's own German word, so a German log line would change`);
lua(`g_currentMission.animalAutoCareCore = nil; g_currentMission.animalVetSystem = nil`);
// Akita's FactoryWeekSchedule and RealisticDealer apps (MAINTENANCE row 105, batch 15), on stand-ins shaped like the
// drawers' reads: a schedule with a named factory at work and a bare one (no name, no worker, no event), and a dealer
// with an overdue contract carrying notices, a paid contract with no name, and one on the mod's own status. In German,
// French, Polish and English each draw must pass FLAG and PASS, the tablet's own words (the fallback names, "No
// event", the statuses, the installments line) are the file's, a factory's Open is its own key (German's Settings
// verb "Öffnen" is not a state), and the mod's own texts are drawn as the mod gives them.
lua(`
  HARNESS.setup = nil
  g_currentMission.fws_weekSchedule = { getOpenFactoryCountForHud = function(self) return 1, 2 end,
    hudDayName = "Montag", hudTimeText = "06:00", fireAutoEnabled = true, hudEventSummaryText = "Streik",
    factoriesForHud = { { displayName = "Molkerei Nord", isOpen = true, workerText = "3/5 Arbeiter" }, { isOpen = false } } }
  g_currentMission.realisticDealer = { financeManager = { getFarmOSData = function(self, farmId) return {
    active = 2, debt = 45000, creditScore = 72, overdue = 1, contracts = {
      { name = "Fendt 942", remainingAmount = 30000, installmentAmount = 2500, paidInstallments = 3, totalInstallments = 12, missedInstallments = 2, status = "overdue" },
      { remainingAmount = 0, installmentAmount = 1000, paidInstallments = 12, totalInstallments = 12, status = "paid" },
      { name = "Claas Lexion", status = "Gestundet", paidInstallments = 1, totalInstallments = 6 } } } end } }
`);
for (const loc of ["de", "fr", "pl", "en"]) {
  t.setLocale(loc);
  const f = (k) => file(loc, k);
  const fws = t.draw("factory_week_schedule", false); const vF = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  const rd = t.draw("realistic_dealer", false); const vR = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
  eChecks += 2;
  for (const [what, r, v] of [["FactoryWeekSchedule", fws, vF], ["RealisticDealer", rd, vR]]) {
    if (r.error) failures.push(`E ${loc} ${what}: ${r.error}`);
    if (v.length) failures.push(`E ${loc} ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  }
  expectIn(`${loc} Factory header`, fws.texts, fmt(f("ft_fws_open_count"), 1, 2));
  expectIn(`${loc} Factory fire system on`, fws.texts, f("ft_common_on"));
  expectIn(`${loc} Factory open state`, fws.texts, f("ft_fws_state_open"));
  expectIn(`${loc} Factory closed state`, fws.texts, f("ft_common_closed"));
  expectIn(`${loc} Factory fallback name`, fws.texts, `${f("ft_fws_factory")} 2`);
  expectIn(`${loc} Factory no event`, fws.texts, f("ft_fws_no_event"));
  expectIn(`${loc} Factory the mod's worker text`, fws.texts, "3/5 Arbeiter");
  expectIn(`${loc} Dealer overdue status`, rd.texts, f("ft_rd_status_overdue"));
  expectIn(`${loc} Dealer paid status`, rd.texts, f("ft_rd_status_paid"));
  expectIn(`${loc} Dealer the mod's own status`, rd.texts, "Gestundet");
  expectIn(`${loc} Dealer fallback name`, rd.texts, f("ft_rd_vehicle"));
  expectIn(`${loc} Dealer installments with notices`, rd.texts, `${fmt(f("ft_rd_installment_line"), 3, 12)} | ${fmt(f("ft_rd_notices_line"), 2)}`);
  expectIn(`${loc} Dealer installments`, rd.texts, fmt(f("ft_rd_installment_line"), 12, 12));
  expectIn(`${loc} Dealer server note`, rd.texts, f("ft_rd_server_note"));
}
if (file("de", "ft_fws_state_open") === file("de", "ft_common_open")) failures.push(`E de: a factory's Open is the Settings button's verb ${JSON.stringify(file("de", "ft_common_open"))}`);
lua(`g_currentMission.fws_weekSchedule = nil; g_currentMission.realisticDealer = nil`);
// Financial Cockpit (MAINTENANCE row 105, batch 16; FT-6, and RSF-F130's debt rows), through an IncomeManager stand-in
// whose getEmergencyLoanView returns IncomeMod's own view shape (IncomeMod src/IncomeManager.lua:587, EmergencyLoan.lua
// getView :831): COMPLETE (READY, 5250 outstanding), INCOMPLETE (no view yet: nil, "NO_VIEW_YET", the client's reply
// before the host answers) and NATIVE_ONLY (no manager). The home page, and the vital pocket through the heart's real
// button; the history modes through the reader's own probe (_historyMode: Time Guard absent, host, joined client,
// dedicated). The app's real back handler returns it home after each walk. Each draw must pass FLAG and PASS, in de,
// fr, pl and en, and F130's rows draw the file's text.
lua(`
  HARNESS.setup = nil
  E_FC = {}
  function E_FC.tick() g_currentMission.time = (g_currentMission.time or 0) + 600000 end
  function E_FC.home() local h = FarmTabletUI._appBackHandlers[FT.APP.FINANCIAL_COCKPIT]; if h then h() end end
  function E_FC.view(mode)
    if mode == "COMPLETE" then
      g_currentMission.incomeManager = { getEmergencyLoanView = function(self, farmId)
        return { version = 1, farmId = 1, revision = 1, readiness = "READY", nativeLoan = 0, principal = 5000, accruedInterest = 250,
          outstanding = 5250, drawCount = 1, effectiveMonthlyRate = 0.02, automaticRepaymentShare = 0.25,
          canBorrow = false, borrowReason = "NO_ACTOR_CONTEXT", canRepay = false, repayReason = "NO_ACTOR_CONTEXT" } end,
        settings = { getPaymentAmount = function() return 1500 end, getPayModeName = function() return E_FC.payMode end },
        getNextPaymentInfo = E_FC.nextInfo }
    elseif mode == "INCOMPLETE" then
      g_currentMission.incomeManager = { getEmergencyLoanView = function(self, farmId) return nil, "NO_VIEW_YET" end }
    else
      g_currentMission.incomeManager = nil
    end
    E_FC.tick()
  end
  E_FC.isServer = g_currentMission.getIsServer
  E_FC.payMode = "Hourly"
  E_FC.nextInfo = nil
`);
for (const loc of ["de", "fr", "pl", "en"]) {
  t.setLocale(loc);
  const f = (k) => file(loc, k);
  // Open a pocket with its real button, then draw it fresh: the snapshot is cached per game time, so the pocket's
  // first draw reuses the home draw's texts and the FLAG check could not see which resolver made them.
  const open = (walk) => { t.flow("financial_cockpit", walk); lua(`E_FC.tick()`); return t.draw("financial_cockpit", false); };
  const clean = (what, r) => {
    const v = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
    eChecks++;
    if (r.error) failures.push(`E ${loc} Cockpit ${what}: ${r.error}`);
    if (v.length) failures.push(`E ${loc} Cockpit ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  };
  // COMPLETE: F130's emergency and total rows, the loan button, and the debt parts in the leverage vital.
  lua(`E_FC.home(); E_FC.view("COMPLETE")`);
  let r = t.draw("financial_cockpit", false); clean("home (COMPLETE)", r);
  expectIn(`${loc} Cockpit emergency loan row`, r.texts, f("ft_fc_emergency_loan"));
  expectIn(`${loc} Cockpit total debt row`, r.texts, f("ft_fc_total_debt"));
  expectIn(`${loc} Cockpit manage loan button`, r.texts, f("ft_fc_open_loan"));
  expectIn(`${loc} Cockpit bank loan row (RSF-F130's word)`, r.texts, f("ft_fc_loan"));
  // The forecast and flows pockets, through their real open buttons (the home draws forecast, history, flows).
  lua(`E_FC.home(); E_FC.tick()`);
  r = open([f("ft_fc_open") + "#1"]); clean("forecast pocket", r);
  expectIn(`${loc} Cockpit forecast next income`, r.texts, f("ft_fc_forecast_next_pay"));
  expectIn(`${loc} Cockpit forecast note, IncomeMod's pay mode in the file's word`, r.texts, f("ft_companion_hourly"));
  lua(`E_FC.home(); E_FC.tick()`);
  r = open([f("ft_fc_open") + "#3"]); clean("flows pocket", r);
  expectIn(`${loc} Cockpit flows pay mode`, r.texts, f("ft_companion_hourly"));
  // IncomeMod's own next-payment sentence is its text: drawn as IncomeMod gives it.
  lua(`E_FC.home(); E_FC.nextInfo = function() return "Hour 07:00 (~12 game-minute(s) remaining)" end; E_FC.view("COMPLETE")`);
  r = open([f("ft_fc_open") + "#1"]); clean("forecast pocket (IncomeMod's sentence)", r);
  expectIn(`${loc} Cockpit forecast note, IncomeMod's own sentence`, r.texts, "Hour 07:00 (~12 game-minute(s) remaining)");
  lua(`E_FC.home(); E_FC.nextInfo = nil; E_FC.view("COMPLETE")`);
  r = open([""]); clean("vital pocket (COMPLETE)", r);
  const parts = r.texts.find((s) => s.includes(f("ft_fc_debt_emergency")) && s.includes(f("ft_fc_debt_total")));
  eChecks++;
  if (!parts || !parts.startsWith(f("ft_fc_debt_native"))) failures.push(`E ${loc} Cockpit debt parts: no "${f("ft_fc_debt_native")} ... ${f("ft_fc_debt_emergency")} ... ${f("ft_fc_debt_total")}" line (${JSON.stringify(r.texts).slice(0, 160)})`);
  expectIn(`${loc} Cockpit vitals section`, r.texts, f("ft_fc_section_vitals"));
  expectIn(`${loc} Cockpit worst rule`, r.texts, f("ft_fc_worst_rule"));
  expectIn(`${loc} Cockpit no clock (Time Guard absent)`, r.texts, f("ft_fc_history_no_clock"));
  // INCOMPLETE: the owner is present without a view; the combined figure is unknown, the loan button stays.
  lua(`E_FC.home(); E_FC.view("INCOMPLETE")`);
  r = t.draw("financial_cockpit", false); clean("home (INCOMPLETE)", r);
  expectIn(`${loc} Cockpit unavailable (INCOMPLETE)`, r.texts, f("ft_fc_unavailable"));
  expectIn(`${loc} Cockpit manage loan button (INCOMPLETE)`, r.texts, f("ft_fc_open_loan"));
  r = open([""]); clean("vital pocket (INCOMPLETE)", r);
  expectIn(`${loc} Cockpit leverage partial (INCOMPLETE)`, r.texts, f("ft_fc_partial"));
  // NATIVE_ONLY: no owner, no F130 rows, no loan button.
  lua(`E_FC.home(); E_FC.view("NATIVE_ONLY")`);
  r = t.draw("financial_cockpit", false); clean("home (NATIVE_ONLY)", r);
  eChecks++;
  if (r.texts.includes(f("ft_fc_open_loan")) || r.texts.includes(f("ft_fc_emergency_loan"))) failures.push(`E ${loc} Cockpit NATIVE_ONLY draws F130's loan rows`);
  // History modes through the reader's own probe: a joined client, then a dedicated server.
  lua(`E_FC.home(); g_currentMission.timeGuard = {}; g_currentMission.getIsServer = function() return false end; E_FC.tick()`);
  r = open([""]); clean("vital pocket (host only)", r);
  expectIn(`${loc} Cockpit host only (joined client)`, r.texts, f("ft_fc_history_host_only"));
  lua(`E_FC.home(); g_currentMission.isDedicatedServer = true; E_FC.tick()`);
  r = open([""]); clean("vital pocket (dedicated)", r);
  expectIn(`${loc} Cockpit dedicated`, r.texts, f("ft_fc_history_dedicated"));
  lua(`E_FC.home(); g_currentMission.isDedicatedServer = nil; g_currentMission.timeGuard = nil; g_currentMission.getIsServer = E_FC.isServer; E_FC.tick()`);
}
lua(`E_FC.home(); g_currentMission.incomeManager = nil; E_FC.tick()`);
lua(`FT_DataProvider.getOwnedFields = E_OWNED; g_currentMission.soilFertilityManager = nil; HARNESS.setup = nil`);

// MAINTENANCE row 158's six named sites and Organic's practice lines (the final fc sweep), each reached by its drawer's own route, in German, French
// and Polish: pens the engine's way (placeables with spec_husbandryAnimals; DataProvider names the type), a farmland the
// real getOwnedFields reads (Field Jobs' start view, through its real buttons), Hotspot Manager's and Personnel's real
// buttons (the message is set on the press and drawn on the next frame, where the FLAG row cannot attribute it: the
// flag on the drawn text is the check), DairyCore's barn rows (a disease id is SoilFertilizer's, relayed as DairyCore
// gives it), and FactoryWeekSchedule's day and time. The file's text is drawn as it is, with the flag; the mods' own
// text keeps the renderer's pass (Organic's disease id, and FactoryWeekSchedule's day when no time comes with it).
const expectLit = (label, res, want, lit = true) => {
  eChecks++;
  const i = want == null ? -1 : res.texts.indexOf(want);
  if (i < 0) failures.push(`E ${label}: ${JSON.stringify(want)} is not drawn (${JSON.stringify(res.texts.slice(0, 8)).slice(0, 160)} ...)`);
  else if (res.flagged[i] !== lit) failures.push(`E ${label}: ${JSON.stringify(want)} is drawn ${lit ? "without" : "with"} the flag`);
};
lua(`
  HARNESS.setup = nil
  E_RS = { placeables = g_currentMission.placeableSystem, farmland = g_farmlandManager }
  local function pen(name, n, max)
    return { spec_husbandry = {}, spec_husbandryAnimals = { animalType = { name = name } },
      getOwnerFarmId = function() return 1 end,
      getNumOfAnimals = function() return n end, getMaxNumOfAnimals = function() return max end }
  end
  g_currentMission.placeableSystem = { placeables = { pen("COW", 12, 20), pen("PIG", 0, 40) } }
  g_farmlandManager = { farmlands = { { id = 4, farmId = 1, field = { getAreaHa = function() return 3.1 end } } } }
  E_RS.soil = g_currentMission.soilFertilityManager
  g_currentMission.soilFertilityManager = { soilSystem = { isInitialized = true, getFieldInfo = function() return nil end } }
  g_currentMission.dairyCoreManager = { getBarnRows = function() return {
    { barnId = 1, farmId = 1, herdHealth = 90, feedDiseaseFlag = true, feedDiseaseCropName = nil },
    { barnId = 2, farmId = 1, herdHealth = 60, feedDiseaseFlag = true, feedDiseaseCropName = "stripe_rust" } } end }
  g_currentMission.workerCostsManager = { settings = { enabled = true }, refreshRecruits = function() end,
    getRosterSnapshot = function() return { authoritative = true, count = 0, working = 0,
      levels = { novice = 0, experienced = 0, master = 0 }, workers = {}, recruits = {} } end }
  g_currentMission.fws_weekSchedule = { getOpenFactoryCountForHud = function() return 0, 0 end,
    hudDayName = "Montag", hudTimeText = "06:00", factoriesForHud = {} }
`);
for (const loc of ["de", "fr", "pl"]) {
  t.setLocale(loc);
  const f = (k) => file(loc, k);
  const clean = (what, r) => {
    const v = t.violations().filter((x) => !F_ALLOW[`${x[0]} ${x[1]}`]);
    eChecks++;
    if (r.error) failures.push(`E ${loc} ${what}: ${r.error}`);
    if (v.length) failures.push(`E ${loc} ${what}: ${v.length} violation(s), first ${v[0][0]} ${v[0][1]} ${JSON.stringify(v[0][2]).slice(0, 80)}`);
  };
  // AnimalHusbandryApp: the pen header, a type name DataProvider resolved, a count or the file's "empty".
  let r = t.draw("animals", false); clean("Animals", r);
  expectLit(`${loc} Animals pen header`, r, `${f("ft_auto_animal_cow")}  (12 / 20)`);
  expectLit(`${loc} Animals empty pen header`, r, `${f("ft_auto_animal_pig")}  (${f("ft_common_empty_lower")})`);
  // FieldJobsApp: the start view's field label, from the field getOwnedFields builds (its crop word is the file's).
  lua(`local h = FarmTabletUI._appBackHandlers["field_jobs"]; if h then h() end`);
  const home = t.draw("field_jobs", false);
  const walk = home.texts.includes(f("ft_fieldjobs_finish_job")) ? [f("ft_fieldjobs_finish_job"), f("ft_fieldjobs_start_job")] : [f("ft_fieldjobs_start_job")];
  r = t.flow("field_jobs", walk); clean("Field Jobs start view", r);
  expectLit(`${loc} Field Jobs field label`, r, fmt(f("ft_fieldjobs_field_label"), "4", f("ft_field_crop_empty")));
  // HotspotManagerApp: ADD PIN HERE with no player position; the error is the file's.
  r = t.flow("hotspot_manager", [f("ft_hotspot_add_pin")]); clean("Hotspot Manager status", r);
  expectLit(`${loc} Hotspot Manager status message`, r, f("ft_hotspot_err_no_position"));
  // PersonnelApp: HIRE, then REROLL; the message is the file's.
  r = t.flow("personnel", [t.auto("HIRE"), t.auto("REROLL")]); clean("Personnel reroll", r);
  expectLit(`${loc} Personnel reroll message`, r, f("ft_personnel_msg_rerolled"));
  // OrganicApp: a feed disease with no name draws the file's fallback; with DairyCore's disease id, the mod's text.
  r = t.draw("organic", false); clean("Organic barns", r);
  expectLit(`${loc} Organic feed disease fallback`, r, f("ft_organic_elevated_risk"));
  // The practice lines for the selected field (Soil Fertilizer has no data for it yet): the file's text.
  expectLit(`${loc} Organic practice line`, r, f("ft_organic_practice_no_data"));
  expectLit(`${loc} Organic feed disease (DairyCore's id keeps the pass)`, r, "stripe_rust", false);
  // FactoryWeekSchedule: the day and time as the mod gives them ("06:00" not split); with no time, the day keeps the pass.
  lua(`g_currentMission.fws_weekSchedule.hudTimeText = "06:00"`);
  r = t.draw("factory_week_schedule", false); clean("FactoryWeekSchedule time", r);
  expectLit(`${loc} FactoryWeekSchedule day and time`, r, "Montag 06:00");
  lua(`g_currentMission.fws_weekSchedule.hudTimeText = nil`);
  r = t.draw("factory_week_schedule", false); clean("FactoryWeekSchedule no time", r);
  expectLit(`${loc} FactoryWeekSchedule day with no time`, r, "Montag -", false);
}
lua(`g_currentMission.placeableSystem = E_RS.placeables; g_farmlandManager = E_RS.farmland; g_currentMission.dairyCoreManager = nil
  g_currentMission.soilFertilityManager = E_RS.soil; local h = FarmTabletUI._appBackHandlers["field_jobs"]; if h then h() end
  g_currentMission.workerCostsManager = nil; g_currentMission.fws_weekSchedule = nil`);

console.log(`  T/H: 4 surfaces x 8 texts x 6 flag values, 9 helpers; F: ${draws} draws (${ids.length} drawers x main/help + ${CHROME.length} chrome x ${locales.length} locales), ${allTexts} texts, ${flaggedTexts} drawn with the flag; E: ${eChecks} named-case checks`);
if (failures.length) {
  for (const f of failures.slice(0, 80)) console.log("  FAIL " + f);
  if (failures.length > 80) console.log(`  ... and ${failures.length - 80} more`);
  console.log(`renderer-literal-flag: ${failures.length} failure(s)`);
  process.exit(1);
}
console.log(`renderer-literal-flag: PASS - the switch is exact on every surface and passed down part by part; no resolved text reaches the renderer without it in ${draws} draws; "OK" is "OK"; the named cases draw their file text`);
