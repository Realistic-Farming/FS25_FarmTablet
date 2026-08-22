-- =========================================================
-- FarmTablet v2 – Focus State API (#84)
-- =========================================================
-- The single authority on the tablet's on-screen focus, exposed cross-mod via
-- g_currentMission.farmTablet so other mods (e.g. WorkerCosts' HireHallCore) can
-- tell WHEN the tablet is showing and WHICH app is active — without polling the
-- render loop every frame.
--
-- The tablet renders through a custom Overlay system (not the FS25 GUI XML stack),
-- so external mods have no native way to introspect it. This is that entry point.
-- It replaces the rejected "EdgeTabContext / browser tab" concept from
-- WorkerCosts #77 with a real, FS25-native focus broadcaster.
--
-- TWO WAYS TO CONSUME (both safe on any peer):
--   * Poll:  g_currentMission.farmTablet.isVisible / .appId   (updated immediately)
--   * Event: FT_EventBus:on(FT_EventBus.EVENTS.TABLET_FOCUS_CHANGED, fn)  -> fn(state)
--
-- "Visible" means EFFECTIVE focus: the tablet is open AND no blocking game GUI
-- (pause menu / dialog) is covering it. Opening the ESC menu therefore reports
-- isVisible=false even though the tablet is still technically open, which is what a
-- consumer drawing its own overlay actually needs.
--
-- App IDs are always the framework's string IDs (e.g. "worker_costs", "dashboard"),
-- never integers or pseudo-URLs.
-- =========================================================
FarmTabletFocus = FarmTabletFocus or {}

-- Shared state table, reused for every broadcast (no per-emit allocation).
FarmTabletFocus._state = { isVisible = false, appId = nil }

-- Mirror fields for cheap direct reads. Kept in lockstep with _state so a poller
-- always sees the live state even if it missed an event broadcast.
FarmTabletFocus.isVisible = false
FarmTabletFocus.appId     = nil

-- Raw inputs from FarmTabletUI (effective visibility is derived from these + GUI).
FarmTabletFocus._open  = false
FarmTabletFocus._appId = nil

-- Rapid app switches are coalesced so external UIs don't thrash. Visibility changes
-- (open / close / ESC / pause) always fire immediately and bypass this.
FarmTabletFocus.EMIT_COOLDOWN = 250   -- ms
FarmTabletFocus._lastEmitAt   = -100000
FarmTabletFocus._pending      = false

local function nowMs()
    return (g_currentMission and g_currentMission.time) or 0
end

-- True when a real FS25 GUI (pause menu, dialog) is up over the tablet. The tablet
-- itself is a custom HUD overlay, not a g_gui screen, so this is false when only the
-- tablet is showing. Same check the edit-mode auto-exit uses.
local function guiBlocked()
    return g_gui ~= nil and (g_gui:getIsGuiVisible() or g_gui:getIsDialogVisible())
end

-- Broadcast the focus-changed event with the shared state table.
function FarmTabletFocus:_emit()
    self._lastEmitAt = nowMs()
    self._pending    = false
    if FT_EventBus and FT_EventBus.EVENTS then
        FT_EventBus:emit(FT_EventBus.EVENTS.TABLET_FOCUS_CHANGED, self._state)
    end
end

-- Recompute effective visibility from the raw open state and whether a blocking GUI
-- covers the tablet, then publish. A visibility change fires immediately; an app
-- switch while already visible is debounced (trailing emit flushed by update()).
function FarmTabletFocus:_apply()
    local effVisible = self._open and not guiBlocked()
    local effAppId   = effVisible and self._appId or nil

    local visChanged = (effVisible ~= self._state.isVisible)
    local appChanged = (effAppId ~= self._state.appId)
    if not visChanged and not appChanged then
        return
    end

    self._state.isVisible = effVisible
    self._state.appId     = effAppId
    self.isVisible        = effVisible
    self.appId            = effAppId

    if visChanged then
        -- Open and (critically) close/ESC/pause must fire at once.
        self:_emit()
    elseif (nowMs() - self._lastEmitAt) >= self.EMIT_COOLDOWN then
        self:_emit()
    else
        self._pending = true
    end
end

--- Update the raw open state. Called by FarmTabletUI on open / close / app switch.
function FarmTabletFocus:setFocus(isOpen, appId)
    self._open  = isOpen == true
    self._appId = self._open and appId or nil
    self:_apply()
end

--- Per-frame tick (driven by FarmTabletManager:update). Re-derives visibility so a
--- pause menu opening/closing over the tablet flips focus, and flushes any debounced
--- app-switch broadcast once the cooldown has elapsed.
function FarmTabletFocus:update()
    self:_apply()
    if self._pending and (nowMs() - self._lastEmitAt) >= self.EMIT_COOLDOWN then
        self:_emit()
    end
end

--- Read-only snapshot. Returns the shared state table — treat as immutable.
function FarmTabletFocus:getState()
    return self._state
end

--- True when the tablet is showing AND `appId` is the active app. The convenience a
--- consumer like the Hire Hall wants: "should I draw my overlay right now?".
function FarmTabletFocus:isAppFocused(appId)
    return self._state.isVisible == true and self._state.appId == appId
end

--- Clear on mission unload so a stale "visible" never leaks into the next session.
function FarmTabletFocus:reset()
    self._open            = false
    self._appId           = nil
    self._state.isVisible = false
    self._state.appId     = nil
    self.isVisible        = false
    self.appId            = nil
    self._pending         = false
    self._lastEmitAt      = -100000
end

getfenv(0)["FarmTabletFocus"] = FarmTabletFocus
