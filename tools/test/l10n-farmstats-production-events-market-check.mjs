// l10n-farmstats-production-events-market-check.mjs - MAINTENANCE row 105's text bar for the Farm Stats,
// Production Buildings, Random World Events and Market Dynamics apps (batch 3 of the remaining apps in the
// tablet translation wave; the pattern of l10n-animals-contracts-fleet-check.mjs, #185).
//
// A batch of four small apps (Tyson's ruling for this pass: 3 or 4 small apps per PR):
//   - Farm Stats (FarmStatsApp.lua);
//   - Production Buildings (ProductionBuildingsApp.lua);
//   - Random World Events (RandomWorldEventsApp.lua);
//   - Market Dynamics (MarketDynamicsApp.lua).
// Drawn literals reach their keys through the renderer's FT.l10nAuto; built texts through FT.l10n and
// FT.l10nFormat. A SOURCES entry's drawnTables names a local table whose string values the app draws
// through FT.l10nAuto, and drawnArgs a local function whose argument at an index it draws that way:
// each such value is checked as a drawn literal (S2) and executed (X1).
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %.1f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80);
//   - script row (Bob's MAJOR on #177): in a locale written in its own script, the text carries at
//     least one letter of that script (CJK ideographs for cs and ct, kana or CJK for jp, Hangul for
//     kr, Cyrillic for ru and uk), unless the key is an own name (ALLOW_ALL), the pair is allowed
//     below, or English's own text holds no letter. A romanised or other-language value differs
//     from English, so the rows above pass it; this row fails it. FarmTablet ships no
//     translation_cs.xml, so the row covers ct, jp, kr, ru and uk until one is added.
//
// Draw-site rows (below the text rows), over the real source files in SOURCES:
//   S1  every key a SOURCES file passes as a literal to one of its text functions (KEYFN) is one of
//       KEYS or named in OTHER_PR, and translation_en.xml carries it;
//   S2  every literal a SOURCES file hands straight to a drawing call (DRAWFN) or holds in a drawn
//       table field resolves through the real FT.AUTO_L10N (Constants.lua run in fengari) to one of
//       KEYS or OTHER_PR, unless NO_KEY names it with its reason; none holds an em dash;
//   S3  no drawing call (and no FT_Renderer.truncate, whose result is drawn) gets text built from an
//       English literal at run time: a string.format of a worded literal, or a concatenation holding
//       one. FT.l10nAuto looks the whole text up, so such text reads English in every language.
//   S4  every key in KEYS is drawn by a SOURCES file: a key call, or a drawn literal the real map sends to it,
//       unless UNDRAWN names it with its reason. A text moved back to a bare literal leaves its key
//       checked and never drawn; S4 fails that.
//   X1  the lookup, executed (Bob's ask on #181): every key call site runs the app's OWN text helper
//       (cut from the real source, with the top-level definitions it needs, the globals other src
//       files set included, such as FarmTabletUI.lua's FT_UI_TEXT) in fengari beside the real
//       Constants.lua, with g_i18n answering from the real locale file, in all 26 files; each drawn
//       literal runs the real FT.l10nAuto. The result must be the file's text (formatted, when the
//       site passes arguments), never the fallback. S1 and S2 read the code; X1 runs it. A helper the
//       bar cannot run fails X1 until X1_SKIP names it with a reason.
//   S5  a drawnArgs function draws that parameter through FT.l10nAuto (none in this batch).
//
// Usage:  node tools/test/l10n-farmstats-production-events-market-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  "ft_auto_active_4", "ft_auto_active_at_least_one_production_chain_is_enabled_and", "ft_auto_active_event",
  "ft_auto_active_events_and_their_intensity_are_listed_here", "ft_auto_active_stalled",
  "ft_auto_active_world_events_market_price_modifiers",
  "ft_auto_adjusted_in_the_market_dynamics_mod_settings", "ft_auto_after_a_fixed_duration",
  "ft_auto_and_event_frequency_settings", "ft_auto_and_time_of_day", "ft_auto_animal_pens",
  "ft_auto_animals_number_of_animal_pens_on_your_farm", "ft_auto_area",
  "ft_auto_area_total_farmland_owned_in_hectares", "ft_auto_balance",
  "ft_auto_balance_your_current_available_money", "ft_auto_building_list", "ft_auto_category",
  "ft_auto_check_your_storage_app_to_ensure_inputs_are_stocked", "ft_auto_cooldown", "ft_auto_current_event",
  "ft_auto_current_in_game_day_season_if_seasons_mod_is_active", "ft_auto_disabled_2",
  "ft_auto_displays_fs25_marketdynamics_status", "ft_auto_displays_fs25_randomworldevents_status",
  "ft_auto_duration", "ft_auto_each_entry_shows_the_building_name_and_how_many_of_its", "ft_auto_economic",
  "ft_auto_enabled", "ft_auto_etc_it_appears_here_with_its_name_events_end", "ft_auto_event_categories",
  "ft_auto_event_frequency", "ft_auto_event_types", "ft_auto_events_like_droughts_trade_disruptions_and",
  "ft_auto_farm_stats", "ft_auto_farm_totals", "ft_auto_field_3",
  "ft_auto_fields_count_of_fields_your_farm_owns_with_crop_or_empt", "ft_auto_frequency",
  "ft_auto_frequency_1_10_controls_how_often_events", "ft_auto_frequency_intensity",
  "ft_auto_income_and_expenses_tracked_since_this_session_started", "ft_auto_inputs_outputs",
  "ft_auto_install_fs25_marketdynamics_to_use_this_app",
  "ft_auto_install_fs25_randomworldevents_to_use_this_app", "ft_auto_integration", "ft_auto_intensity",
  "ft_auto_intensity_and_event_counter", "ft_auto_lists_the_fill_types_the_building_consumes_and_produces",
  "ft_auto_loan_2", "ft_auto_loan_outstanding_loan_amount_0_if_debt_free",
  "ft_auto_management_menu_to_turn_them_on", "ft_auto_market_dynamics_is_not_installed",
  "ft_auto_market_movers_per_1_000_l", "ft_auto_net_p_l_income_minus_expenses_for_the_session",
  "ft_auto_net_worth", "ft_auto_net_worth_balance_minus_loan_your_true_financial_positi", "ft_auto_no",
  "ft_auto_no_active_market_events", "ft_auto_no_buildings_shown", "ft_auto_no_event_currently_active",
  "ft_auto_no_sell_price_data_found", "ft_auto_occur_intensity_1_5_controls_how_severe",
  "ft_auto_outputs_pile_up_if_the_unloading_station_is_full_check",
  "ft_auto_pest_outbreaks_temporarily_shift_crop_prices", "ft_auto_placeable_from_the_shop_to_see_it_here",
  "ft_auto_price_modifiers", "ft_auto_price_modifiers_and_event_frequency_can_be", "ft_auto_production",
  "ft_auto_production_buildings_must_be_owned_by_your_farm", "ft_auto_production_lines_are_currently_active",
  "ft_auto_production_production_buildings_you_own",
  "ft_auto_purchase_a_cheese_factory_bakery_or_other_production",
  "ft_auto_random_world_events_is_not_installed", "ft_auto_ready_2", "ft_auto_session_p_l",
  "ft_auto_shows_every_production_building_your_farm_owns",
  "ft_auto_since_the_last_time_the_savegame_was_loaded", "ft_auto_special",
  "ft_auto_stalled_no_productions_are_enabled_check_the_building", "ft_auto_status_2",
  "ft_auto_the_building_has_the_inputs_it_needs", "ft_auto_the_currently_active_event_frequency",
  "ft_auto_their_effects_are", "ft_auto_unavailable", "ft_auto_vehicle_2",
  "ft_auto_vehicles_motorized_vehicles_owned_by_your_farm", "ft_auto_volatility",
  "ft_auto_what_this_app_shows", "ft_auto_when_an_event_is_running_fire_flood_drought", "ft_auto_wildlife",
  "ft_auto_world_data", "ft_auto_world_events", "ft_auto_world_events_2", "ft_auto_yes_2",
  "ft_auto_your_silo_capacity", "ft_auto_1f_ha", "ft_rwe_duration_fmt", "ft_md_volatility_fmt",
  "ft_md_active_events_fmt", "ft_md_event_intensity_fmt",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
  "ft_md_volatility_fmt": "a number and the multiplier sign x, the same in every language",
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "br:ft_auto_1f_ha": "the base game writes the hectare sign ha in br too (unit_haShort, dataS/l10n/l10n_br.xml)",
  "ct:ft_auto_1f_ha": "the base game writes the hectare sign ha in ct too (unit_haShort, dataS/l10n/l10n_ct.xml)",
  "cz:ft_auto_1f_ha": "the base game writes the hectare sign ha in cz too (unit_haShort, dataS/l10n/l10n_cz.xml)",
  "da:ft_auto_1f_ha": "the base game writes the hectare sign ha in da too (unit_haShort, dataS/l10n/l10n_da.xml)",
  "de:ft_auto_1f_ha": "the base game writes the hectare sign ha in de too (unit_haShort, dataS/l10n/l10n_de.xml)",
  "ea:ft_auto_1f_ha": "the base game writes the hectare sign ha in ea too (unit_haShort, dataS/l10n/l10n_ea.xml)",
  "es:ft_auto_1f_ha": "the base game writes the hectare sign ha in es too (unit_haShort, dataS/l10n/l10n_es.xml)",
  "fc:ft_auto_1f_ha": "the base game writes the hectare sign ha in fc too (unit_haShort, dataS/l10n/l10n_fc.xml)",
  "fi:ft_auto_1f_ha": "the base game writes the hectare sign ha in fi too (unit_haShort, dataS/l10n/l10n_fi.xml)",
  "fr:ft_auto_1f_ha": "the base game writes the hectare sign ha in fr too (unit_haShort, dataS/l10n/l10n_fr.xml)",
  "hu:ft_auto_1f_ha": "the base game writes the hectare sign ha in hu too (unit_haShort, dataS/l10n/l10n_hu.xml)",
  "id:ft_auto_1f_ha": "the base game writes the hectare sign ha in id too (unit_haShort, dataS/l10n/l10n_id.xml)",
  "it:ft_auto_1f_ha": "the base game writes the hectare sign ha in it too (unit_haShort, dataS/l10n/l10n_it.xml)",
  "jp:ft_auto_1f_ha": "the base game writes the hectare sign ha in jp too (unit_haShort, dataS/l10n/l10n_jp.xml)",
  "kr:ft_auto_1f_ha": "the base game writes the hectare sign ha in kr too (unit_haShort, dataS/l10n/l10n_kr.xml)",
  "nl:ft_auto_1f_ha": "the base game writes the hectare sign ha in nl too (unit_haShort, dataS/l10n/l10n_nl.xml)",
  "no:ft_auto_1f_ha": "the base game writes the hectare sign ha in no too (unit_haShort, dataS/l10n/l10n_no.xml)",
  "pl:ft_auto_1f_ha": "the base game writes the hectare sign ha in pl too (unit_haShort, dataS/l10n/l10n_pl.xml)",
  "pt:ft_auto_1f_ha": "the base game writes the hectare sign ha in pt too (unit_haShort, dataS/l10n/l10n_pt.xml)",
  "ro:ft_auto_1f_ha": "the base game writes the hectare sign ha in ro too (unit_haShort, dataS/l10n/l10n_ro.xml)",
  "sv:ft_auto_1f_ha": "the base game writes the hectare sign ha in sv too (unit_haShort, dataS/l10n/l10n_sv.xml)",
  "tr:ft_auto_1f_ha": "the base game writes the hectare sign ha in tr too (unit_haShort, dataS/l10n/l10n_tr.xml)",
  "vi:ft_auto_1f_ha": "the base game writes the hectare sign ha in vi too (unit_haShort, dataS/l10n/l10n_vi.xml)",
  "ea:ft_auto_no": "No is the Spanish word",
  "es:ft_auto_no": "No is the Spanish word",
  "it:ft_auto_no": "No is the Italian word",
  "fc:ft_auto_production": "Production is the French word",
  "fr:ft_auto_production": "Production is the French word",
  "id:ft_auto_status_2": "Status is the Indonesian word",
  "ro:ft_auto_economic": "Economic is the Romanian word",
  "ro:ft_auto_special": "Special is the Romanian word",
};
// (locale, key) pairs in a script locale whose text is written in Latin letters and differs from
// English, each with its reason (a unit symbol the language writes that way, such as jp "ha").
const SCRIPT_ALLOW = {

};
// Keys this app draws that another PR of the wave checks, with the PR.
const OTHER_PR = {
  "ft_auto_day_2": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_expenses": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_fields_3": "another bar's key (l10n-home-check.mjs)",
  "ft_auto_finances": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_income": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_market_dynamics": "another bar's key (l10n-appstore-check.mjs)",
  "ft_auto_net_p_l": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_off_2": "another bar's key (l10n-rotation-sysset-prostaff-check.mjs)",
  "ft_auto_on_2": "another bar's key (l10n-rotation-sysset-prostaff-check.mjs)",
  "ft_auto_random_world_events": "another bar's key (l10n-appstore-check.mjs)",
  "ft_auto_season": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_settings": "another bar's key (l10n-settings-check.mjs)",
  "ft_auto_status": "another bar's key (l10n-field-sentry-check.mjs)",
  "ft_auto_time_2": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_vehicles_3": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_weather": "another bar's key (l10n-dashboard-check.mjs)",
  "ft_auto_world": "another bar's key (l10n-dashboard-check.mjs)",
};
// Drawn literals with no key, each with its reason.
const NO_KEY = {

};
// Keys this bar checks that no SOURCES file draws, each with its reason.
const UNDRAWN = {

};
// Key helpers X1 does not run, each with its reason (e.g. a helper returning a table of lines).
const X1_SKIP = {

};
// [outer, inner]: the outer text names the inner key's text (case-insensitive).
const CONTAINS = [

];
// The source files the draw-site rows read, and in each the text functions whose first argument is
// a key. keyPrefix limits a shared file to this app's keys.
const SOURCES = [
  {"file": "src/apps/FarmStatsApp.lua", "keyFns": ["l10n", "l10nFormat"], "literals": true},
  {"file": "src/apps/ProductionBuildingsApp.lua", "keyFns": ["l10n", "l10nFormat"], "literals": true},
  {"file": "src/apps/RandomWorldEventsApp.lua", "keyFns": ["l10n", "l10nFormat"], "literals": true},
  {"file": "src/apps/MarketDynamicsApp.lua", "keyFns": ["l10n", "l10nFormat"], "literals": true},
];
const DRAWFN = new Set(["appText", "text", "drawRow", "drawSection", "button", "drawButton", "drawButtonPair",
  "drawAppHeader", "appHeaderText", "sectionHeader", "row", "badge", "l10nAuto", "infoRow", "actionRow", "section"]);
