// l10n-settings-check.mjs - MAINTENANCE row 105's text bar for the Settings app (SettingsApp.lua)
// (a PR of the tablet translation wave; the pattern of l10n-fieldjobs-check.mjs).
//
// Every key below is drawn on the Settings screen: through the app's ftSafeText / ftSafeFormat
// (every section, row title, value, hint and button, and the help page), through ftOnOff
// (ft_common_on, ft_common_off), through FarmTabletUI:_getSignalOutageFrequencyLabel and
// :_getTabletRepairFrequencyLabel, which SettingsApp.lua calls for the two frequency rows
// (ft_common_off, _rare, _normal, _frequent), and through the renderer's FT.l10nAuto for the
// author row ("TisonK", ft_auto_tisonk). The start-app row draws app names: those are the home
// screen PR's keys (OTHER_PR below).
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %.0f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80).
// Control-name row: the outage-frequency hint names the four frequency labels by their own text.
//
// Draw-site rows (below the text rows), over the real src/apps/SettingsApp.lua:
//   S1  every key SettingsApp.lua passes as a literal to ftSafeText / ftSafeFormat, and every key the
//       two frequency getters in FarmTabletUI.lua draw, is one of KEYS or named in OTHER_PR, and
//       translation_en.xml carries it;
//   S2  every literal SettingsApp.lua hands straight to a drawing call (section, infoRow, actionRow,
//       appText, button, drawAppHeader) resolves through the real FT.AUTO_L10N (run from Constants.lua
//       in fengari) to one of KEYS, unless NO_KEY names it with its reason;
//   T1  SettingsApp.lua holds no runtime language table and no language branch (row 136's rule:
//       the locale file wins): no table field named ft_... holding a string, and no read of
//       g_languageShort, languageShort or currentLanguage;
//   L1  a key drawn as an actionRow title, value, hint or button fits that row's cut (short() at
//       42, 44, 66 and 24) in characters, in all 26 files, so no translation is cut mid-word.
//       short() counts characters since row 138 (#176), so a text within its cut is never cut.
//
// Usage:  node tools/test/l10n-settings-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  "ft_common_on", "ft_common_off", "ft_common_rare", "ft_common_normal", "ft_common_frequent",
  "ft_auto_settings", "ft_settings_help_display_title", "ft_settings_help_display_body",
  "ft_settings_help_sound_title", "ft_settings_help_sound_body2", "ft_settings_help_network_title",
  "ft_settings_help_network_body", "ft_settings_help_scroll_title", "ft_settings_help_scroll_body",
  "ft_auto_display", "ft_settings_scale_format", "ft_auto_position", "ft_auto_scale",
  "ft_settings_edit_position", "ft_common_active", "ft_settings_hint_edit_position",
  "ft_settings_edit_stop", "ft_settings_reset_position", "ft_common_default",
  "ft_settings_hint_reset_position", "ft_common_reset", "ft_settings_appearance",
  "ft_settings_background_color", "ft_settings_hint_screen_color2", "ft_common_change",
  "ft_settings_home_image_title", "ft_settings_hint_home_image", "ft_common_switch", "ft_size_small",
  "ft_size_medium", "ft_size_large", "ft_color_white", "ft_color_gold", "ft_color_app",
  "ft_settings_app_labels", "ft_settings_hint_icon_text", "ft_common_turn_off", "ft_common_turn_on",
  "ft_settings_text_size_title", "ft_settings_hint_text_size2", "ft_font_scale_small",
  "ft_font_scale_normal", "ft_font_scale_large", "ft_font_scale_huge",
  "ft_settings_content_font_title", "ft_settings_hint_content_font", "ft_settings_text_color_title",
  "ft_settings_hint_text_color2", "ft_settings_sound_section", "ft_settings_sounds",
  "ft_settings_hint_sounds", "ft_settings_app_sound", "ft_settings_hint_app_sound", "ft_common_toggle",
  "ft_settings_help_sound", "ft_settings_hint_help_sound", "ft_settings_tablet_sound",
  "ft_settings_hint_tablet_sound", "ft_settings_general", "ft_settings_notifications",
  "ft_settings_hint_notifications2", "ft_battery_mode_off", "ft_battery_mode_open",
  "ft_battery_mode_standby", "ft_settings_battery_drain", "ft_settings_hint_battery_drain_mode",
  "ft_battery_profile_low", "ft_battery_profile_normal", "ft_battery_profile_high",
  "ft_battery_profile_custom", "ft_settings_battery_profile", "ft_settings_hint_battery_profile",
  "ft_settings_battery_open_rate", "ft_battery_rate_minutes", "ft_settings_hint_battery_open_rate",
  "ft_settings_battery_standby_rate", "ft_settings_hint_battery_standby_rate",
  "ft_settings_start_app_title", "ft_settings_hint_start_app2", "ft_settings_debug_mode",
  "ft_settings_hint_debug2", "ft_settings_network_repair", "ft_signal_very_good", "ft_signal_good",
  "ft_signal_medium", "ft_signal_weak", "ft_signal_none", "ft_settings_outage", "ft_settings_provider",
  "ft_settings_daily_fee", "ft_price_per_day", "ft_settings_reception", "ft_settings_hint_provider2",
  "ft_settings_network_outages", "ft_settings_hint_frequency", "ft_settings_outage_duration",
  "ft_duration_hours_short", "ft_settings_hint_outage_duration", "ft_settings_display_damage",
  "ft_settings_hint_display_damage2", "ft_settings_provider_selection", "ft_common_open_list",
  "ft_settings_hint_provider_select", "ft_common_open", "ft_common_info", "ft_common_version",
  "ft_common_author", "ft_settings_apps_loaded", "ft_settings_open_key", "ft_settings_scroll_help",
  "ft_settings_console_help", "ft_settings_reset_section", "ft_settings_all_settings",
  "ft_settings_default_values", "ft_settings_hint_reset_all", "ft_settings_reset_all",
  "ft_auto_tisonk",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
  ft_auto_tisonk: "the author's own name",
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "br:ft_battery_profile_normal": "the same word: Brazilian Portuguese says Normal",
  "br:ft_battery_rate_minutes": "a unit: Brazilian Portuguese writes minutes as min",
  "br:ft_common_normal": "the same word: Brazilian Portuguese says Normal",
  "cz:ft_battery_rate_minutes": "a unit: Czech writes minutes as min",
  "da:ft_battery_profile_normal": "the same word: Danish says Normal",
  "da:ft_battery_rate_minutes": "a unit: Danish writes minutes as min",
  "da:ft_common_version": "the same word: Danish says Version",
  "de:ft_auto_position": "the same word: German says Position",
  "de:ft_battery_profile_normal": "the same word: German says Normal",
  "de:ft_color_gold": "the same word: German says Gold",
  "de:ft_common_info": "the same word: German says Info",
  "de:ft_common_normal": "the same word: German says Normal",
  "de:ft_common_version": "the same word: German says Version",
  "de:ft_font_scale_normal": "the same word: German says Normal, and the de file keeps the 0.8x style for every size",
  "ea:ft_battery_profile_normal": "the same word: Spanish says Normal",
  "ea:ft_battery_rate_minutes": "a unit: Spanish writes minutes as min",
  "ea:ft_common_normal": "the same word: Spanish says Normal",
  "ea:ft_settings_general": "the same word: Spanish says General",
  "es:ft_battery_profile_normal": "the same word: Spanish says Normal",
  "es:ft_battery_rate_minutes": "a unit: Spanish writes minutes as min",
  "es:ft_common_normal": "the same word: Spanish says Normal",
  "es:ft_settings_general": "the same word: Spanish says General",
  "fc:ft_auto_position": "the same word: French says Position",
  "fc:ft_battery_profile_normal": "the same word: French says Normal",
  "fc:ft_battery_rate_minutes": "a unit: French writes minutes as min",
  "fc:ft_common_normal": "the same word: French says Normal",
  "fc:ft_common_rare": "the same word: French says Rare",
  "fc:ft_common_version": "the same word: French says Version",
  "fc:ft_settings_notifications": "the same word: French says Notifications",
  "fi:ft_battery_rate_minutes": "a unit: Finnish writes minutes as min",
  "fr:ft_auto_position": "the same word: French says Position",
  "fr:ft_battery_profile_normal": "the same word: French says Normal",
  "fr:ft_battery_rate_minutes": "a unit: French writes minutes as min",
  "fr:ft_common_normal": "the same word: French says Normal",
  "fr:ft_common_rare": "the same word: French says Rare",
  "fr:ft_common_version": "the same word: French says Version",
  "fr:ft_settings_notifications": "the same word: French says Notifications",
  "it:ft_battery_rate_minutes": "a unit: Italian writes minutes as min",
  "nl:ft_battery_rate_minutes": "a unit: Dutch writes minutes as min",
  "no:ft_battery_profile_normal": "the same word: Norwegian says Normal",
  "no:ft_battery_rate_minutes": "a unit: Norwegian writes minutes as min",
  "pl:ft_battery_rate_minutes": "a unit: Polish writes minutes as min",
  "pt:ft_battery_profile_normal": "the same word: Portuguese says Normal",
  "pt:ft_battery_rate_minutes": "a unit: Portuguese writes minutes as min",
  "pt:ft_common_normal": "the same word: Portuguese says Normal",
  "ro:ft_battery_profile_normal": "the same word: Romanian says Normal",
  "ro:ft_battery_rate_minutes": "a unit: Romanian writes minutes as min",
  "ro:ft_common_normal": "the same word: Romanian says Normal",
  "sv:ft_battery_profile_normal": "the same word: Swedish says Normal",
  "sv:ft_battery_rate_minutes": "a unit: Swedish writes minutes as min",
  "sv:ft_common_version": "the same word: Swedish says Version",
  "tr:ft_battery_profile_normal": "the same word: Turkish says Normal",
  "tr:ft_common_normal": "the same word: Turkish says Normal",
};
// Keys the Settings screen draws that another PR of the wave checks.
const OTHER_PR = {
  ft_ui_app_dashboard: "an app name in the start-app row: the home screen PR's key",
  ft_ui_app_store: "an app name in the start-app row: the home screen PR's key",
  ft_ui_app_weather: "an app name in the start-app row: the home screen PR's key",
  ft_ui_app_field_status: "an app name in the start-app row: the home screen PR's key",
  ft_ui_app_animals: "an app name in the start-app row: the home screen PR's key",
  ft_ui_app_workshop: "an app name in the start-app row: the home screen PR's key",
  ft_ui_app_excavator: "an app name in the start-app row: the home screen PR's key",
};
// [outer, inner]: the outer text names the inner key's text (case-insensitive).
const CONTAINS = [
  ["ft_settings_hint_frequency", "ft_common_off"],
  ["ft_settings_hint_frequency", "ft_common_rare"],
  ["ft_settings_hint_frequency", "ft_common_normal"],
  ["ft_settings_hint_frequency", "ft_common_frequent"],
];

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
const placeholders = (s) => (s.replace(/%%/g, "").match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).join(",");
const breaks = (s) => (s.match(/&#10;|\\n/g) || []).length;

const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length)).filter((l) => l !== "en");
if (locales.length !== 25) { console.log(`expected 25 non-English locale files, found ${locales.length}`); process.exit(1); }
const EN = entries(join(DIR, "translation_en.xml"));
const ALL = { en: EN };
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
  }
  for (const [outer, inner] of CONTAINS) {
    const o = (L.inside.get(outer) || [])[0], i = (L.inside.get(inner) || [])[0];
    if (o && i && !unesc(o).toLowerCase().includes(unesc(i).toLowerCase())) failures.push(`${loc}: ${outer} does not name ${inner}'s text ${JSON.stringify(unesc(i))}`);
  }
}
for (const [outer, inner] of CONTAINS) {
  const o = (EN.inside.get(outer) || [])[0], i = (EN.inside.get(inner) || [])[0];
  if (o && i && !unesc(o).toLowerCase().includes(unesc(i).toLowerCase())) failures.push(`en: ${outer} does not name ${inner}'s text ${JSON.stringify(unesc(i))}`);
}

