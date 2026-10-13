-- scs-irrigation-3d80544.lua - Seasonal Crop Stress's own irrigation read code, copied verbatim for FarmTablet's bench.
--
-- Source: Realistic-Farming/FS25_SeasonalCropStress at 3d8054450645551bd814b1510a1be8d37260a96e (development, 2026-09-26). Every block below is a
-- whole function, byte for byte, marked with its file and line range; the SCS-023 reader rebind's entry-point case
-- (renderer-literal-flag-check.mjs) runs them over a two-farm world held in IrrigationManager's own tables, so the
-- rows the Irrigation Suite reads are built by the host's builder, not written by the bench. When the SCS clone is
-- beside this repo, the case re-reads each range at 3d80544 and fails if a block differs.
IrrigationManager = IrrigationManager or {}
CropStressManager = CropStressManager or {}

-- @@ src/IrrigationManager.lua:1216-1222
function IrrigationManager:getRainKeyState(system)
    if system == nil or system.rainKeyFitted ~= true then return "UNFITTED" end
    if system.rainKeyTripped == true then return "TRIPPED" end
    if system.rainKeyInputState ~= "OK" then return "INPUT_UNAVAILABLE" end
    if system.rainKeyAccumulatedMm and system.rainKeyAccumulatedMm > 0 then return "COLLECTING" end
    return "ARMED"
end

-- @@ src/IrrigationManager.lua:1758-1814
function IrrigationManager:copyIrrigationSystemRow(system, includePrivate)
    local covered = {}
    if system.coveredFields ~= nil then
        for i = 1, #system.coveredFields do covered[i] = system.coveredFields[i] end
    end
    -- Deep-copy the schedule so a reader can never mutate live state.
    local schedule = nil
    if system.schedule ~= nil then
        local days = {}
        if system.schedule.activeDays ~= nil then
            for i = 1, #system.schedule.activeDays do days[i] = system.schedule.activeDays[i] end
        end
        schedule = {
            startHour  = system.schedule.startHour,
            endHour    = system.schedule.endHour,
            activeDays = days,
        }
    end
    local row = {
        id                     = system.id,
        type                   = system.type,
        isActive               = system.isActive == true,
        coveredFields          = covered,
        schedule               = schedule,
        flowRatePerHour        = system.flowRatePerHour,
        operationalCostPerHour = system.operationalCostPerHour,
        -- Rain-key readout + composed activity (RUNNING / RAIN_PAUSED / OFF).
        -- Only fitted pivots carry meaningful rain-key values; unfitted rows keep
        -- neutral defaults so the legacy field shape is preserved.
        rainKeyFitted            = system.rainKeyFitted == true,
        rainKeyTripMm            = system.rainKeyTripMm,
        rainKeyAccumulatedMm     = system.rainKeyAccumulatedMm or 0,
        rainKeyDryElapsedMinutes = system.rainKeyDryElapsedMinutes or 0,
        weatherReadable          = system.rainKeyInputState == "OK",
        rainKeyState             = (self.getRainKeyState and self:getRainKeyState(system))
            or (system.rainKeyFitted == true and "ARMED" or "UNFITTED"),
        rainKeyTripped           = system.rainKeyTripped == true,
        activityState            = system.rainKeyFitted == true
            and (system.rainKeyTripped == true and "RAIN_PAUSED"
                 or (system.isActive == true and "RUNNING" or "OFF"))
            or (system.isActive == true and "RUNNING" or "OFF"),
        pauseReason              = system.rainKeyFitted == true and system.rainKeyTripped == true
            and "RAIN_KEY_TRIPPED"
            or (system.rainKeyFitted == true and system.rainKeyInputState ~= "OK"
                 and "INPUT_UNAVAILABLE" or "NONE"),
        nextWakeKind             = system.rainKeyFitted == true and system.rainKeyTripped == true
            and "DRY_RESET" or "NONE",
        nextWakeGameMinutes      = nil,
        stateRevision            = system.rainKeyStateRevision or 0,
    }
    if includePrivate then
        row.ownerFarmId   = system.ownerFarmId
        row.waterSourceId = system.waterSourceId
        row.stopReason    = self:getSystemStopReason(system)
    end
    return row
end

