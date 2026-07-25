-- =========================================================
-- FarmTablet v2 – DataProvider
-- Single access point for all FS25 game-data queries.
-- All public methods are cached with a per-key TTL so the
-- underlying FS25 APIs are not polled every frame.
--
-- Cache contract:
--   • Data is refreshed when (now - entry.t) >= TTL.
--   • "now" is g_currentMission.time (milliseconds since
--     mission start), so TTL values are in milliseconds.
--   • Call :invalidate() to flush all entries immediately
--     (used on tablet close and after repairs).
-- =========================================================
---@class FT_DataProvider
FT_DataProvider = {}
local FT_DataProvider_mt = Class(FT_DataProvider)

local CACHE_TTL_MS = 2000  -- refresh every 2 seconds

-- Localized fill/fruit display names.  Do not use internal English names like
-- "corn" directly: FS uses language-specific fillType_* keys (e.g. German
-- "Mais").  This helper also contains a tiny safety fallback for maps/mods
-- that expose CORN while the base-game l10n key is named MAIZE.
local function _ftDpLang()
    if g_languageShort ~= nil then return string.lower(tostring(g_languageShort)) end
    if g_i18n ~= nil then
        local l = g_i18n.languageShort or g_i18n.currentLanguage or g_i18n.language or ""
        return string.lower(tostring(l))
    end
    return ""
end

local function _ftDpI18nKey(key)
    if key == nil or key == "" or g_i18n == nil or g_i18n.hasText == nil then return nil end
    if g_i18n:hasText(key) then
        local v = g_i18n:getText(key)
        if v ~= nil and v ~= "" then return v end
    end
    return nil
end

local function _ftDpLocalizedFillTypeName(ft, fallback)
    if ft == nil then return fallback or "" end
    local name = ft.name or ft.fillTypeName or ft.fruitTypeName
    local candidates = {}
    local function add(v) if v ~= nil and v ~= "" then table.insert(candidates, tostring(v)) end end
    add(name)
    if name ~= nil then
        local n = tostring(name)
        add(string.lower(n)); add(string.upper(n))
        add(n:gsub("^%l", string.upper))
    end
    -- Giants base-game German name for corn is usually stored under maize.
    if name ~= nil and string.lower(tostring(name)) == "corn" then
        add("maize"); add("MAIZE"); add("Maize")
    end
    for _, n in ipairs(candidates) do
        local v = _ftDpI18nKey("fillType_" .. n) or _ftDpI18nKey("fruitType_" .. n)
        if v ~= nil then return v end
    end
    if name ~= nil and string.lower(tostring(name)) == "corn" then
        local lang = _ftDpLang()
        if lang == "de" or lang == "ger" or lang == "deutsch" then return "Mais" end
        if lang == "ru" then return "Кукуруза" end
        if lang == "fr" then return "Maïs" end
        if lang == "es" then return "Maíz" end
        if lang == "it" then return "Mais" end
        if lang == "pl" then return "Kukurydza" end
        if lang == "cz" or lang == "cs" then return "Kukuřice" end
        if lang == "pt" or lang == "br" then return "Milho" end
    end
    local t = ft.title or ft.nameI18N or fallback or name or ""
    if FT and FT.l10nAuto then return FT.l10nAuto(t) end
    return t
end

function FT_DataProvider.new()
    local self = setmetatable({}, FT_DataProvider_mt)
    self._cache            = {}
    self._sessionIncome    = {}   -- [farmId] = accumulated income this session
    self._sessionExpenses  = {}   -- [farmId] = accumulated expenses this session
    self._origChangeBalance = nil -- saved original Farm.changeBalance for cleanup
    self._networkOnline    = true
    self._networkFrozen    = false
    self._networkRecovered = false
    self._frozenWorldInfo  = nil
    return self
end

function FT_DataProvider:setNetworkOnline(isOnline)
    isOnline = isOnline ~= false
    if self._networkOnline ~= isOnline then
        if isOnline == false then
            -- Weltzeit vor dem Offline-Schalten merken, damit Uhr/Tag sichtbar einfrieren.
            local entry = self._cache and self._cache["world"] or nil
            self._frozenWorldInfo = entry and entry.v or nil
            if self._frozenWorldInfo == nil and g_currentMission and g_currentMission.environment then
                local env = g_currentMission.environment
                local dayTimeMs = env.dayTime or 0
                local totalHours = dayTimeMs / 3600000
                self._frozenWorldInfo = {
                    day = env.currentDay or 1,
                    season = env.currentSeason,
                    hour = math.floor(totalHours) % 24,
                    minute = math.floor((totalHours % 1) * 60),
                }
            end
            if self._frozenWorldInfo ~= nil then
                self._cache["world"] = { v = self._frozenWorldInfo, t = g_currentMission and g_currentMission.time or 0 }
            end
        end
        self._networkOnline = isOnline
        self._networkFrozen = not isOnline
        if isOnline then
            self._frozenWorldInfo = nil
            -- Beim Wiederherstellen wird einmal sauber neu geladen.
            self._networkRecovered = true
            self:invalidate()
        end
    end
end

function FT_DataProvider:isNetworkOnline()
    return self._networkOnline ~= false
end

