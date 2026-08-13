-- =========================================================
-- FS25_FarmTablet - MasterHUD bridge
-- =========================================================
-- Optional bridge to FS25_MasterHUD. FarmTablet ships standalone (it renders as an
-- engine drawable), so this is delegate-when-present:
--
--   * MasterHUD installed -> FarmTablet subscribes as a self-draw with an
--     `isFullscreen` claim. While the tablet is open it owns the WHOLE screen, so
--     MasterHUD stands every other companion's HUD down (Income, Tax, RWE, Soil,
--     ...). A panel background is an overlay, and an overlay does not cover text
--     that was already rendered underneath it, so the others have to not draw.
--     This is the same contract SoilFertilizer's settings panel declared (its
--     `isFullscreen`), applied to the tablet's full-screen surface.
--   * MasterHUD absent -> FarmTablet keeps its engine drawable, exactly as before.
--
-- While MasterHUD is active the tablet does NOT add itself as an engine drawable
-- (see FarmTabletUI:openTablet/closeTablet): MasterHUD's loop draws it when it
-- claims the screen, so the tablet renders once, not twice.
-- =========================================================

FTMasterHUDBridge = {}

FTMasterHUDBridge.active = false   -- MasterHUD present and we subscribed

--- Register the tablet with MasterHUD. Called once at loadMission00Finished, after
--- the UI instance exists. Idempotent.
---@param ui table the FarmTabletUI instance (farmTabletManager.ui)
function FTMasterHUDBridge.register(ui)
    if ui == nil or FTMasterHUDBridge.active then return end
    local hud = (g_currentMission ~= nil and g_currentMission.masterHUD) or g_masterHUD
    if hud == nil or hud.subscribe == nil then return end

    local ok, err = pcall(function()
        hud:subscribe("FarmTablet_UI", {
            -- MasterHUD calls this every frame; draw only while the tablet is open.
            -- When the tablet claims the screen, MasterHUD's loop calls ONLY this
            -- draw, so the tablet renders once in the right layer.
            draw = function()
                if ui.isOpen then ui:draw() end
            end,
            -- Declares that the tablet owns the whole screen while open, so every
            -- other companion HUD stands down. Optional on MasterHUD's side, so an
            -- older MasterHUD simply ignores it and behaves exactly as before.
            isFullscreen = function()
                return ui.isOpen == true
            end,
        })
    end)

    if ok then
        FTMasterHUDBridge.active = true
        Logging.info("[FarmTablet] registered with MasterHUD (fullscreen claim while open)")
    else
        Logging.warning("[FarmTablet] MasterHUD registration failed: %s (using own drawable)", tostring(err))
    end
end
