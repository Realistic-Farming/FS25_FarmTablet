-- =========================================================
-- FarmTablet v2 – FarmTabletManager
-- Top-level coordinator
-- =========================================================
---@class FarmTabletManager
FarmTabletManager = {}
local FarmTabletManager_mt = Class(FarmTabletManager)

function FarmTabletManager.new(mission, modDirectory, modName)
    local self = setmetatable({}, FarmTabletManager_mt)

    self.mission      = mission
    self.modDirectory = modDirectory
    self.modName      = modName

    -- Settings subsystem
    self.settingsManager = SettingsManager.new()
    self.settings        = Settings.new(self.settingsManager)
    self.settings:load()

    -- Invoice manager — always initialised (provides data for RoleplayPhoneApp).
    -- Attached to g_currentMission so FS25_RoleplayPhone can reach it cross-mod.
    self.invoiceManager = FT_InvoiceManager.new()
    mission.ftInvoiceManager = self.invoiceManager

    -- #84 Tablet focus state — the cross-mod accessor other mods read to know when
    -- the tablet is showing and which app is active. getfenv(0)/g_FarmTablet is
    -- per-mod scoped, so the shared global g_currentMission.farmTablet is the only
    -- reliable cross-mod handle. FarmTabletUI drives it; the manager just publishes
    -- the handle and ticks the debounce.
    if FarmTabletFocus then
        FarmTabletFocus:reset()
        mission.farmTablet = FarmTabletFocus
    end

    -- Core systems — FarmTabletSystem is safe on all contexts (pure data).
    -- FarmTabletUI and InputHandler are client-only (rendering + keyboard input).
    self.system = FarmTabletSystem.new(self.settings)
    if mission:getIsClient() then
        self.ui           = FarmTabletUI.new(self.settings, self.system, modDirectory)
        self.inputHandler = InputHandler.new(self)
    end

    -- Settings UI (pause menu injection) — client only
    if mission:getIsClient() and g_gui then
        self.settingsUI = SettingsUI.new(self.settings)
        InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(
            InGameMenuSettingsFrame.onFrameOpen,
            function() self.settingsUI:inject() end
        )
        InGameMenuSettingsFrame.updateButtons = Utils.appendedFunction(
            InGameMenuSettingsFrame.updateButtons,
            function(frame) self.settingsUI:ensureResetButton(frame) end
        )

        -- Help panel sound: play paging sound when the in-game help section opens or closes
        -- InGameMenuHelpFrame is the help/manual page inside the pause menu
        if InGameMenuHelpFrame then
            InGameMenuHelpFrame.onFrameOpen = Utils.appendedFunction(
                InGameMenuHelpFrame.onFrameOpen,
                function()
                    local s = self.settings
                    if s and s.soundEffects and s.soundOnHelpOpen then
                        pcall(function()
                            if g_gui and g_gui.guiSoundPlayer then
                                g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
                            end
                        end)
                    end
                end
            )
            InGameMenuHelpFrame.onFrameClose = Utils.appendedFunction(
                InGameMenuHelpFrame.onFrameClose,
                function()
                    local s = self.settings
                    if s and s.soundEffects and s.soundOnHelpOpen then
                        pcall(function()
                            if g_gui and g_gui.guiSoundPlayer then
                                g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
                            end
                        end)
                    end
                end
            )
        end
    end

    -- Console commands — only register on the local client, not on a remote/server peer.
    -- On a listen-server (host who also plays) getIsClient() is true, so commands appear.
    -- On a pure dedicated server the g_dedicatedServer guard in main.lua prevents us from
    -- ever reaching this constructor, so this check is a secondary safety net.
    if mission:getIsClient() then
        self.settingsGUI = SettingsGUI.new()
        self.settingsGUI:registerConsoleCommands()
    end

    return self
end

