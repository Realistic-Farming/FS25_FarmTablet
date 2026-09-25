// l10n-dashboard-check.mjs - MAINTENANCE row 105's text bar for the Dashboard app (DashboardApp.lua)
// (a PR of the tablet translation wave; the pattern of l10n-fieldjobs-check.mjs).
//
// Every key below is drawn by DashboardApp.lua through the renderer's FT.l10nAuto: the header,
// the EDIT and DONE buttons' neighbours, the empty-dashboard hints, the balance and loan labels,
// the section and row labels of the widgets (the WIDGETS table's label and section, drawn on the
// dashboard and in the customize list), the ON/OFF toggles, and the help page (one key per line).
// EDIT and DONE themselves are the home screen PR's keys.
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %02d, %.1f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80).
// Control-name row: the widget hint names the ON toggle by its own text
// Control-name row: the widget hint names the OFF toggle by its own text
//
// Draw-site rows (S1, S2, below the text rows): every literal DashboardApp.lua draws resolves to a key
// through the real FT.AUTO_L10N (run from Constants.lua in fengari), and none holds an em dash.
//
// Usage:  node tools/test/l10n-dashboard-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  // dashboard and customize view
  "ft_auto_dashboard", "ft_auto_current_balance", "ft_auto_current_balance_2", "ft_auto_loan",
  "ft_auto_loan_amount", "ft_auto_finances", "ft_auto_income", "ft_auto_expenses", "ft_auto_net_p_l",
  "ft_auto_farm", "ft_auto_active_fields", "ft_auto_vehicles_3", "ft_auto_active_contracts_2",
  "ft_auto_none", "ft_auto_world", "ft_auto_season", "ft_auto_day_2", "ft_auto_time_2", "ft_auto_weather",
  "ft_auto_nothing_pinned", "ft_auto_tap_edit_to_add_widgets", "ft_auto_customize_widgets",
  "ft_auto_tap_on_off_to_show_or_hide_each_widget", "ft_auto_on", "ft_auto_off",
  // help page
  "ft_auto_your_farm_s_total_available_money", "ft_auto_green_positive_red_overdrawn",
  "ft_auto_loan_amount_shown_alongside_balance_if_active", "ft_auto_income_expenses_net_p_l",
  "ft_auto_tracked_from_the_current_session_since_load", "ft_auto_income_money_earned_expenses_money_spent",
  "ft_auto_net_p_l_income_minus_expenses", "ft_auto_active_fields_vehicles",
  "ft_auto_fields_land_you_own_with_a_crop_growing",
  "ft_auto_vehicles_motorised_vehicles_owned_by_your_farm", "ft_auto_active_contracts",
  "ft_auto_count_of_accepted_contracts_currently_in_progress",
  "ft_auto_open_the_contracts_app_for_details_and_deadlines", "ft_auto_season_day_time_weather",
  "ft_auto_season_requires_the_seasons_mod_blank_in_base_game",
  "ft_auto_day_and_time_show_the_in_game_clock_24h", "ft_auto_customising_widgets",
  "ft_auto_tap_the_small_edit_button_top_right_of_the_dashboard",
  "ft_auto_to_show_or_hide_individual_data_rows", "ft_auto_changes_are_saved_automatically",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "fr:ft_auto_finances": "cognate: French says FINANCES",
  "fc:ft_auto_finances": "cognate: French says FINANCES",
};
const CONTAINS = [["ft_auto_tap_on_off_to_show_or_hide_each_widget", "ft_auto_on", true], ["ft_auto_tap_on_off_to_show_or_hide_each_widget", "ft_auto_off", true]];

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
// ---- Draw-site rows: every literal this app draws must reach a key (the lookup cannot miss).
//   S1  every string literal the files below pass to a drawing call (appText, text, drawRow,
//       drawSection, button, drawButton, drawAppHeader, appHeaderText, row, FT.l10nAuto; for
//       drawHelpPage only its header title) or hold in a drawn table field (title, label, section,
//       and each line of a help body) resolves to a key through the real FT.AUTO_L10N (run from
//       Constants.lua in fengari): exactly, or with its "\n" for a help line, as row 136's retry
//       looks it up; and translation_en.xml carries that key. A literal named in NO_KEY is exempt,
//       with its reason.
//   S2  no literal drawn here holds an em dash.
{
  const FILES = ["src/apps/DashboardApp.lua"];
  const NO_KEY = {};
  const { createRequire } = await import("node:module");
  const req = createRequire(join(ROOT, "tools", "test", "package.json"));
  const luaparse = req("luaparse");
  const fengari = req("fengari");
  const { lua, lauxlib, lualib, to_luastring } = fengari;
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
  const DRAW = new Set(["appText", "text", "drawRow", "drawSection", "button", "drawButton", "drawButtonPair", "drawAppHeader", "appHeaderText", "sectionHeader", "row", "l10nAuto"]);
  const FIELDS = new Set(["title", "label", "section"]);
  let sites = 0;
  const seen = new Set();
  const check = (rel, line, text, helpLine) => {
    if (text === "" || /^ft_[a-z0-9_]+$/.test(text) || /^[\s\d%.:,+\-/()'x*]*$/.test(text)) return;
    const id = `${rel}|${text}`;
    if (seen.has(id)) return;
    seen.add(id);
    sites++;
    if (text.includes(EMD)) failures.push(`S2 ${rel}:${line}: the drawn literal ${JSON.stringify(text)} holds an em dash`);
    if (NO_KEY[text]) return;
    const key = AUTO.get(text) || (helpLine ? AUTO.get(text + "\n") : undefined);
    if (!key) { failures.push(`S1 ${rel}:${line}: ${JSON.stringify(text)} has no FT.AUTO_L10N entry: the lookup misses and every language reads English`); return; }
    if (!EN.inside.has(key)) failures.push(`S1 ${rel}:${line}: ${JSON.stringify(text)} maps to ${key}, which translation_en.xml does not carry`);
  };
  for (const rel of FILES) {
    const ast = luaparse.parse(readFileSync(join(ROOT, rel), "latin1"), { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true });
    (function walk(n) {
      if (!n || typeof n !== "object") return;
      if (Array.isArray(n)) { n.forEach(walk); return; }
      if (n.type === "CallExpression") {
        const name = n.base && (n.base.type === "MemberExpression" ? n.base.identifier.name : null);
        if (name && DRAW.has(name)) {
          for (const a of n.arguments) {
            const v = fold(a); if (v !== null) check(rel, n.loc.start.line, v, false);
            if (a && a.type === "LogicalExpression") for (const s of [a.left, a.right]) { const w = fold(s); if (w !== null) check(rel, n.loc.start.line, w, false); }
          }
        }
        if (name === "drawHelpPage") { const v = fold(n.arguments[2]); if (v !== null) check(rel, n.loc.start.line, v, false); }
      }
      if (n.type === "TableKeyString" && FIELDS.has(n.key.name)) { const v = fold(n.value); if (v !== null) check(rel, n.loc.start.line, v, false); }
      if (n.type === "TableKeyString" && n.key.name === "body") {
        const v = fold(n.value);
        if (v !== null) for (const line of v.split("\n")) check(rel, n.loc.start.line, line, true);
      }
      for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") walk(n[k]);
    })(ast.body);
  }
  console.log(`  draw sites checked: ${sites} literals in ${FILES.join(", ")}`);
}
const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-dashboard: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-dashboard: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names`);
