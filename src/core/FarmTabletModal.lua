-- =========================================================
-- FarmTablet v2 - FarmTabletModal  (BUILD 06:33, PB-02 / PB-03 / PB-10)
-- =========================================================
-- BUILD 06:33 addresses the Vera Stage 8b AUDIT FAIL on SUBMIT 19:13. Three
-- things in the previous build were doors that do not open:
--
--   a) The mod mouse listener returned true to "swallow" a drag. `BaseMission`
--      fans mouseEvent out to `g_modEventListeners` and IGNORES what a listener
--      returns, and it passes no `eventUsed` argument, so that return bought
--      nothing and camera look still ran. Mouse look accumulates on its own
--      `accumMouseMovementX/Y` channel in `InputBinding`; what actually stops it
--      is the bound look axes going inactive, which is the input context below,
--      with the per-frame `setRotation` snap in `FarmTabletUI:update` as a belt.
--   b) The claim was taken one frame AFTER the first paint. `InputAction.MENU`
--      -> `onInputToggleMenu` -> `g_gui:changeScreen(nil, InGameMenu)` is the
--      pause door, and it stayed live for that window, so an Escape pressed on
--      the frame the tablet appeared opened the pause menu behind it. The claim
--      is now taken at the end of a fully successful open, before first paint.
--   c) Escape could be spent twice. Wizard's `inputBinding.xml` binds both MENU
--      and MENU_BACK to `KEY_esc`, and the tablet drove `stepBack` from the
--      MENU_BACK action event AND from the raw keyEvent wrapper, so one press
--      walked two levels of the ladder. Both paths now go through
--      `requestStepBack`, which spends at most one level per press.
--

-- The tablet is a HUD drawable, not a g_gui screen, so nothing in the engine
-- stands the world down for it. Before this file the tablet drew on top of a
-- live player: dragging the unlock slider panned the camera, and Escape opened
-- the base pause menu straight over the tablet instead of stepping back through
-- it. Both are the PB-03 stacked-layer trap.
--
-- This module is the single owner of everything the tablet takes from the rest
-- of the game while it is up, and the single place that hands it all back.
--
-- WHAT IS CLAIMED
--   1. Input, via a custom input context. `g_inputBinding:setContext(name, true,
--      false)` opens a NEW (non-sub) context, so every action event registered
--      before it goes inactive: player movement, camera axes, and the base
--      pause/menu open. This is the same mechanism TextInputElement uses so that
--      typing in a text box cannot drive the game, and that Gui:enterMenuContext
--      uses for menu screens. The tablet then re-registers only what it wants
--      inside that context.
--   2. The vanilla HUD, via `g_currentMission.hud:setIsVisible(false)` - the
--      base-game call VehicleCamera uses for its orthographic debug view. That
--      is one switch for the F1 help list, the minimap and the base status HUD
--      (PB-10). It SUPPRESSES, it does not destroy: no HUD state is touched, and
--      the previous visibility is restored verbatim on release.
--   There is no third claim on the raw mouse. The tablet cannot take the mouse
--   stream, because a mod listener cannot consume it (see (a) above); it reads
--   the stream for its own hit tests and leaves it alone otherwise.
--
-- WHEN IT IS CLAIMED
--   At the end of a fully successful open, BEFORE the tablet has painted, so no
--   frame is ever drawn with the player's bound MENU and look axes still live.
--   The safety that the old post-paint timing bought is kept a different way:
--   the claim is the LAST statement of `FarmTabletUI._openTabletBody`, so an
--   open that is refused by the repair/battery gates never reaches it, and an
--   open that throws part way is pcalled by `openTablet` and hands everything
--   back through `_releaseClaims`. `update()` below is still the backstop that
--   force-releases the moment `isOpen` goes false down any path.
--
-- ESCAPE LADDER (PB-02)
--   Escape is a raw key, not a rebindable action, so it arrives through
--   keyEvent(unicode, sym, modifier, isDown) rather than through an InputAction.
--   `onKeyEvent` below returns true when it has spent the press, and main.lua
--   wraps FSBaseMission.keyEvent so that a true answer means the base body is
--   never called for it. One press, one level:
--
--       deep app sub-page -> app root -> Home grid -> tablet closed -> vanilla
--
--   ONE PRESS, ONE DISPATCH. MENU_BACK is registered for gamepads, which have no
--   Escape key, but Wizard's bindings also put MENU_BACK on `KEY_esc`, so on a
--   keyboard the action event and the raw wrapper both fire for the same press.
--   Neither is removed - a pad player needs the action, a keyboard player needs
--   the raw wrapper to consume the key - so both are routed through
--   `requestStepBack`, which spends one level and then ignores every further
--   request for `STEP_GUARD_FRAMES` frames. The guard is frames, not a flag, so
--   it holds whichever of the two paths the engine dispatches first and whether
--   they land in the same frame or in adjacent ones.
--
--   The context revert is deliberately deferred by one frame after the press
--   that closes the tablet, so the same Escape cannot also reach the base menu.
-- =========================================================
FarmTabletModal = FarmTabletModal or {}

