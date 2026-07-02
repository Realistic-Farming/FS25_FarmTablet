-- =========================================================
-- FarmTablet v2 - RandomWorldEventsApp
-- Read-only integration app for FS25_RandomWorldEvents.
-- Reads the cross-mod handle that mod publishes at mission load:
--   g_currentMission.randomWorldEvents   (bridge field)
--   getfenv(0)["g_RandomWorldEvents"]    (same instance, engine global)
-- Soft lookup only: when the mod is missing the app renders an
-- install hint instead of erroring. Display only - no writes.
--
-- Data shapes (verified against FS25_RandomWorldEvents source):
--   mgr.events.enabled / frequency (1-10) / intensity (1-5)
--   mgr.events.<category>Events           boolean toggles
--   mgr.eventCounter                      number of registered event types
--   mgr.EVENT_STATE.activeEvent           event name string or nil
--   mgr.EVENT_STATE.eventStartTime        g_currentMission.time ms
--   mgr.EVENT_STATE.eventDuration         ms
--   mgr.EVENT_STATE.cooldownUntil         g_currentMission.time ms
--   mgr.EVENTS[name].category             "weather".."special"
-- Note: EVENT_STATE.history is declared by the mod but never
-- written, so there is no event history to display yet.
-- =========================================================

-- Category key -> display word (translated via FT.AUTO_L10N word map).
local RWE_CATEGORY_LABEL = {
    weather  = "Weather",
    economic = "Economic",
    vehicle  = "Vehicle",
    field    = "Field",
    wildlife = "Wildlife",
    special  = "Special",
}

-- "field_mice_invasion" -> "Field mice invasion" (same rule as the RWE HUD).
local function rweDisplayName(eventId)
    local displayName = tostring(eventId):gsub("_", " ")
    return displayName:sub(1, 1):upper() .. displayName:sub(2)
end

FarmTabletUI:registerDrawer(FT.APP.RANDOM_EVENTS, function(self)
    local AC = FT.appColor(FT.APP.RANDOM_EVENTS)

    if self:drawHelpPage("_rweHelp", FT.APP.RANDOM_EVENTS, "Random World Events", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays FS25_RandomWorldEvents status:\n" ..
                  "the currently active event, frequency,\n" ..
                  "intensity, and event counter." },
        { title = "ACTIVE EVENT",
          body  = "When an event is running (fire, flood, drought,\n" ..
                  "etc.) it appears here with its name. Events end\n" ..
                  "after a fixed duration." },
        { title = "FREQUENCY / INTENSITY",
          body  = "Frequency (1-10) controls how often events\n" ..
                  "occur. Intensity (1-5) controls how severe\n" ..
                  "their effects are." },
    }) then return end

    local startY = self:drawAppHeader("Random World Events", "Integration")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y   = startY + scrollY
    local mgr = (g_currentMission and g_currentMission.randomWorldEvents)
             or getfenv(0)["g_RandomWorldEvents"]

    if not mgr then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Random World Events is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_RandomWorldEvents to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_rweHelp", AC)
        return
    end

    local evCfg = mgr.events
    local state = mgr.EVENT_STATE

    local enabled   = evCfg and evCfg.enabled or false
    local frequency = (evCfg and evCfg.frequency) or 0
    local intensity = (evCfg and evCfg.intensity) or 0

    y = self:drawSection(y, "STATUS")
    y = self:drawRow(y, "Status", enabled and "Enabled" or "Disabled", nil,
        enabled and FT.C.POSITIVE or FT.C.NEGATIVE)
    y = self:drawRow(y, "Frequency", tostring(frequency) .. " / 10")
    y = self:drawRow(y, "Intensity", tostring(intensity) .. " / 5")
    y = self:drawRow(y, "Event Types", tostring(mgr.eventCounter or 0))

    y = y - FT.py(4)
    y = self:drawSection(y, "CURRENT EVENT")

    local activeId = state and state.activeEvent
    local nowMs    = (g_currentMission and g_currentMission.time) or 0

    if activeId then
        local eventDef = mgr.EVENTS and mgr.EVENTS[activeId]
        local catWord  = eventDef and RWE_CATEGORY_LABEL[eventDef.category or ""]

        -- Remaining time, same math as the mod's own HUD.
        local elapsed  = nowMs - ((state and state.eventStartTime) or 0)
        local duration = (state and state.eventDuration) or 0
        local remMs    = math.max(0, duration - elapsed)
        local remMin   = math.ceil(remMs / 60000)
        local durMin   = math.max(1, math.ceil(duration / 60000))

        y = self:drawRow(y, "Active", rweDisplayName(activeId), nil, FT.C.WARNING)
        if catWord then
            y = self:drawRow(y, "Category", catWord)
        end
        y = self:drawRow(y, "Duration", string.format("%dm / %dm", remMin, durMin))
        y = y + FT.py(FT.SP.ROW) - FT.py(8)
        y = self:drawBar(y, remMin, durMin, FT.C.WARNING)
        y = y - FT.py(6)
    else
        self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
            "No event currently active.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(18)

        local coolUntil = (state and state.cooldownUntil) or 0
        local isReady   = coolUntil == 0 or nowMs >= coolUntil
        if isReady then
            y = self:drawRow(y, "Cooldown", "Ready", nil, FT.C.POSITIVE)
        else
            local coolMin = math.ceil((coolUntil - nowMs) / 60000)
            y = self:drawRow(y, "Cooldown", tostring(coolMin) .. "m", nil, FT.C.TEXT_DIM)
        end
    end

    y = y - FT.py(4)
    y = self:drawSection(y, "EVENT CATEGORIES")

    local cats = {
        { key = "weatherEvents",  label = "Weather"  },
        { key = "economicEvents", label = "Economic" },
        { key = "vehicleEvents",  label = "Vehicle"  },
        { key = "fieldEvents",    label = "Field"    },
        { key = "wildlifeEvents", label = "Wildlife" },
        { key = "specialEvents",  label = "Special"  },
    }
    for _, c in ipairs(cats) do
        local on = evCfg and evCfg[c.key] == true
        y = self:drawRow(y, c.label, on and "On" or "Off", nil,
            on and FT.C.POSITIVE or FT.C.TEXT_DIM)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_rweHelp", AC)
    self:drawScrollBar()
end)
