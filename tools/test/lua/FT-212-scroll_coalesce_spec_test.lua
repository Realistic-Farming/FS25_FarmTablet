--!load: src/core/Constants.lua, src/utils/Renderer.lua, src/FarmTabletUI.lua
-- #212 (MarkusVII): fast wheel scrolling rebuilt the app page on every notch. Each notch ran
-- _applyContentScroll -> _redrawScrolledContent, which cleared the app layer and called
-- _drawContent, which cleared it again and reran the drawer; a burst of notches rebuilt the page
-- many times before one frame was drawn.
--   * a notch now only moves the scroll position and marks the page dirty;
--   * the frame's update redraws once (FarmTabletUI:_flushContentScroll), however many notches came;
--   * a click redraws first, so the buttons are where the content now is;
--   * one redraw clears the layer once.
--
-- THE ENTRY-POINT BAR. The wheel and the click enter through the real FarmTabletUI:_onMouse, the
-- frame through the real FarmTabletUI:update, and the page through FarmTabletUI:_drawContent with a
-- drawer registered by the real registerDrawer. The tablet object is a recorder over the real
-- FarmTabletUI methods: only the subsystems update reaches on the way (signal, repair, battery,
-- charge, edit mode) are stubbed, and the renderer records its clears.

local function group(name, fn)
    local ok, err = pcall(fn)
    if not ok then T.ok(name .. " [group crashed]", false, tostring(err)) end
end

Input = Input or {}
Input.MOUSE_BUTTON_WHEEL_UP, Input.MOUSE_BUTTON_WHEEL_DOWN = 4, 5
Input.isMouseButtonPressed = function() return false end
FarmTabletModal = nil

local APP = "FT212_TEST_APP"
local STEP, MAX = 10, 500
-- The drawer: one button whose height on screen follows the scroll, as a scrolled row's does.
local DRAWS = {}
FarmTabletUI:registerDrawer(APP, function(ui)
    DRAWS[#DRAWS + 1] = ui._contentScrollY
    ui._contentBtns[#ui._contentBtns + 1] = { x = 0.10, y = 0.60 + ui._contentScrollY / 1000, w = 0.20, h = 0.02,
                                               meta = { onClick = function() ui.clicks = ui.clicks + 1 end } }
end)

--- An open tablet on the test app, with the page drawn once (as opening it does).
local function tablet()
    FT.LAYOUT.contentX, FT.LAYOUT.contentY, FT.LAYOUT.contentW, FT.LAYOUT.contentH = 0, 0, 1, 1
    local ui = setmetatable({ isOpen = true, uiState = "app", system = { currentApp = APP }, _contentBtns = {},
                              _contentScrollY = 0, _contentScrollTarget = 0, _contentScrollMax = MAX, _contentScrollStep = STEP,
                              _clockTimer = 0, _contentTimer = 0, clicks = 0, clears = 0 }, { __index = FarmTabletUI })
    ui.r = { clearAppLayer = function() ui.clears = ui.clears + 1 end }
    function ui:_updateSignalSystem() return false end
    function ui:_updateTabletRepairSystem() return false end
    function ui:_updateTabletRepairUsage() return false end
    function ui:_evalPhysicalCharge() end
    function ui:_updateEditMode() end
    function ui:_updateBatterySystem() return false end
    function ui:_refreshStatusBar() end
    function ui:_rebuildScreen() end
    function ui:playUISound() end
    ui:_drawContent()
    DRAWS, ui.clears = {}, 0
    return ui
end
local function wheel(ui, dir, n)
    for _ = 1, n do ui:_onMouse(0.5, 0.5, true, false, dir > 0 and Input.MOUSE_BUTTON_WHEEL_DOWN or Input.MOUSE_BUTTON_WHEEL_UP) end
end
local function frame(ui) ui:update(16) end
local function draws() return #DRAWS .. "@" .. table.concat(DRAWS, ",") end

group("W", function()
    local ui = tablet()
    wheel(ui, 1, 5)
    T.eq("W1 [entry point] five wheel notches in one frame move the page five steps and draw nothing yet",
        ui._contentScrollY .. "/" .. draws() .. "/" .. ui.clears, "50/0@/0")
    frame(ui)
    T.eq("W2 NAMED: the frame draws the page once, at the new position, clearing the layer once",
        draws() .. "/" .. ui.clears, "1@50/1")
    frame(ui)
    T.eq("W3 a frame with no new notch draws nothing more", draws() .. "/" .. ui.clears, "1@50/1")
end)

group("C", function()
    local ui = tablet()
    wheel(ui, 1, 2)
    -- The button follows the scroll: at 20 it sits at y 0.62..0.64; it was at 0.60..0.62 before.
    ui:_onMouse(0.15, 0.63, true, false, 1)
    T.eq("C1 NAMED: a click right after the wheel draws the page first and hits the button where it now is",
        draws() .. "/" .. ui.clicks, "2@20,20/1")
    local ui2 = tablet()
    wheel(ui2, 1, 2)
    ui2:_onMouse(0.15, 0.605, true, false, 1)
    T.eq("C2 a click on the button's old place, after the wheel moved it, misses", tostring(ui2.clicks), "0")
end)

group("B", function()
    local ui = tablet()
    wheel(ui, -1, 3)
    frame(ui)
    T.eq("B1 at the top, notches up move nothing and draw nothing", ui._contentScrollY .. "/" .. draws(), "0/0@")
    wheel(ui, 1, 60)
    frame(ui)
    T.eq("B2 a long burst stops at the bottom and draws once", ui._contentScrollY .. "/" .. draws(), MAX .. "/1@" .. MAX)
end)

group("R", function()
    local ui = tablet()
    wheel(ui, 1, 1)
    ui:_drawContent()           -- the 4-second content refresh draws the page itself
    frame(ui)
    T.eq("R1 NAMED: a full draw meets a pending scroll, so the next frame does not draw it again",
        draws() .. "/" .. ui.clears, "1@10/1")
    local ui2 = tablet()
    wheel(ui2, 1, 1)
    ui2.isOpen = false
    T.eq("R2 a closed tablet does not draw a pending scroll", tostring(ui2:_flushContentScroll()) .. "/" .. draws(), "false/0@")
end)
