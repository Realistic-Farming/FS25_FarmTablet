---@class InputHandler
InputHandler = {}
local InputHandler_mt = Class(InputHandler)

function InputHandler.new(tabletManager)
    local self = setmetatable({}, InputHandler_mt)
    self.tabletManager = tabletManager
    self.wasPressed    = false
    return self
end

function InputHandler:update(dt)
    local isPressed = Input.isKeyPressed(Input.KEY_t)
    if isPressed and not self.wasPressed then
        self.tabletManager:toggleTablet()
    end
    self.wasPressed = isPressed
end

function InputHandler:getKeybindString()
    return "T"
end
