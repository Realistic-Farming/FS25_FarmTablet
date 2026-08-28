-- =========================================================
-- FarmAdminActionEvent
--
-- Admin-authorised client -> server request for the Farm Admin app's
-- server-side mutations (money, time scale, skip-to-hour, repair, fuel).
--
-- On a dedicated server the server is a separate headless process, so no client
-- (not even the admin) satisfies getIsServer(). The old app gated every mutation
-- on getIsServer() and so did nothing for anyone on a dedi, including the admin
-- (#139). An admin client now sends this event; the server validates the sender
-- is a master user and performs the mutation. The results (balance, clock,
-- vehicle state) are server-authoritative and sync back through the game's own
-- paths, so there is no broadcast-back to do.
-- =========================================================

FarmAdminActionEvent = FarmAdminActionEvent or {}
local FarmAdminActionEvent_mt = Class(FarmAdminActionEvent, Event)

InitEventClass(FarmAdminActionEvent, "FarmAdminActionEvent")

function FarmAdminActionEvent.emptyNew()
    return Event.new(FarmAdminActionEvent_mt)
end

function FarmAdminActionEvent.new(actionId, param, farmId)
    local self = FarmAdminActionEvent.emptyNew()
    self.actionId = actionId or 0
    self.param    = param or 0
    self.farmId   = farmId or 0
    return self
end

function FarmAdminActionEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.actionId)
    streamWriteInt32(streamId, self.param)
    streamWriteInt32(streamId, self.farmId)
end

function FarmAdminActionEvent:readStream(streamId, connection)
    self.actionId = streamReadUInt8(streamId)
    self.param    = streamReadInt32(streamId)
    self.farmId   = streamReadInt32(streamId)
    self:run(connection)
end

function FarmAdminActionEvent:run(connection)
    -- Server authority only. This event is never sent to clients; if one somehow
    -- receives it, ignore it.
    if g_server == nil then return end

    -- The event only ever arrives from a client connection. Require the sender to
    -- be an authenticated admin (master user) - otherwise any client could hand
    -- itself free money or seize control of the clock.
    if not connection:getIsServer() then
        local user = g_currentMission ~= nil and g_currentMission.userManager ~= nil
            and g_currentMission.userManager:getUserByConnection(connection) or nil
        if user == nil or not user:getIsMasterUser() then
            if Logging ~= nil and Logging.warning ~= nil then
                Logging.warning(
                    "[FarmTablet] Farm Admin action from a non-admin client denied (actionId=%s)",
                    tostring(self.actionId))
            end
            return
        end
    end

    -- Apply on the server. FarmAdminActions.applyServer lives in FarmAdminApp.lua
    -- (same mod scope); the target farm is passed explicitly because a dedicated
    -- server has no g_localPlayer to read it from.
    if FarmAdminActions ~= nil and FarmAdminActions.applyServer ~= nil then
        FarmAdminActions.applyServer(self.actionId, self.param, self.farmId)
    end
end
