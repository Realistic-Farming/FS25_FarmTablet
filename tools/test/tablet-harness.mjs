// tablet-harness.mjs - the whole tablet, loaded the way the game loads it, for the bars that must see
// what the screen draws (MAINTENANCE row 154).
//
// makeTablet(readFile) loads tools/test/lua/prelude.lua, a small engine stand-in, then every file
// src/main.lua sources, in its order, each as its own chunk (file-level locals stay file-level, as the
// engine keeps them). Every drawer is reached the way FarmTabletUI:draw reaches it: through
// FarmTabletUI._appDrawers, which the app files fill at load with the real registerDrawer. The drawers
// draw through the real FT_Renderer; only the engine's overlay factory is stubbed. The world is a
// fixture: a mission with no other mod loaded, one farm, no fields and no vehicles, so each drawer
// shows the page it shows when its mod is absent, and its help page. g_i18n answers from the real
// locale file set with setLocale.
//
// readFile(rel) returns a repo file's text (the working tree, or a git ref for a before/after
// comparison).
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

export const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const req = createRequire(join(ROOT, "tools", "test", "package.json"));
const { lua, lauxlib, lualib, to_luastring } = req("fengari");

export const workingTree = (rel) => readFileSync(join(ROOT, rel), "utf8");

const unesc = (s) => s.replace(/&#10;/g, "\n").replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&apos;/g, "'").replace(/&amp;/g, "&");
export function localeTexts(readFile, loc) {
  const whole = readFile(`translations/translation_${loc}.xml`);
  const s = whole.indexOf("<texts>"), e = whole.indexOf("</texts>");
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  const out = new Map();
  let m;
  while ((m = re.exec(whole)) !== null) if (m.index > s && m.index < e && !out.has(m[1])) out.set(m[1], unesc(m[2]));
  return out;
}

const ENGINE = `
getfenv = getfenv or function() return _G end
setfenv = setfenv or function() end
g_languageShort = "en"
g_i18n = { texts = {}, moneyUnit = 2 }
function g_i18n:hasText(k) return self.texts[k] ~= nil end
function g_i18n:getText(k) local v = self.texts[k]; if v == nil then return string.format("Missing '%s' in l10n", tostring(k)) end return v end
function g_i18n:formatMoney(n) return "$" .. tostring(math.floor(tonumber(n) or 0)) end
function g_i18n:formatNumber(n) return tostring(n) end
function g_i18n:getCurrencySymbol() return "$" end
function g_i18n:getTemperature(c) return c end
function g_i18n:getTemperatureUnit() return "C" end
function g_i18n:formatTemperature(c) return tostring(c) .. " C" end
function g_i18n:getSpeedMeasuringUnit() return "km/h" end
function g_i18n:getSpeed(v) return v end
function g_i18n:getArea(v) return v end
function g_i18n:getAreaUnit() return "ha" end
function g_i18n:getVolumeUnit() return "l" end
function g_i18n:getCurrency(v) return v end
g_overlayManager = { createOverlay = function() return { setColor = function() end, setIsVisible = function() end, render = function() end, delete = function() end } end }
g_plainColorSliceId = "plain"
g_screenWidth, g_screenHeight = 1920, 1080
FarmManager = FarmManager or { SINGLEPLAYER_FARM_ID = 1 }
g_localPlayer = { farmId = 1 }
g_time = 0
g_currentMission.getIsServer = function() return true end
g_currentMission.getIsClient = function() return true end
g_currentMission.missionInfo = { timeScale = 1 }
g_currentMission.environment = { currentDay = 1, currentHour = 6, currentMinute = 30, dayTime = 23400000, daysPerPeriod = 1 }
g_currentMission.getFarmId = function() return 1 end
g_farmManager = { getFarmById = function() return { money = 0, getBalance = function() return 0 end, farmId = 1 } end, farms = {} }
InputAction = InputAction or {}
ToolType = ToolType or { UNDEFINED = 0 }
FillType = FillType or {}
source = function() end
Mission00 = Mission00 or {}
FSCareerMissionInfo = FSCareerMissionInfo or {}
getNormalizedScreenValues = function(x, y) return x / 1920, y / 1080 end
addModEventListener = function() end
function print() end
`;

// Loads the tablet from readFile. Returns an object that draws it.
export function makeTablet(readFile, opts = {}) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const run = (code, name) => {
    const buf = typeof code === "string" ? to_luastring(code) : code;
    if (lauxlib.luaL_loadbuffer(L, buf, null, to_luastring(name)) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return e; }
    if (lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return e; }
    return null;
  };
  const errors = [];
  const prelude = readFileSync(join(ROOT, "tools", "test", "lua", "prelude.lua"), "utf8");
  let err = run(prelude, "@prelude.lua") || run(ENGINE, "@engine");
  if (err) throw new Error("harness engine: " + err);
  if (opts.before) { err = run(opts.before, "@before"); if (err) throw new Error("harness before: " + err); }
  const main = readFile("src/main.lua");
  const files = [...main.matchAll(/^source\(modDirectory \.\. "([^"]+)"\)/gm)].map((m) => m[1]);
  for (const rel of files) {
    const e = run(readFile(rel), "@" + rel);
    if (e) errors.push(`${rel}: ${e}`);
  }
  err = run(`
    HARNESS = {}
    local SETTINGS = Settings.new(SettingsManager.new())
    -- A fresh system for every draw: no app's cache carries one locale's text into the next.
    local function tablet(appId, help)
      local system = FarmTabletSystem.new(SETTINGS)
      system.currentApp = appId
      -- The real FarmTabletUI.new (its fields, its renderer), then the help switch on top.
      local okNew, ui = pcall(FarmTabletUI.new, SETTINGS, system, "")
      if not okNew or type(ui) ~= "table" then
        HARNESS.newError = tostring(ui)
        ui = { _contentBtns = {}, _iconQueue = {}, _providerBtns = {}, _appCellRects = {} }
      end
      ui.isOpen, ui._contentScrollY, ui.settings, ui.system = true, 0, SETTINGS, system
      setmetatable(ui, { __index = function(t, k)
        if help and type(k) == "string" and k:sub(1, 1) == "_" and k:sub(-4) == "Help" then return true end
        return FarmTabletUI[k]
      end })
      ui.r = FT_Renderer.new()
      FarmTabletUI._computeLayout(ui)
      -- A fixture's per-draw state (a queued toast, a selected field), set on each fresh tablet.
      if HARNESS.setup then HARNESS.setup(ui) end
      return ui
    end
    HARNESS.tablet = tablet
    local function collect(ui)
      local out = {}
      local function add(list) for _, e in ipairs(list or {}) do if e.text ~= nil then out[#out + 1] = (e._lit and "\\2" or "") .. tostring(e.text) end end end
      add(ui.r._headerTexts); add(ui.r._buttons); add(ui.r._texts)
      return out
    end
    -- The renderer's text surfaces, watched from outside (they are not changed): a text queued by a call
    -- with the literal flag (final argument, exactly true) is marked, so a comparison knows it was drawn as
    -- handed. Nested calls (button's own appText) are the renderer's business, not the caller's.
    local RDEPTH = 0
    local HELPERS = { drawRow = true, drawSection = true, drawAppHeader = true, drawHelpPage = true, drawButton = true,
                      drawButtonPair = true, row = true, sectionHeader = true, badge = true }
    local function watch(name, textAt, flagAt, list)
      local orig = FT_Renderer[name]
      FT_Renderer[name] = function(self, ...)
        local args = { ... }
        local literal = (args[flagAt] == true)
        if RDEPTH == 0 and HARNESS.check then
          -- The app's own line: past the renderer's plumbing and FarmTabletUI's forwarding helpers.
          local lvl, info = 2, debug.getinfo(2, "Sln")
          while info and (tostring(info.source):find("Renderer.lua", 1, true)
              or (tostring(info.source):find("FarmTabletUI.lua", 1, true) and HELPERS[info.name or ""])) do
            lvl = lvl + 1
            info = debug.getinfo(lvl, "Sln")
          end
          HARNESS.check(name, args[textAt], literal, (info and (tostring(info.source):gsub("^@", "") .. ":" .. tostring(info.currentline)) or "?"))
        end
        RDEPTH = RDEPTH + 1
        local before = #(self[list] or {})
        local r = { pcall(orig, self, ...) }
        RDEPTH = RDEPTH - 1
        if not r[1] then error(r[2], 0) end
        if literal then
          local l = self[list] or {}
          for i = before + 1, #l do if l[i].text ~= nil then l[i]._lit = true end end
        end
        return unpack(r, 2)
      end
    end
    watch("appText", 4, 7, "_buttons")
    watch("text", 4, 7, "_texts")
    watch("appHeaderText", 4, 7, "_headerTexts")
    watch("button", 5, 8, "_buttons")
    function HARNESS.inRenderer() return RDEPTH > 0 end

    -- Instrumentation (makeTablet(readFile, { instrument: true })). Every string a resolver returned during
    -- the current draw is recorded, each of its lines too: FT.l10n, FT.l10nFormat, g_i18n:getText (every
    -- file-local resolver ends there), a string.format or string.gsub over a recorded string, and
    -- FT.l10nAuto handed a recorded string. Nothing is recorded from inside the renderer. Two things are
    -- kept as violations (HARNESS.V):
    --   FLAG  a renderer call from app code, without the flag, whose text equals a recorded string or holds
    --         one of 4 or more characters, unless the text is English source (an FT.AUTO_L10N key, or a
    --         literal the code writes: HARNESS.SRC);
    --   PASS  FT.l10nAuto handed a recorded string outside the renderer (a second translation where the
    --         text is written), unless that string is also English source.
    HARNESS.REC, HARNESS.V, HARNESS.SRC = {}, {}, {}
    if ${opts.instrument ? "true" : "false"} then
      local function rec(s)
        if type(s) == "string" and s ~= "" and RDEPTH == 0 then
          HARNESS.REC[s] = true
          for line in (s .. "\\n"):gmatch("([^\\n]*)\\n") do if line ~= "" then HARNESS.REC[line] = true end end
        end
        return s
      end
      local function english(s) return HARNESS.SRC[s] or FT.AUTO_L10N[s] ~= nil or FT.AUTO_L10N[s .. "\\n"] ~= nil end
      local o_l10n, o_fmt, o_auto = FT.l10n, FT.l10nFormat, FT.l10nAuto
      local depth = 0
      FT.l10n = function(...) return rec(o_l10n(...)) end
      FT.l10nFormat = function(...) return rec(o_fmt(...)) end
      FT.l10nAuto = function(s)
        local resolvedIn = depth == 0 and RDEPTH == 0 and type(s) == "string" and s:find("%a") and HARNESS.REC[s] and not english(s)
        if resolvedIn then
          local info = debug.getinfo(2, "Sl")
          HARNESS.V[#HARNESS.V + 1] = "PASS" .. "\\t" .. (info and (tostring(info.source):gsub("^@", "") .. ":" .. tostring(info.currentline)) or "?") .. "\\t" .. s
        end
        depth = depth + 1
        local ok, r = pcall(o_auto, s)
        depth = depth - 1
        if not ok then error(r, 0) end
        -- A translation written at the call site is a resolver's output too (not the renderer's own pass).
        if depth == 0 and RDEPTH == 0 then rec(r) end
        return r
      end
      local o_get = g_i18n.getText
      g_i18n.getText = function(self, k) return rec(o_get(self, k)) end
      local o_sf = string.format
      string.format = function(f, ...) local r = o_sf(f, ...); if type(f) == "string" and HARNESS.REC[f] then rec(r) end return r end
      local o_gsub = string.gsub
      string.gsub = function(s, ...) local r, n = o_gsub(s, ...); if type(s) == "string" and HARNESS.REC[s] then rec(r) end return r, n end
      function HARNESS.check(name, s, literal, site)
        if literal or type(s) ~= "string" or not s:find("%a") or english(s) then return end
        if HARNESS.REC[s] then HARNESS.V[#HARNESS.V + 1] = "FLAG" .. "\\t" .. site .. "\\t" .. name .. "\\t" .. s return end
        for r in pairs(HARNESS.REC) do
          if #r >= 4 and r:find("%a") and s:find(r, 1, true) then HARNESS.V[#HARNESS.V + 1] = "FLAG" .. "\\t" .. site .. "\\t" .. name .. "\\t" .. s .. "\\t" .. r return end
        end
      end
    end
    function HARNESS.setSources(joined)
      HARNESS.SRC = {}
      for s in (joined .. "\\1"):gmatch("([^\\1]*)\\1") do if s ~= "" then HARNESS.SRC[s] = true end end
    end
    function HARNESS.violations() return table.concat(HARNESS.V, "\\n") end
    function HARNESS.recHas(s) return HARNESS.REC[s] == true and "1" or "" end
    -- Whether s is made of resolver outputs of this draw and letterless glue (numbers, spaces, brackets):
    -- remove every recorded string of 3 or more characters that it holds, longest first; no letter may remain.
    function HARNESS.recCovers(s)
      local list = {}
      for r in pairs(HARNESS.REC) do if #r >= 3 and r:find("%a") and s:find(r, 1, true) then list[#list + 1] = r end end
      table.sort(list, function(a, b) return #a > #b end)
      for _, r in ipairs(list) do
        local i = s:find(r, 1, true)
        while i do s = s:sub(1, i - 1) .. " " .. s:sub(i + #r); i = s:find(r, 1, true) end
      end
      return s:find("%a") and "" or "1"
    end
    function HARNESS.auto(s) return FT.l10nAuto(s) end
    function HARNESS.appIds()
      local ids = {}
      for id in pairs(FarmTabletUI._appDrawers or {}) do ids[#ids + 1] = id end
      table.sort(ids)
      return table.concat(ids, "\\n")
    end
    -- One drawer, main page or help page: every text the renderer queued, joined by "\\n", then
    -- "\\1" and the error, if the drawer stopped.
    function HARNESS.draw(appId, help)
      HARNESS.REC, HARNESS.V = {}, {}
      local ui = tablet(appId, help)
      local ok, e = pcall(FarmTabletUI._appDrawers[appId], ui)
      return table.concat(collect(ui), "\\n") .. (ok and "" or ("\\1" .. tostring(e)))
    end
    -- Draw a page, then press the button whose drawn label is the given text (its real onClick).
    function HARNESS.press(appId, label)
      local ui = tablet(appId, false)
      local ok = pcall(FarmTabletUI._appDrawers[appId], ui)
      local list = ui.r._buttons or {}
      for i, e in ipairs(list) do
        if not e._isText and e.meta and e.meta.onClick and list[i - 1] and list[i - 1]._isText and tostring(list[i - 1].text) == label then
          local okc, err = pcall(e.meta.onClick)
          return okc and "1" or ("error: " .. tostring(err))
        end
      end
      return ""
    end
    -- A player's walk on ONE tablet: draw, then press each drawn button in order (its real onClick) and
    -- redraw; "label#n" is the n-th button drawn with that label. The last draw's texts come back, with
    -- HARNESS.REC and HARNESS.V holding that draw only.
    function HARNESS.flow(appId, labels)
      local ui = tablet(appId, false)
      local ok, e = pcall(FarmTabletUI._appDrawers[appId], ui)
      if not ok then return "\\1" .. tostring(e) end
      for step in (labels .. "\\1"):gmatch("([^\\1]*)\\1") do
        local label, nth = step:match("^(.-)#(%d+)$")
        if label == nil then label, nth = step, 1 else nth = tonumber(nth) end
        local seen, hit = 0, false
        local list = ui.r._buttons or {}
        for i, b in ipairs(list) do
          if not b._isText and b.meta and b.meta.onClick and list[i - 1] and list[i - 1]._isText and tostring(list[i - 1].text) == label then
            seen = seen + 1
            if seen == nth then
              local okc, err = pcall(b.meta.onClick)
              if not okc then return "\\1press " .. step .. ": " .. tostring(err) end
              hit = true
              break
            end
          end
        end
        if not hit then return "\\1no button " .. step end
        ui.r = FT_Renderer.new()
        HARNESS.REC, HARNESS.V = {}, {}
        ok, e = pcall(FarmTabletUI._appDrawers[appId], ui)
        if not ok then return "\\1" .. tostring(e) end
      end
      return table.concat(collect(ui), "\\n")
    end
    function HARNESS.chrome(name)
      HARNESS.REC, HARNESS.V = {}, {}
      local ui = tablet("dashboard", false)
      local f = FarmTabletUI[name]
      if f == nil then return "\\1no " .. name end
      local ok, e = pcall(f, ui)
      return table.concat(collect(ui), "\\n") .. (ok and "" or ("\\1" .. tostring(e)))
    end
  `, "@harness");
  if (err) throw new Error("harness: " + err);
  const callStr = (fn, ...args) => {
    lua.lua_getglobal(L, to_luastring("HARNESS"));
    lua.lua_getfield(L, -1, to_luastring(fn));
    for (const a of args) { if (typeof a === "boolean") lua.lua_pushboolean(L, a); else lua.lua_pushstring(L, to_luastring(String(a))); }
    if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 2); return "\u0001" + e; }
    const v = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 2); return v;
  };
  const split = (s) => {
    const i = s.indexOf("\u0001");
    const body = i < 0 ? s : s.slice(0, i);
    const raw = body === "" ? [] : body.split("\n");
    return { texts: raw.map((x) => x.replace(/^\u0002/, "")), flagged: raw.map((x) => x.startsWith("\u0002")), error: i < 0 ? null : s.slice(i + 1) };
  };
  return {
    L, run, loadErrors: errors,
    setLocale(loc) {
      const map = localeTexts(readFile, loc);
      lua.lua_getglobal(L, to_luastring("g_i18n"));
      lua.lua_createtable(L, 0, map.size);
      for (const [k, v] of map) { lua.lua_pushstring(L, to_luastring(v)); lua.lua_setfield(L, -2, to_luastring(k)); }
      lua.lua_setfield(L, -2, to_luastring("texts"));
      lua.lua_pop(L, 1);
      run(`g_languageShort = ${JSON.stringify(loc)}`, "@locale");
    },
    appIds: () => callStr("appIds").split("\n").filter(Boolean),
    draw: (appId, help) => split(callStr("draw", appId, !!help)),
    chrome: (name) => split(callStr("chrome", name)),
    // After a draw: whether a string was a resolver's output in that draw, and the E2 hits.
    recHas: (s) => callStr("recHas", s) === "1",
    recCovers: (s) => callStr("recCovers", s) === "1",
    violations: () => callStr("violations").split("\n").filter(Boolean).map((l) => l.split("\t")),
    setSources: (list) => callStr("setSources", list.join("\u0001")),
    auto: (s) => callStr("auto", s),
    press: (appId, label) => callStr("press", appId, label),
    flow: (appId, labels) => split(callStr("flow", appId, labels.join("\u0001"))),
  };
}
