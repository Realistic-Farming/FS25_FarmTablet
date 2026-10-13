// l10n-appstore-check.mjs - MAINTENANCE row 105's text bar for the App Store (AppStoreApp.lua) and the app descriptions it shows (AppRegistry.lua)
// (a PR of the tablet translation wave; the pattern of l10n-fieldjobs-check.mjs).
//
// Every key below is drawn by the App Store: the help page's header, titles and body lines
// (drawHelpPage, one line per key through row 136's retry), the header's installed count and
// the group labels, each row's version, OPEN and not-installed texts, the labels and install
// hint of companion mods that are not installed (FT.l10nFormat for the two formatted strings),
// and each installed app's description (AppRegistry.lua, through FT.l10nAuto).
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %02d, %.1f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80).
// Control-name row: the OPEN button's help title names the button by its own text
// Control-name row: the version help line names the Built-in version label by its own text
//
// Draw-site rows (S1 to S4, below the text rows): every description and version in AppRegistry.lua
// and every literal AppStoreApp.lua draws resolves to a key through the real FT.AUTO_L10N (run
// from Constants.lua in fengari), the two formatted strings use their named keys, no em dash.
//
// Usage:  node tools/test/l10n-appstore-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  // help page
  "ft_auto_app_store", "ft_auto_what_is_the_app_store", "ft_auto_open_button", "ft_auto_mod_integrations",
  "ft_auto_version_developer", "ft_auto_lists_every_app_registered_with_the_farm_tablet",
  "ft_auto_grouped_into_built_in_farming_and", "ft_auto_mod_integration_categories",
  "ft_auto_click_open_on_any_app_row_to_switch_to_it_directly",
  "ft_auto_this_is_a_shortcut_you_can_also_click_the_icon_in", "ft_auto_the_left_sidebar_at_any_time",
  "ft_auto_all_known_companion_mod_integrations_are_listed_here",
  "ft_auto_active_mods_show_in_full_colour_with_an_open_button",
  "ft_auto_dimmed_rows_are_supported_but_not_currently_installed",
  "ft_auto_no_setup_needed_apps_appear_automatically_when_the",
  "ft_auto_matching_mod_is_loaded_in_your_savegame", "ft_auto_built_in_apps_show_built_in_as_their_version",
  "ft_auto_third_party_companion_apps_show_their_own_version", "ft_auto_number_and_developer_name",
  // header, groups, rows
  "ft_appstore_installed_count", "ft_auto_built_in", "ft_auto_farming", "ft_auto_finance",
  "ft_auto_built_in_2", "ft_auto_integrated", "ft_auto_not_installed", "ft_auto_open",
  "ft_appstore_install_to_enable",
  // labels of companion mods that are not installed
  "ft_auto_income_mod", "ft_auto_tax_mod", "ft_auto_npc_favor", "ft_auto_soil_fertilizer",
  "ft_auto_market_dynamics", "ft_auto_worker_costs", "ft_auto_random_world_events", "ft_auto_usedplus",
  "ft_auto_invoices_phone", "ft_auto_dairy", "ft_auto_animalautocare", "ft_auto_animalvetsystem",
  "ft_auto_factoryweekschedule", "ft_auto_realisticdealer",
  // app descriptions
  "ft_auto_farm_overview_balance_fields_vehicles_world_state", "ft_auto_browse_and_manage_installed_apps",
  "ft_auto_tablet_configuration", "ft_auto_current_conditions_and_forecast",
  "ft_auto_all_owned_fields_with_crop_and_growth_state", "ft_auto_animal_pens_food_water_cleanliness",
  "ft_auto_nearby_vehicle_diagnostics", "ft_auto_silo_inventory_and_current_sell_prices",
  "ft_auto_view_and_remove_map_hotspots", "ft_auto_checkbox_style_farm_todo_list",
  "ft_auto_log_field_work_sessions_field_vehicle_task_duration",
  "ft_auto_active_contracts_completion_reward_time_remaining",
  "ft_auto_all_owned_vehicles_fuel_wear_operating_hours",
  "ft_auto_production_building_chains_inputs_outputs_active_status",
  "ft_auto_comprehensive_farm_statistics_snapshot", "ft_auto_changelog_and_update_history",
  "ft_auto_income_mod_controls_and_statistics", "ft_auto_tax_mod_status_and_toggle",
  "ft_auto_npc_favor_tracker", "ft_auto_soil_fertilizer_status",
  "ft_auto_fieldsentry_per_field_soil_sim_status_sleep_and_meadow",
  "ft_auto_market_prices_and_dynamic_events", "ft_auto_worker_wages_and_cost_breakdown",
  "ft_auto_random_world_events_tracker", "ft_auto_usedplus_active_sale_listings_and_finance_deals",
  "ft_auto_invoice_tracker_built_in_roleplayphone_integration",
  "ft_auto_animalautocare_status_and_safe_care_trigger",
  "ft_auto_animalvetsystem_illness_and_treatment_monitor",
  "ft_auto_factoryweekschedule_overview_with_workers_events_and_fi",
  "ft_auto_realisticdealer_financing_installments_and_repossession",
  "ft_auto_terrain_depth_readout_and_bucket_load_counter",
  "ft_auto_admin_controls_money_time_scale_skip_time_repair_fuel",
  "ft_auto_overview_of_every_ecosystem_setting_registered_with_the",
  "ft_auto_whole_farm_financial_health_instruments_history_and_pro",
  "ft_auto_farm_wide_irrigation_operations_trend_and_usage",
  "ft_auto_farm_wide_crop_rotation_standing_and_next_crop_compare",
  "ft_auto_organic_certification_and_practice_advice",
  "ft_auto_workercosts_personnel_hire_fire_assign_payroll",
  "ft_auto_pro_staff_co_op_membership_level_and_investment",
  "ft_auto_co_op_progression_level_benefits_and_investment_status",
  "ft_auto_dairycore_per_barn_herd_health_quality_and_spoilage",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
  "ft_auto_usedplus": "a mod's own name: UsedPlus",
  "ft_auto_animalautocare": "a mod's own name: AnimalAutoCare",
  "ft_auto_animalvetsystem": "a mod's own name: AnimalVetSystem",
  "ft_auto_factoryweekschedule": "a mod's own name: FactoryWeekSchedule",
  "ft_auto_realisticdealer": "a mod's own name: RealisticDealer",
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "cz:ft_auto_finance": "cognate: Czech says FINANCE",
};
const CONTAINS = [["ft_auto_open_button", "ft_auto_open", true], ["ft_auto_built_in_apps_show_built_in_as_their_version", "ft_auto_built_in_2", true]];

