-- =========================================================
-- FarmTabletForceRepairEvent
--
-- Force-complete the tablet repair on a dedicated server.
--
-- The tablet display state is client-local (each player's own tablet can break),
-- but the repair fee has to be charged on the server. A client that force-repairs
-- sends this event; the server deducts the fee from the requesting farm and
-- broadcasts the event back; the receiving client then completes its local
-- repair. Every other client no-ops because its own tablet is not in repair.
-- =========================================================

FarmTabletForceRepairEvent = {}
local FarmTabletForceRepairEvent_mt = Class(FarmTabletForceRepairEvent, Event)

InitEventClass(FarmTabletForceRepairEvent, "FarmTabletForceRepairEvent")

function FarmTabletForceRepairEvent.emptyNew()
    local self = Event.new(FarmTabletForceRepairEvent_mt)
    return self
end

function FarmTabletForceRepairEvent.new(farmId)
    local self = FarmTabletForceRepairEvent.emptyNew()
    self.farmId = farmId
    return self
end

function FarmTabletForceRepairEvent:readStream(streamId, connection)
    self.farmId = streamReadInt32(streamId)
    self:run(connection)
end

function FarmTabletForceRepairEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.farmId)
end

function FarmTabletForceRepairEvent:run(connection)
    if g_server ~= nil then
        -- Server authority: charge the fee to the requesting farm, then broadcast
        -- the confirm so the requesting client can complete its local repair.
        local fee = FT ~= nil and FT.FORCE_REPAIR_FEE or 3000
        local ok = false
        pcall(function()
            local farm = g_farmManager ~= nil and g_farmManager:getFarmById(self.farmId) or nil
            if farm ~= nil and farm.changeBalance ~= nil then
                farm:changeBalance(-fee, MoneyType.OTHER)
                if g_currentMission ~= nil and g_currentMission.addMoneyChange ~= nil then
                    g_currentMission:addMoneyChange(-fee, self.farmId, MoneyType.OTHER, true)
                end
                ok = true
            end
        end)
        if ok and g_server.broadcastEvent ~= nil then
            g_server:broadcastEvent(FarmTabletForceRepairEvent.new(self.farmId))
        end
    elseif g_FarmTablet ~= nil and g_FarmTablet.ui ~= nil then
        -- Receiving client: the fee is charged, finish the local repair.
        pcall(function()
            g_FarmTablet.ui:_completeLocalForceRepair()
        end)
    end
end