function FarmTabletManager:onMissionLoaded()
    -- Load persisted invoices now that savegameDirectory is available
    if self.invoiceManager then
        self.invoiceManager:load()
    end

    self.system:initialize()

    -- Ensure the custom home-screen background folder exists in the savegame so
    -- players have a place to drop their own PNG wallpapers.
    if self.mission:getIsClient() and createFolder
       and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory then
        createFolder(g_currentMission.missionInfo.savegameDirectory .. "/FTBackground")
    end

    -- Suppress vehicle camera zoom (scroll wheel) while the tablet is open.
    -- The mouseEvent handler already returns eventUsed=true for wheel buttons,
    -- but InputAction.CAMERA_ZOOM_IN_OUT is a separate system that ignores that.
    if self.mission:getIsClient() and Enterable and Enterable.actionEventCameraZoomInOut then
        self._origCameraZoom = Enterable.actionEventCameraZoomInOut
        Enterable.actionEventCameraZoomInOut = function(vehicle, actionName, inputValue, ...)
            if g_FarmTablet and g_FarmTablet.ui and g_FarmTablet.ui.isOpen then
                return
            end
            return self._origCameraZoom(vehicle, actionName, inputValue, ...)
        end
    end

    -- Welcome notification: client-only (HUD does not exist on server peers)
    if self.mission:getIsClient() and self.settings.enabled and self.settings.showTabletNotifications then
        local title = string.format("Farm Tablet %s", FT.VERSION or "v2")
        local msg   = string.format(
            (g_i18n and g_i18n:getText("ft_ui_welcome_message")) or "Press %s to open",
            self.inputHandler and self.inputHandler:getKeybindString() or "T"
        )
        self:showNotification(title, msg)
    end
end

function FarmTabletManager:update(dt)
    -- #84 Flush any debounced focus broadcast (ticks regardless of enabled state so a
    -- pending close/switch emit is never stranded).
    if FarmTabletFocus then FarmTabletFocus:update() end
    if not self.settings.enabled then return end
    if self.inputHandler then self.inputHandler:update(dt) end
    if self.system       then self.system:update(dt)      end
    if self.ui           then self.ui:update(dt)          end
end

function FarmTabletManager:openTablet()
    if self.ui then self.ui:openTablet() end
end

function FarmTabletManager:closeTablet()
    if self.ui then self.ui:closeTablet() end
end

function FarmTabletManager:toggleTablet()
    if self.ui then self.ui:toggleTablet() end
end

function FarmTabletManager:switchApp(appId)
    if self.ui then return self.ui:switchApp(appId) end
    return false
end

function FarmTabletManager:showNotification(title, message)
    if not self.mission or not self.settings.showTabletNotifications then return end
    -- HUD only exists on client peers; skip silently on listen-server-only context
    if not self.mission:getIsClient() then return end
    if self.mission.hud and self.mission.hud.showBlinkingWarning then
        self.mission.hud:showBlinkingWarning(title .. ": " .. message, 4000)
    elseif self.mission.addIngameNotification then
        self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, title .. ": " .. message)
    end
end


function FarmTabletManager:delete()
    -- #84 Tear down the cross-mod focus handle so the next session starts clean.
    if FarmTabletFocus then FarmTabletFocus:reset() end
    -- Clear EventBus listeners so a companion's missed :off() cannot leak across reloads.
    if FT_EventBus and FT_EventBus.reset then FT_EventBus:reset() end
    if self.mission then self.mission.farmTablet = nil end
    if self._origCameraZoom then
        Enterable.actionEventCameraZoomInOut = self._origCameraZoom
        self._origCameraZoom = nil
    end
    if self.invoiceManager then self.invoiceManager:save() end
    if self.settings then self.settings:save() end
    if self.system then self.system:delete() end
    if self.ui then self.ui:delete() end
    if self.settingsGUI then self.settingsGUI:unregisterConsoleCommands() end
    Logging.info("[FarmTablet v2] Shutdown complete.")
end

function FarmTabletManager:log(msg, ...)
    if self.settings and self.settings.debugMode then
        Logging.info("[FarmTablet] " .. string.format(msg, ...))
    end
end