function entries(file) {
  const whole = readFileSync(file, "utf8");
  const s = whole.indexOf("<texts>"), e = whole.indexOf("</texts>");
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  const inside = new Map(), outside = new Map();
  let m;
  while ((m = re.exec(whole)) !== null) {
    const map = m.index > s && m.index < e ? inside : outside;
    if (!map.has(m[1])) map.set(m[1], []);
    map.get(m[1]).push(m[2]);
  }
  return { inside, outside };
}
const placeholders = (s) => (s.match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).join(",");
const breaks = (s) => (s.match(/&#10;|\\n/g) || []).length;

const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length)).filter((l) => l !== "en");
if (locales.length !== 25) { console.log(`expected 25 non-English locale files, found ${locales.length}`); process.exit(1); }
const EN = entries(join(DIR, "translation_en.xml"));
const failures = [];
for (const key of KEYS) {
  const e = EN.inside.get(key);
  if (!e || e.length !== 1) { failures.push(`en: ${key} present ${e ? e.length : 0} times inside <texts>`); continue; }
  if (EN.outside.has(key)) failures.push(`en: ${key} also sits outside <texts>`);
}
for (const loc of locales) {
  const L = entries(join(DIR, `translation_${loc}.xml`));
  for (const key of KEYS) {
    const e = EN.inside.get(key);
    if (!e || e.length !== 1) continue;
    if (L.outside.has(key)) failures.push(`${loc}: ${key} sits outside <texts>, where FS25 does not read it`);
    const got = L.inside.get(key) || [];
    if (got.length !== 1) { failures.push(`${loc}: ${key} present ${got.length} times inside <texts>`); continue; }
    const v = got[0];
    if (placeholders(v) !== placeholders(e[0])) failures.push(`${loc}: ${key} placeholders [${placeholders(v)}] differ from English [${placeholders(e[0])}]`);
    if (breaks(v) !== breaks(e[0])) failures.push(`${loc}: ${key} has ${breaks(v)} line breaks, English ${breaks(e[0])}`);
    if (v === e[0] && !ALLOW[`${loc}:${key}`] && !ALLOW_ALL[key]) failures.push(`${loc}: ${key} is the English text`);
  }
  for (const [outer, inner, ci] of CONTAINS) {
    const o = (L.inside.get(outer) || [])[0], i = (L.inside.get(inner) || [])[0];
    if (o && i && !(ci ? o.toLowerCase().includes(i.toLowerCase()) : o.includes(i))) failures.push(`${loc}: ${outer} does not name ${inner}'s text ${JSON.stringify(i)}`);
  }
}
// ---- Draw-site rows: every literal the App Store draws must reach a key (the lookup cannot miss).
//   S1  every description = "..." and every non-numeric version = "..." in AppRegistry.lua is an
//       exact FT.AUTO_L10N key that translation_en.xml carries (the App Store passes both
//       through FT.l10nAuto);
//   S2  every literal AppStoreApp.lua draws through FT.l10nAuto resolves: the help page's header
//       and titles, each line of each help body (exactly, or with its "\n" as drawHelpPage's
//       retry looks it up), the not-installed row labels and the FT.l10nAuto("...") arguments;
//   S3  the two formatted strings go through their named keys (FT.l10nFormat), not a
//       concatenation the map can never hold;
//   S4  no literal drawn here holds an em dash.
{
  const { createRequire } = await import("node:module");
  const req = createRequire(join(ROOT, "tools", "test", "package.json"));
  const luaparse = req("luaparse");
  const fengari = req("fengari");
  const { lua, lauxlib, lualib, to_luastring } = fengari;
  const EMD = String.fromCharCode(0x2014);
  // the real FT.AUTO_L10N, built by running Constants.lua
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const cbuf = readFileSync(join(ROOT, "src", "core", "Constants.lua"));
  if (lauxlib.luaL_loadbuffer(L, cbuf, null, to_luastring("@Constants.lua")) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
    failures.push(`S0: Constants.lua did not load: ${lua.lua_tojsstring(L, -1)}`);
  }
  const AUTO = new Map();
  lua.lua_getglobal(L, to_luastring("FT"));
  lua.lua_getfield(L, -1, to_luastring("AUTO_L10N"));
  lua.lua_pushnil(L);
  while (lua.lua_next(L, -2) !== 0) { AUTO.set(lua.lua_tojsstring(L, -2), lua.lua_tojsstring(L, -1)); lua.lua_pop(L, 1); }
  const enKeys = EN.inside;
  const dec = (s) => Buffer.from(s, "latin1").toString("utf8");
  const parse = (rel) => luaparse.parse(readFileSync(join(ROOT, rel), "latin1"), { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true });
  const fold = (n) => {
    if (!n) return null;
    if (n.type === "StringLiteral") return dec(n.value);
    if (n.type === "BinaryExpression" && n.operator === "..") { const a = fold(n.left), b = fold(n.right); return a !== null && b !== null ? a + b : null; }
    return null;
  };
  const walk = (n, fn) => {
    if (!n || typeof n !== "object") return;
    if (Array.isArray(n)) { n.forEach((x) => walk(x, fn)); return; }
    fn(n);
    for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") walk(n[k], fn);
  };
  const show = (s) => JSON.stringify(s);
  let sites = 0;
  const resolve = (row, rel, line, text, helpLine) => {
    sites++;
    if (text.includes(EMD)) failures.push(`S4 ${rel}:${line}: the drawn literal ${show(text)} holds an em dash`);
    const key = AUTO.get(text) || (helpLine ? AUTO.get(text + "\n") : undefined);
    if (!key) { failures.push(`${row} ${rel}:${line}: ${show(text)} has no FT.AUTO_L10N entry: the lookup misses and every language reads English`); return; }
    if (!enKeys.has(key)) failures.push(`${row} ${rel}:${line}: ${show(text)} maps to ${key}, which translation_en.xml does not carry`);
  };
  // S1: AppRegistry.lua descriptions and versions
  const reg = "src/core/AppRegistry.lua";
  walk(parse(reg).body, (n) => {
    if (n.type === "TableKeyString" && (n.key.name === "description" || n.key.name === "version")) {
      const v = fold(n.value);
      if (v !== null && !(n.key.name === "version" && /^[0-9]/.test(v))) resolve("S1", reg, n.loc.start.line, v, false);
    }
  });
  // S2: AppStoreApp.lua
  const appStore = "src/apps/AppStoreApp.lua";
  walk(parse(appStore).body, (n) => {
    if (n.type === "TableKeyString" && (n.key.name === "title" || n.key.name === "label")) {
      const v = fold(n.value); if (v !== null) resolve("S2", appStore, n.loc.start.line, v, false);
    }
    if (n.type === "TableKeyString" && n.key.name === "body") {
      const v = fold(n.value);
      if (v !== null) for (const line of v.split("\n")) if (line !== "") resolve("S2", appStore, n.loc.start.line, line, true);
    }
    if (n.type === "CallExpression" && n.base && n.base.type === "MemberExpression" && n.base.identifier.name === "l10nAuto" && n.arguments.length === 1) {
      const v = fold(n.arguments[0]); if (v !== null) resolve("S2", appStore, n.loc.start.line, v, false);
    }
    if (n.type === "CallExpression" && n.base && n.base.type === "MemberExpression" && n.base.identifier.name === "drawHelpPage") {
      const v = fold(n.arguments[2]); if (v !== null) resolve("S2", appStore, n.loc.start.line, v, false);
    }
  });
  // S3: the named format keys
  const src = readFileSync(join(ROOT, appStore), "utf8");
  for (const [key, fb] of [["ft_appstore_installed_count", "%d installed"], ["ft_appstore_install_to_enable", "Install %s to enable"]]) {
    if (!src.includes(`FT.l10nFormat("${key}", "${fb}"`)) failures.push(`S3 ${appStore}: ${JSON.stringify(fb)} is not drawn through FT.l10nFormat("${key}", ...)`);
    if (!enKeys.has(key)) failures.push(`S3 translation_en.xml lacks ${key}`);
  }
  if (/"Install " \.\. /.test(src) || /" \.\. FT\.l10nAuto\("installed"\)/.test(src)) failures.push(`S3 ${appStore}: a concatenated install hint or installed count is still drawn`);
  console.log(`  draw sites checked: ${sites} (AppRegistry descriptions and versions, AppStoreApp literals)`);
}
const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-appstore: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-appstore: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names`);