local function _ftDefaultCachedValue(key)
    key = tostring(key or "")
    -- Numeric getters must keep returning numbers while the mobile network is offline.
    -- Otherwise apps such as Dashboard/FarmStats compare a number with the generic
    -- table fallback and crash with "attempt to compare number <= table".
    if string.find(key, "^balance_") ~= nil then return 0 end
    if string.find(key, "^loan_") ~= nil then return 0 end
    if string.find(key, "^income_") ~= nil then return 0 end
    if string.find(key, "^expenses_") ~= nil then return 0 end
    if string.find(key, "^active_field_count_") ~= nil then return 0 end
    if string.find(key, "^vehicle_count_") ~= nil then return 0 end
    if key == "sell_prices" then return {} end
    if key == "weather" then
        return {
            temperature = 0, rainScale = 0, isRaining = false, isStorming = false,
            isFoggy = false, cloudCover = 0, windSpeed = 0, condKey = "clear",
            condition = (FT and FT.l10nAuto and FT.l10nAuto("Clear")) or "Clear",
            forecast = {}
        }
    end
    if string.find(key, "^storages_") ~= nil then
        return { siloCount = 0, totalCap = 0, crops = {} }
    end
    if string.find(key, "^animal_pens_") ~= nil then return {} end
    if string.find(key, "^fleet_") ~= nil then return {} end
    if string.find(key, "^productions_") ~= nil then return {} end
    if string.find(key, "^fields_") ~= nil then return {} end
    if string.find(key, "^contracts_") ~= nil then return {} end
    if string.find(key, "^nearby_") ~= nil then return {} end
    if key == "world" and g_currentMission and g_currentMission.environment then
        local env = g_currentMission.environment
        local dayTimeMs = env.dayTime or 0
        local totalHours = dayTimeMs / 3600000
        return { day = env.currentDay or 1, season = env.currentSeason, hour = math.floor(totalHours) % 24, minute = math.floor((totalHours % 1) * 60) }
    end
    return {}
end

function FT_DataProvider:_cached(key, ttl, fn)
    local now = g_currentMission and g_currentMission.time or 0
    local entry = self._cache[key]

    -- Bei Netzausfall keine neuen Daten abrufen: vorhandene Cache-Daten bleiben stehen.
    -- Wenn noch kein Cache existiert, geben wir einen passenden leeren Wert zurück.
    -- Dadurch crashen Apps wie Lager/Tiere nicht mit pairs(nil) oder #nil.
    if self._networkOnline == false then
        if entry ~= nil then
            return entry.v
        end
        local fallback = _ftDefaultCachedValue(key)
        self._cache[key] = { v = fallback, t = now }
        return fallback
    end

    if entry and (now - entry.t) < (ttl or CACHE_TTL_MS) then
        return entry.v
    end

    local ok, v = pcall(fn)
    if not ok or v == nil then
        v = (entry ~= nil and entry.v) or _ftDefaultCachedValue(key)
    end
    self._cache[key] = { v = v, t = now }
    return v
end

-- ── Farm / Finance ────────────────────────────────────────

--- Returns the farm ID that the local player belongs to.
--- Falls back to 1 (the default single-player farm) if the player object
--- is not yet available or does not expose getFarmId().
function FT_DataProvider:getPlayerFarmId()
    if g_localPlayer then
        return (g_localPlayer.getFarmId and g_localPlayer:getFarmId()) or g_localPlayer.farmId or 1
    end
    return 1
end

function FT_DataProvider:getBalance(farmId)
    local v = self:_cached("balance_"..farmId, 1000, function()
        if g_farmManager then
            local farm = g_farmManager:getFarmById(farmId)
            -- farm:getBalance() is the authoritative FS25 API (confirmed in AIJob.lua)
            if farm and farm.getBalance then
                return math.floor(farm:getBalance() or 0)
            elseif farm and farm.balance then
                return math.floor(farm.balance)
            end
        end
        return 0
    end)
    return tonumber(v) or 0
end

function FT_DataProvider:getLoan(farmId)
    local v = self:_cached("loan_"..farmId, 2000, function()
        if g_farmManager then
            local farm = g_farmManager:getFarmById(farmId)
            if farm and farm.loan then return math.floor(farm.loan) end
        end
        return 0
    end)
    return tonumber(v) or 0
end

function FT_DataProvider:getFarmName(farmId)
    if g_farmManager then
        local farm = g_farmManager:getFarmById(farmId)
        if farm and farm.name and farm.name ~= "" then return farm.name end
    end
    return nil
end

-- Income and expenses are tracked by hooking Farm.changeBalance.
-- FS25 has no stats table with per-category money keys; all money
-- flows through farm:changeBalance(amount, moneyType).  We accumulate
-- session totals ourselves so any mod (IncomeMod, TaxMod, NPCFavor
-- contractor pay, UsedPlus deals, etc.) is automatically captured.
-- Call initSessionTracking() once after mission load.
function FT_DataProvider:getIncome(farmId)
    return math.floor(self._sessionIncome[farmId] or 0)
end

function FT_DataProvider:getExpenses(farmId)
    return math.floor(self._sessionExpenses[farmId] or 0)
end

-- Hook Farm.changeBalance to accumulate session income/expenses.
-- Safe to call multiple times — installs the hook only once.
--
-- Multiplayer note: this hook is LOCAL to the calling client.
-- Dedicated servers never reach this code (main.lua bails out on g_dedicatedServer).
-- On a listen server (host) all balance changes flow through here — full accuracy.
-- On a pure client, FS25 updates farm.balance via network events that may bypass
-- this Lua function, so session totals on clients will be incomplete.
-- This is an accepted limitation: session income/expenses are best-effort in MP.
function FT_DataProvider:initSessionTracking()
    if self._origChangeBalance then return end  -- already hooked
    if not Farm or not Farm.changeBalance then return end

    local data = self
    local orig = Farm.changeBalance
    self._origChangeBalance = orig

    Farm.changeBalance = function(farm, amount, moneyType)
        orig(farm, amount, moneyType)
        if type(amount) ~= "number" or amount == 0 then return end
        local fid = farm.farmId or (farm.getId and farm:getId()) or 0
        if not fid or fid == 0 then return end
        if amount > 0 then
            data._sessionIncome[fid] = (data._sessionIncome[fid] or 0) + amount
        else
            data._sessionExpenses[fid] = (data._sessionExpenses[fid] or 0) + math.abs(amount)
        end
    end
