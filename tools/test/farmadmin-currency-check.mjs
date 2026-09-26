// farmadmin-currency-check.mjs - MAINTENANCE row 153: the Farm Admin money buttons show the player's
// money unit, not the language's.
//
// FS25 picks the currency symbol from the player's money setting, never from the language:
// I18N:getCurrencySymbol(useShort) returns unit_euroShort, unit_poundShort or unit_dollarShort by
// self.moneyUnit (GS_MONEY_EURO, GS_MONEY_POUND, anything else dollar), dataS/scripts/I18N.lua:392.
// The decompile's postFix in the pound and dollar branches is a decompiler artifact; the bar models
// the control flow. The money itself is never converted for display: I18N:getCurrency has no caller
// in the game's scripts, and the HUD draws the stored balance with formatMoney
// (GameInfoDisplay.lua:146). So +1K adds 1000 whatever the unit, and only the symbol changes.
//
// THE ENTRY-POINT BAR. The drawer is reached the way FarmTabletUI:draw reaches it: through the
// registry that FarmAdminApp.lua fills at load with the real FarmTabletUI:registerDrawer. The buttons
// are drawn by the real FT_Renderer (button, then appText, then FT.l10nAuto over the real
// Constants.lua map); only the engine's overlay factory is stubbed. The tablet's layout painters
// (header, section, rule, help page) are recorders. The WORLD is the engine's i18n:
//   - the mod's texts, from the real translation file of each locale;
//   - the base game's unit texts (each of the 27 base-game l10n files carries unit_euroShort "€",
//     unit_poundShort "£" and unit_dollarShort "$", checked 2026-09-26 in dataS/l10n);
//   - the player's money setting.
// Nothing here hands the drawer a label or a symbol: it asks g_i18n, as the game has it answer.
//
// Rows:
//   T1  the five money keys, in all 26 files, sit inside <texts> once, hold exactly one %s and no
//       literal currency sign: the symbol comes only from the money setting (a "€" written into a
//       value reads euros to a player on dollars, which is this row's defect);
//   R1  [reached] the drawer is in the registry after FarmAdminApp.lua loads;
//   R2  [reached] a draw on the host draws the four money buttons first: pressing them adds 1K, 10K,
//       100K and 1M;
//   U1  in every locale, under each money unit, each money button reads the locale's text formatted
//       with that unit's symbol, and holds no other unit's symbol;
//   U2  the MONEY help line lists the four labels the buttons draw, in the locale's own sentence;
//   U3  de and en spelled out under euro, pound and dollar (Bob's ask on the row);
//   U4  a locale file without the keys falls back to English with the setting's symbol, never "$";
//   U5  with no g_i18n at all the labels read "$", the only place "$" is chosen without the setting;
//   U6  the amount added is the button's own under every unit: nothing converts it.
//
// Usage:  node tools/test/farmadmin-currency-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");
const req = createRequire(join(ROOT, "tools", "test", "package.json"));
const { lua, lauxlib, lualib, to_luastring } = req("fengari");

const MONEY_KEYS = ["ft_farmadmin_money_1k_fmt", "ft_farmadmin_money_10k_fmt", "ft_farmadmin_money_100k_fmt", "ft_farmadmin_money_1m_fmt"];
const HELP_KEY = "ft_farmadmin_help_money_fmt";
const KEYS = [...MONEY_KEYS, HELP_KEY];
// GS_MONEY_EURO = 1, GS_MONEY_DOLLAR = 2, GS_MONEY_POUND = 3 (std.lua:12-14).
const UNITS = [{ name: "euro", id: 1, sym: "€" }, { name: "pound", id: 3, sym: "£" }, { name: "dollar", id: 2, sym: "$" }];
const SIGNS = ["€", "£", "$"];
const SEP = " · ";
const LOAD = ["src/core/Constants.lua", "src/utils/Renderer.lua", "src/FarmTabletUI.lua", "src/apps/FarmAdminApp.lua"];

