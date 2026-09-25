// l10n-lookup-check.mjs - MAINTENANCE row 136's bar: the locale file is the only source of a
// translation.
//
// Loads the REAL src/core/Constants.lua in fengari, once per language, with an I18N model
// (hasText / getText) built from the REAL translations/translation_<lang>.xml. Like the game
// (mods.lua:798), only <text> elements inside <texts> are read, and only the file of the
// player's language: a key that file lacks is a key the game does not have.
//
// Rows, for de and ru (the two languages the old runtime layers rewrote) and en:
//   R1  every FT.AUTO_L10N literal whose key the file carries: FT.l10nAuto(literal) is the
//       file's text.
//   R2  every key the file carries: FT.l10n(key, <English>) is the file's text.
//   R3  a key the file lacks: FT.l10n returns the English fallback unchanged, even one full of
//       words the old layers rewrote (Open, Offers, now, Day, Off, pen).
//   R4  "Open Offers", "time unknown" and "Today" come back as the file's text or the
//       unchanged English, never rewritten.
//   R5  every help-page line (a map literal ending in one "\n", drawn by drawHelpPage without
//       it) resolves: FT.l10nAuto(line) is the file's text without its trailing "\n".
//   R6  the RSF-141 Field Jobs keys (DESIGN-CHECK row 101; the list in l10n-fieldjobs-check.mjs)
//       resolve to the file's text in every language checked.
//   R7  the source defines exactly one FT.l10n and one FT.l10nAuto.
//
// Usage:  node tools/test/l10n-lookup-check.mjs [lang ...]     (default: de ru en)
// Exit:   0 clean, 1 any failure.
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import fengari from "fengari";

const { lua, lauxlib, lualib, to_luastring } = fengari;
const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..", "..");
const CONSTANTS = join(ROOT, "src", "core", "Constants.lua");

function decodeXml(s) {
  return s.replace(/&(#x[0-9a-fA-F]+|#\d+|amp|lt|gt|quot|apos);/g, (all, e) => {
    if (e === "amp") return "&";
    if (e === "lt") return "<";
    if (e === "gt") return ">";
    if (e === "quot") return '"';
    if (e === "apos") return "'";
    if (e.startsWith("#x")) return String.fromCodePoint(parseInt(e.slice(2), 16));
    return String.fromCodePoint(parseInt(e.slice(1), 10));
  });
}
function readLocale(lang) {
  const whole = readFileSync(join(ROOT, "translations", `translation_${lang}.xml`), "utf8");
  const s = whole.indexOf("<texts>"), e = whole.indexOf("</texts>");
  const body = s >= 0 && e > s ? whole.slice(s, e) : "";
  const out = new Map();
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  let m;
  while ((m = re.exec(body)) !== null) if (!out.has(m[1])) out.set(m[1], decodeXml(m[2]).replace(/\r\n/g, "\n"));
  return out;
}

// One fresh Lua state per language: the model I18N, then the real Constants.lua.
function makeState(lang, texts) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  lua.lua_newtable(L);
  for (const [k, v] of texts) {
    lua.lua_pushstring(L, to_luastring(k));
    lua.lua_pushstring(L, to_luastring(v));
    lua.lua_settable(L, -3);
  }
  lua.lua_setglobal(L, to_luastring("__TEXTS"));
  const prelude = `
    g_languageShort = ${JSON.stringify(lang)}
    g_i18n = {
      hasText = function(self, k) return __TEXTS[k] ~= nil end,
      getText = function(self, k) return __TEXTS[k] or ("Missing '" .. tostring(k) .. "' in l10n") end,
    }
    RenderText = { ALIGN_LEFT = 0, ALIGN_CENTER = 1, ALIGN_RIGHT = 2 }`;
  for (const [code, name] of [[to_luastring(prelude), "=model"], [readFileSync(CONSTANTS), "@Constants.lua"]]) {
    if (lauxlib.luaL_loadbuffer(L, code, null, to_luastring(name)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
      throw new Error(`${lang}: ${name} did not load: ${lua.lua_tojsstring(L, -1)}`);
    }
  }
  const call = (fn, args) => {
    lua.lua_getglobal(L, to_luastring("FT"));
    lua.lua_getfield(L, -1, to_luastring(fn));
    for (const a of args) lua.lua_pushstring(L, to_luastring(a));
    if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 2); return `<error: ${e}>`; }
    const r = lua.lua_isstring(L, -1) ? lua.lua_tojsstring(L, -1) : "<not a string>";
    lua.lua_pop(L, 2);
    return r;
  };
  const autoMap = () => {
    const out = new Map();
    lua.lua_getglobal(L, to_luastring("FT"));
    lua.lua_getfield(L, -1, to_luastring("AUTO_L10N"));
    lua.lua_pushnil(L);
    while (lua.lua_next(L, -2) !== 0) { out.set(lua.lua_tojsstring(L, -2), lua.lua_tojsstring(L, -1)); lua.lua_pop(L, 1); }
    lua.lua_pop(L, 2);
    return out;
  };
  return { auto: (raw) => call("l10nAuto", [raw]), l10n: (k, f) => call("l10n", [k, f]), autoMap };
}

