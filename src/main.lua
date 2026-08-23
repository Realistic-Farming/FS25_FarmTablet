-- =========================================================
-- FS25 Farm Tablet  v2.1.0.0  (complete overhaul)
-- Author: TisonK
-- =========================================================
-- Hot-reload latch (FuelCosts reference): g_currentModDirectory and
-- g_currentModName are nil on a live re-source, so they are latched into
-- module globals on first load, with a g_modsDirectory loose-folder fallback.
FarmTabletModDirectory = FarmTabletModDirectory
    or g_currentModDirectory
    or (g_modsDirectory ~= nil and (g_modsDirectory .. "FS25_FarmTablet/") or nil)
FarmTabletModName = FarmTabletModName or g_currentModName or "FS25_FarmTablet"
local modDirectory = FarmTabletModDirectory
local modName = FarmTabletModName

-- Core
source(modDirectory .. "src/core/Constants.lua")
source(modDirectory .. "src/core/EventBus.lua")
source(modDirectory .. "src/core/FarmTabletFocus.lua")
source(modDirectory .. "src/core/FarmTabletModal.lua")
source(modDirectory .. "src/core/AppRegistry.lua")
source(modDirectory .. "src/events/FarmTabletForceRepairEvent.lua")

-- Settings
source(modDirectory .. "src/settings/SettingsManager.lua")
source(modDirectory .. "src/settings/Settings.lua")
source(modDirectory .. "src/settings/SettingsGUI.lua")
source(modDirectory .. "src/settings/SettingsUI.lua")

-- Utils
source(modDirectory .. "src/utils/UIHelper.lua")
source(modDirectory .. "src/utils/InputHandler.lua")
source(modDirectory .. "src/utils/FunctionHooks.lua")
source(modDirectory .. "src/utils/Renderer.lua")
source(modDirectory .. "src/utils/DataProvider.lua")
source(modDirectory .. "src/ui/Icons.lua")

-- Data managers
source(modDirectory .. "src/InvoiceManager.lua")

-- System & UI
source(modDirectory .. "src/FarmTabletSystem.lua")
source(modDirectory .. "src/FarmTabletUI.lua")
source(modDirectory .. "src/ui/HomeScreen.lua")
source(modDirectory .. "src/ui/LockScreen.lua")
source(modDirectory .. "src/FarmTabletUIEditMode.lua")
source(modDirectory .. "src/FarmTabletManager.lua")
source(modDirectory .. "src/integrations/FTMasterHUDBridge.lua")

-- Built-in Apps
source(modDirectory .. "src/apps/DashboardApp.lua")
source(modDirectory .. "src/apps/AppStoreApp.lua")
source(modDirectory .. "src/apps/SettingsApp.lua")
source(modDirectory .. "src/apps/SystemSettingsApp.lua")
source(modDirectory .. "src/apps/UpdatesApp.lua")
source(modDirectory .. "src/apps/WeatherApp.lua")
source(modDirectory .. "src/apps/WorkshopApp.lua")
source(modDirectory .. "src/apps/FieldStatusApp.lua")
source(modDirectory .. "src/apps/AnimalHusbandryApp.lua")
source(modDirectory .. "src/apps/DairyApp.lua")
source(modDirectory .. "src/apps/ExcavatorApp.lua")
source(modDirectory .. "src/apps/DiggingApp.lua")          -- legacy stub (id redirect)
source(modDirectory .. "src/apps/BucketTrackerApp.lua")    -- legacy stub (id redirect)
source(modDirectory .. "src/apps/StorageApp.lua")
source(modDirectory .. "src/apps/IncomeApp.lua")
source(modDirectory .. "src/apps/TaxApp.lua")
source(modDirectory .. "src/apps/NPCFavorApp.lua")
source(modDirectory .. "src/apps/SeasonalCropStressApp.lua")
source(modDirectory .. "src/apps/IrrigationSuiteApp.lua")
source(modDirectory .. "src/apps/SoilNutrientApp.lua")
source(modDirectory .. "src/apps/SoilFertilizerApp.lua")
source(modDirectory .. "src/apps/RotationPlannerApp.lua")
source(modDirectory .. "src/apps/OrganicApp.lua")
source(modDirectory .. "src/apps/MarketDynamicsApp.lua")
source(modDirectory .. "src/apps/WorkerCostsApp.lua")
source(modDirectory .. "src/apps/PersonnelApp.lua")
source(modDirectory .. "src/apps/ProStaffApp.lua")
source(modDirectory .. "src/apps/RandomWorldEventsApp.lua")
source(modDirectory .. "src/apps/UsedPlusApp.lua")
source(modDirectory .. "src/apps/RoleplayPhoneApp.lua")
source(modDirectory .. "src/apps/TimeControlsApp.lua")
source(modDirectory .. "src/apps/HotspotManagerApp.lua")
source(modDirectory .. "src/apps/NotesApp.lua")
source(modDirectory .. "src/apps/FarmAdminApp.lua")
source(modDirectory .. "src/apps/FieldJobsApp.lua")
source(modDirectory .. "src/apps/ContractsApp.lua")
source(modDirectory .. "src/apps/FleetManagerApp.lua")
source(modDirectory .. "src/apps/ProductionBuildingsApp.lua")
source(modDirectory .. "src/apps/FarmStatsApp.lua")
source(modDirectory .. "src/apps/FinancialCockpitApp.lua")
source(modDirectory .. "src/apps/AkitaTabletIntegrationsApp.lua")

