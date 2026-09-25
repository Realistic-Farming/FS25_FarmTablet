// utf8-cut-check.mjs - MAINTENANCE row 138's bar: drawn text is cut in characters, never in bytes.
//
// Runs the REAL src/core/Constants.lua and src/utils/Renderer.lua in fengari and feeds them every
// text value of the 26 REAL translation files (only <text> inside <texts>, as the game reads them).
//   C1  FT.utf8Sub(value, n) for every n from 1 to 30, and for the value's length and length + 1,
//       is a prefix of the value
//       that ends on a character boundary and holds exactly min(n, length) characters, and
//       FT.utf8Len(value) is the value's character count.
//   C2  FT_Renderer.truncate(value, n) for the budgets the apps pass (8 to 40) is valid UTF-8 and
//       at most n characters (the ellipsis included).
//   C3  FT.utf8Cut(name, n, 4) for every app name and grid short name (ft_ui_app_*, ft_ui_short_*)
//       at the home grid's three label sizes (13, 11, 9) is valid UTF-8, at most n characters,
//       and a prefix of the name.
//   C4  the sweep: every byte-based cut (":sub(1," or "string.sub(x, 1,") left in the swept files
//       (SWEEP below) is one of the named uses that never cuts drawn text.
//   C5  the real call sites, run: HomeScreen.lua's appLabel and SettingsApp.lua's short() are
//       lifted out of the real files (luaparse ranges) and run in fengari. appLabel, with a
//       g_i18n model over each locale file, gets every app name at the grid's three label sizes;
//       short() gets every value at the Settings rows' cuts (24, 42, 44, 66). Each result must be
//       valid UTF-8, at most the budget in characters, and (appLabel) a prefix of the name.
//       The named case: Russian "Мастерская" (ft_ui_app_workshop, 20 bytes) at 13.
//
// Usage:  node tools/test/utf8-cut-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";
import fengari from "fengari";
import luaparse from "luaparse";

const { lua, lauxlib, lualib, to_luastring } = fengari;
const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

// The files C4 sweeps: the four named sites of row 138.
const SWEEP = ["src/ui/HomeScreen.lua", "src/utils/Renderer.lua", "src/apps/AppStoreApp.lua", "src/apps/SettingsApp.lua"];
// Byte-based cuts that do not cut drawn text, each with its reason (C4).
const ALLOWED_BYTE_CUTS = {
  "src/apps/AkitaTabletIntegrationsApp.lua|lang:sub(1,2)": "a language code, ASCII",
  "src/apps/SettingsApp.lua|lang:sub(1,2)": "a language code, ASCII",
  "src/apps/FinancialCockpitApp.lua|label:sub(1, 1):upper() .. label:sub(2)": "rejoins the two halves, so no byte is lost",
  "src/apps/RandomWorldEventsApp.lua|displayName:sub(1, 1):upper() .. displayName:sub(2)": "rejoins the two halves, so no byte is lost",
  "src/ui/HomeScreen.lua|string.sub(app.id, 1, 2)": "an app id, ASCII (the missing-icon monogram)",
};

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
function readLocale(file) {
  const whole = readFileSync(file, "utf8");
  const s = whole.indexOf("<texts>"), e = whole.indexOf("</texts>");
  const body = s >= 0 && e > s ? whole.slice(s, e) : "";
  const out = new Map();
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  let m;
  while ((m = re.exec(body)) !== null) if (!out.has(m[1])) out.set(m[1], decodeXml(m[2]));
  return out;
}

// One Lua state with the real Constants.lua and Renderer.lua; values go in and out as bytes.
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const load = (buf, name) => {
  if (lauxlib.luaL_loadbuffer(L, buf, null, to_luastring(name)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
    console.log(`utf8-cut: ${name} did not load: ${lua.lua_tojsstring(L, -1)}`); process.exit(1);
  }
};
load(to_luastring("Class = function(t) return { __index = t } end"), "=model");
load(readFileSync(join(ROOT, "src", "core", "Constants.lua")), "@Constants.lua");
load(readFileSync(join(ROOT, "src", "utils", "Renderer.lua")), "@Renderer.lua");
function call(path, args) {
  // path: ["FT", "utf8Sub"] or ["FT_Renderer", "truncate"]; returns the result's raw bytes
  lua.lua_getglobal(L, to_luastring(path[0]));
  lua.lua_getfield(L, -1, to_luastring(path[1]));
  for (const a of args) {
    if (typeof a === "number") lua.lua_pushnumber(L, a);
    else lua.lua_pushstring(L, Buffer.from(a, "utf8"));
  }
  if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 2); throw new Error(e); }
  const r = lua.lua_type(L, -1) === lua.LUA_TNUMBER ? lua.lua_tonumber(L, -1) : Buffer.from(lua.lua_tostring(L, -1));
  lua.lua_pop(L, 2);
  return r;
}
const validUtf8 = (buf) => { try { new TextDecoder("utf-8", { fatal: true }).decode(buf); return true; } catch { return false; } };
const chars = (s) => [...s].length;

