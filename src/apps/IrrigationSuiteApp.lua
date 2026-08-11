-- =========================================================
-- FarmTablet - Irrigation Suite (Wizard UI brief 2026-07-24)
-- =========================================================
-- Read-only farm-wide irrigation operating picture over
-- SeasonalCropStress. Three views: Operations, Forecast, Usage.
-- Handle: g_currentMission.cropStressManager ONLY (no getfenv).
-- Soil risk rows optional via soilFertilityManager.soilSystem.
-- =========================================================

local MODES = { "operations", "forecast", "usage" }
local MODE_LABEL = {
    operations = "Operations",
    forecast   = "Forecast",
    usage      = "Usage",
}

local function _T(key, fallback)
    if g_i18n and key and g_i18n:hasText(key) then
        return g_i18n:getText(key)
    end
    return fallback or key
end

local function _scs()
    return g_currentMission and g_currentMission.cropStressManager or nil
end

local function _soilSystem()
    local mgr = g_currentMission and g_currentMission.soilFertilityManager
    return mgr and mgr.soilSystem or nil
end

local function _pcall(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function _pct(v)
    if v == nil then return "n/a" end
    return string.format("%d%%", math.floor((tonumber(v) or 0) * 100 + 0.5))
end

local function _money(v)
    if v == nil then return "n/a" end
    local n = tonumber(v) or 0
    if g_i18n ~= nil and g_i18n.formatMoney ~= nil then
        return g_i18n:formatMoney(n, 0, true, true)
    end
    return string.format("$%.0f", n)
end

local function _dayBits(activeDays)
    if type(activeDays) ~= "table" then return "schedule n/a" end
    local names = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }
    local on = {}
    for i = 1, 7 do
        if activeDays[i] then on[#on + 1] = names[i] end
    end
    if #on == 0 then return "no active days" end
    if #on == 7 then return "every day" end
    return table.concat(on, " ")
end

-- Module-level coverage cache (rebuild on systems/coverage change only).
local _coveragePolyCache = nil
local _coveragePolyKey = nil
local _farmlandFieldIndex = nil

local function _farmlandFieldMap()
    if _farmlandFieldIndex ~= nil then return _farmlandFieldIndex end
    local map = {}
    if g_fieldManager ~= nil and g_fieldManager.fields ~= nil then
        for _, field in pairs(g_fieldManager.fields) do
            local fl = field and field.farmland
            local id = fl and fl.id
            if id ~= nil and map[id] == nil then
                map[id] = field
            end
        end
    end
    _farmlandFieldIndex = map
    return map
end

local function _coverageKey(systems)
    local parts = { tostring(#(systems or {})) }
    for _, sys in ipairs(systems or {}) do
        local ids = {}
        for _, fid in ipairs(sys.coveredFields or {}) do
            ids[#ids + 1] = tostring(fid)
        end
        table.sort(ids)
        parts[#parts + 1] = string.format("%s:%s:%s",
            tostring(sys.id or sys.name or "?"),
            sys.isActive == true and "1" or "0",
            table.concat(ids, ","))
    end
    return table.concat(parts, "|")
end

--- Real frame-cache: rebuild polygons only when the coverage fingerprint changes.
local function _cacheCoveragePolys(scs, systems)
    local key = _coverageKey(systems)
    if _coveragePolyCache ~= nil and _coveragePolyKey == key then
        return _coveragePolyCache
    end

    local cache = { entries = {}, minX = 1e9, maxX = -1e9, minZ = 1e9, maxZ = -1e9 }
    local seen = {}
    local fieldMap = _farmlandFieldMap()
    for _, sys in ipairs(systems or {}) do
        for _, fid in ipairs(sys.coveredFields or {}) do
            if not seen[fid] then
                seen[fid] = true
                local field = fieldMap[fid]
                if field ~= nil and type(scs.getFieldPolygonWorld) == "function" then
                    local ok, vx, vz, n = pcall(function()
                        return scs:getFieldPolygonWorld(field)
                    end)
                    if ok and type(vx) == "table" and type(vz) == "table" and type(n) == "number" and n >= 3 then
                        local pts = {}
                        for i = 1, n do
                            local px, pz = vx[i], vz[i]
                            if px ~= nil and pz ~= nil then
                                pts[#pts + 1] = { x = px, z = pz }
                                if px < cache.minX then cache.minX = px end
                                if px > cache.maxX then cache.maxX = px end
                                if pz < cache.minZ then cache.minZ = pz end
                                if pz > cache.maxZ then cache.maxZ = pz end
                            end
                        end
                        if #pts >= 3 then
                            cache.entries[#cache.entries + 1] = {
                                id = fid,
                                active = sys.isActive == true,
                                pts = pts,
                            }
                        end
                    end
                end
            end
        end
    end
    _coveragePolyCache = cache
    _coveragePolyKey = key
    return cache
end

local function _drawCoverageMap(self, x, y, w, h, polyCache, accent)
    self.r:appRect(x, y - h, w, h, FT.C.BG_PANEL)
    if polyCache == nil or #polyCache.entries == 0 then
        self.r:appText(x + FT.px(8), y - h * 0.5, FT.FONT.SMALL,
            "No coverage polygons available.", RenderText.ALIGN_LEFT, FT.C.MUTED)
        return
    end
    local spanX = math.max(1, polyCache.maxX - polyCache.minX)
    local spanZ = math.max(1, polyCache.maxZ - polyCache.minZ)
    local pad = FT.px(6)
    local iw, ih = w - pad * 2, h - pad * 2
    local scale = math.min(iw / spanX, ih / spanZ)
    local ox = x + pad + (iw - spanX * scale) * 0.5
    local oy = y - pad - (ih - spanZ * scale) * 0.5

    local function mapPoint(px, pz)
        local sx = ox + (px - polyCache.minX) * scale
        local sy = oy - (pz - polyCache.minZ) * scale
        return sx, sy
    end

    for _, entry in ipairs(polyCache.entries) do
        local col = entry.active and { accent[1], accent[2], accent[3], 0.55 }
            or { 0.55, 0.58, 0.62, 0.45 }
        local pts = entry.pts
        for i = 1, #pts do
            local a = pts[i]
            local b = pts[(i % #pts) + 1]
            local x1, y1 = mapPoint(a.x, a.z)
            local x2, y2 = mapPoint(b.x, b.z)
            local dx, dy = x2 - x1, y2 - y1
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.0001 then
                local segs = math.max(1, math.floor(len / FT.px(3)))
                for s = 0, segs - 1 do
                    local t0 = s / segs
                    local px = x1 + dx * t0
                    local py = y1 + dy * t0
                    self.r:appRect(px, py - FT.py(1), FT.px(3), FT.py(2), col)
                end
            end
        end
    end
end

local function _moistureSplit(scs, fieldId)
    local moisture = _pcall(function() return scs:getMoisture(fieldId) end)
    local rate = _pcall(function() return scs:getIrrigationRate(fieldId) end) or 0
    if moisture == nil then
        return nil, nil, nil
    end
    -- Display arithmetic only: irrigation share vs remainder (sky / other).
    local irrShare = math.max(0, math.min(moisture, rate))
    local rainShare = math.max(0, moisture - irrShare)
    return moisture, irrShare, rainShare
end

--- SCS-009: per-field water need, the pure ranking figure.
--- Monotone in moisture deficit and dry stress; active irrigation (rate > 0)
--- reduces need. Returns nil when moisture is unreadable (the field does not
--- rank). Display-only: feeds the advisory sort, never any economic hook.
local function _waterNeed(moisture, stress, rate)
    if moisture == nil then return nil end
    local deficit = math.max(0, 1 - moisture)          -- 0 wet .. 1 dry
    local stressT = math.max(0, math.min(1, stress or 0))
    local need    = deficit * 0.65 + stressT * 0.35
    if (rate or 0) > 0 then
        need = need * 0.6    -- already being watered: the edge is covered
    end
    return need
end

--- SCS-009: the plain call for a need value.
--- Thresholds are display-only (no economic effect); they pick the words.
---@param need number 0..1
---@return string key, string fallback
local function _waterCall(need)
    if need >= 0.75 then return "ft_irr_call_water_today", "water today" end
    if need >= 0.45 then return "ft_irr_call_watch", "watch" end
    return "ft_irr_call_can_hold", "can hold"
end

FarmTabletUI:registerDrawer(FT.APP.IRRIGATION_SUITE, function(self)
    local AC = FT.appColor(FT.APP.IRRIGATION_SUITE)

    if self:drawHelpPage("_irrigationSuiteHelp", FT.APP.IRRIGATION_SUITE, "Irrigation Suite", AC, {
        { title = "WHAT THIS IS",
          body  = "Farm-wide irrigation picture from Seasonal Crop Stress:\n" ..
                  "which systems run, what they cover, moisture split,\n" ..
                  "a short trend, and usage plus soil risk when Soil Fertilizer\n" ..
                  "is present. Read-only mirror. No second moisture model." },
        { title = "OPERATIONS",
          body  = "Active systems, schedules, coverage outline, and per-field\n" ..
                  "irrigation-versus-rain split from live SCS reads." },
        { title = "FORECAST",
          body  = "Current moisture and drought stress plus a clearly labeled\n" ..
                  "trend. Not a simulated future. Farm-wide advisory when SCS\n" ..
                  "publishes one." },
        { title = "USAGE AND RISK",
          body  = "What SCS is charging per active hour when costs are on.\n" ..
                  "Compaction / OM / disease from Soil Fertilizer when present.\n" ..
                  "Unscouted disease reads Unscouted, never a false all-clear." },
    }) then return end

    local startY = self:drawAppHeader("Irrigation Suite", "")
    local x, cyBottom, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local bottomPad = FT.py(28)

    local scs = _scs()
    if scs == nil then
        local yMiss = startY + scrollY
        self.r:appText(x, yMiss - FT.py(12), FT.FONT.BODY,
            "Seasonal Crop Stress not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, yMiss - FT.py(30), FT.FONT.SMALL,
            "Install FS25_SeasonalCropStress. This app stays hidden when absent.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_irrigationSuiteHelp", AC)
        return
    end

    -- Mode strip is FIXED (like Personnel tabs). Putting it at startY made the
    -- labels sit above bodyClipTop so Operations / Forecast / Usage were clipped.
    local mode = self.system.irrigationSuiteMode or "operations"
    local btnW = (cw - FT.px(8)) / 3
    local btnH = FT.py(22)
    local tabY = startY - btnH
    for i, m in ipairs(MODES) do
        local bx = x + (i - 1) * (btnW + FT.px(4))
        local selected = (mode == m)
        local col = selected and { AC[1], AC[2], AC[3], 0.95 } or FT.C.BTN_NEUTRAL
        local captured = m
        local btn = self.r:button(bx, tabY, btnW, btnH, MODE_LABEL[m], col, {
            onClick = function()
                self.system.irrigationSuiteMode = captured
                self._contentScrollY = 0
                self._contentScrollTarget = 0
            end
        })
        table.insert(self._contentBtns, btn)
    end

    local y = tabY - FT.py(10) + scrollY
    y = self:drawRule(y, 0.35)

    local systems = _pcall(function() return scs:getIrrigationSystems() end) or {}
    if type(systems) ~= "table" then systems = {} end

    ------------------------------------------------------------------
    -- OPERATIONS
    ------------------------------------------------------------------
    if mode == "operations" then
        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL, "SYSTEMS",
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(16)

        if #systems == 0 then
            self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
                "No irrigation systems registered.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(28)
        else
            for _, sys in ipairs(systems) do
                local state = (sys.isActive and "RUNNING") or "idle"
                local scol = sys.isActive and FT.C.POSITIVE or FT.C.MUTED
                local coverN = #(sys.coveredFields or {})
                self.r:appText(x, y - FT.py(2), FT.FONT.BODY,
                    FT_Renderer.truncate(string.format("#%s  %s",
                        tostring(sys.id or "?"), tostring(sys.type or "system")), 22),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(x + cw, y - FT.py(2), FT.FONT.SMALL, state,
                    RenderText.ALIGN_RIGHT, scol)
                y = y - FT.py(14)
                local sched = sys.schedule
                local schedTxt = "no schedule"
                if type(sched) == "table" then
                    schedTxt = string.format("%02d:00-%02d:00  %s",
                        tonumber(sched.startHour) or 0,
                        tonumber(sched.endHour) or 0,
                        _dayBits(sched.activeDays))
                end
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    string.format("%s  ·  %d fields  ·  flow %.2f/h",
                        schedTxt, coverN, tonumber(sys.flowRatePerHour) or 0),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                y = y - FT.py(16)
            end
        end

        y = self:drawRule(y, 0.3)
        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL, "COVERAGE OUTLINE",
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(14)
        local polyCache = _cacheCoveragePolys(scs, systems)
        -- Slightly shorter map so the moisture list stays inside the frame.
        local mapH = FT.py(96)
        local mapW = cw - FT.px(6)
        _drawCoverageMap(self, x, y, mapW, mapH, polyCache, AC)
        y = y - mapH - FT.py(10)

        y = self:drawRule(y, 0.3)
        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL, "FIELD MOISTURE SPLIT",
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(16)

        local farmId = self.system.data:getPlayerFarmId()
        local fields = self.system.data:getOwnedFields(farmId) or {}
        local shown = 0
        for _, f in ipairs(fields) do
            local fid = f.id
            local moisture, irrShare, rainShare = _moistureSplit(scs, fid)
            local irrigated = _pcall(function() return scs:isFieldIrrigated(fid) end)
            if moisture ~= nil or irrigated then
                shown = shown + 1
                if shown > 12 then
                    self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
                        "… more fields omitted", RenderText.ALIGN_LEFT, FT.C.MUTED)
                    y = y - FT.py(16)
                    break
                end
                local tag = irrigated and "watering" or "idle"
                -- Keep % and bars clear of the scrollbar / frame edge.
                local valueX = x + cw - FT.px(10)
                local barW = cw - FT.px(12)
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    string.format("Field #%s  %s", tostring(fid), tag),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(valueX, y - FT.py(1), FT.FONT.SMALL,
                    moisture ~= nil and _pct(moisture) or "n/a",
                    RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
                y = y - FT.py(14)
                if moisture ~= nil then
                    local barY = y
                    self.r:progressBar(x, barY, barW, moisture, 1.0, AC)
                    y = barY - FT.py(10)
                    self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                        string.format("pivot ~%s   sky/other ~%s",
                            _pct(irrShare), _pct(rainShare)),
                        RenderText.ALIGN_LEFT, FT.C.MUTED)
                    y = y - FT.py(14)
                else
                    self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                        "moisture not available", RenderText.ALIGN_LEFT, FT.C.MUTED)
                    y = y - FT.py(14)
                end
            end
        end
        if shown == 0 then
            self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
                "No owned fields with moisture reads yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(24)
        end

    ------------------------------------------------------------------
    -- FORECAST
    ------------------------------------------------------------------
    elseif mode == "forecast" then
        local hint = _pcall(function() return scs:getCriticalAlertHint() end)
        if hint ~= nil and hint ~= "" then
            self.r:appRect(x - FT.px(2), y - FT.py(28), cw + FT.px(4), FT.py(26), FT.C.BG_CARD)
            self.r:appText(x, y - FT.py(6), FT.FONT.SMALL, "FARM ADVISORY",
                RenderText.ALIGN_LEFT, AC)
            self.r:appText(x, y - FT.py(18), FT.FONT.SMALL, tostring(hint),
                RenderText.ALIGN_LEFT, FT.C.TEXT)
            y = y - FT.py(34)
        end

        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
            "CURRENT + LABELED TREND (not a forecast model)",
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(16)

        local temp = _pcall(function() return scs:getTemperature() end)
        local evap = _pcall(function() return scs:getEvaporativeDemand() end)
        if temp ~= nil or evap ~= nil then
            self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                string.format("Air %s C   drying x%s",
                    temp ~= nil and string.format("%.1f", temp) or "n/a",
                    evap ~= nil and string.format("%.2f", evap) or "n/a"),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(16)
        end

        local farmId = self.system.data:getPlayerFarmId()
        local fields = self.system.data:getOwnedFields(farmId) or {}
        local alerts = 0
        for _, f in ipairs(fields) do
            local fid = f.id
            local moisture = _pcall(function() return scs:getMoisture(fid) end)
            local stress = _pcall(function() return scs:getStress(fid) end)
            local rate = _pcall(function() return scs:getIrrigationRate(fid) end) or 0
            if moisture == nil and stress == nil then
                -- skip untracked
            else
                local m = tonumber(moisture) or 0
                local s = tonumber(stress) or 0
                -- Trivial labeled trend: watering now vs dry urgency.
                local trend
                if rate > 0 then
                    trend = "trend: watering now"
                elseif s >= 0.55 or m <= 0.30 then
                    trend = "trend: drying - consider a window"
                    alerts = alerts + 1
                elseif m >= 0.75 then
                    trend = "trend: wet - holding may waterlog"
                    alerts = alerts + 1
                else
                    trend = "trend: steady"
                end
                self.r:appText(x, y - FT.py(1), FT.FONT.BODY,
                    string.format("Field #%s", tostring(fid)),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(x + cw, y - FT.py(1), FT.FONT.SMALL,
                    string.format("moist %s  dry-stress %s", _pct(moisture), _pct(stress)),
                    RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
                y = y - FT.py(13)
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL, trend,
                    RenderText.ALIGN_LEFT, FT.C.MUTED)
                y = y - FT.py(15)
                if alerts >= 6 then
                    self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
                        "Alert set capped - check SCS for more detail.",
                        RenderText.ALIGN_LEFT, FT.C.MUTED)
                    y = y - FT.py(16)
                    break
                end
            end
        end

        -- ══════════════════════════════════════════════════════
        -- SCS-009: ProStaff irrigation advisory (level-gated)
        -- ══════════════════════════════════════════════════════
        -- Read-only, display-only, no economic effect (the standing cert gate).
        -- Everything feeds no cost / yield / price / efficiency hook. Data is all
        -- shipped SCS getters, nil-safe, neutral-absent; SCS absent means the whole
        -- app already returned above. ProStaff absent: the gated sections stay
        -- honest-locked (header + the one-liner naming the unlocking level).
        -- Local farm only: getPlayerFarmId + getOwnedFields, no cross-farm read.
        local psm = g_currentMission and g_currentMission.proStaffManager
        local hasForecastAccess = false
        local hasPredictiveControl = false
        if psm ~= nil then
            pcall(function() hasForecastAccess = psm:hasForecastAccess(farmId) end)
            pcall(function() hasPredictiveControl = psm:hasPredictiveControl(farmId) end)
        end

        -- Shared advisory data, computed once for both gated sections. All shipped
        -- SCS reads, nil-safe, neutral-absent; display-only, no economic effect.
        -- The urgency modifier (R1-A: never per-field) scales the WHOLE list but
        -- reorders nothing - the per-field need figure stays the sort key.
        local urgency = 1.0
        do
            local evap = _pcall(function() return scs:getEvaporativeDemand() end)
            local temp = _pcall(function() return scs:getTemperature() end)
            if evap ~= nil and temp ~= nil then
                urgency = math.max(0.5, evap * (0.8 + math.max(0, temp - 10) * 0.02))
            elseif evap ~= nil then
                urgency = math.max(0.5, evap)
            end
        end
        local ranked = {}
        for _, f in ipairs(fields) do
            local need = _waterNeed(
                _pcall(function() return scs:getMoisture(f.id) end),
                _pcall(function() return scs:getStress(f.id) end),
                _pcall(function() return scs:getIrrigationRate(f.id) end))
            if need ~= nil then
                ranked[#ranked + 1] = { id = f.id, need = need }
            end
        end
        table.sort(ranked, function(a, b) return a.need > b.need end)

        y = self:drawRule(y, 0.3)

        -- L7 WATER NEED -------------------------------------------------------
        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
            _T("ft_irr_advisory_water_need", "WATER NEED (advisory)"),
            RenderText.ALIGN_LEFT, AC)
        y = y - FT.py(14)
        if not hasForecastAccess then
            self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                _T("ft_irr_advisory_locked_l7", "Unlocks at co-op level 7"),
                RenderText.ALIGN_LEFT, FT.C.MUTED)
            y = y - FT.py(16)
        else
            local hint = _pcall(function() return scs:getCriticalAlertHint() end)
            if hint ~= nil and hint ~= "" then
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL, tostring(hint),
                    RenderText.ALIGN_LEFT, FT.C.WARN)
                y = y - FT.py(14)
            end

            local shownNeed = 0
            for _, r in ipairs(ranked) do
                if shownNeed >= 8 then
                    self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                        "… more fields omitted", RenderText.ALIGN_LEFT, FT.C.MUTED)
                    y = y - FT.py(14)
                    break
                end
                local effNeed = math.min(1, r.need * urgency)
                local callKey, callFallback = _waterCall(effNeed)
                local callCol = effNeed >= 0.75 and FT.C.WARN
                    or (effNeed >= 0.45 and FT.C.TEXT_DIM or FT.C.MUTED)
                self.r:appText(x, y - FT.py(1), FT.FONT.BODY,
                    string.format("Field #%s", tostring(r.id)),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(x + cw, y - FT.py(1), FT.FONT.SMALL,
                    _T(callKey, callFallback), RenderText.ALIGN_RIGHT, callCol)
                y = y - FT.py(14)
                shownNeed = shownNeed + 1
            end
            if shownNeed == 0 then
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    _T("ft_irr_advisory_no_reads", "No owned fields with water reads yet."),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                y = y - FT.py(14)
            end
        end

        y = self:drawRule(y, 0.3)

        -- L18 FORWARD CALL -----------------------------------------------------
        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
            _T("ft_irr_advisory_forward_call", "FORWARD CALL (advisory)"),
            RenderText.ALIGN_LEFT, AC)
        y = y - FT.py(14)
        if not hasPredictiveControl then
            self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                _T("ft_irr_advisory_locked_l18", "Unlocks at co-op level 18"),
                RenderText.ALIGN_LEFT, FT.C.MUTED)
            y = y - FT.py(16)
        else
            -- The hold-or-water call extended across the schedule read: which
            -- fields' schedules cover the coming need and which gap. Still from
            -- shipped reads only (getIrrigationSchedule); still display-only.
            local covered, gap = 0, 0
            local shownFwd = 0
            for _, r in ipairs(ranked) do
                if shownFwd >= 6 then break end
                local sched = _pcall(function() return scs:getIrrigationSchedule(r.id) end)
                local hasSched = type(sched) == "table"
                    and tonumber(sched.startHour) ~= nil
                    and tonumber(sched.endHour) ~= nil
                local effNeed = math.min(1, r.need * urgency)
                local callK, callF = _waterCall(effNeed)
                if hasSched then covered = covered + 1 else gap = gap + 1 end
                local fwdKey = hasSched and "ft_irr_advisory_schedule_covers"
                    or "ft_irr_advisory_schedule_gap"
                local fwdTxt = hasSched and "schedule covers" or "schedule gap"
                local fwdCol = hasSched and FT.C.POSITIVE or FT.C.WARN
                self.r:appText(x, y - FT.py(1), FT.FONT.BODY,
                    string.format("Field #%s  %s", tostring(r.id),
                        _T(callK, callF)),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(x + cw, y - FT.py(1), FT.FONT.SMALL,
                    _T(fwdKey, fwdTxt), RenderText.ALIGN_RIGHT, fwdCol)
                y = y - FT.py(14)
                shownFwd = shownFwd + 1
            end
            if shownFwd == 0 then
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    _T("ft_irr_advisory_no_reads", "No owned fields with water reads yet."),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                y = y - FT.py(14)
            else
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    string.format("%d covered  ·  %d gap", covered, gap),
                    RenderText.ALIGN_LEFT, FT.C.MUTED)
                y = y - FT.py(14)
            end
        end

    ------------------------------------------------------------------
    -- USAGE + RISK
    ------------------------------------------------------------------
    else
        local costsOn = _pcall(function() return scs:getIrrigationCostsEnabled() end)
        if costsOn == nil then costsOn = true end

        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL, "SYSTEM USAGE (SCS CHARGING)",
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(16)

        if not costsOn then
            self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
                "Irrigation costs are off in Seasonal Crop Stress.",
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(24)
        elseif #systems == 0 then
            self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
                "No systems to price.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(24)
        else
            for _, sys in ipairs(systems) do
                local cost = tonumber(sys.operationalCostPerHour) or 0
                local flow = tonumber(sys.flowRatePerHour) or 0
                local sched = sys.schedule
                local hours = 0
                if type(sched) == "table" then
                    local startH = tonumber(sched.startHour) or 0
                    local endH = tonumber(sched.endHour) or 0
                    local span = endH - startH
                    if span < 0 then span = span + 24 end
                    local days = 0
                    if type(sched.activeDays) == "table" then
                        for i = 1, 7 do if sched.activeDays[i] then days = days + 1 end end
                    end
                    hours = span * days
                end
                self.r:appText(x, y - FT.py(1), FT.FONT.BODY,
                    string.format("#%s  %s", tostring(sys.id or "?"), tostring(sys.type or "system")),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                y = y - FT.py(13)
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    string.format("%s / hour active   flow %.2f   ~%d schedule hours / week",
                        _money(cost), flow, hours),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                y = y - FT.py(16)
            end
        end

        y = self:drawRule(y, 0.3)
        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL, "SOIL RISK (when Soil Fertilizer present)",
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(16)

        local soil = _soilSystem()
        if soil == nil or type(soil.getFieldInfo) ~= "function" then
            self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
                "Soil Fertilizer not available - risk rows hidden.",
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(24)
        else
            local farmId = self.system.data:getPlayerFarmId()
            local fields = self.system.data:getOwnedFields(farmId) or {}
            local n = 0
            for _, f in ipairs(fields) do
                local fid = f.id
                local info = _pcall(function() return soil:getFieldInfo(fid) end)
                if info ~= nil then
                    n = n + 1
                    if n > 10 then
                        self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
                            "… more fields omitted", RenderText.ALIGN_LEFT, FT.C.MUTED)
                        y = y - FT.py(14)
                        break
                    end
                    local disease
                    if info.shownDiseasePressure == nil then
                        disease = "Unscouted"
                    else
                        disease = _pct(info.shownDiseasePressure)
                    end
                    self.r:appText(x, y - FT.py(1), FT.FONT.BODY,
                        string.format("Field #%s", tostring(fid)),
                        RenderText.ALIGN_LEFT, FT.C.TEXT)
                    y = y - FT.py(13)
                    self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                        string.format("compaction %s   OM %s   disease %s",
                            _pct(info.compaction),
                            info.organicMatter ~= nil and string.format("%.1f", info.organicMatter) or "n/a",
                            disease),
                        RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                    y = y - FT.py(15)
                end
            end
            if n == 0 then
                self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
                    "No field risk reads yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                y = y - FT.py(24)
            end
        end
    end

    self:setContentHeight((tabY - FT.py(10)) - y + scrollY + bottomPad)
    self:drawInfoIcon("_irrigationSuiteHelp", AC)
    self:drawScrollBar()
end)