FarmTabletModal.CONTEXT_NAME = "FT_TABLET_MODAL"

--- How many frames a spent Escape blocks a second `stepBack`. Two, so the guard
--- survives one frame boundary and still catches the MENU_BACK action event when
--- the engine dispatches it on the frame after the raw key (or the other way
--- round). At 60 fps that is about 33 ms, far below a human double press, so no
--- deliberate second press is ever eaten.
FarmTabletModal.STEP_GUARD_FRAMES = 2

FarmTabletModal._claimed        = false
FarmTabletModal._contextPushed  = false
FarmTabletModal._hudSuppressed  = false
FarmTabletModal._hudWasVisible  = true
FarmTabletModal._pendingRevert  = 0
FarmTabletModal._escDown        = false
FarmTabletModal._stepGuard      = 0
FarmTabletModal._ui             = nil

local function log(fmt, ...)
    if Logging ~= nil and Logging.info ~= nil then
        Logging.info("[FarmTablet v2] " .. fmt, ...)
    end
end

-- ---------------------------------------------------------
-- Vanilla HUD suppression (PB-10)
-- ---------------------------------------------------------

-- Read the current HUD visibility without inventing a getter. `setIsVisible` is
-- the documented base-game call; the matching read is not, so each candidate is
-- type-checked before use and the fallback is "it was visible", which is the
-- state the HUD is in for all but a player who has already hidden it.
local function readHudVisible(hud)
    if type(hud.getIsVisible) == "function" then
        local ok, v = pcall(hud.getIsVisible, hud)
        if ok and type(v) == "boolean" then return v end
    end
    if type(hud.isVisible) == "boolean" then
        return hud.isVisible
    end
    return true
end

local function suppressHud()
    if FarmTabletModal._hudSuppressed then return end
    local hud = g_currentMission ~= nil and g_currentMission.hud or nil
    if hud == nil or type(hud.setIsVisible) ~= "function" then return end

    FarmTabletModal._hudWasVisible = readHudVisible(hud)
    local ok = pcall(hud.setIsVisible, hud, false)
    if ok then
        FarmTabletModal._hudSuppressed = true
    end
end

local function restoreHud()
    if not FarmTabletModal._hudSuppressed then return end
    FarmTabletModal._hudSuppressed = false

    local hud = g_currentMission ~= nil and g_currentMission.hud or nil
    if hud == nil or type(hud.setIsVisible) ~= "function" then return end
    -- Restore exactly what was there, not an assumed "on".
    pcall(hud.setIsVisible, hud, FarmTabletModal._hudWasVisible ~= false)
end

-- ---------------------------------------------------------
-- Input context (PB-03)
-- ---------------------------------------------------------