const failures = [];
const defined = (name) => { lua.lua_getglobal(L, to_luastring("FT")); lua.lua_getfield(L, -1, to_luastring(name)); const ok = lua.lua_isfunction(L, -1); lua.lua_pop(L, 2); return ok; };
const helpers = ["utf8Len", "utf8Sub", "utf8Cut"].every(defined);
if (!helpers) failures.push("C0 FT.utf8Len, FT.utf8Sub and FT.utf8Cut are not all defined in Constants.lua");
const fail = (row, msg) => { if (failures.filter((f) => f.startsWith(row)).length < 12) failures.push(`${row} ${msg}`); else failures.push(row); };
const dir = join(ROOT, "translations");
const files = readdirSync(dir).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
let c1 = 0, c2 = 0, c3 = 0, multibyte = 0;
for (const f of files) {
  const loc = f.slice(12, 14);
  for (const [key, value] of readLocale(join(dir, f))) {
    const n = chars(value);
    const mb = Buffer.byteLength(value) !== value.length;
    if (mb) multibyte++;
    // C1
    if (!helpers) { c1 = c1; } else {
    const len = call(["FT", "utf8Len"], [value]);
    if (len !== n) fail("C1", `${loc} ${key}: FT.utf8Len says ${len}, the value has ${n} characters`);
    // Every cut from 1 to 30 on multi-byte text; on plain ASCII text the edges are enough.
    const ks = mb ? new Set([...Array(Math.min(n + 1, 30)).keys()].map((i) => i + 1).concat([n, n + 1].filter((x) => x > 0)))
                  : new Set([1, 2, n - 1, n, n + 1].filter((x) => x > 0));
    for (const k of ks) {
      const got = call(["FT", "utf8Sub"], [value, k]);
      c1++;
      const want = [...value].slice(0, k).join("");
      if (!got.equals(Buffer.from(want, "utf8"))) fail("C1", `${loc} ${key}: FT.utf8Sub(v, ${k}) is not its first ${Math.min(k, n)} characters${validUtf8(got) ? "" : " (cut inside a character)"}`);
    }
    }
    // C2
    for (const budget of (mb ? [8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40] : [8, 20, 40])) {
      const got = call(["FT_Renderer", "truncate"], [value, budget]);
      c2++;
      if (!validUtf8(got)) { fail("C2", `${loc} ${key}: FT_Renderer.truncate(v, ${budget}) cuts inside a character`); continue; }
      if (chars(got.toString("utf8")) > budget) fail("C2", `${loc} ${key}: FT_Renderer.truncate(v, ${budget}) keeps ${chars(got.toString("utf8"))} characters`);
    }
    // C3
    if (helpers && /^ft_ui_(app|short)_/.test(key)) {
      for (const budget of [13, 11, 9]) {
        const got = call(["FT", "utf8Cut"], [value, budget, 4]);
        c3++;
        if (!validUtf8(got)) { fail("C3", `${loc} ${key}: FT.utf8Cut(v, ${budget}) cuts inside a character`); continue; }
        const s = got.toString("utf8");
        if (chars(s) > budget) fail("C3", `${loc} ${key}: FT.utf8Cut(v, ${budget}) keeps ${chars(s)} characters`);
        if (!value.startsWith(s)) fail("C3", `${loc} ${key}: FT.utf8Cut(v, ${budget}) is not a prefix of the name`);
      }
    }
  }
}
// C5: the real call sites, lifted out of their files and run.
let c5 = 0;
{
  const lift = (rel, names) => {
    const text = readFileSync(join(ROOT, rel), "latin1");
    const ast = luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", ranges: true });
    const parts = [];
    for (const n of ast.body) {
      const name = n.type === "FunctionDeclaration" && n.isLocal && n.identifier ? n.identifier.name
        : n.type === "LocalStatement" && n.variables.length === 1 ? n.variables[0].name : null;
      if (name && names.includes(name)) parts.push(text.slice(n.range[0], n.range[1]));
    }
    if (parts.length !== names.length) { failures.push(`C5 ${rel}: expected ${names.join(", ")} at the top level, found ${parts.length}`); return false; }
    load(Buffer.from(parts.join("\n") + `\nC5_FN = ${names[names.length - 1]}`, "latin1"), `@${rel}`);
    return true;
  };
  const run = (args) => {
    lua.lua_getglobal(L, to_luastring("C5_FN"));
    for (const a of args) {
      if (typeof a === "number") lua.lua_pushnumber(L, a);
      else if (typeof a === "string") lua.lua_pushstring(L, Buffer.from(a, "utf8"));
      else { lua.lua_createtable(L, 0, 2); for (const [k, v] of Object.entries(a)) { lua.lua_pushstring(L, to_luastring(v)); lua.lua_setfield(L, -2, to_luastring(k)); } }
    }
    if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); throw new Error(e); }
    const r = Buffer.from(lua.lua_tostring(L, -1));
    lua.lua_pop(L, 1);
    return r;
  };
  load(to_luastring("C5_L10N = {}\ng_i18n = { hasText = function(self, k) return C5_L10N[k] ~= nil end, getText = function(self, k) return C5_L10N[k] end }"), "=i18n");
  const setText = (k, v) => { lua.lua_getglobal(L, to_luastring("C5_L10N")); if (v === null) lua.lua_pushnil(L); else lua.lua_pushstring(L, Buffer.from(v, "utf8")); lua.lua_setfield(L, -2, to_luastring(k)); lua.lua_pop(L, 1); };
  const check = (row, what, got, budget, whole) => {
    c5++;
    if (!validUtf8(got)) { fail("C5", `${what} at ${budget}: cuts inside a character`); return; }
    const s = got.toString("utf8");
    if (chars(s) > budget) fail("C5", `${what} at ${budget}: keeps ${chars(s)} characters`);
    if (whole !== null && !whole.startsWith(s)) fail("C5", `${what} at ${budget}: is not a prefix of the name`);
  };
  if (lift("src/ui/HomeScreen.lua", ["SHORT_NAMES", "appLabel"])) {
    for (const f of files) {
      const loc = f.slice(12, 14);
      const texts = readLocale(join(dir, f));
      const names = [...texts].filter(([k]) => /^ft_ui_app_/.test(k));
      for (const [k, v] of names) setText(k, v);
      for (const [k, v] of names) {
        for (const budget of [13, 11, 9]) {
          let got;
          try { got = run([{ id: "c5_" + k, name: k }, budget]); } catch (e) { fail("C5", `${loc} ${k}: appLabel raised ${e.message}`); continue; }
          check("C5", `${loc} ${k}: appLabel`, got, budget, v);
        }
      }
      for (const [k] of names) setText(k, null);
    }
    const ru = readLocale(join(dir, "translation_ru.xml")).get("ft_ui_app_workshop");
    if (ru !== "\u041c\u0430\u0441\u0442\u0435\u0440\u0441\u043a\u0430\u044f") fail("C5", `ru ft_ui_app_workshop is ${JSON.stringify(ru)}, not the named case; update the row`);
    // The named case, on its own line whatever else fails: the Russian Workshop name at the grid's 13.
    setText("ft_ui_app_workshop", ru);
    const named = run([{ id: "c5_named", name: "ft_ui_app_workshop" }, 13]);
    setText("ft_ui_app_workshop", null);
    const namedOk = validUtf8(named) && named.toString("utf8") === ru;
    if (!namedOk) failures.unshift(`C5 named case: ru ft_ui_app_workshop "${ru}" (${Buffer.byteLength(ru)} bytes) at the grid's 13 comes back as ${named.length} bytes${validUtf8(named) ? "" : ", cut inside a character"}`);
    else console.log(`  C5 named case: ru "${ru}" at the grid's 13 comes back whole (${chars(ru)} characters, ${Buffer.byteLength(ru)} bytes)`);
  }
  if (lift("src/apps/SettingsApp.lua", ["short"])) {
    for (const f of files) {
      const loc = f.slice(12, 14);
      for (const [key, value] of readLocale(join(dir, f))) {
        if (chars(value) <= 24) continue;
        for (const budget of [24, 42, 44, 66]) {
          let got;
          try { got = run([value, budget]); } catch (e) { fail("C5", `${loc} ${key}: short() raised ${e.message}`); continue; }
          check("C5", `${loc} ${key}: SettingsApp short()`, got, budget, null);
        }
      }
    }
  }
}
// C4: the sweep
let c4 = 0;
const walk = (d) => readdirSync(d).flatMap((f) => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p) : [p]; });
for (const p of walk(join(ROOT, "src")).filter((p) => p.endsWith(".lua") && !p.endsWith("Constants.lua"))) {
  const rel = relative(ROOT, p).replace(/\\/g, "/");
  if (SWEEP !== null && !SWEEP.includes(rel)) continue;
  readFileSync(p, "utf8").split("\n").forEach((line, i) => {
    if (!/:sub\(1,|string\.sub\([^,]+, *1,/.test(line)) return;
    c4++;
    const ok = Object.keys(ALLOWED_BYTE_CUTS).some((sig) => { const [f, snip] = sig.split("|"); return f === rel && line.includes(snip); });
    if (!ok) fail("C4", `${rel}:${i + 1}: a byte-based cut of text: ${line.trim().slice(0, 100)}`);
  });
}
console.log(`  C1 ${c1} utf8Sub cuts, C2 ${c2} truncates, C3 ${c3} grid labels, C5 ${c5} real call-site cuts, C4 ${c4} byte cuts left in ${SWEEP === null ? "src/" : SWEEP.length + " swept files"} (all named); ${multibyte} values hold multi-byte text`);
if (failures.length) {
  const counts = {};
  for (const f of failures) counts[f.slice(0, 2)] = (counts[f.slice(0, 2)] || 0) + 1;
  for (const f of failures.filter((f) => f.length > 3).slice(0, 20)) console.log("  FAIL " + f);
  console.log(`utf8-cut: ${failures.length} failure(s) (${Object.entries(counts).map(([k, v]) => `${k} ${v}`).join(", ")})`);
  process.exit(1);
}
console.log("utf8-cut: PASS - every cut ends on a character boundary, in all 26 files, and no byte-based cut of drawn text is left");