end

-- Restore Farm.changeBalance to its original on unload.
function FT_DataProvider:stopSessionTracking()
    if self._origChangeBalance then
        Farm.changeBalance = self._origChangeBalance
        self._origChangeBalance = nil
    end
end

-- ── Farm Stats ────────────────────────────────────────────

-- Each Farmland links to one Field via farmland.field (set by FieldManager).
-- g_fieldManager.farmlandIdFieldMapping[farmlandId] is the authoritative lookup.
function FT_DataProvider:getActiveFieldCount(farmId)
    return self:_cached("fieldcount_"..farmId, 5000, function()
        local count = 0
        if not g_farmlandManager then return 0 end
        for _, fl in pairs(g_farmlandManager.farmlands) do
            if fl.farmId == farmId then
                local hasField = fl.field ~= nil
                if not hasField and g_fieldManager and g_fieldManager.farmlandIdFieldMapping then
                    hasField = g_fieldManager.farmlandIdFieldMapping[fl.id] ~= nil
                end
                if hasField then count = count + 1 end
            end
        end
        return count
    end)
end

function FT_DataProvider:getVehicleCount(farmId)
    return self:_cached("vehcount_"..farmId, 5000, function()
        local count = 0
        local vehicles = g_currentMission
            and g_currentMission.vehicleSystem
            and g_currentMission.vehicleSystem.vehicles
        if vehicles then
            for _, v in pairs(vehicles) do
                if v.spec_motorized and v.getOwnerFarmId then
                    if v:getOwnerFarmId() == farmId then count = count + 1 end
                end
            end
        end
        return count
    end)
end

-- ── World / Environment ───────────────────────────────────

function FT_DataProvider:getWorldInfo()
    if self._networkOnline == false and self._frozenWorldInfo ~= nil then
        return self._frozenWorldInfo
    end
    return self:_cached("world", 500, function()
        if not (g_currentMission and g_currentMission.environment) then
            return nil
        end
        local env = g_currentMission.environment
        -- FS25 uses env.dayTime (ms within the day, 0–86400000).
        -- currentSeason is always present in base FS25 (1-4); not a Seasons-mod add-on.
        local dayTimeMs  = env.dayTime or 0
        local totalHours = dayTimeMs / 3600000
        return {
            day    = env.currentDay or 1,
            season = env.currentSeason,
            hour   = math.floor(totalHours) % 24,
            minute = math.floor((totalHours % 1) * 60),
        }
    end)
end