local function pushContext(ui)
    if FarmTabletModal._contextPushed then return end
    if g_inputBinding == nil or type(g_inputBinding.setContext) ~= "function" then return end

    local ok = pcall(g_inputBinding.setContext, g_inputBinding,
                     FarmTabletModal.CONTEXT_NAME, true, false)
    if not ok then return end
    FarmTabletModal._contextPushed = true

    -- Re-register the tablet's own toggle inside the new context, or the chord
    -- that opened the tablet would be dead while it is up and the player would
    -- have no key to close it with.
    if InputAction ~= nil and InputHandler ~= nil
        and InputAction[InputHandler.ACTION_NAME] ~= nil then
        pcall(function()
            local _, id = g_inputBinding:registerActionEvent(
                InputAction[InputHandler.ACTION_NAME], ui,
                function() ui:toggleTablet() end,
                false, true, false, true)
            if id ~= nil and g_inputBinding.setActionEventTextVisibility ~= nil then
                g_inputBinding:setActionEventTextVisibility(id, false)
            end
        end)
    end

    -- Gamepads have no Escape key: MENU_BACK is the pad's back button and drives
    -- the same one-level-per-press ladder. On a keyboard it is also on KEY_esc,
    -- so it goes through requestStepBack and not straight at stepBack: whichever
    -- of this and the raw key wrapper arrives first spends the press, the other
    -- one finds the guard up and does nothing.
    if InputAction ~= nil and InputAction.MENU_BACK ~= nil then
        pcall(function()
            local _, id = g_inputBinding:registerActionEvent(
                InputAction.MENU_BACK, ui,
                function() FarmTabletModal.requestStepBack(ui) end,
                false, true, false, true)
            if id ~= nil and g_inputBinding.setActionEventTextVisibility ~= nil then
                g_inputBinding:setActionEventTextVisibility(id, false)
            end
        end)
    end
end

local function popContext()
    if not FarmTabletModal._contextPushed then return end
    FarmTabletModal._contextPushed = false
    if g_inputBinding == nil or type(g_inputBinding.revertContext) ~= "function" then return end
    pcall(g_inputBinding.revertContext, g_inputBinding, false)
end

-- ---------------------------------------------------------
-- Claim / release
-- ---------------------------------------------------------

function FarmTabletModal.isClaimed()
    return FarmTabletModal._claimed == true
end

--- Take the world. Called as the last statement of a fully successful
--- `FarmTabletUI._openTabletBody`, before the first paint, so no frame is drawn
--- with the player's MENU and look axes still live. `FarmTabletUI:update` calls
--- it again as a backstop if the open-time claim did not take.
function FarmTabletModal.claim(ui)
    if FarmTabletModal._claimed or ui == nil then return end
    FarmTabletModal._claimed       = true
    FarmTabletModal._ui            = ui
    FarmTabletModal._pendingRevert = 0
    FarmTabletModal._escDown       = false
    FarmTabletModal._stepGuard     = 0
    pushContext(ui)
    suppressHud()
end

--- Hand everything back.
---@param deferContext boolean when true the input context is reverted on the
---       NEXT frame instead of this one, so the Escape press that closed the
---       tablet cannot also be seen by the base pause menu.
function FarmTabletModal.release(deferContext)
    if not FarmTabletModal._claimed then
        -- Already released. Do not touch a revert that is deliberately waiting a
        -- frame (the Escape-closes-the-tablet path releases, then calls
        -- closeTablet, which lands back here); just make sure a half-finished
        -- claim is not left holding anything.
        restoreHud()
        if FarmTabletModal._pendingRevert <= 0 then
            popContext()
        end
        return
    end
    FarmTabletModal._claimed = false
    FarmTabletModal._escDown = false

    restoreHud()

    if deferContext then
        FarmTabletModal._pendingRevert = 1
    else
        FarmTabletModal._pendingRevert = 0
        popContext()
    end
    FarmTabletModal._ui = nil
end

