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
const fmt = (s, ...a) => { let i = 0; return s.replace(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g, () => String(a[i++])); };
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
lua(`FT_DataProvider.getOwnedFields = E_OWNED; g_currentMission.soilFertilityManager = nil; HARNESS.setup = nil`);

console.log(`  T/H: 4 surfaces x 8 texts x 6 flag values, 9 helpers; F: ${draws} draws (${ids.length} drawers x main/help + ${CHROME.length} chrome x ${locales.length} locales), ${allTexts} texts, ${flaggedTexts} drawn with the flag; E: ${eChecks} named-case checks`);
if (failures.length) {
  for (const f of failures.slice(0, 80)) console.log("  FAIL " + f);
  if (failures.length > 80) console.log(`  ... and ${failures.length - 80} more`);
  console.log(`renderer-literal-flag: ${failures.length} failure(s)`);
  process.exit(1);
}
console.log(`renderer-literal-flag: PASS - the switch is exact on every surface and passed down part by part; no resolved text reaches the renderer without it in ${draws} draws; "OK" is "OK"; the named cases draw their file text`);
