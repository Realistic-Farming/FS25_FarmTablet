// l10n-field-status-check.mjs - MAINTENANCE row 105's text bar for the Field Status app (FieldStatusApp.lua)
// (a PR of the tablet translation wave; the pattern of l10n-fieldjobs-check.mjs).
//
// Every key below is drawn by the Field Status app: through FieldStatusApp.lua's ftText / ftFormat
// (the header's field count, the empty-list texts, the three summary badges, the column headers and
// the help page), through DataProvider.lua's _ftDpText for the rows it builds for this app (the
// eight growth states and the empty and unknown crop names, keys ft_field_*), and through the
// renderer's FT.l10nAuto for the HA column header (ft_auto_ha_3). The app's name is the home
// screen PR's key (OTHER_PR below). Crop names otherwise come from the game's own fill-type l10n.
// Control-name rows: the summary help names the three badges by their own text, and the columns
// help (title and body) names the CROP, HA and STATE headers by theirs.
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %.1f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80).
//
// Draw-site rows (below the text rows), over the real source files in SOURCES:
//   S1  every key a SOURCES file passes as a literal to one of its text functions (KEYFN) is one of
//       KEYS or named in OTHER_PR, and translation_en.xml carries it;
//   S2  every literal a SOURCES file hands straight to a drawing call (DRAWFN) or holds in a drawn
//       table field resolves through the real FT.AUTO_L10N (Constants.lua run in fengari) to one of
//       KEYS or OTHER_PR, unless NO_KEY names it with its reason; none holds an em dash.
//
// Usage:  node tools/test/l10n-field-status-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  "ft_fields_help_summary_title", "ft_fields_help_summary_body", "ft_fields_help_columns_title",
  "ft_fields_help_columns_body", "ft_fields_help_state_colors_title",
  "ft_fields_help_state_colors_body", "ft_fields_help_scrolling_title",
  "ft_fields_help_scrolling_body", "ft_fields_count", "ft_fields_none", "ft_fields_none_hint",
  "ft_fields_badge_ready", "ft_fields_badge_grow", "ft_fields_badge_empty", "ft_fields_col_crop",
  "ft_fields_col_state", "ft_field_state_empty", "ft_field_state_harvest", "ft_field_state_harvested",
  "ft_field_state_withered", "ft_field_state_seeded", "ft_field_state_germinated",
  "ft_field_state_ripening", "ft_field_state_growing", "ft_field_crop_empty", "ft_field_crop_unknown",
  "ft_auto_ha_3",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {

};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "br:ft_auto_ha_3": "the hectare unit: Brazilian Portuguese writes the column as HA",
  "cz:ft_auto_ha_3": "the hectare unit: Czech writes the column as HA",
  "da:ft_auto_ha_3": "the hectare unit: Danish writes the column as HA",
  "de:ft_auto_ha_3": "the hectare unit: German writes the column as HA",
  "ea:ft_auto_ha_3": "the hectare unit: Spanish writes the column as HA",
  "es:ft_auto_ha_3": "the hectare unit: Spanish writes the column as HA",
  "fc:ft_auto_ha_3": "the hectare unit: French writes the column as HA",
  "fi:ft_auto_ha_3": "the hectare unit: Finnish writes the column as HA",
  "fr:ft_auto_ha_3": "the hectare unit: French writes the column as HA",
  "hu:ft_auto_ha_3": "the hectare unit: Hungarian writes the column as HA",
  "id:ft_auto_ha_3": "the hectare unit: Indonesian writes the column as HA",
  "it:ft_auto_ha_3": "the hectare unit: Italian writes the column as HA",
  "nl:ft_auto_ha_3": "the hectare unit: Dutch writes the column as HA",
  "no:ft_auto_ha_3": "the hectare unit: Norwegian writes the column as HA",
  "pl:ft_auto_ha_3": "the hectare unit: Polish writes the column as HA",
  "pt:ft_auto_ha_3": "the hectare unit: Portuguese writes the column as HA",
  "ro:ft_auto_ha_3": "the hectare unit: Romanian writes the column as HA",
  "sv:ft_auto_ha_3": "the hectare unit: Swedish writes the column as HA",
  "tr:ft_auto_ha_3": "the hectare unit: Turkish writes the column as HA",
  "vi:ft_auto_ha_3": "the hectare unit: Vietnamese writes the column as HA",
};
// Keys this app draws that another PR of the wave checks, with the PR.
const OTHER_PR = {
  "ft_ui_app_field_status": "the app name: the home screen PR's key",
};
// Drawn literals with no key, each with its reason.
const NO_KEY = {

};
// [outer, inner]: the outer text names the inner key's text (case-insensitive).
const CONTAINS = [
  ["ft_fields_help_summary_body", "ft_fields_badge_ready"],
  ["ft_fields_help_summary_body", "ft_fields_badge_grow"],
  ["ft_fields_help_summary_body", "ft_fields_badge_empty"],
  ["ft_fields_help_columns_title", "ft_fields_col_crop"],
  ["ft_fields_help_columns_title", "ft_auto_ha_3"],
  ["ft_fields_help_columns_title", "ft_fields_col_state"],
  ["ft_fields_help_columns_body", "ft_fields_col_crop"],
  ["ft_fields_help_columns_body", "ft_auto_ha_3"],
  ["ft_fields_help_columns_body", "ft_fields_col_state"],
];
// The source files the draw-site rows read, and in each the text functions whose first argument is
// a key. keyPrefix limits a shared file to this app's keys.
const SOURCES = [
  {"file": "src/apps/FieldStatusApp.lua", "keyFns": ["ftText", "ftFormat"], "literals": true},
  {"file": "src/utils/DataProvider.lua", "keyFns": ["_ftDpText"], "keyPrefix": "ft_field_"},
];
const DRAWFN = new Set(["appText", "text", "drawRow", "drawSection", "button", "drawButton", "drawButtonPair",
  "drawAppHeader", "appHeaderText", "sectionHeader", "row", "badge", "l10nAuto", "infoRow", "actionRow", "section"]);