local farmTabletManager

local function isEnabled()
    return farmTabletManager ~= nil
end

local function loadedMission(mission, node)
    if not isEnabled() then return end
    if mission.cancelLoading then return end
    farmTabletManager:onMissionLoaded()
    -- MasterHUD claim (delegate-when-present): while the tablet is open it owns the
    -- whole screen, so every other companion HUD stands down.
    if FTMasterHUDBridge ~= nil then
        FTMasterHUDBridge.register(farmTabletManager.ui)
    end
end

local function load(mission)
    -- Farm Tablet is a client-side HUD mod — it must not run on dedicated servers.
    -- A dedicated server has no local player, no GUI, no keyboard and no rendering.
    -- g_dedicatedServer is set by the engine before Mission00.load fires.
    if g_dedicatedServer then
        Logging.info("[FarmTablet v2] Dedicated server detected – skipping initialisation.")
        return
    end

    if farmTabletManager == nil then
        Logging.info("[FarmTablet v2] Initializing...")
        farmTabletManager = FarmTabletManager.new(mission, modDirectory, modName)
        getfenv(0)["g_FarmTablet"] = farmTabletManager
        Logging.info("[FarmTablet v2] Ready.")
    end
end

local function unload()
    if farmTabletManager ~= nil then
        farmTabletManager:delete()
        farmTabletManager = nil
        getfenv(0)["g_FarmTablet"] = nil
    end
end


-- ---------------------------------------------------------
-- BUILD 10:50: the tablet's toggle, as a real binding
-- ---------------------------------------------------------
-- Registered from the game's own player-action rebuild rather than once at
-- startup. PlayerInputComponent:registerActionEvents runs every time the player
-- context is (re)built, so a one-shot registration would be silently dropped the
-- first time that happens and the tablet would stop answering. Same path
-- FS25_FertilizerDepot uses.
local _ftPlayerInputWrapped = false

local function wrapPlayerInput()
    if _ftPlayerInputWrapped then
        return
    end
    if PlayerInputComponent == nil or PlayerInputComponent.registerActionEvents == nil then
        return
    end

    _ftPlayerInputWrapped = true
    local origRegister = PlayerInputComponent.registerActionEvents

    PlayerInputComponent.registerActionEvents = function(inputComp, ...)
        origRegister(inputComp, ...)

        -- The owning player only. Networked players must not register a local
        -- keyboard action.
        if not (inputComp ~= nil and inputComp.player ~= nil and inputComp.player.isOwner) then
            return
        end

        local handler = farmTabletManager ~= nil and farmTabletManager.inputHandler or nil
        if handler == nil then
            return
        end

        -- The context was just rebuilt, so any id from the previous one is stale.
        handler:forgetRegistration()

        g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
        local ok, err = pcall(handler.register, handler)
        g_inputBinding:endActionEventsModification()

        if not ok then
            Logging.warning("[FarmTablet v2] toggle action registration failed: %s", tostring(err))
        end
    end