// ---- Draw-site rows, over the real source.
{
  const { createRequire } = await import("node:module");
  const req = createRequire(join(ROOT, "tools", "test", "package.json"));
  const luaparse = req("luaparse");
  const fengari = req("fengari");
  const { lua, lauxlib, lualib, to_luastring } = fengari;
  const KEYSET = new Set(KEYS);
  const NO_KEY = {};
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
  const parse = (rel) => {
    const text = readFileSync(join(ROOT, rel), "latin1");
    return { text, ast: luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true }) };
  };
  const walk = (n, visit) => {
    if (!n || typeof n !== "object") return;
    if (Array.isArray(n)) { for (const c of n) walk(c, visit); return; }
    visit(n);
    for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") walk(n[k], visit);
  };
  const callName = (n) => (n.base.type === "Identifier" ? n.base.name : n.base.type === "MemberExpression" ? n.base.identifier.name : null);
  const KEYFN = new Set(["ftSafeText", "ftSafeFormat", "ftUiText", "ftUiFormat"]);
  const DRAWFN = new Set(["section", "infoRow", "actionRow", "appText", "button", "drawAppHeader", "drawSection"]);
  const drawnKey = (rel, line, key) => {
    if (!KEYSET.has(key) && !OTHER_PR[key]) failures.push(`S1 ${rel}:${line}: ${key} is drawn on the Settings screen, and this bar does not check it: it can read English in every language`);
    if (!EN.inside.has(key)) failures.push(`S1 ${rel}:${line}: ${key} is drawn, and translation_en.xml does not carry it`);
  };
  let keySites = 0, litSites = 0;
  const APP = "src/apps/SettingsApp.lua";
  const app = parse(APP);
  const ROWCUT = [42, 44, 66, 24];
  const cutKeys = new Map();
  const keyOf = (a) => {
    if (a && a.type === "CallExpression" && (callName(a) === "ftSafeText")) return [fold(a.arguments[0])];
    if (a && a.type === "CallExpression" && callName(a) === "ftOnOff") return ["ft_common_on", "ft_common_off"];
    return [];
  };
  walk(app.ast.body, (n) => {
    if (n.type !== "CallExpression") return;
    const name = callName(n);
    if (KEYFN.has(name)) {
      const k = fold(n.arguments[0]);
      if (k !== null) { keySites++; drawnKey(APP, n.loc.start.line, k); }
    }
    if (DRAWFN.has(name)) {
      for (const a of n.arguments) {
        const v = fold(a);
        if (v === null || v === "" || /^ft_[a-z0-9_]+$/.test(v) || /^[\s\d%.:,+\-/()'x*]*$/.test(v) || NO_KEY[v]) continue;
        litSites++;
        const key = AUTO.get(v);
        if (!key) failures.push(`S2 ${APP}:${n.loc.start.line}: ${JSON.stringify(v)} has no FT.AUTO_L10N entry: the lookup misses and every language reads English`);
        else if (!KEYSET.has(key) && !OTHER_PR[key]) failures.push(`S2 ${APP}:${n.loc.start.line}: ${JSON.stringify(v)} maps to ${key}, which this bar does not check`);
      }
    }
    if (name === "actionRow") {
      n.arguments.slice(0, 4).forEach((a, i) => { for (const k of keyOf(a)) if (k) { const c = cutKeys.get(k); cutKeys.set(k, c === undefined ? ROWCUT[i] : Math.min(c, ROWCUT[i])); } });
    }
  });
  // The two frequency getters the Settings screen calls (SettingsApp.lua, the network rows).
  const UI = "src/FarmTabletUI.lua";
  const ui = parse(UI);
  const GETTERS = ["_getSignalOutageFrequencyLabel", "_getTabletRepairFrequencyLabel"];
  const found = new Set();
  walk(ui.ast.body, (n) => {
    if (n.type !== "FunctionDeclaration" || !n.identifier || n.identifier.type !== "MemberExpression") return;
    const fname = n.identifier.identifier.name;
    if (!GETTERS.includes(fname)) return;
    found.add(fname);
    walk(n.body, (c) => {
      if (c.type === "CallExpression" && KEYFN.has(callName(c))) {
        const k = fold(c.arguments[0]);
        if (k !== null) { keySites++; drawnKey(UI, c.loc.start.line, k); const cut = cutKeys.get(k); cutKeys.set(k, cut === undefined ? 44 : Math.min(cut, 44)); }
      }
    });
  });
  for (const g of GETTERS) {
    if (!found.has(g)) failures.push(`S1 ${UI}: FarmTabletUI:${g} not found, so its drawn keys went unchecked`);
    if (!app.text.includes(g)) failures.push(`S1 ${APP}: no longer calls ${g}; update this bar's GETTERS`);
  }
  // T1: no runtime language table, no language branch.
  walk(app.ast.body, (n) => {
    if (n.type === "TableKeyString" && /^ft_/.test(n.key.name) && n.value.type === "StringLiteral") {
      failures.push(`T1 ${APP}:${n.loc.start.line}: a runtime text table field ${n.key.name}: the locale file must win (row 136)`);
    }
    if ((n.type === "Identifier" && (n.name === "g_languageShort")) || (n.type === "MemberExpression" && ["languageShort", "currentLanguage"].includes(n.identifier.name))) {
      failures.push(`T1 ${APP}:${n.loc.start.line}: reads the game language (${n.type === "Identifier" ? n.name : n.identifier.name}): a language branch in front of the locale file`);
    }
  });
  // L1: the actionRow cuts, in characters.
  let cutChecks = 0;
  for (const [key, cut] of cutKeys) {
    for (const loc of ["en", ...locales]) {
      const v = ((ALL[loc] && ALL[loc].inside.get(key)) || [])[0];
      if (v === undefined) continue;
      cutChecks++;
      const n = Array.from(unesc(v)).length;
      if (n > cut) failures.push(`L1 ${loc}: ${key} is ${n} characters, over its row's cut of ${cut}: short() ends it mid-word`);
    }
  }
  console.log(`  draw sites checked: ${keySites} key calls, ${litSites} drawn literals; ${cutKeys.size} keys under a row cut (${cutChecks} texts measured)`);
}

const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-settings: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-settings: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names`);
