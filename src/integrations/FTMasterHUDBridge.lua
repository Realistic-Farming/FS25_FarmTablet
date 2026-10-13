-- =========================================================
-- FS25_FarmTablet - MasterHUD bridge
-- =========================================================
-- Optional bridge to FS25_MasterHUD. FarmTablet ships standalone (it renders as an
-- engine drawable), so this is delegate-when-present:
--
--   * MasterHUD installed -> FarmTablet subscribes with an `isFullscreen` claim.
--     While the tablet is open it owns the WHOLE screen, so MasterHUD stands every
--     other companion's HUD down (Income, Tax, RWE, Soil, ...). The subscribe draw
--     callback is a NO-OP: the tablet always renders via its own engine drawable,
--     never through MasterHUD's draw loop.
--   * MasterHUD absent -> FarmTablet keeps its engine drawable, exactly as before.
--
-- The tablet is NOT a HUD. It must stay visible when MasterHUD hides suite HUDs.
-- Rendering through MasterHUD's loop would suppress the tablet along with the
-- corner overlays, so the engine drawable is the only draw path. The subscribe
-- exists solely for the isFullscreen claim.
-- =========================================================

FTMasterHUDBridge = FTMasterHUDBridge or {}

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
            -- No-op: the tablet renders via its own engine drawable, not MasterHUD's
            -- draw loop. This keeps the tablet visible when suite HUDs are hidden.
            draw = function() end,
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