end

Mission00.load                  = Utils.prependedFunction(Mission00.load, load)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, wrapPlayerInput)

-- ---------------------------------------------------------
-- Realistic Farming Control Center: publish a runnable delegate.
-- Reached through g_currentMission because that is the only channel that
-- carries live between mod environments. Registered from
-- loadMission00Finished, by which point SettingsHub has published the registry
-- during its own Mission00.load.
-- ---------------------------------------------------------
local function registerControlCenterActions()
    local registry = g_currentMission ~= nil and g_currentMission.rfActionRegistry or nil
    if registry == nil or farmTabletManager == nil then return end

    registry.registerAction({
        action = "FT_TOGGLE_TABLET",
        button = "Open",
        -- The tablet is a fullscreen surface, so the Control Center steps aside.
        closeFirst = true,
        run        = function() farmTabletManager:toggleTablet() end,
    })
end

Mission00.loadMission00Finished = Utils.appendedFunction(
    Mission00.loadMission00Finished, registerControlCenterActions)
FSBaseMission.delete            = Utils.appendedFunction(FSBaseMission.delete, unload)

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(mission, dt)
    if farmTabletManager then farmTabletManager:update(dt) end
end)

-- BUILD 15:39 (PB-02) / BUILD 19:05 (PB-03). Escape is a raw key, not a
-- rebindable action, so it does not arrive through an InputAction and has to be
-- read here. The signature is the engine's keyEvent contract
-- (unicode, sym, modifier, isDown).
--
-- WHY THIS IS NOT Utils.appendedFunction
--   A wrapper is the only form that can decide whether the base body sees the
--   key at all, which is what "the tablet has this press" has to mean. It is the
--   same form the repo already uses for `g_currentMission.mouseEvent`.
--
-- WHAT THIS HOOK IS AND IS NOT FOR (BUILD 06:33, Vera 8b FAILFIX)
--   It is NOT what keeps the pause menu shut. `FSBaseMission.keyEvent` does not
--   open the pause menu and, like `mouseEvent`, ignores what its listeners
--   return; pause is `InputAction.MENU` -> `PlayerInputComponent:onInputToggleMenu`
--   -> `g_gui:changeScreen(nil, InGameMenu)`. That action is stood down by the
--   FT_TABLET_MODAL input context, which is now claimed before the tablet's
--   first paint, plus the one-frame deferred revert in FarmTabletModal.release
--   so the press that closes the tablet cannot also reach the base menu.
--
--   What this hook IS for: Escape is a raw key, not a rebindable action, so a
--   keyboard press does not arrive as an InputAction at all and the ladder would
--   otherwise be unreachable without a pad. It runs the ladder and keeps the key
--   from travelling any further.
--
--   The diversion is as narrow as it can be. `FarmTabletModal.onKeyEvent`
--   returns true only while the tablet holds the input claim AND the key is
--   Escape; every other key, and every key at all while the tablet is shut,
--   returns false and reaches the base body untouched. It goes through
--   `requestStepBack`, so if the MENU_BACK action event has already spent this
--   press (Wizard's bindings put MENU_BACK on KEY_esc too) the key is still
--   consumed here but no second ladder step is taken.
if FSBaseMission.keyEvent ~= nil then
    local ftPrevKeyEvent = FSBaseMission.keyEvent

    FSBaseMission.keyEvent = function(mission, unicode, sym, modifier, isDown)
        if FarmTabletModal ~= nil then
            local ok, consumed = pcall(FarmTabletModal.onKeyEvent, unicode, sym, modifier, isDown)
            if not ok then
                -- A throw in the tablet must never cost the player their Escape
                -- key. Log it and fall through to the base handler.
                Logging.warning("[FarmTablet v2] key hook failed: %s", tostring(consumed))
            elseif consumed == true then
                return true
            end
        end

        return ftPrevKeyEvent(mission, unicode, sym, modifier, isDown)
    end
end

Logging.info("[FarmTablet v2] Module loaded.")
