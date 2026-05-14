-- =========================================================
-- FarmTablet v2 – InputHandler
-- Uses the FS25 standard input binding system.
-- =========================================================
---@class InputHandler
InputHandler = {}
local InputHandler_mt = Class(InputHandler)

function InputHandler.new(tabletManager)
    local self = setmetatable({}, InputHandler_mt)
    self.tabletManager = tabletManager
    self.actionEventId = nil
    return self
end

function InputHandler:registerKeyBinding()
    -- Clear any existing registration just in case
    self:unregisterKeyBinding()
    
    local _, eventId = g_inputBinding:registerActionEvent(
        'FT_TOGGLE_TABLET', 
        self, 
        self.onToggleAction, 
        false, -- triggerUp
        true,  -- triggerDown
        false, -- triggerAlways
        true   -- startActive
    )
    
    if eventId then
        self.actionEventId = eventId
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        
        -- Set active status (always active)
        g_inputBinding:setActionEventActive(eventId, true)
        
        self.tabletManager:log("Tablet keybind registered via inputBinding system (action: FT_TOGGLE_TABLET)")
    else
        self.tabletManager:log("Failed to register input binding for FT_TOGGLE_TABLET")
    end
end

function InputHandler:onToggleAction(actionName, inputValue)
    if actionName == "FT_TOGGLE_TABLET" then
        self.tabletManager:toggleTablet()
    end
end

function InputHandler:update(dt)
    -- Nothing to update manually, standard input binding handles polling
end

function InputHandler:getKeybindString()
    -- Fallback to the settings keybind if the input binding lookup fails
    local defaultKey = self.tabletManager.settings.tabletKeybind or "T"
    return defaultKey
end

function InputHandler:unregisterKeyBinding()
    if self.actionEventId ~= nil then
        g_inputBinding:removeActionEvent(self.actionEventId)
        self.actionEventId = nil
        self.tabletManager:log("Input handler cleaned up")
    end
end
