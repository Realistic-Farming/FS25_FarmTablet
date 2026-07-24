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

local function _fieldByFarmlandId(farmlandId)
    if g_fieldManager == nil or g_fieldManager.fields == nil then return nil end
    for _, field in pairs(g_fieldManager.fields) do
        local fl = field and field.farmland
        local id = fl and fl.id
        if id == farmlandId then return field end
    end
    return nil
end

--- Cache field polygons for covered farmland ids (light overlay).
local function _cacheCoveragePolys(scs, systems)
    local cache = { entries = {}, minX = 1e9, maxX = -1e9, minZ = 1e9, maxZ = -1e9 }
    local seen = {}
    for _, sys in ipairs(systems or {}) do
        for _, fid in ipairs(sys.coveredFields or {}) do
            if not seen[fid] then
                seen[fid] = true
                local field = _fieldByFarmlandId(fid)
                if field ~= nil and type(scs.getFieldPolygonWorld) == "function" then
                    local ok, vx, vz, n = pcall(function()
                        return scs:getFieldPolygonWorld(field)
                    end)
                    if ok and type(vx) == "table" and type(vz) == "table" and type(n) == "number" and n >= 3 then
                        local pts = {}
                        for i = 1, n do
                            local x, z = vx[i], vz[i]
                            if x ~= nil and z ~= nil then
                                pts[#pts + 1] = { x = x, z = z }
                                if x < cache.minX then cache.minX = x end
                                if x > cache.maxX then cache.maxX = x end
                                if z < cache.minZ then cache.minZ = z end
                                if z > cache.maxZ then cache.maxZ = z end
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
    local y = startY + scrollY

    local scs = _scs()
    if scs == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Seasonal Crop Stress not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_SeasonalCropStress. This app stays hidden when absent.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_irrigationSuiteHelp", AC)
        return
    end

    -- Mode strip
    local mode = self.system.irrigationSuiteMode or "operations"
    local btnW = (cw - FT.px(8)) / 3
    local btnH = FT.py(20)
    for i, m in ipairs(MODES) do
        local bx = x + (i - 1) * (btnW + FT.px(4))
        local selected = (mode == m)
        local col = selected and AC or FT.C.BTN_NEUTRAL
        local captured = m
        local btn = self.r:button(bx, y, btnW, btnH, MODE_LABEL[m], col, {
            onClick = function()
                self.system.irrigationSuiteMode = captured
            end
        })
        table.insert(self._contentBtns, btn)
    end
    y = y - btnH - FT.py(8)
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
                    string.format("#%s  %s", tostring(sys.id or "?"), tostring(sys.type or "system")),
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
        local mapH = FT.py(110)
        _drawCoverageMap(self, x, y, cw, mapH, polyCache, AC)
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
                self.r:appText(x, y - FT.py(1), FT.FONT.SMALL,
                    string.format("Field #%s  %s", tostring(fid), tag),
                    RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(x + cw, y - FT.py(1), FT.FONT.SMALL,
                    moisture ~= nil and _pct(moisture) or "n/a",
                    RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
                y = y - FT.py(12)
                if moisture ~= nil then
                    local barY = y
                    self.r:progressBar(x, barY, cw, moisture, 1.0, AC)
                    y = y - FT.py(10)
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

    self:drawInfoIcon("_irrigationSuiteHelp", AC)
    self:setContentHeight(startY - y + scrollY + FT.py(12))
end)