function FT_DataProvider:getWeather()
    return self:_cached("weather", 2000, function()
        if not (g_currentMission and g_currentMission.environment) then
            return nil
        end
        local env = g_currentMission.environment

        -- FS25 v1.17+: weather lives at env.weatherSystem.
        -- Older builds / some mods expose env.weather as a fallback.
        local weather = env.weatherSystem or env.weather
        if not weather then return nil end

        -- ── Rain / precipitation ──────────────────────────
        -- Try all known FS25 rain scale method/field names
        local rainScale = 0
        if     weather.getRainFallScale          then rainScale = weather:getRainFallScale()
        elseif weather.getRainScale              then rainScale = weather:getRainScale()
        elseif weather.getPrecipitationIntensity then rainScale = weather:getPrecipitationIntensity()
        elseif type(weather.rainFallScale) == "number" then rainScale = weather.rainFallScale
        elseif type(env.rainScale)         == "number" then rainScale = env.rainScale
        end

        -- ── Temperature ───────────────────────────────────
        local temp = 15
        if     weather.getCurrentTemperature then temp = weather:getCurrentTemperature()
        elseif weather.getTemperature        then temp = weather:getTemperature()
        elseif type(weather.temperature) == "number" then temp = weather.temperature
        elseif type(env.temperature)     == "number" then temp = env.temperature
        end

        -- ── Cloud cover (0.0 – 1.0) ───────────────────────
        local cloud = 0
        if     weather.getCloudCoverage then
            cloud = weather:getCloudCoverage()
        elseif env.cloudUpdater and env.cloudUpdater.getCloudCoverage then
            cloud = env.cloudUpdater:getCloudCoverage()
        elseif type(weather.cloudCoverage) == "number" then cloud = weather.cloudCoverage
        elseif type(env.cloudCoverage)     == "number" then cloud = env.cloudCoverage
        end
        -- Clamp to 0–1 (some mods return 0–100)
        if cloud > 1.0 then cloud = cloud / 100 end

        -- ── Fog ───────────────────────────────────────────
        local fogScale = 0
        if     type(weather.fogScale) == "number" then fogScale = weather.fogScale
        elseif type(env.fogScale)     == "number" then fogScale = env.fogScale
        end

        -- ── Wind ──────────────────────────────────────────
        local windSpeed = 0
        if     weather.getWindSpeed       then windSpeed = weather:getWindSpeed()
        elseif type(weather.windSpeed) == "number" then windSpeed = weather.windSpeed
        elseif type(env.windSpeed)     == "number" then windSpeed = env.windSpeed
        end
        -- Convert m/s → km/h if value looks like m/s (< 30)
        if windSpeed > 0 and windSpeed < 30 then windSpeed = windSpeed * 3.6 end

        -- Wind direction (optional)
        local windDir = nil
        if     weather.getWindDirection then
            local deg = weather:getWindDirection()
            if type(deg) == "number" then
                local dirs = {"N","NE","E","SE","S","SW","W","NW"}
                local idx  = math.floor(((deg + 22.5) % 360) / 45) + 1
                windDir    = dirs[idx]
            end
        elseif type(weather.windDirection) == "number" then
            local deg  = weather.windDirection
            local dirs = {"N","NE","E","SE","S","SW","W","NW"}
            local idx  = math.floor(((deg + 22.5) % 360) / 45) + 1
            windDir    = dirs[idx]
        end

        -- ── Humidity (optional, present in some mods) ─────
        local humidity = nil
        if     weather.getHumidity        then humidity = weather:getHumidity()
        elseif type(weather.humidity) == "number" then humidity = weather.humidity
        elseif type(env.humidity)     == "number" then humidity = env.humidity
        end
        if humidity and humidity > 1.0 then humidity = humidity / 100 end

        -- ── Build result table ─────────────────────────────
        local w = {
            temperature = temp,
            rainScale   = rainScale,
            isRaining   = rainScale > 0.05,
            isStorming  = rainScale > 0.70,
            isFoggy     = fogScale  > 0.3,
            cloudCover  = cloud,       -- 0.0–1.0
            windSpeed   = windSpeed,   -- km/h
            windDir     = windDir,     -- compass string or nil
            humidity    = humidity,    -- 0.0–1.0 or nil
        }

        if     w.isStorming then w.condition = "Stormy";        w.condKey = "storm"
        elseif w.isRaining  then w.condition = "Rainy";         w.condKey = "rain"
        elseif w.isFoggy    then w.condition = "Foggy";         w.condKey = "fog"
        elseif cloud > 0.70 then w.condition = "Overcast";      w.condKey = "overcast"
        elseif cloud > 0.30 then w.condition = "Partly Cloudy"; w.condKey = "cloudy"
        else                     w.condition = "Clear";         w.condKey = "clear"
        end

        -- ── Projected 5-day Forecast ──────────────────────
        -- FS25 has no public forecast Lua API (confirmed: SeasonalCropStress
        -- WeatherIntegration.lua comment).  We build a projection from:
        --   • Near-term (days 1-2): current cloud coverage → rain probability
        --   • Far-term  (days 3-5): seasonal base rain probability, blended in
        -- Temperature drifts ±1 C per day toward the seasonal mean.
        do
            -- Seasonal base rain probabilities (spring/summer/autumn/winter)
            local SEASONAL_RAIN = {[0]=0.30, [1]=0.12, [2]=0.28, [3]=0.35}
            local season = env.currentSeason
            season = (type(season) == "number") and math.floor(season) or 0
            local seasonRain = SEASONAL_RAIN[season] or 0.25

            -- Best cloud coverage reading for the projection
            local cloudFC = cloud  -- already clamped 0-1 above
            if env.cloudUpdater and env.cloudUpdater.getCloudCoverage then
                cloudFC = env.cloudUpdater:getCloudCoverage()
                if cloudFC > 1.0 then cloudFC = cloudFC / 100 end
            end

            local fc = {}
            for day = 1, 5 do
                -- Blend: day 1 = 100% cloud-based, day 5 = 100% seasonal
                local blend   = (day - 1) / 4   -- 0.0 → 1.0
                local rainProb = cloudFC * 0.7 * (1 - blend) + seasonRain * blend

                -- Slight temperature drift toward seasonal typical
                local seasonalMid = ({[0]=12, [1]=24, [2]=14, [3]=2})[season] or 15
                local projTemp = math.floor(temp + (seasonalMid - temp) * blend * 0.3)

                local condKey, condition
                if     rainProb > 0.60 then condKey, condition = "storm",    "Stormy"
                elseif rainProb > 0.35 then condKey, condition = "rain",     "Rainy"
                elseif cloudFC  > 0.55 then condKey, condition = "overcast", "Overcast"
                elseif cloudFC  > 0.25 then condKey, condition = "cloudy",   "Partly Cloudy"
                else                        condKey, condition = "clear",    "Clear"
                end

                table.insert(fc, {
                    condition   = condition,
                    condKey     = condKey,
                    temperature = projTemp,
                    rainProb    = math.floor(rainProb * 100),
                })
            end
            w.forecast = fc
        end

        return w
    end)
end

-- ── Fields ────────────────────────────────────────────────

-- Determines the display name and color for a fruit growth state using
-- the same logic as FS25's MapOverlayGenerator (minHarvestingGrowthState,
-- harvestTransitions, witheredState). Avoids the static 0-8 table which
-- gives wrong results for crops with more than 8 growth stages (e.g. Canola).
local function _ftDpText(key, fallback)
    if g_i18n and key and g_i18n.hasText and g_i18n:hasText(key) then
        return g_i18n:getText(key)
    end
    return fallback or tostring(key or "")
end

