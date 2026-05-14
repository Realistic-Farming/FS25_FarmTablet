-- =========================================================
-- FarmTablet v2 – InputHandler
-- Thin wrapper retained for compatibility. Action event
-- registration is handled by FarmTabletManager via
-- addModEventListener / registerActionEvents.
-- =========================================================
---@class InputHandler
InputHandler = {}
local InputHandler_mt = Class(InputHandler)

function InputHandler.new(tabletManager)
    local self = setmetatable({}, InputHandler_mt)
    self.tabletManager = tabletManager
    return self
end

function InputHandler:update(dt)
end

function InputHandler:getKeybindString()
    return self.tabletManager.settings.tabletKeybind or "T"
end