-- @@ src/IrrigationManager.lua:1819-1830
function IrrigationManager:getIrrigationSystemsRows(farmId)
    local out = {}
    for id, sys in pairs(self.systems) do
        local includePrivate = farmId ~= nil
        if includePrivate and sys.ownerFarmId ~= farmId then
            -- a different farm's system never appears in this farm's copy
        else
            out[#out + 1] = self:copyIrrigationSystemRow(sys, includePrivate)
        end
    end
    return out
end

-- @@ src/IrrigationManager.lua:1490-1496
function IrrigationManager:getSystemStopReason(system)
    if system == nil then return nil end
    local source = self.waterSources[system.waterSourceId]
    if source == nil then return "no_source" end
    if source.finite and not source.hasWater then return "dry_source" end
    return nil
end

-- @@ src/IrrigationManager.lua:1835-1868
function IrrigationManager:getIrrigationWaterSources(farmId)
    local out = {}
    for id, source in pairs(self.waterSources) do
        if farmId == nil or farmId <= 0 or source.farmId == farmId then
            local connected = {}
            for sysId, sys in pairs(self.systems) do
                if sys.waterSourceId == id then connected[#connected + 1] = sysId end
            end
            table.sort(connected)
            local connectedCopy = {}
            for i = 1, #connected do connectedCopy[i] = connected[i] end
            out[#out + 1] = {
                id = id,
                ownerFarmId = source.farmId,
                waterCapacity = source.capacity,
                waterRemaining = source.finite and source.waterRemaining or nil,
                isUnlimited = not source.finite,
                hasWater = source.hasWater == true,
                -- BUILD 07:10: getText on a key absent from l10n returns the truthy
                -- "Missing '...'" string, so an `or` fallback after it never fires.
                -- Ask hasText first, for the key the 26 translation files carry.
                label = (g_i18n ~= nil and g_i18n:hasText("cs_irr_water_source")
                    and g_i18n:getText("cs_irr_water_source")) or "Water source",
                connectedSystemIds = connectedCopy,
                -- legacy aliases for older readers
                capacity = source.capacity,
                unlimited = not source.finite,
                connectedSystems = connectedCopy,
            }
        end
    end
    table.sort(out, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return out
end

-- @@ src/IrrigationManager.lua:1872-1877
function IrrigationManager:applyFarmPrivateSnapshot(farmId, systemRows, sourceRows)
    self._clientFarmSystems[farmId] = systemRows or {}
    self._clientFarmSources[farmId] = sourceRows or {}
    self._clientFarmCurrent[farmId] = true
    return true
end

-- @@ src/IrrigationManager.lua:1880-1886
function IrrigationManager:getCachedFarmSystems(farmId)
    local rows = self._clientFarmSystems[farmId]
    if rows == nil then return nil end
    local out = {}
    for i = 1, #rows do out[i] = rows[i] end
    return out
end

-- @@ src/IrrigationManager.lua:1889-1895
function IrrigationManager:getCachedFarmSources(farmId)
    local rows = self._clientFarmSources[farmId]
    if rows == nil then return nil end
    local out = {}
    for i = 1, #rows do out[i] = rows[i] end
    return out
end

-- @@ src/CropStressManager.lua:1207-1238
function CropStressManager:getIrrigationSystems(farmId)
    local irrMgr = self.irrigationManager
    if irrMgr == nil or irrMgr.systems == nil then return {} end
    -- SCS-023 v2.3 (SDS 8): the farm-scoped public surface. A positive valid
    -- farm is current immediately on the server/listen host; a pure client
    -- returns nil until that farm's complete private snapshot applied. An
    -- invalid, spectator or not-yet-current farm returns nil. farmId nil keeps
    -- the exact legacy all-public field shape for older FarmTablet versions.
    if farmId ~= nil then
        if type(farmId) ~= "number" or farmId <= 0 then return nil end
        if g_server ~= nil then
            if irrMgr.getIrrigationSystemsRows ~= nil then
                return irrMgr:getIrrigationSystemsRows(farmId)
            end
            return nil
        end
        if irrMgr._clientFarmCurrent ~= nil and irrMgr._clientFarmCurrent[farmId] == true
           and irrMgr.getCachedFarmSystems ~= nil then
            return irrMgr:getCachedFarmSystems(farmId)
        end
        return nil
    end
    -- Legacy no-arg public copy: route through the single row builder so the
    -- public list and the farm-scoped private snapshot can never drift again.
    -- includePrivate = false keeps the all-public field shape older FarmTablet
    -- versions expect (no ownerFarmId / waterSourceId / stopReason).
    local out = {}
    for _, sys in pairs(irrMgr.systems) do
        out[#out + 1] = irrMgr:copyIrrigationSystemRow(sys, false)
    end
    return out
end

-- @@ src/CropStressManager.lua:1244-1256
function CropStressManager:getIrrigationWaterSources(farmId)
    local irrMgr = self.irrigationManager
    if irrMgr == nil or irrMgr.getIrrigationWaterSources == nil then return {} end
    if farmId ~= nil and (type(farmId) ~= "number" or farmId <= 0) then return nil end
    if g_server ~= nil or farmId == nil then
        return irrMgr:getIrrigationWaterSources(farmId)
    end
    if irrMgr._clientFarmCurrent ~= nil and irrMgr._clientFarmCurrent[farmId] == true
       and irrMgr.getCachedFarmSources ~= nil then
        return irrMgr:getCachedFarmSources(farmId)
    end
    return nil
end