local function _resolveGrowthState(gs, ft2)
    if gs == 0 or ft2 == nil then
        return _ftDpText("ft_field_state_empty", "Empty"), FT.C.MUTED, "empty"
    end
    local minH = ft2.minHarvestingGrowthState or 0
    local maxH = ft2.maxHarvestingGrowthState or minH
    -- Ready to harvest
    if minH > 0 and gs >= minH and gs <= maxH then
        return _ftDpText("ft_field_state_harvest", "Ready"), FT.C.POSITIVE, "ready"
    end
    -- Post-harvest stubble state (harvestTransitions set is crop-specific)
    if ft2.harvestTransitions then
        for _, hState in pairs(ft2.harvestTransitions) do
            if gs == hState then
                return _ftDpText("ft_field_state_harvested", "Harvested"), FT.C.MUTED, "empty"
            end
        end
    end
    -- Withered
    if ft2.witheredState and gs == ft2.witheredState then
        return _ftDpText("ft_field_state_withered", "Withered"), FT.C.NEGATIVE, "withered"
    end
    -- Growing stages (1 .. minH-1)
    if gs == 1 then return _ftDpText("ft_field_state_seeded", "Seeded"),     FT.C.MUTED,    "growing" end
    if gs == 2 then return _ftDpText("ft_field_state_germinated", "Germinated"), FT.C.INFO,     "growing" end
    if minH > 0 and gs == minH - 1 then
        return _ftDpText("ft_field_state_ripening", "Ripening"), FT.C.BRAND, "growing"
    end
    return _ftDpText("ft_field_state_growing", "Growing"), FT.C.WARNING, "growing"
end

-- Each Farmland links to ONE Field via farmland.field (set by FieldManager).
-- Crop/growth state must be queried via FieldState:update(cx, cz), not from field directly.
function FT_DataProvider:getOwnedFields(farmId)
    return self:_cached("fields_"..farmId, 4000, function()
        local out = {}
        if not g_farmlandManager then return out end

        -- One reusable FieldState for sampling crop/growth at each field's center
        local fieldState = (FieldState ~= nil) and FieldState.new() or nil

        for _, fl in pairs(g_farmlandManager.farmlands) do
            if fl.farmId == farmId then
                -- Resolve the field linked to this farmland
                local field = fl.field
                if field == nil and g_fieldManager and g_fieldManager.farmlandIdFieldMapping then
                    field = g_fieldManager.farmlandIdFieldMapping[fl.id]
                end

                if field then
                    local cropName   = _ftDpText("ft_field_crop_empty", "Empty")
                    local stateName  = _ftDpText("ft_field_state_empty", "Empty")
                    local stateColor = FT.C.MUTED
                    local phase      = "empty"

                    if fieldState and field.getCenterOfFieldWorldPosition then
                        local cx, cz = field:getCenterOfFieldWorldPosition()
                        if cx then
                            fieldState:update(cx, cz)

                            local fruitIdx = fieldState.fruitTypeIndex
                            local unknown  = FruitType and FruitType.UNKNOWN or 0
                            if fruitIdx and fruitIdx ~= unknown and g_fruitTypeManager then
                                local ft2 = g_fruitTypeManager:getFruitTypeByIndex(fruitIdx)
                                if ft2 then
                                    cropName = _ftDpLocalizedFillTypeName(ft2, _ftDpText("ft_field_crop_unknown", "Unknown"))
                                    local gs = fieldState.growthState or 0
                                    stateName, stateColor, phase = _resolveGrowthState(gs, ft2)
                                end
                            end
                        end
                    end

                    -- Use field:getAreaHa() for the cultivatable field area;
                    -- fl.areaInHa is land area (includes borders) which reads ~0.3 Ha too high
                    local areaHa = (field.getAreaHa and field:getAreaHa()) or fl.areaInHa or 0
                    table.insert(out, {
                        id         = fl.id,
                        cropName   = cropName,
                        stateName  = stateName,
                        stateColor = stateColor,
                        phase      = phase,
                        area       = areaHa,
                    })
                end
            end
        end

        table.sort(out, function(a, b) return a.id < b.id end)
        return out
    end)
end

-- ── Animals ───────────────────────────────────────────────

-- Animal pens are Placeables with spec_husbandry.
-- Counts:  placeable:getNumOfAnimals() / getMaxNumOfAnimals()
-- Food:    placeable:getTotalFood()    / getFoodCapacity()
-- Water:   placeable:getHusbandryFillLevel(FillType.WATER) / getHusbandryCapacity(FillType.WATER)
-- Straw:   placeable:getConditionInfos() → array of {title, value, ratio}
function FT_DataProvider:getAnimalPens(farmId)
    return self:_cached("animals_"..farmId, 3000, function()
        local out = {}
        if not (g_currentMission and g_currentMission.placeableSystem) then
            return out
        end

        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable.spec_husbandry and
               placeable.getOwnerFarmId and
               placeable:getOwnerFarmId() == farmId then

                -- Animal type name from spec_husbandryAnimals
                local typeName = "Unknown"
                if placeable.spec_husbandryAnimals then
                    local aspec = placeable.spec_husbandryAnimals
                    if aspec.animalType and aspec.animalType.name then
                        typeName = aspec.animalType.name
                    end
                end
                if FT and FT.l10nAuto then typeName = FT.l10nAuto(typeName) end

                -- Count
                local numAnimals = 0
                local maxAnimals = 0
                if placeable.getNumOfAnimals then
                    numAnimals = placeable:getNumOfAnimals()
                end
                if placeable.getMaxNumOfAnimals then
                    maxAnimals = placeable:getMaxNumOfAnimals()
                end

                -- Food
                local foodPct = nil
                if placeable.getTotalFood and placeable.getFoodCapacity then
                    local cap = placeable:getFoodCapacity()
                    if cap and cap > 0 then
                        foodPct = math.floor(placeable:getTotalFood() / cap * 100)
                    end
                end

                -- Water
                local waterPct = nil
                if placeable.getHusbandryFillLevel and placeable.getHusbandryCapacity then
                    local wt = FillType and FillType.WATER
                    if wt then
                        local wCap = placeable:getHusbandryCapacity(wt)
                        if wCap and wCap > 0 then
                            waterPct = math.floor(
                                placeable:getHusbandryFillLevel(wt) / wCap * 100)
                        end
                    end
                end

                -- Straw/cleanliness from condition infos
                local cleanPct = nil
                if placeable.getConditionInfos then
                    local infos = placeable:getConditionInfos() or {}
                    for _, info in ipairs(infos) do
                        if info.ratio ~= nil then
                            cleanPct = math.floor(info.ratio * 100)
                            break
                        end
                    end
                end

                table.insert(out, {
                    typeName       = typeName,
                    numAnimals     = numAnimals,
                    maxAnimals     = maxAnimals,
                    foodPct        = foodPct,
                    waterPct       = waterPct,
                    cleanPct       = cleanPct,
                    hasFood        = placeable.getTotalFood ~= nil,
                    hasWater       = placeable.getHusbandryFillLevel ~= nil and FillType ~= nil,
                    hasCleanliness = placeable.getConditionInfos ~= nil,
                })
            end
        end
        return out
    end)