// The Field Jobs keys, read from the RSF-141 bar itself so the two lists cannot drift.
function fieldJobsKeys() {
  const src = readFileSync(join(HERE, "l10n-fieldjobs-check.mjs"), "utf8");
  const m = src.match(/const KEYS = \[([\s\S]*?)\];/);
  return m ? [...m[1].matchAll(/"(ft_[a-z0-9_]+)"/g)].map((x) => x[1]) : [];
}

const langs = process.argv.slice(2).length ? process.argv.slice(2) : ["de", "ru", "en"];
const en = readLocale("en");
const fj = fieldJobsKeys();
const failures = [];
const counts = {};
const fail = (row, lang, msg) => { failures.push(`${row} ${lang}: ${msg}`); counts[`${row} ${lang}`] = (counts[`${row} ${lang}`] || 0) + 1; };
const show = (s) => JSON.stringify(s).slice(0, 90);
const stats = [];

// R7: exactly one definition of each
{
  const src = readFileSync(CONSTANTS, "utf8");
  const n1 = (src.match(/^\s*function FT\.l10n\s*\(/gm) || []).length;
  const n2 = (src.match(/^\s*function FT\.l10nAuto\s*\(/gm) || []).length;
  if (n1 !== 1) fail("R7", "src", `FT.l10n is defined ${n1} times, expected once`);
  if (n2 !== 1) fail("R7", "src", `FT.l10nAuto is defined ${n2} times, expected once`);
}
if (fj.length < 50) fail("R6", "setup", `read only ${fj.length} Field Jobs keys from l10n-fieldjobs-check.mjs`);

for (const lang of langs) {
  const file = readLocale(lang);
  const st = makeState(lang, file);
  const AUTO = st.autoMap();
  let r1 = 0, r2 = 0, r5 = 0, r6 = 0;
  // R1
  for (const [raw, key] of AUTO) {
    if (!file.has(key)) continue;
    r1++;
    const got = st.auto(raw);
    if (got !== file.get(key)) fail("R1", lang, `FT.l10nAuto(${show(raw)}) = ${show(got)}, the file says ${show(file.get(key))}`);
  }
  // R2
  for (const [key, text] of file) {
    if (text === "") continue;
    r2++;
    const got = st.l10n(key, en.get(key) || key);
    if (got !== text) fail("R2", lang, `FT.l10n(${key}) = ${show(got)}, the file says ${show(text)}`);
  }
  // R3
  const absent = "ft_row136_key_no_file_has";
  const fallback = "Open Offers now: Day 3, pen Off, time unknown";
  const got3 = st.l10n(absent, fallback);
  if (got3 !== fallback) fail("R3", lang, `FT.l10n(<absent key>, ${show(fallback)}) = ${show(got3)}`);
  const got3b = st.auto(fallback);
  if (got3b !== fallback) fail("R3", lang, `FT.l10nAuto(${show(fallback)}) = ${show(got3b)}`);
  // R4
  for (const raw of ["Open Offers", "time unknown", "Today"]) {
    const key = AUTO.get(raw);
    const want = key && file.has(key) ? file.get(key) : raw;
    const got = st.auto(raw);
    if (got !== want) fail("R4", lang, `FT.l10nAuto(${show(raw)}) = ${show(got)}, want ${show(want)}`);
  }
  // R5
  for (const [raw, key] of AUTO) {
    if (!raw.endsWith("\n") || raw.slice(0, -1).includes("\n") || AUTO.has(raw.slice(0, -1)) || !file.has(key)) continue;
    r5++;
    const want = file.get(key).replace(/\n$/, "");
    const got = st.auto(raw.slice(0, -1));
    if (got !== want) fail("R5", lang, `help line ${show(raw.slice(0, -1))} = ${show(got)}, the file says ${show(want)}`);
  }
  // R6
  const inv = new Map();
  for (const [raw, key] of AUTO) if (!inv.has(key)) inv.set(key, raw);
  for (const key of fj) {
    if (!file.has(key)) { fail("R6", lang, `${key} is not in the file`); continue; }
    r6++;
    const got = st.l10n(key, en.get(key) || key);
    if (got !== file.get(key)) fail("R6", lang, `FT.l10n(${key}) = ${show(got)}, the file says ${show(file.get(key))}`);
    if (inv.has(key)) {
      const raw = inv.get(key);
      const g2 = st.auto(raw);
      if (g2 !== file.get(key)) fail("R6", lang, `FT.l10nAuto(${show(raw)}) = ${show(g2)}, the file says ${show(file.get(key))}`);
    }
  }
  stats.push(`${lang}: R1 ${r1} literals, R2 ${r2} keys, R5 ${r5} help lines, R6 ${r6} Field Jobs keys`);
}

for (const s of stats) console.log("  " + s);
if (failures.length) {
  for (const [k, n] of Object.entries(counts)) console.log(`  FAIL ${k}: ${n}`);
  for (const f of failures.slice(0, 25)) console.log("    " + f);
  console.log(`l10n-lookup: ${failures.length} failure(s)`);
  process.exit(1);
}
console.log(`l10n-lookup: PASS - ${langs.join(", ")}: the locale file's text for every key it carries, the English unchanged for a key it lacks, help lines resolved, Field Jobs keys resolved`);
