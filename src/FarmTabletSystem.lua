-- =========================================================
-- FarmTablet v2 – FarmTabletSystem
-- Orchestrates state, data, and the app registry.
-- Safe to construct on all contexts (pure data, no rendering).
-- =========================================================
---@class FarmTabletSystem
FarmTabletSystem = {}

local function _ftSystemLang()
    if g_languageShort ~= nil then return string.lower(tostring(g_languageShort)) end
    if g_i18n ~= nil then
        return string.lower(tostring(g_i18n.languageShort or g_i18n.currentLanguage or g_i18n.language or ""))
    end
    return ""
end

local function _ftSystemI18nKey(key)
    if key == nil or key == "" or g_i18n == nil or g_i18n.hasText == nil then return nil end
    if g_i18n:hasText(key) then
        local v = g_i18n:getText(key)
        if v ~= nil and v ~= "" then return v end
    end
    return nil
end

local function _ftSystemPrettyCropName(name)
    name = tostring(name or "")
    if name == "" then return name end
    if name:find("%l") then return name end
    name = name:gsub("_", " ")
    return (name:lower():gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

local function _ftSystemLocalizedFillName(ft, fallback)
    if ft == nil then return fallback or "Unknown" end
    local name = ft.name or ft.fillTypeName or ft.fruitTypeName
    local candidates = {}
    local function add(v) if v ~= nil and v ~= "" then table.insert(candidates, tostring(v)) end end
    add(name)
    if name ~= nil then
        local n = tostring(name)
        add(string.lower(n)); add(string.upper(n)); add(n:gsub("^%l", string.upper))
    end
    if name ~= nil and string.lower(tostring(name)) == "corn" then
        add("maize"); add("MAIZE"); add("Maize")
    end
    for _, n in ipairs(candidates) do
        local v = _ftSystemI18nKey("fillType_" .. n) or _ftSystemI18nKey("fruitType_" .. n)
        if v ~= nil then return v end
    end
    if name ~= nil and g_fillTypeManager ~= nil and g_fillTypeManager.getFillTypeByName ~= nil then
        local n = tostring(name)
        local fill = g_fillTypeManager:getFillTypeByName(n)
            or g_fillTypeManager:getFillTypeByName(string.upper(n))
            or g_fillTypeManager:getFillTypeByName(string.lower(n))
        if fill ~= nil and fill.title ~= nil and tostring(fill.title) ~= "" then
            return tostring(fill.title)
        end
    end
    if name ~= nil and string.lower(tostring(name)) == "corn" then
        local lang = _ftSystemLang()
        if lang == "de" or lang == "ger" then return "Mais" end
        if lang == "ru" then return "Кукуруза" end
        if lang == "fr" then return "Maïs" end
        if lang == "es" then return "Maíz" end
        if lang == "it" then return "Mais" end
        if lang == "pl" then return "Kukurydza" end
        if lang == "cz" or lang == "cs" then return "Kukuřice" end
        if lang == "pt" or lang == "br" then return "Milho" end
    end
    local pretty = (name ~= nil and name ~= "") and _ftSystemPrettyCropName(name) or nil
    local t = ft.title or ft.nameI18N or pretty or fallback or "Unknown"
    if FT and FT.l10nAuto then return FT.l10nAuto(t) end
    return t
end
local FarmTabletSystem_mt = Class(FarmTabletSystem)

function FarmTabletSystem.new(settings)
    local self = setmetatable({}, FarmTabletSystem_mt)
    self.settings      = settings
    self.isInitialized = false

    self.registry      = AppRegistry.new()
    self.data          = FT_DataProvider.new()

    self.currentApp   = self.settings.startupApp or "dashboard"
    self.isTabletOpen = false

    -- Workshop state
    self.workshopSelectedVehicle = nil

    -- Bucket tracker
    self.bucket = {
        isEnabled   = true,
        vehicle     = nil,
        history     = {},
        totalLoads  = 0,
        totalWeight = 0,
        lastFill    = 0,
        lastType    = nil,
        startTime   = 0,
    }

    return self
end

function FarmTabletSystem:initialize()
    if self.isInitialized then return end
    self.isInitialized = true
    self.registry:autoDetect()
    self.data:initSessionTracking()
    self:log("System initialized. Apps: %d", #self.registry:getAll())
end

function FarmTabletSystem:delete()
    self.data:stopSessionTracking()
end

-- reset workshopSelectedVehicle and soilSelectedField on close so stale
-- selections don't persist across tablet open/close cycles.
function FarmTabletSystem:onTabletClosed()
    self.workshopSelectedVehicle = nil
    self.soilSelectedField = nil
    self.data:invalidate()
end

function FarmTabletSystem:update(dt)
    if not self.settings.enabled or not self.isInitialized then return end
    if self.currentApp == FT.APP.BUCKET and self.bucket.isEnabled then
        self:_updateBucket()
    end
end

-- ── Bucket Tracker ────────────────────────────────────────

function FarmTabletSystem:_getBucketVehicle()
    if not (g_currentMission and g_currentMission.controlledVehicle) then
        return nil
    end
    local v = g_currentMission.controlledVehicle
    if not v.spec_fillUnit then return nil end

    local typeName = (v.typeName or ""):lower()
    local loaderTypes = {"wheelloader","frontloader","loader","excavator",
                         "backhoe","telehandler","skidsteer","materialhandler"}
    for _, t in ipairs(loaderTypes) do
        if typeName:find(t) then return v end
    end
    if v.getAttachedImplements then
        for _, impl in ipairs(v:getAttachedImplements()) do
            local it = ((impl.object or {}).typeName or ""):lower()
            if it:find("bucket") or it:find("loader") or
               it:find("grapple") or it:find("fork") then
                return v
            end
        end
    end
    return nil
end

-- Returns fill information for vehicle v as a table:
--   { total, cap, fillType, name, pct }
-- Uses the public spec_fillUnit API when available; falls
-- back to iterating the raw fillUnits table for modded vehicles
-- that do not expose the standard accessor methods.
--   v:getNumFillUnits()         → count of fill units
--   v:getFillUnitFillLevel(i)   → current litres for unit i
--   v:getFillUnitCapacity(i)    → max litres for unit i
--   v:getFillUnitFillType(i)    → fill type index for unit i
function FarmTabletSystem:_getBucketFillInfo(v)
    local info = { total=0, cap=0, fillType=nil, name="Empty", pct=0 }
    if not v then return info end

    -- Prefer the public spec API if available
    if v.getNumFillUnits then
        for i = 1, v:getNumFillUnits() do
            local level = v:getFillUnitFillLevel(i) or 0
            local cap   = v:getFillUnitCapacity(i)  or 0
            info.cap   = info.cap   + cap
            info.total = info.total + level
            if level > 0 and v.getFillUnitFillType then
                info.fillType = v:getFillUnitFillType(i)
            end
        end
    elseif v.spec_fillUnit then
        -- Fallback: iterate raw fillUnits table
        for _, fu in ipairs(v.spec_fillUnit.fillUnits or {}) do
            info.cap   = info.cap   + (fu.capacity  or 0)
            info.total = info.total + (fu.fillLevel  or 0)
            if (fu.fillLevel or 0) > 0 then
                info.fillType = fu.fillType or FillType.UNKNOWN
            end
        end
    end

    if info.cap > 0 then
        info.pct = info.total / info.cap * 100
    end
    if info.fillType and g_fillTypeManager then
        local ft2 = g_fillTypeManager:getFillTypeByIndex(info.fillType)
        if ft2 then info.name = _ftSystemLocalizedFillName(ft2, "Unknown") end
    end
    return info
end

-- Density table: kg per litre for common fill types (approximate).
-- Intentionally lazy — resolved at call time so FillType constants are
-- guaranteed to be populated by the time the first bucket fill happens.
local DENSITY_MAP = nil
local function getDensities()
    if DENSITY_MAP then return DENSITY_MAP end
    -- Only build once FillType global is available (after mission load)
    if not FillType then return {} end
    DENSITY_MAP = {
        [FillType.DIRT   or 0] = 1.5,
        [FillType.STONES or 0] = 1.8,
        [FillType.GRAVEL or 0] = 1.7,
        [FillType.SAND   or 0] = 1.6,
        [FillType.SOIL   or 0] = 1.4,
    }
    -- Remove the zero-key fallback entry if it was inserted (UNKNOWN / unresolved type)
    DENSITY_MAP[0] = nil
    return DENSITY_MAP
end

function FarmTabletSystem:_estimateWeight(litres, fillType)
    local density = getDensities()[fillType or 0] or 1.0
    return litres * density
end

function FarmTabletSystem:_updateBucket()
    local v = self:_getBucketVehicle()
    self.bucket.vehicle = v
    if not v then return end

    local fi      = self:_getBucketFillInfo(v)
    local current = fi.total

    -- Detect a dump (fill level drops by more than 50 L)
    if self.bucket.lastFill > 50 and current < self.bucket.lastFill - 50 then
        local weight = self:_estimateWeight(self.bucket.lastFill, fi.fillType)
        self.bucket.totalLoads  = self.bucket.totalLoads  + 1
        self.bucket.totalWeight = self.bucket.totalWeight + weight

        local entry = {
            n        = self.bucket.totalLoads,
            typeName = fi.name,
            litres   = self.bucket.lastFill,
            weight   = weight,
        }
        table.insert(self.bucket.history, entry)
        if #self.bucket.history > 20 then
            table.remove(self.bucket.history, 1)
        end
    end

    self.bucket.lastFill = current
    self.bucket.lastType = fi.fillType
end

function FarmTabletSystem:resetBucket()
    self.bucket.history     = {}
    self.bucket.totalLoads  = 0
    self.bucket.totalWeight = 0
    self.bucket.lastFill    = 0
    self.bucket.lastType    = nil
end

-- ── Logging ───────────────────────────────────────────────

function FarmTabletSystem:log(msg, ...)
    if self.settings and self.settings.debugMode then
        Logging.info("[FarmTablet System] " .. string.format(msg, ...))
    end
end