end

-- ── Vehicles ──────────────────────────────────────────────

function FT_DataProvider:getNearbyVehicles(radiusM)
    radiusM = radiusM or 20

    local px, py, pz
    if g_localPlayer then
        -- Check getIsInVehicle before calling getCurrentVehicle to avoid
        -- stale/invalid returns when the player is on foot.
        if g_localPlayer.getIsInVehicle and g_localPlayer:getIsInVehicle() then
            local sv = g_localPlayer.getCurrentVehicle and g_localPlayer:getCurrentVehicle()
            if sv and sv.rootNode and sv.rootNode ~= 0 then
                local ok, x, y, z = pcall(getWorldTranslation, sv.rootNode)
                if ok then px, py, pz = x, y, z end
            end
        end
        if not px and g_localPlayer.rootNode then
            local ok, x, y, z = pcall(getWorldTranslation, g_localPlayer.rootNode)
            if ok then px, py, pz = x, y, z end
        end
    end
    if not px then return {} end

    local vehicles = g_currentMission
        and g_currentMission.vehicleSystem
        and g_currentMission.vehicleSystem.vehicles
    if not vehicles then return {} end

    local out = {}
    for _, v in pairs(vehicles) do
        if v.rootNode and v.rootNode ~= 0 and v.spec_motorized then
            local ok, vx, vy, vz = pcall(getWorldTranslation, v.rootNode)
            if ok and vx then
            local dist = math.sqrt((px-vx)^2 + (py-vy)^2 + (pz-vz)^2)
            if dist <= radiusM then
                local name = (v.getFullName and v:getFullName()) or
                             v.configFileName or "Unknown"

                -- Fuel: read via FillUnit API (propellantFillUnitIndices[1])
                local fuel, fuelCap = 0, 1
                local ms = v.spec_motorized
                if ms and ms.propellantFillUnitIndices and #ms.propellantFillUnitIndices > 0 then
                    local idx = ms.propellantFillUnitIndices[1]
                    fuel    = v:getFillUnitFillLevel(idx) or 0
                    fuelCap = math.max(v:getFillUnitCapacity(idx) or 1, 1)
                end

                -- Wear: spec_wearable.damage is mechanical damage (0-1)
                local wearPct = 0
                if v.spec_wearable then
                    wearPct = math.floor((v.spec_wearable.damage or 0) * 100)
                end

                -- operatingTime is on the vehicle root table in milliseconds
                local opHours = 0
                if v.operatingTime then
                    opHours = math.floor(v.operatingTime / 3600000)
                end

                table.insert(out, {
                    vehicle  = v,
                    name     = name,
                    distance = math.floor(dist),
                    fuel     = fuel,
                    fuelCap  = fuelCap,
                    fuelPct  = math.floor(fuel / fuelCap * 100),
                    wearPct  = wearPct,
                    opHours  = opHours,
                })
            end  -- dist <= radiusM
            end  -- ok and vx
        end  -- spec_motorized
    end  -- for vehicles
    table.sort(out, function(a,b) return a.distance < b.distance end)
    return out
end

-- ── Storage & Sell Prices ─────────────────────────────────

-- Returns aggregated fill levels across all player-owned silos.
-- out = { siloCount, totalCap, crops = { {fillTypeIndex, name, amount} } }
-- Crops are sorted largest-first.
function FT_DataProvider:getStorages(farmId)
    return self:_cached("storages_"..farmId, 3000, function()
        local out = { siloCount = 0, totalCap = 0, crops = {} }
        if not (g_currentMission and g_currentMission.placeableSystem) then
            return out
        end

        local amounts = {}

        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable.spec_silo
               and placeable.getOwnerFarmId
               and placeable:getOwnerFarmId() == farmId then

                out.siloCount = out.siloCount + 1

                -- Capacity: sum all storage slots in the silo
                local spec = placeable.spec_silo
                if spec.storages then
                    for _, storage in pairs(spec.storages) do
                        out.totalCap = out.totalCap + (storage.capacity or 0)
                    end
                end

                -- Fill levels: {[fillTypeIndex] = amount}
                if placeable.getFillLevels then
                    local levels = placeable:getFillLevels()
                    if levels then
                        for fillTypeIdx, amount in pairs(levels) do
                            if type(amount) == "number" and amount > 0 then
                                amounts[fillTypeIdx] = (amounts[fillTypeIdx] or 0) + amount
                            end
                        end
                    end
                end
            end
        end

        for fillTypeIdx, amount in pairs(amounts) do
            if g_fillTypeManager then
                local ft2 = g_fillTypeManager:getFillTypeByIndex(fillTypeIdx)
                if ft2 then
                    table.insert(out.crops, {
                        fillTypeIndex = fillTypeIdx,
                        name          = _ftDpLocalizedFillTypeName(ft2, ("Type "..fillTypeIdx)),
                        amount        = math.floor(amount),
                    })
                end
            end
        end

        table.sort(out.crops, function(a, b) return a.amount > b.amount end)
        return out
    end)