const failures = [];
const unesc = (s) => s.replace(/&#10;/g, "\n").replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&apos;/g, "'").replace(/&amp;/g, "&");
function entries(file) {
  const whole = readFileSync(file, "utf8");
  const s = whole.indexOf("<texts>"), e = whole.indexOf("</texts>");
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  const inside = new Map(), outside = new Set();
  let m;
  while ((m = re.exec(whole)) !== null) {
    if (m.index > s && m.index < e) { if (!inside.has(m[1])) inside.set(m[1], []); inside.get(m[1]).push(unesc(m[2])); }
    else outside.add(m[1]);
  }
  return { inside, outside };
}

// ---- T1: the text rows.
const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length));
if (locales.length !== 26) { console.log(`expected 26 locale files, found ${locales.length}`); process.exit(1); }
const TEXTS = {};
for (const loc of locales) {
  const E = entries(join(DIR, `translation_${loc}.xml`));
  TEXTS[loc] = E.inside;
  for (const k of KEYS) {
    const got = E.inside.get(k) || [];
    if (E.outside.has(k)) failures.push(`T1 ${loc}: ${k} sits outside <texts>, where FS25 does not read it`);
    if (got.length !== 1) { failures.push(`T1 ${loc}: ${k} present ${got.length} times inside <texts>`); continue; }
    const v = got[0];
    const n = (v.replace(/%%/g, "").match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []);
    if (n.length !== 1 || n[0] !== "%s") failures.push(`T1 ${loc}: ${k} ${JSON.stringify(v)} must hold exactly one %s (the symbol, or the list of amounts), found [${n.join(",")}]`);
    for (const c of SIGNS) if (v.includes(c)) failures.push(`T1 ${loc}: ${k} ${JSON.stringify(v)} writes the currency sign "${c}" itself: a player on another money unit reads the wrong currency`);
  }
}