const FIELDS = new Set(["title", "label", "section"]);

const ALL = {};
const unesc = (s) => s.replace(/&#10;/g, "\n").replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&apos;/g, "'").replace(/&amp;/g, "&");
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
const SCRIPT = {
  cs: { name: "CJK ideograph", re: /\p{Script=Han}/u },
  ct: { name: "CJK ideograph", re: /\p{Script=Han}/u },
  jp: { name: "kana or CJK ideograph", re: /[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]/u },
  kr: { name: "Hangul letter", re: /\p{Script=Hangul}/u },
  ru: { name: "Cyrillic letter", re: /\p{Script=Cyrillic}/u },
  uk: { name: "Cyrillic letter", re: /\p{Script=Cyrillic}/u },
};
const hasLetter = (s) => /\p{L}/u.test(s.replace(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g, "").replace(/&[a-z]+;|&#\d+;/g, ""));
let scriptChecked = 0;
const placeholders = (s) => (s.replace(/%%/g, "").match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).join(",");
const breaks = (s) => (s.match(/&#10;|\\n/g) || []).length;

const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length)).filter((l) => l !== "en");
if (locales.length !== 25) { console.log(`expected 25 non-English locale files, found ${locales.length}`); process.exit(1); }
const EN = entries(join(DIR, "translation_en.xml"));
ALL.en = EN;
const failures = [];
for (const key of KEYS) {
  const e = EN.inside.get(key);
  if (!e || e.length !== 1) { failures.push(`en: ${key} present ${e ? e.length : 0} times inside <texts>`); continue; }
  if (EN.outside.has(key)) failures.push(`en: ${key} also sits outside <texts>`);
}
for (const loc of locales) {
  const L = entries(join(DIR, `translation_${loc}.xml`));
  ALL[loc] = L;
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
    if (SCRIPT[loc] && !ALLOW_ALL[key] && !ALLOW[`${loc}:${key}`] && !SCRIPT_ALLOW[`${loc}:${key}`] && hasLetter(e[0])) {
      scriptChecked++;
      if (!SCRIPT[loc].re.test(v)) failures.push(`${loc}: ${key} ${JSON.stringify(v)} holds no ${SCRIPT[loc].name}: it is another language, or romanised`);
    }
  }
  for (const [outer, inner] of CONTAINS) {
    const o = (L.inside.get(outer) || [])[0], i = (L.inside.get(inner) || [])[0];
    if (o && i && !unesc(o).toLowerCase().includes(unesc(i).toLowerCase())) failures.push(`${loc}: ${outer} does not name ${inner}'s text ${JSON.stringify(unesc(i))}`);
  }
}

// ---- Draw-site rows, over the real source.
{
  const { createRequire } = await import("node:module");
  const req = createRequire(join(ROOT, "tools", "test", "package.json"));
  const luaparse = req("luaparse");
  const fengari = req("fengari");
  const { lua, lauxlib, lualib, to_luastring } = fengari;
  const KEYSET = new Set(KEYS);
  const EMD = String.fromCharCode(0x2014);
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
  const dec = (s) => Buffer.from(s, "latin1").toString("utf8");
  const fold = (n) => {
    if (!n) return null;
    if (n.type === "StringLiteral") return dec(n.value);
    if (n.type === "BinaryExpression" && n.operator === "..") { const a = fold(n.left), b = fold(n.right); return a !== null && b !== null ? a + b : null; }
    return null;
  };
  const callName = (n) => (n.base.type === "Identifier" ? n.base.name : n.base.type === "MemberExpression" ? n.base.identifier.name : null);
  let keySites = 0, litSites = 0;
  const PARSED = new Map(), X1KEYS = [], X1LITS = [];
  const seen = new Set();
  for (const src of SOURCES) {
    const text = readFileSync(join(ROOT, src.file), "latin1");
    const ast = luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true, ranges: true });
    PARSED.set(src.file, { text, ast });
    const keyFn = new Set(src.keyFns);
    const hasWord = (s) => /[A-Za-z]{2,}/.test(s);
    const dyn = (a, line) => {
      if (!a) return;
      if (a.type === "CallExpression" && a.base.type === "MemberExpression" && a.base.base && a.base.base.name === "string" && a.base.identifier.name === "format") {
        const f = fold(a.arguments[0]);
        if (f !== null && hasWord(f)) failures.push(`S3 ${src.file}:${line}: string.format(${JSON.stringify(f)}, ...) is drawn: the formatted text never matches a map key, so it reads English in every language`);
        return;
      }
      if (a.type === "BinaryExpression" && a.operator === ".." && fold(a) === null) {
        const lits = [];
        (function c(x) { if (!x) return; if (x.type === "StringLiteral") lits.push(dec(x.value)); else if (x.type === "BinaryExpression" && x.operator === "..") { c(x.left); c(x.right); } })(a);
        for (const s of lits) if (hasWord(s)) failures.push(`S3 ${src.file}:${line}: a drawn concatenation holds the English literal ${JSON.stringify(s)}, which no map can hold`);
        return;
      }
      if (a.type === "LogicalExpression") { dyn(a.left, line); dyn(a.right, line); }
    };
    const lit = (line, v, helpLine) => {
      if (v === "" || /^ft_[a-z0-9_]+$/.test(v) || /^[\s\d%.:,+\-/()'x*#]*$/.test(v)) return;
      const id = `${src.file}|${v}`;
      if (seen.has(id)) return;
      seen.add(id);
      litSites++;
      if (v.includes(EMD)) failures.push(`S2 ${src.file}:${line}: the drawn literal ${JSON.stringify(v)} holds an em dash`);
      if (NO_KEY[v]) return;
      const key = AUTO.get(v) || (helpLine ? AUTO.get(v + "\n") : undefined);
      if (key) X1LITS.push({ v, key, file: src.file, line });
      if (!key) failures.push(`S2 ${src.file}:${line}: ${JSON.stringify(v)} has no FT.AUTO_L10N entry: the lookup misses and every language reads English`);
      else if (!KEYSET.has(key) && !OTHER_PR[key]) failures.push(`S2 ${src.file}:${line}: ${JSON.stringify(v)} maps to ${key}, which this bar does not check`);
      else if (!EN.inside.has(key)) failures.push(`S2 ${src.file}:${line}: ${JSON.stringify(v)} maps to ${key}, which translation_en.xml does not carry`);
    };
    (function walk(n) {
      if (!n || typeof n !== "object") return;
      if (Array.isArray(n)) { n.forEach(walk); return; }
      if (n.type === "CallExpression") {
        const name = callName(n);
        if (keyFn.has(name)) {
          const k = fold(n.arguments[0]);
          if (k !== null && (!src.keyPrefix || k.startsWith(src.keyPrefix))) {
            keySites++;
            X1KEYS.push({ file: src.file, fn: name, key: k, nargs: n.arguments.length, line: n.loc.start.line, method: n.base.type === "MemberExpression" && n.base.indexer === ":" });
            if (!KEYSET.has(k) && !OTHER_PR[k]) failures.push(`S1 ${src.file}:${n.loc.start.line}: ${k} is drawn, and this bar does not check it: it can read English in every language`);
            if (!EN.inside.has(k)) failures.push(`S1 ${src.file}:${n.loc.start.line}: ${k} is drawn, and translation_en.xml does not carry it`);
          }
        } else if (src.literals && DRAWFN.has(name)) {
          // A literal argument, or every literal inside an `a and "X" or "Y"` choice.
          const pick = (a) => {
            if (!a) return;
            const v = fold(a);
            if (v !== null) { lit(n.loc.start.line, v, false); return; }
            if (a.type === "LogicalExpression") { pick(a.left); pick(a.right); }
          };
          for (const a of n.arguments) pick(a);
          for (const a of n.arguments) dyn(a, n.loc.start.line);
        }
        // drawnArgs: a local draw function whose argument at the given index is drawn through
        // FT.l10nAuto, called directly or through pcall.
        if (src.drawnArgs) {
          let fn = name, args = n.arguments;
          if (name === "pcall" && args[0] && args[0].type === "Identifier") { fn = args[0].name; args = args.slice(1); }
          if (Object.prototype.hasOwnProperty.call(src.drawnArgs, fn)) {
            const v = fold(args[src.drawnArgs[fn]]);
            if (v !== null) lit(n.loc.start.line, v, false);
          }
        }
        if (src.literals && name === "truncate") dyn(n.arguments[0], n.loc.start.line);
        if (src.literals && name === "drawHelpPage") { const v = fold(n.arguments[2]); if (v !== null) lit(n.loc.start.line, v, false); }
      }
      // A local table whose values the app draws through FT.l10nAuto (drawnTables): every string value
      // is a drawn literal, as if handed to the renderer.
      if (src.drawnTables && n.type === "LocalStatement" && n.variables.length === 1 && src.drawnTables.includes(n.variables[0].name)
          && n.init && n.init[0] && n.init[0].type === "TableConstructorExpression") {
        for (const f of n.init[0].fields) { const v = fold(f.value); if (v !== null) lit(f.loc.start.line, v, false); }
      }
      if (src.literals && n.type === "TableKeyString" && FIELDS.has(n.key.name)) { const v = fold(n.value); if (v !== null) lit(n.loc.start.line, v, false); }
      if (src.literals && n.type === "TableKeyString" && n.key.name === "body") { const v = fold(n.value); if (v !== null) for (const line of v.split("\n")) lit(n.loc.start.line, line, true); }
      for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") walk(n[k]);
    })(ast.body);
  }

  // ---- S5: a drawnArgs function draws that parameter through FT.l10nAuto (a label drawn raw would read
  // English in every language while S2 still finds its map entry).
  for (const src of SOURCES) {
    if (!src.drawnArgs) continue;
    const { ast } = PARSED.get(src.file);
    for (const [fn, idx] of Object.entries(src.drawnArgs)) {
      let decl = null;
      (function w(n) {
        if (!n || typeof n !== "object" || decl) return;
        if (Array.isArray(n)) { n.forEach(w); return; }
        if (n.type === "FunctionDeclaration" && n.identifier && n.identifier.name === fn) { decl = n; return; }
        for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]);
      })(ast.body);
      const param = decl && decl.parameters[idx] ? decl.parameters[idx].name : null;
      let flows = false;
      if (param) (function w(n) {
        if (!n || typeof n !== "object" || flows) return;
        if (Array.isArray(n)) { n.forEach(w); return; }
        if (n.type === "CallExpression" && callName(n) === "l10nAuto" && n.arguments[0] && n.arguments[0].type === "Identifier" && n.arguments[0].name === param) { flows = true; return; }
        for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]);
      })(decl.body);
      if (!flows) failures.push(`S5 ${src.file}: ${fn}'s parameter ${idx + 1} (${param || "not found"}) is not drawn through FT.l10nAuto: its label reads English in every language`);
    }
  }

  // ---- S4: every checked key is drawn.
  {
    const reached = new Set([...X1KEYS.map((s) => s.key), ...X1LITS.map((s) => s.key)]);
    for (const k of KEYS) if (!reached.has(k) && !UNDRAWN[k]) failures.push(`S4 ${k} is checked here, and no SOURCES file draws it (a key call, or a drawn literal the map sends to it)`);
  }
  // ---- X1: the lookup, executed against the real locale files.
  let x1Calls = 0;
  {
    const { readdirSync: rd, statSync: st } = await import("node:fs");
    const tree = (dir) => rd(join(ROOT, dir)).flatMap((f) => { const rel = dir + "/" + f; return st(join(ROOT, rel)).isDirectory() ? tree(rel) : rel.endsWith(".lua") ? [rel] : []; });
    const parsedOf = (rel) => {
      if (!PARSED.has(rel)) { const text = readFileSync(join(ROOT, rel), "latin1"); PARSED.set(rel, { text, ast: luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true, ranges: true }) }); }
      return PARSED.get(rel);
    };
    const topDefs = (rel) => {
      const { ast } = parsedOf(rel); const locals = new Map(), globals = new Map();
      for (const s of ast.body) {
        if (s.type === "FunctionDeclaration" && s.identifier && s.identifier.type === "Identifier") (s.isLocal ? locals : globals).set(s.identifier.name, s);
        if (s.type === "LocalStatement") for (const v of s.variables) locals.set(v.name, s);
        if (s.type === "AssignmentStatement") for (const v of s.variables) if (v.type === "Identifier" && !locals.has(v.name)) globals.set(v.name, s);
      }
      return { locals, globals };
    };
    const GLOBAL_DEFS = new Map();
    for (const rel of tree("src")) { try { for (const [g, s] of topDefs(rel).globals) if (!GLOBAL_DEFS.has(g)) GLOBAL_DEFS.set(g, { rel, s }); } catch (e) { failures.push(`X1 ${rel}: luaparse cannot read it (${e.message})`); } }
    // The statements a definition needs: top-level locals of its own file it names, and globals other
    // src files set (with theirs), each file's pieces in source order.
    const need = new Map();
    const addStmt = (rel, s) => {
      if (!need.has(rel)) need.set(rel, new Set());
      if (need.get(rel).has(s)) return;
      need.get(rel).add(s);
      const { locals } = topDefs(rel);
      const names = new Set();
      (function w(n) { if (!n || typeof n !== "object") return; if (Array.isArray(n)) { n.forEach(w); return; } if (n.type === "Identifier") names.add(n.name); for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]); })(s.type === "FunctionDeclaration" ? s.body : s);
      for (const nm of names) {
        if (locals.has(nm) && locals.get(nm) !== s) addStmt(rel, locals.get(nm));
        else if (!locals.has(nm) && GLOBAL_DEFS.has(nm) && nm !== "FT") { const g = GLOBAL_DEFS.get(nm); addStmt(g.rel, g.s); }
      }
    };
    const helperOf = new Map();
    for (const site of X1KEYS) {
      const id = `${site.file}|${site.fn}`;
      if (helperOf.has(id) || X1_SKIP[site.fn]) continue;
      const { locals } = topDefs(site.file);
      const d = locals.get(site.fn);
      if (!site.method && d && d.type === "FunctionDeclaration") { addStmt(site.file, d); helperOf.set(id, `X1_H[${JSON.stringify(id)}] = ${site.fn}`); continue; }
      lua.lua_getglobal(L, to_luastring("FT"));
      lua.lua_getfield(L, -1, to_luastring(site.fn));
      const isFT = lua.lua_type(L, -1) === lua.LUA_TFUNCTION;
      lua.lua_pop(L, 2);
      if (isFT) { helperOf.set(id, `X1_H[${JSON.stringify(id)}] = FT.${site.fn}`); continue; }
      helperOf.set(id, null);
      failures.push(`X1 ${site.file}:${site.line}: the bar cannot run ${site.fn} (not a top-level local function of the file, not an FT function); name it in X1_SKIP with a reason, or teach the bar`);
    }
    const run = (buf, name) => {
      if (lauxlib.luaL_loadbuffer(L, buf, null, to_luastring(name)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return e; }
      return null;
    };
    let err = run(to_luastring(`
      X1_H = {}
      g_i18n = { texts = {} }
      function g_i18n:hasText(k) return self.texts[k] ~= nil end
      function g_i18n:getText(k) return self.texts[k] end
      local SENT = "\\1fallback"
      function X1_text(id, key, want) return X1_H[id](key, SENT) == want end
      function X1_fmt(id, key, want, a, b, c)
        local ok, w = pcall(string.format, want, a, b, c)
        if not ok then w = want end
        return X1_H[id](key, SENT .. " %s %s %s", a, b, c) == w
      end
      function X1_auto(text, want) return FT.l10nAuto(text) == want end
    `), "@X1");
    for (const [rel, set] of need) {
      if (err) break;
      const { text } = parsedOf(rel);
      const pieces = [...set].sort((a, b) => a.range[0] - b.range[0]).map((s) => text.slice(s.range[0], s.range[1]));
      const tail = [...helperOf.entries()].filter(([id, v]) => v && id.startsWith(rel + "|")).map(([, v]) => v);
      err = run(Buffer.from(pieces.join("\n") + "\n" + tail.join("\n") + "\n", "latin1"), "@" + rel + " (X1 cut)");
    }
    for (const [id, v] of helperOf) if (!err && v && v.includes("= FT.")) err = run(to_luastring(v), "@X1");
    if (err) failures.push(`X1: the helpers did not run in fengari: ${err}`);
    else {
      const argsFor = (fmt) => (fmt.replace(/%%/g, "").match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).map((q) => (q.endsWith("s") ? "x" : q.endsWith("d") || q.endsWith("i") ? 7 : 1.5));
      const call = (fn, args) => {
        lua.lua_getglobal(L, to_luastring(fn));
        for (const a of args) { if (typeof a === "number") lua.lua_pushnumber(L, a); else lua.lua_pushstring(L, to_luastring(a)); }
        if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return e; }
        const ok = lua.lua_toboolean(L, -1); lua.lua_pop(L, 1); return ok;
      };
      for (const loc of ["en", ...locales]) {
        const map = ALL[loc].inside;
        lua.lua_getglobal(L, to_luastring("g_i18n"));
        lua.lua_createtable(L, 0, map.size);
        for (const [k, v] of map) { lua.lua_pushstring(L, to_luastring(unesc(v[0]))); lua.lua_setfield(L, -2, to_luastring(k)); }
        lua.lua_setfield(L, -2, to_luastring("texts"));
        lua.lua_pop(L, 1);
        const bad = [];
        const seenSite = new Set();
        for (const s of X1KEYS) {
          const id = `${s.file}|${s.fn}`;
          if (!helperOf.get(id) || !map.has(s.key) || seenSite.has(id + "|" + s.key + "|" + (s.nargs > 2))) continue;
          seenSite.add(id + "|" + s.key + "|" + (s.nargs > 2));
          const want = unesc(map.get(s.key)[0]);
          x1Calls++;
          let r;
          if (s.nargs > 2) { const a = argsFor(want).slice(0, 3); while (a.length < 3) a.push("x"); r = call("X1_fmt", [id, s.key, want, ...a]); }
          else r = call("X1_text", [id, s.key, want]);
          if (r !== true) bad.push(`${s.key} (${s.fn})`);
        }
        const seenLit = new Set();
        for (const s of X1LITS) {
          if (!map.has(s.key) || seenLit.has(s.v)) continue;
          seenLit.add(s.v);
          x1Calls++;
          const want = unesc(map.get(s.key)[0]).replace(/\n$/, "");
          const r = call("X1_auto", [s.v, want]);
          if (r !== true) bad.push(`${JSON.stringify(s.v).slice(0, 30)} (l10nAuto)`);
        }
        if (bad.length) failures.push(`X1 ${loc}: ${bad.length} lookups return something other than the file's text (the fallback, for a helper that never reaches the file): ${bad.slice(0, 4).join(", ")}${bad.length > 4 ? ", ..." : ""}`);
      }
    }
  }
  console.log(`  draw sites checked: ${keySites} key calls, ${litSites} drawn literals in ${SOURCES.map((s) => s.file).join(", ")}; X1: ${x1Calls} lookups executed against the files`);
}

const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures.slice(0, 60)) console.log("  FAIL " + f);
  if (failures.length > 60) console.log(`  ... and ${failures.length - 60} more`);
  console.log(`l10n-farmstats-production-events-market: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-farmstats-production-events-market: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names; script rule: ${scriptChecked} values in ${locales.filter((l) => SCRIPT[l]).join(", ")}`);