end

-- Returns best sell prices across all active selling stations on the map.
-- out = { [fillTypeIndex] = { name, bestPrice ($/1000L), bestStation, stations = {{name,price}} } }
function FT_DataProvider:getSellPrices()
    return self:_cached("sell_prices", 5000, function()
        local out = {}
        if not (g_currentMission and g_currentMission.storageSystem) then
            return out
        end

        local stations = g_currentMission.storageSystem:getUnloadingStations()
        if not stations then return out end

        for _, station in pairs(stations) do
            if station.isSellingPoint and station.getEffectiveFillTypePrice then
                -- Station display name
                local stationName = "Sell Point"
                if station.owningPlaceable then
                    local sp = station.owningPlaceable
                    stationName = (sp.getName and sp:getName())
                               or (sp.getFullName and sp:getFullName())
                               or stationName
                end

                -- Iterate only fill types this station actually accepts.
                -- Calling getEffectiveFillTypePrice() for every registered fill type can
                -- trigger a GIANTS SellingStation call stack on some maps/mod sell points.
                local candidates = {}
                local function addCandidate(idx)
                    idx = tonumber(idx)
                    if idx ~= nil and idx > 1 then candidates[idx] = true end
                end
                if station.acceptedFillTypes ~= nil then
                    for k, v in pairs(station.acceptedFillTypes) do
                        if v == true or type(v) == "number" then addCandidate(k) end
                    end
                end
                if station.fillTypes ~= nil then
                    for k, v in pairs(station.fillTypes) do
                        if v == true or type(v) == "number" then addCandidate(k) end
                    end
                end
                if station.priceMultipliers ~= nil then
                    for k, _ in pairs(station.priceMultipliers) do addCandidate(k) end
                end

                if g_fillTypeManager and g_fillTypeManager.fillTypes then
                    for fillTypeIdx, _ in pairs(candidates) do
                        local fillType = g_fillTypeManager.fillTypes[fillTypeIdx]
                        if fillType ~= nil then
                            -- Do NOT call SellingStation:getEffectiveFillTypePrice() here.
                            -- Some mod maps throw a GIANTS call stack from inside that method even when pcall catches it.
                            -- Use only already cached/raw station price tables when available; otherwise skip safely.
                            local price = nil
                            if station.fillTypePrices ~= nil then
                                price = station.fillTypePrices[fillTypeIdx]
                            elseif station.prices ~= nil then
                                price = station.prices[fillTypeIdx]
                            end
                            if price and type(price) == "number" and price > 0 then
                                local p1000 = math.floor(price * 1000)
                                if not out[fillTypeIdx] then
                                    out[fillTypeIdx] = {
                                        name        = fillType.title or fillType.name or ((FT and FT.l10nAuto and FT.l10nAuto("Type")) or "Type") .. " " .. fillTypeIdx,
                                        bestPrice   = 0,
                                        bestStation = "",
                                        stations    = {},
                                    }
                                end
                                table.insert(out[fillTypeIdx].stations, {
                                    name  = stationName,
                                    price = p1000,
                                })
                                if p1000 > out[fillTypeIdx].bestPrice then
                                    out[fillTypeIdx].bestPrice   = p1000
                                    out[fillTypeIdx].bestStation = stationName
                                end
                            end
                        end
                    end
                end
            end
        end

        return out
    end)
end

-- ── Fleet Vehicles ────────────────────────────────────────

-- Returns all motorized vehicles owned by farmId with status details.
-- out = { { name, fuelPct, fuelLitres, fuelCap, wearPct, opHours, aiActive } }
-- Sorted by fuel % ascending (most urgent first).
function FT_DataProvider:getFleetVehicles(farmId)
    return self:_cached("fleet_"..farmId, 4000, function()
        local out = {}
        local vehicles = g_currentMission
            and g_currentMission.vehicleSystem
            and g_currentMission.vehicleSystem.vehicles
        if not vehicles then return out end

        for _, v in pairs(vehicles) do
            if v.spec_motorized and v.getOwnerFarmId and v:getOwnerFarmId() == farmId then
                local name = (v.getFullName and v:getFullName())
                          or v.configFileName or "Vehicle"

                local fuel, fuelCap = 0, 1
                local ms = v.spec_motorized
                if ms and ms.propellantFillUnitIndices and #ms.propellantFillUnitIndices > 0 then
                    local idx = ms.propellantFillUnitIndices[1]
                    fuel    = v:getFillUnitFillLevel(idx) or 0
                    fuelCap = math.max(v:getFillUnitCapacity(idx) or 1, 1)
                end

                local wearPct = 0
                if v.spec_wearable then
                    wearPct = math.floor((v.spec_wearable.damage or 0) * 100)
                end

                local opHours = 0
                if v.operatingTime then
                    opHours = math.floor(v.operatingTime / 3600000)
                end

                local aiActive = false
                if v.getAIIsActive then
                    local ok, val = pcall(function() return v:getAIIsActive() end)
                    aiActive = ok and val == true
                end

                table.insert(out, {
                    name       = name,
                    fuelPct    = math.floor(fuel / fuelCap * 100),
                    fuelLitres = math.floor(fuel),
                    fuelCap    = math.floor(fuelCap),
                    wearPct    = wearPct,
                    opHours    = opHours,
                    aiActive   = aiActive,
                })
            end
        end

        table.sort(out, function(a, b) return a.fuelPct < b.fuelPct end)
        return out
    end)
