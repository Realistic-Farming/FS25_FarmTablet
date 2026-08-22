---@class InputHandler
--- The tablet used to open on a raw keyboard scan of the T key, read every frame
--- from the manager's update. That is not a binding: it could not be rebound, it
--- never appeared in Controls, and it fired whatever else T was doing, which on
--- this map is chat plus two other mods. It now goes through a real InputAction
--- registered in the player context, which the game binds, lists and lets the
--- player change.
---
--- The old scan symbols are deliberately not quoted anywhere in this file, so a
--- plain search for them across the packed mod comes back empty.
InputHandler = InputHandler or {}
local InputHandler_mt = Class(InputHandler)

--- Must match the <action name=...> in modDesc.xml.
InputHandler.ACTION_NAME = "FT_TOGGLE_TABLET"

--- Label of last resort, used only when the engine offers no way to ask what the
--- key currently is. Must match the default binding in modDesc.xml.
---
--- BUILD 15:39 (PB-12): Right Ctrl + T, the single locked authority. Must match
--- the binding in modDesc.xml. Never plain T, which is chat, and never an F-key.
InputHandler.DEFAULT_KEY_LABEL = "Right Ctrl + T"

function InputHandler.new(tabletManager)
    local self = setmetatable({}, InputHandler_mt)
    self.tabletManager = tabletManager
    self.eventId = nil
    return self
end

--- Called by the action, not by a key scan.
function InputHandler:onToggleTabletAction()
    if self.tabletManager ~= nil then
        self.tabletManager:toggleTablet()
    end
end

--- Register in the PLAYER context. Called from the PlayerInputComponent wrap in
--- main.lua, which is the point the game itself uses to (re)build player actions,
--- so this survives context rebuilds instead of being registered once and lost.
function InputHandler:register()
    if g_inputBinding == nil or InputAction == nil then
        return false
    end
    if InputAction[InputHandler.ACTION_NAME] == nil then
        Logging.warning("[FarmTablet v2] InputAction.%s is nil - check modDesc <actions>",
            InputHandler.ACTION_NAME)
        return false
    end
    if self.eventId ~= nil then
        return true
    end

    local ok, id = g_inputBinding:registerActionEvent(
        InputAction[InputHandler.ACTION_NAME], self, InputHandler.onToggleTabletAction,
        false, true, false, true)

    if not ok or id == nil then
        -- BUILD 21:53 (PB-H04, George TASK 21:39). The live log carried this warning
        -- twice while Controls still listed the chord, which means both context
        -- rebuilds failed the same way - and the proven cause class for a false
        -- return here is a chord collision with an action already registered in the
        -- context (the suite documented it on KEY_backslash in FS25_MasterHUD's
        -- modDesc). So the failure now names the live chord so the colliding mod can
        -- be found in Controls, and arms ONE deferred retry through update(): the
        -- retry runs outside the rebuild that just failed, wrapped in its own
        -- explicit player-context modification - the same cross-context registration
        -- pattern FS25_MasterHUD uses from the vehicle hook, proven live by Brian's
        -- rebind round trip.
        self._retryPending = true
        Logging.warning(
            "[FarmTablet v2] %s registration failed (live chord: %s). Likely a chord "
            .. "collision with another mod's action in the player context - rebinding "
            .. "Farm Tablet in Controls resolves it. One deferred retry is armed.",
            InputHandler.ACTION_NAME, self:getKeybindString())
        return false
    end
    self._retryPending = false

    self.eventId = id
    -- The tablet is a whole screen, not a context prompt: no help-bar entry.
    if g_inputBinding.setActionEventTextVisibility ~= nil then
        g_inputBinding:setActionEventTextVisibility(id, false)
    end

    -- BUILD 11:20: say so on success as well as on failure. The 10:50 build logged
    -- only failures, so a silent log left "the action never registered" and "the
    -- action registered and the chord never fired" looking identical from outside.
    Logging.info("[FarmTablet v2] %s registered in player context (default %s)",
        InputHandler.ACTION_NAME, InputHandler.DEFAULT_KEY_LABEL)
    return true
end

--- A player context rebuild invalidates the event id, so forget it and let the
--- next register() make a fresh one rather than returning early on a stale id.
function InputHandler:forgetRegistration()
    self.eventId = nil
    -- Fresh context, fresh one-retry allowance (see update).
    self._retryUsed = false
end

--- BUILD 21:53: one deferred retry per failed registration, run from the manager's
--- per-frame update - i.e. OUTSIDE the context rebuild whose registration just
--- failed. Wrapped in an explicit player-context modification session, which is the
--- registration form the suite has proven works outside a rebuild (FS25_MasterHUD
--- re-registers its player actions this way from the vehicle hook). Exactly one
--- retry per failure: if the chord is genuinely taken by another mod, retrying
--- forever would only spam the log, and the Controls rebind is the real cure.
--- Polling the keyboard is still gone - this touches only the action registration.
function InputHandler:update(dt)
    if not self._retryPending or self.eventId ~= nil then
        return
    end
    -- One retry per context rebuild, hard-capped: the failure branch in register()
    -- re-arms _retryPending, so without this guard a persistent collision would
    -- retry (and log) every frame. forgetRegistration() resets the cap when the
    -- engine genuinely rebuilds the context.
    if self._retryUsed then
        self._retryPending = false
        return
    end
    self._retryUsed = true
    self._retryPending = false
    if g_inputBinding == nil or PlayerInputComponent == nil then
        return
    end
    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
    local ok, err = pcall(self.register, self)
    g_inputBinding:endActionEventsModification()
    if ok and self.eventId ~= nil then
        Logging.info("[FarmTablet v2] %s deferred retry succeeded", InputHandler.ACTION_NAME)
    elseif not ok then
        Logging.warning("[FarmTablet v2] %s deferred retry errored: %s",
            InputHandler.ACTION_NAME, tostring(err))
    end
end

--- The key the player would actually press, read live wherever the engine will
--- tell us. No display-name helper for a bound action could be verified against
--- the local reference, so each candidate is tried behind a type check and the
--- shipped default is the fallback. It is never the old hardcoded "T".
function InputHandler:getKeybindString()
    if g_inputBinding ~= nil and InputAction ~= nil
        and InputAction[InputHandler.ACTION_NAME] ~= nil then

        local action = InputAction[InputHandler.ACTION_NAME]
        for _, name in ipairs({ "getDisplayKeyNamesOfDigitalAction", "getDisplayKeyNames" }) do
            if type(g_inputBinding[name]) == "function" then
                local ok, text = pcall(g_inputBinding[name], g_inputBinding, action)
                if ok and type(text) == "string" and text ~= "" then
                    return text
                end
            end
        end
    end

    return InputHandler.DEFAULT_KEY_LABEL
end