const FIELDS = new Set(["title", "label", "section"]);

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
  const seen = new Set();
  for (const src of SOURCES) {
    const text = readFileSync(join(ROOT, src.file), "latin1");
    const ast = luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true });
    const keyFn = new Set(src.keyFns);
    const lit = (line, v, helpLine) => {
      if (v === "" || /^ft_[a-z0-9_]+$/.test(v) || /^[\s\d%.:,+\-/()'x*#]*$/.test(v)) return;
      const id = `${src.file}|${v}`;
      if (seen.has(id)) return;
      seen.add(id);
      litSites++;
      if (v.includes(EMD)) failures.push(`S2 ${src.file}:${line}: the drawn literal ${JSON.stringify(v)} holds an em dash`);
      if (NO_KEY[v]) return;
      const key = AUTO.get(v) || (helpLine ? AUTO.get(v + "\n") : undefined);
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
            if (!KEYSET.has(k) && !OTHER_PR[k]) failures.push(`S1 ${src.file}:${n.loc.start.line}: ${k} is drawn, and this bar does not check it: it can read English in every language`);
            if (!EN.inside.has(k)) failures.push(`S1 ${src.file}:${n.loc.start.line}: ${k} is drawn, and translation_en.xml does not carry it`);
          }
        } else if (src.literals && DRAWFN.has(name)) {
          for (const a of n.arguments) {
            const v = fold(a); if (v !== null) lit(n.loc.start.line, v, false);
            if (a && a.type === "LogicalExpression") for (const s of [a.left, a.right]) { const w = fold(s); if (w !== null) lit(n.loc.start.line, w, false); }
          }
        }
        if (src.literals && name === "drawHelpPage") { const v = fold(n.arguments[2]); if (v !== null) lit(n.loc.start.line, v, false); }
      }
      if (src.literals && n.type === "TableKeyString" && FIELDS.has(n.key.name)) { const v = fold(n.value); if (v !== null) lit(n.loc.start.line, v, false); }
      if (src.literals && n.type === "TableKeyString" && n.key.name === "body") { const v = fold(n.value); if (v !== null) for (const line of v.split("\n")) lit(n.loc.start.line, line, true); }
      for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") walk(n[k]);
    })(ast.body);
  }
  console.log(`  draw sites checked: ${keySites} key calls, ${litSites} drawn literals in ${SOURCES.map((s) => s.file).join(", ")}`);
}

const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures.slice(0, 60)) console.log("  FAIL " + f);
  if (failures.length > 60) console.log(`  ... and ${failures.length - 60} more`);
  console.log(`l10n-field-status: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-field-status: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names`);