end

-- ── Production Buildings ──────────────────────────────────

-- Helper: derive a readable name from a placeable object.
local function _placeableName(p)
    if not p then return "Building" end
    if p.getName then
        local ok, n = pcall(function() return p:getName() end)
        if ok and n and n ~= "" then return n end
    end
    if p.getFullName then
        local ok, n = pcall(function() return p:getFullName() end)
        if ok and n and n ~= "" then return n end
    end
    local tn = p.typeName or p.className or ""
    if tn ~= "" then
        -- camelCase → words: "cheeseFactory" → "Cheese Factory"
        tn = tn:gsub("(%u)", " %1"):gsub("^%s+", "")
        if tn ~= "" then return tn end
    end
    local cf = (p.configFileName or ""):match("([^/\\]+)%.xml$") or ""
    if cf ~= "" then
        cf = cf:gsub("[_%-]+", " ")
        cf = cf:gsub("(%a)([%w']*)", function(a, b) return a:upper()..b:lower() end)
        return cf
    end
    return "Building"
end

-- Helper: get a fill type display name by index.
local function _fillTypeName(idx)
    if not g_fillTypeManager then return "?" end
    local ft = g_fillTypeManager:getFillTypeByIndex(idx)
    return ft and (ft.title or ft.name or ("Type "..idx)) or ("Type "..idx)
end

-- Returns all production points owned by farmId.
-- out = { { name, activeCount, totalCount, inputs = {name,...}, outputs = {name,...} } }
function FT_DataProvider:getProductionBuildings(farmId)
    return self:_cached("prod_"..farmId, 5000, function()
        local out = {}
        local mgr = g_currentMission and g_currentMission.productionChainManager
        if not mgr then return out end

        local points = mgr:getProductionPointsForFarmId(farmId)
        if not points then return out end

        for _, pp in ipairs(points) do
            local buildingName = _placeableName(pp.owningPlaceable)

            -- Count enabled vs total productions.
            -- A production's enabled state is reflected by membership in
            -- pp.activeProductions (the array of productions the player has
            -- switched on) — NOT by a field on the pp.productions definitions.
            -- Reading prod.enabled off the definitions always saw nil and
            -- reported "stalled" while a production was actually running (#72).
            -- Verified against SDK objects/ProductionPoint.lua: writeStream
            -- iterates #self.activeProductions; self.productions is all defs.
            local total  = (pp.productions and #pp.productions) or 0
            local active = (pp.activeProductions and #pp.activeProductions) or 0

            -- Collect input fill type names
            local inputs = {}
            if pp.inputFillTypeIds then
                for idx, _ in pairs(pp.inputFillTypeIds) do
                    if type(idx) == "number" then
                        table.insert(inputs, _fillTypeName(idx))
                    end
                end
            end
            table.sort(inputs)

            -- Collect output fill type names
            local outputs = {}
            if pp.outputFillTypeIds then
                for idx, _ in pairs(pp.outputFillTypeIds) do
                    if type(idx) == "number" then
                        table.insert(outputs, _fillTypeName(idx))
                    end
                end
            end
            table.sort(outputs)

            table.insert(out, {
                name        = buildingName,
                activeCount = active,
                totalCount  = total,
                inputs      = inputs,
                outputs     = outputs,
            })
        end

        table.sort(out, function(a, b) return a.name < b.name end)
        return out
    end)
end

-- ── Farm Area ─────────────────────────────────────────────

-- Returns total owned farmland area in hectares.
function FT_DataProvider:getTotalFarmArea(farmId)
    return self:_cached("farmarea_"..farmId, 10000, function()
        local total = 0
        if not g_farmlandManager then return total end
        for _, fl in pairs(g_farmlandManager.farmlands) do
            if fl.farmId == farmId then
                total = total + (fl.areaInHa or 0)
            end
        end
        return math.floor(total * 10) / 10  -- 1 decimal
    end)
end

-- ── Helpers ───────────────────────────────────────────────

--- Formats an integer money amount using the game's locale-aware formatter.
--- Falls back to a simple "$amount" string if g_i18n is unavailable.
---@param amount number
---@return string
function FT_DataProvider:formatMoney(amount)
    if g_i18n then
        return g_i18n:formatMoney(amount, 0, true, true) or ("$"..amount)
    end
    return string.format("$%d", amount or 0)
end

-- guard against nil season (base game has no seasons mod)
--- Returns the display name for a season index (0=Spring … 3=Winter).
--- Returns nil if seasonIdx is nil (base game has no seasons).
local SEASON_NAMES = {"Spring","Summer","Autumn","Winter"}
function FT_DataProvider:getSeasonName(seasonIdx)
    if seasonIdx == nil then return nil end
    return (FT and FT.l10nAuto and FT.l10nAuto(SEASON_NAMES[seasonIdx + 1] or "Unknown")) or (SEASON_NAMES[seasonIdx + 1] or "Unknown")
end

--- Flushes all cached data immediately.
--- Call this after any action that changes game state (repairs, tablet close, etc.)
--- so the next draw cycle picks up fresh values.
function FT_DataProvider:invalidate()
    self._cache = {}
end

function FT_DataProvider:getNetworkStatus()
    return {
        online = self._networkOnline ~= false,
        frozen = self._networkFrozen == true,
    }
end