--- Per-frame tick, driven by FarmTabletUI:update. Flushes a deferred context
--- revert, and is the backstop that guarantees a claim can never outlive the
--- tablet being open.
function FarmTabletModal.update(ui)
    -- Ticks even while the tablet is shut: the press that closes it sets the
    -- guard, and the guard has to run down afterwards or the next open would
    -- start with a stale one.
    if FarmTabletModal._stepGuard > 0 then
        FarmTabletModal._stepGuard = FarmTabletModal._stepGuard - 1
    end

    if FarmTabletModal._pendingRevert > 0 then
        FarmTabletModal._pendingRevert = FarmTabletModal._pendingRevert - 1
        if FarmTabletModal._pendingRevert <= 0 then
            popContext()
        end
    end

    if FarmTabletModal._claimed and (ui == nil or ui.isOpen ~= true) then
        FarmTabletModal.release(false)
    end
end

-- ---------------------------------------------------------
-- The ladder (PB-02)
-- ---------------------------------------------------------

--- BUILD 06:33. The ONLY legal way in to the ladder. Both doors that can carry a
--- back press - the MENU_BACK action event (pads, and KEY_esc on Wizard's
--- bindings) and the raw keyEvent wrapper (keyboards) - call this, so a single
--- press walks exactly one level no matter which of them the engine dispatches
--- first, or whether it dispatches both.
---
--- Returns true when the press belongs to the tablet, whether or not this
--- particular call is the one that spent it, so the raw wrapper still consumes
--- the key on the guarded path instead of letting it fall through to the base
--- handler.
function FarmTabletModal.requestStepBack(ui)
    if ui == nil or ui.isOpen ~= true then return false end

    if FarmTabletModal._stepGuard > 0 then
        -- The other door already spent this press.
        return true
    end
    FarmTabletModal._stepGuard = FarmTabletModal.STEP_GUARD_FRAMES

    return FarmTabletModal.stepBack(ui)
end

--- Spend one Escape / MENU_BACK press on exactly one level of the tablet stack.
--- Returns true when the press was consumed. Do not call directly from an input
--- door: go through `requestStepBack` so the one-press-one-level guard applies.
function FarmTabletModal.stepBack(ui)
    if ui == nil or ui.isOpen ~= true then return false end

    local state = ui.uiState

    -- The repair screen is deliberately modal: it closes only through its own
    -- visible button, so Escape is swallowed rather than acted on.
    if state == "repair" then
        return true
    end

    if state == "app" then
        -- goBack pops an in-app sub-page when the app registered a back handler
        -- and is still below its root; otherwise it lands on the Home grid.
        ui:goBack()
        return true
    end

    if state == "home" then
        -- One definition of "is there a level above me": the same predicate that
        -- decides whether the Back glyph draws live or dimmed. Escape and the
        -- Back button therefore always agree about where the root is.
        local _, backOn = ui:_navState()
        if backOn then
            ui:goBack()
            return true
        end
        -- Root: this press closes the tablet. The next one is vanilla's.
        FarmTabletModal.release(true)
        ui:closeTablet()
        return true
    end

    -- lock / provider / empty: one press closes.
    FarmTabletModal.release(true)
    ui:closeTablet()
    return true
end

--- Raw keyboard hook. Escape is not a rebindable action, so it arrives here.
--- Edge-detected so holding the key steps exactly one level.
function FarmTabletModal.onKeyEvent(unicode, sym, modifier, isDown)
    if not FarmTabletModal._claimed then
        FarmTabletModal._escDown = false
        return false
    end
    if Input == nil or Input.KEY_esc == nil or sym ~= Input.KEY_esc then
        return false
    end

    if isDown then
        if FarmTabletModal._escDown then return true end
        FarmTabletModal._escDown = true
        local ui = FarmTabletModal._ui
        local ok, err = pcall(FarmTabletModal.requestStepBack, ui)
        if not ok then
            Logging.warning("[FarmTablet v2] escape step failed, releasing: %s", tostring(err))
            FarmTabletModal.release(false)
            if ui ~= nil and ui.isOpen then pcall(ui.closeTablet, ui) end
        end
        return true
    end

    FarmTabletModal._escDown = false
    return true
end

getfenv(0)["FarmTabletModal"] = FarmTabletModal