// ---- The drawer, run.
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const ENGINE = `
-- The engine's i18n as FarmAdminApp.lua meets it: the mod's texts merged into g_i18n, the base
-- game's unit texts beside them, and the player's money setting.
GS_MONEY_EURO, GS_MONEY_DOLLAR, GS_MONEY_POUND = 1, 2, 3
CUR_BASE = { unit_euroShort = "€", unit_poundShort = "£", unit_dollarShort = "$",
             unit_euro = "Euro", unit_pound = "Pound", unit_dollar = "Dollar" }
CUR_I18N = { texts = {}, moneyUnit = GS_MONEY_EURO }
function CUR_I18N:hasText(k) return self.texts[k] ~= nil or CUR_BASE[k] ~= nil end
function CUR_I18N:getText(k) return self.texts[k] or CUR_BASE[k] or string.format("Missing '%s' in l10n", tostring(k)) end
-- I18N.lua:392, by its control flow.
function CUR_I18N:getCurrencySymbol(useShort)
    local postFix = useShort and "Short" or ""
    if self.moneyUnit == GS_MONEY_EURO then
        return self:getText("unit_euro" .. postFix)
    elseif self.moneyUnit == GS_MONEY_POUND then
        return self:getText("unit_pound" .. postFix)
    else
        return self:getText("unit_dollar" .. postFix)
    end
end
function CUR_I18N:formatMoney(n) return tostring(n) end
g_i18n = CUR_I18N
g_overlayManager = { createOverlay = function() return { setColor = function() end, setIsVisible = function() end } end }
g_plainColorSliceId = "plain"
FarmManager = { SINGLEPLAYER_FARM_ID = 1 }
g_localPlayer = { farmId = 1 }
CUR_ADDED = {}
local farm = { getBalance = function() return 0 end,
               changeBalance = function(_, amount) CUR_ADDED[#CUR_ADDED + 1] = amount end }
g_farmManager = { getFarmById = function() return farm end }
g_currentMission.getIsServer = function() return true end
g_currentMission.addMoneyChange = function() end
g_currentMission.missionInfo = { timeScale = 1 }
`;
const HARNESS = `
local function tablet()
    local ui = setmetatable({ isOpen = true, system = { currentApp = FT.APP.FARM_ADMIN }, _contentBtns = {}, help = {} }, { __index = FarmTabletUI })
    ui.r = FT_Renderer.new()
    function ui:drawHelpPage(_, _, _, _, sections) self.help = sections return false end
    function ui:drawAppHeader() return 500 end
    function ui:contentInner() return 0, 0, 200, 0 end
    function ui:getContentScrollY() return 0 end
    function ui:drawRule(y) return y - 4 end
    function ui:drawSection(y) return y - 10 end
    function ui:setContentHeight() end
    function ui:drawInfoIcon() end
    return ui
end
-- One draw through the registry. A button's label is the text its real FT_Renderer:button queued
-- just before the button's own entry.
local function draw()
    local ui = tablet()
    FarmTabletUI._appDrawers[FT.APP.FARM_ADMIN](ui)
    local labels, btns = {}, {}
    local list = ui.r._buttons
    for i, e in ipairs(list) do
        if not e._isText and e.meta ~= nil then
            local t = list[i - 1]
            labels[#labels + 1] = (t ~= nil and t._isText) and t.text or "?"
            btns[#btns + 1] = e
        end
    end
    local help = "?"
    for _, s in ipairs(ui.help or {}) do if s.title == "MONEY" then help = tostring(s.body) end end
    return labels, btns, help
end
function CUR_registered() return type(FarmTabletUI._appDrawers[FT.APP.FARM_ADMIN]) == "function" end
-- The first four buttons' labels, tab-joined, then a newline and the MONEY help body.
function CUR_money()
    local labels, _, help = draw()
    return table.concat({ labels[1] or "?", labels[2] or "?", labels[3] or "?", labels[4] or "?" }, "\\t") .. "\\n" .. help
end
-- Press the first four buttons on the host: the amounts added, comma-joined.
function CUR_press()
    local _, btns = draw()
    CUR_ADDED = {}
    for i = 1, 4 do if btns[i] and btns[i].meta and btns[i].meta.onClick then btns[i].meta.onClick() end end
    local out = {}
    for i, v in ipairs(CUR_ADDED) do out[i] = string.format("%d", v) end
    return table.concat(out, ",")
end
`;
const prelude = readFileSync(join(ROOT, "tools", "test", "lua", "prelude.lua"), "utf8");
const parts = [prelude, ENGINE];
for (const f of LOAD) parts.push(`-- <<< ${f} >>>\ndo\n${readFileSync(join(ROOT, f), "utf8")}\nend`);
parts.push(HARNESS);
let ran = 0;
if (lauxlib.luaL_dostring(L, to_luastring(parts.join("\n"))) !== lua.LUA_OK) {
  failures.push(`R0 the real files did not load: ${lua.lua_tojsstring(L, -1)}`);
} else {
  const lcall = (fn) => {
    lua.lua_getglobal(L, to_luastring(fn));
    if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return { err: e }; }
    const v = lua.lua_type(L, -1) === lua.LUA_TBOOLEAN ? lua.lua_toboolean(L, -1) : lua.lua_tojsstring(L, -1);
    lua.lua_pop(L, 1);
    return { v };
  };
  const dostr = (s) => lauxlib.luaL_dostring(L, to_luastring(s)) === lua.LUA_OK;
  const setTexts = (map) => {
    lua.lua_getglobal(L, to_luastring("CUR_I18N"));
    lua.lua_createtable(L, 0, map.size);
    for (const [k, v] of map) { lua.lua_pushstring(L, to_luastring(v[0])); lua.lua_setfield(L, -2, to_luastring(k)); }
    lua.lua_setfield(L, -2, to_luastring("texts"));
    lua.lua_pop(L, 1);
  };
  const setUnit = (id) => dostr(`CUR_I18N.moneyUnit = ${id}`);
  const money = () => {
    const r = lcall("CUR_money");
    if (r.err) return { err: r.err };
    const nl = r.v.indexOf("\n");
    return { labels: r.v.slice(0, nl).split("\t"), help: r.v.slice(nl + 1) };
  };
  const want = (map, sym) => MONEY_KEYS.map((k) => (map.get(k) ? map.get(k)[0].replace("%s", sym) : null));
  const helpWant = (map, labels) => (map.get(HELP_KEY) ? map.get(HELP_KEY)[0].replace("%s", labels.join(SEP)) : null);

  // R1, R2: reached, through the registry, on the host.
  const reg = lcall("CUR_registered");
  if (reg.err || reg.v !== true) failures.push("R1 [reached] the Farm Admin drawer is not in FarmTabletUI._appDrawers after FarmAdminApp.lua loads");
  else {
    setTexts(TEXTS.en);
    setUnit(1);
    const p = lcall("CUR_press");
    if (p.err || p.v !== "1000,10000,100000,1000000") failures.push(`R2 [reached] the first four buttons the drawer draws on the host are not the money buttons adding 1K, 10K, 100K and 1M: ${p.err || JSON.stringify(p.v)}`);

    // U1, U2: every locale, every unit.
    for (const loc of locales) {
      setTexts(TEXTS[loc]);
      for (const u of UNITS) {
        setUnit(u.id);
        const got = money();
        ran++;
        if (got.err) { failures.push(`U1 ${loc} ${u.name}: the drawer failed: ${got.err}`); continue; }
        const w = want(TEXTS[loc], u.sym);
        for (let i = 0; i < 4; i++) {
          if (w[i] === null) continue;
          if (got.labels[i] !== w[i]) failures.push(`U1 ${loc} ${u.name}: money button ${i + 1} reads ${JSON.stringify(got.labels[i])}, the file's text with the ${u.name} symbol is ${JSON.stringify(w[i])}`);
          if (!got.labels[i].includes(u.sym)) failures.push(`U1 ${loc} ${u.name}: money button ${i + 1} ${JSON.stringify(got.labels[i])} does not show the ${u.name} symbol ${u.sym}`);
          for (const c of SIGNS) if (c !== u.sym && got.labels[i].includes(c)) failures.push(`U1 ${loc} ${u.name}: money button ${i + 1} ${JSON.stringify(got.labels[i])} shows ${c} to a player on ${u.name}s`);
        }
        const hw = helpWant(TEXTS[loc], w.map((x) => x || "?"));
        if (hw !== null && got.help !== hw) failures.push(`U2 ${loc} ${u.name}: the MONEY help reads ${JSON.stringify(got.help)}, not the buttons' labels in the file's sentence ${JSON.stringify(hw)}`);
      }
    }

    // U3: de and en spelled out.
    const SPELLED = {
      en: { euro: ["+€1K", "+€10K", "+€100K", "+€1M"], pound: ["+£1K", "+£10K", "+£100K", "+£1M"], dollar: ["+$1K", "+$10K", "+$100K", "+$1M"] },
      de: { euro: ["+1.000 €", "+10.000 €", "+100.000 €", "+1.000.000 €"], pound: ["+1.000 £", "+10.000 £", "+100.000 £", "+1.000.000 £"],
            dollar: ["+1.000 $", "+10.000 $", "+100.000 $", "+1.000.000 $"] },
    };
    const HELP_SPELLED = {
      en: "Adds funds to your farm account.\nAmounts: +€1K · +€10K · +€100K · +€1M",
      de: "Fügt deinem Hofkonto Geld hinzu.\nBeträge: +1.000 $ · +10.000 $ · +100.000 $ · +1.000.000 $",
    };
    for (const loc of ["en", "de"]) {
      setTexts(TEXTS[loc]);
      for (const u of UNITS) {
        setUnit(u.id);
        const got = money();
        if (got.err) { failures.push(`U3 ${loc} ${u.name}: the drawer failed: ${got.err}`); continue; }
        if (got.labels.join("|") !== SPELLED[loc][u.name].join("|")) failures.push(`U3 ${loc} ${u.name}: the money buttons read ${got.labels.join(" | ")}, not ${SPELLED[loc][u.name].join(" | ")}`);
        if ((loc === "en" && u.name === "euro") || (loc === "de" && u.name === "dollar")) {
          if (got.help !== HELP_SPELLED[loc]) failures.push(`U3 ${loc} ${u.name}: the MONEY help reads ${JSON.stringify(got.help)}, not ${JSON.stringify(HELP_SPELLED[loc])}`);
        }
      }
    }

    // U4: a locale file without the keys: the code's English, with the setting's symbol.
    const bare = new Map([...TEXTS.en].filter(([k]) => !KEYS.includes(k)));
    setTexts(bare);
    setUnit(1);
    {
      const got = money();
      const w = ["+€1K", "+€10K", "+€100K", "+€1M"];
      if (got.err || got.labels.join("|") !== w.join("|")) failures.push(`U4 without the keys, on euros, the money buttons read ${got.err || got.labels.join(" | ")}, not the fallback with the setting's symbol ${w.join(" | ")}`);
      else if (got.help !== "Adds funds to your farm account.\nAmounts: +€1K · +€10K · +€100K · +€1M") failures.push(`U4 without the keys, on euros, the MONEY help reads ${JSON.stringify(got.help)}`);
    }

    // U5: no g_i18n at all.
    dostr("g_i18n = nil");
    {
      const got = money();
      const w = ["+$1K", "+$10K", "+$100K", "+$1M"];
      if (got.err || got.labels.join("|") !== w.join("|")) failures.push(`U5 with no g_i18n the money buttons read ${got.err || got.labels.join(" | ")}, not ${w.join(" | ")}`);
    }
    dostr("g_i18n = CUR_I18N");

    // U6: the amount is the button's own under every unit.
    setTexts(TEXTS.de);
    for (const u of UNITS) {
      setUnit(u.id);
      const p = lcall("CUR_press");
      if (p.err || p.v !== "1000,10000,100000,1000000") failures.push(`U6 on ${u.name}s the money buttons add ${p.err || p.v}, not 1000,10000,100000,1000000 (the engine converts no money for display)`);
    }
  }
}

console.log(`  drawer runs: ${ran} (26 locales x 3 money units), plus de and en spelled out, the no-key and no-i18n fallbacks and the presses`);
if (failures.length > 0) {
  // Up to 12 per row, so one row's many failures never hide another row's.
  const perRow = new Map();
  for (const f of failures) { const r = f.split(" ")[0]; perRow.set(r, (perRow.get(r) || 0) + 1); if (perRow.get(r) <= 12) console.log("  FAIL " + f); }
  for (const [r, n] of perRow) if (n > 12) console.log(`  ... and ${n - 12} more on ${r}`);
  console.log(`farmadmin-currency: ${failures.length} failure(s)`);
  process.exit(1);
}
console.log(`farmadmin-currency: PASS - ${KEYS.length} keys x ${locales.length} files; the drawer run through the registry in ${locales.length} locales x ${UNITS.length} money units`);
