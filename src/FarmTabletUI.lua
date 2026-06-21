-- =========================================================
-- FarmTablet v2 – FarmTabletUI  (real-tablet overhaul)
--   • Tablet OS state machine: LOCK → HOME (springboard) → APP
--   • Glossy baked app icons (FT_Icons) on a springboard grid + dock
--   • 3D frame: layered shadow, body gradient, screen gloss, status bar,
--     home indicator, hardware buttons
--   • Tablet behaviour: slide-to-unlock, press-down feedback, launch zoom
--   • All app drawers untouched — they render into FT.LAYOUT.content* which
--     becomes the full screen in APP state.
-- =========================================================
---@class FarmTabletUI
FarmTabletUI = {}
local FarmTabletUI_mt = Class(FarmTabletUI)

-- ── Frame / layout constants (reference px @ FT.REF_W x FT.REF_H) ──
local BEZEL_REF    = 40    -- tablet bezel thickness
local STATUS_H_REF = 28    -- top status bar height
local APPBAR_H_REF = 36    -- in-app top bar height
local DOCK_H_REF   = 78    -- springboard dock height
local HOMEIND_REF  = 10    -- home-indicator strip height

-- ── Dock favourites (always-present built-ins) ───────────
local DOCK_APPS = { "dashboard", "weather", "app_store", "settings" }

-- ── Nav-glyph helpers (#90) ──────────────────────────────
-- The renderer only draws axis-aligned rects, so the Back arrow and Home
-- house are approximated with a short stack of rects. Sizes are passed in
-- already-normalised (the caller converts via FT.px / FT.py).
--
-- NOTE: coordinates are normalised (0..1), so the stacking dimension uses a
-- fractional half-step overlap (step * 1.5) to avoid hairline gaps — never a
-- literal "+1", which would add a full screen width/height.
local GLYPH_STEPS = 6

-- Left-pointing filled triangle: short tip at (tipX, cy), widening to the
-- right over width w and total height h. Used as the Back arrowhead.
local function drawTriLeft(r, tipX, cy, w, h, color)
    local step = w / GLYPH_STEPS
    for i = 0, GLYPH_STEPS - 1 do
        local colH = h * (i + 1) / GLYPH_STEPS
        r:rect(tipX + i * step, cy - colH / 2, step * 1.5, colH, color)
    end
end

-- Up-pointing filled triangle: full-width base at baseY, narrowing to an apex
-- h above it (screen Y increases upward). Used as the Home roof.
local function drawTriUp(r, cx, baseY, w, h, color)
    local step = h / GLYPH_STEPS
    for i = 0, GLYPH_STEPS - 1 do
        local rowW = w * (1 - i / GLYPH_STEPS)
        r:rect(cx - rowW / 2, baseY + i * step, rowW, step * 1.5, color)
    end
end

-- 4-point star / sparkle (the Favourites glyph): four spikes of length `len`
-- and base half-width `halfW`, all sharing the centre (cx, cy). Each spike is
-- a tapering stack of rects, so the four overlap into a solid star core.
local function drawStar(r, cx, cy, len, halfW, color)
    local s = len / GLYPH_STEPS
    for i = 0, GLYPH_STEPS - 1 do
        local hw = halfW * (1 - i / GLYPH_STEPS)   -- taper toward each apex
        r:rect(cx - hw,         cy + i * s,        hw * 2,   s * 1.5, color)  -- up
        r:rect(cx - hw,         cy - i * s - s,    hw * 2,   s * 1.5, color)  -- down
        r:rect(cx + i * s,      cy - hw,           s * 1.5,  hw * 2,  color)  -- right
        r:rect(cx - i * s - s,  cy - hw,           s * 1.5,  hw * 2,  color)  -- left
    end
end

function FarmTabletUI.new(settings, system, modDirectory)
    local self = setmetatable({}, FarmTabletUI_mt)
    self.settings     = settings
    self.system       = system
    self.modDirectory = modDirectory or ""
    self.r        = FT_Renderer.new()
    self.isOpen   = false

    -- Initialise the baked-icon cache for this mod directory.
    if FT_Icons and FT_Icons.init then FT_Icons.init(self.modDirectory) end

    -- Tablet OS state: "lock" | "home" | "app"
    self.uiState  = "home"
    self._page    = 0       -- current springboard page (0-based)
    self._pageCount = 1

    -- Per-frame hover / press tracking
    self._mouseX  = 0
    self._mouseY  = 0
    self._pressedIcon = nil  -- appId currently pressed (for depress feedback)
    self._pressedRect = nil
    self._pressMoved  = false

    -- Named persistent hitboxes
    self._closeBtn    = nil
    self._powerBtn    = nil
    self._homeBtn     = nil
    self._backBtn     = nil
    self._unlockBtn   = nil
    self._iconBtns    = {}   -- springboard grid {appId,x,y,w,h}
    self._dockBtns    = {}   -- dock {appId,x,y,w,h}
    self._pageDots    = {}   -- {x,y,w,h,page}
    self._contentBtns = {}   -- app-specific, cleared per switch
    self._iconQueue   = {}   -- {appId,x,y,size,mono} rendered in draw()
    self._appCellRects = {}  -- appId -> {x,y,w,h} (for launch/home zoom)

    -- Slide-to-unlock state
    self._unlockTrack = nil  -- {x,y,w,h}
    self._unlockKnobX = nil  -- current knob left-x while dragging
    self._unlockDragging = false

    -- Content area scroll state (per-app, reset on app switch)
    self._contentScrollY      = 0
    self._contentScrollMax    = 0
    self._contentScrollStep   = FT.py and FT.py(22) or 0.018

    -- Animation (transient overlay drawn on top of the built screen)
    self._anim    = nil      -- {kind, t, dur, data}
    self._fx      = nil      -- reusable plain-colour overlay for fades/curtains

    -- Battery flavour (drains slowly while open)
    self._battery    = 86
    self._sessionSec = 0

    -- Camera lock while tablet is open (normal mode)
    self._tabletCamRotX = nil
    self._tabletCamRotY = nil
    self._tabletCamRotZ = nil

    -- ── Edit mode (resize/move) — state used by FarmTabletUIEditMode.lua ──
    self._editModeActive  = false
    self._editBgOverlay   = nil
    self._editAnimTimer   = 0
    self._emDragging      = false
    self._emDragOffX      = 0
    self._emDragOffY      = 0
    self._emResizing      = false
    self._emResizeStartX  = 0
    self._emResizeStartY  = 0
    self._emResizeStartS  = 1.0
    self._emHoverCorner   = nil
    self._emEdgeDragging  = nil
    self._emEdgeStartX    = 0
    self._emEdgeStartW    = 1.0
    self._emCamRotX = nil
    self._emCamRotY = nil
    self._emCamRotZ = nil
    self.EM_HANDLE_SIZE  = 0.010
    self.EM_MIN_SCALE    = 0.5
    self.EM_MAX_SCALE    = 2.0
    self.EM_MIN_WIDTH    = 0.5
    self.EM_MAX_WIDTH    = 2.0

    return self
end

-- ─────────────────────────────────────────────────────────
-- OPEN / CLOSE / TOGGLE
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:openTablet()
    if not self.settings.enabled or self.isOpen then return end
    self.isOpen = true
    self.system.isTabletOpen = true
    self.system.registry:autoDetect()

    -- Fresh session: start at the lock screen (if enabled) or the home springboard.
    if self.settings.lockScreenEnabled ~= false then
        self.uiState = "lock"
    else
        self.uiState = "home"
    end
    self._page        = 0
    self._homeMode    = "springboard"   -- always start on the full springboard
    self._favEditing  = false
    self._sessionSec  = 0
    self._battery      = 80 + math.random(0, 16)
    self._batteryStart = nil
    self._unlockKnobX = nil
    self._unlockDragging = false
    self._pressedIcon = nil

    -- Reusable plain-colour overlay for fades / curtains.
    if g_overlayManager and g_plainColorSliceId and not self._fx then
        self._fx = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 1, 1)
    end

    self:_build()

    if self.settings.soundOnTabletToggle ~= false then
        self:playUISound("paging")
    end

    if g_currentMission then
        g_currentMission:addDrawable(self)
    end

    if g_inputBinding then
        g_inputBinding:setShowMouseCursor(true)
        self._mouseListener = {_ui = self}
        function self._mouseListener:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
            if not eventUsed and self._ui:_onMouse(posX, posY, isDown, isUp, button) then
                return true
            end
            return eventUsed
        end
        addModEventListener(self._mouseListener)
    end

    if g_cameraManager and getRotation then
        local cam = g_cameraManager:getActiveCamera()
        if cam and cam ~= 0 then
            self._tabletCamRotX, self._tabletCamRotY, self._tabletCamRotZ = getRotation(cam)
        end
    end

    -- "Screen-on" wake animation
    self:_startAnim("wake", 360)

    FT_EventBus:emit(FT_EventBus.EVENTS.TABLET_OPENED)
    if FarmTabletFocus then FarmTabletFocus:setFocus(true, self.system.currentApp) end
end

function FarmTabletUI:closeTablet()
    if not self.isOpen then return end

    if self.settings.soundOnTabletToggle ~= false then
        self:playUISound("back")
    end

    self.isOpen = false
    self.system.isTabletOpen = false
    self._anim = nil
    self:_destroy()

    if self.system.onTabletClosed then
        self.system:onTabletClosed()
    end

    if g_currentMission then
        g_currentMission:removeDrawable(self)
        if self._mouseListener then
            removeModEventListener(self._mouseListener)
            self._mouseListener = nil
        end
    end
    if g_inputBinding then
        g_inputBinding:setShowMouseCursor(false)
    end

    self._tabletCamRotX = nil
    self._tabletCamRotY = nil
    self._tabletCamRotZ = nil

    FT_EventBus:emit(FT_EventBus.EVENTS.TABLET_CLOSED)
    if FarmTabletFocus then FarmTabletFocus:setFocus(false, nil) end
end

function FarmTabletUI:toggleTablet()
    if self.isOpen then self:closeTablet() else self:openTablet() end
end

-- ─────────────────────────────────────────────────────────
-- NAVIGATION (state transitions)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:unlock()
    if self.uiState ~= "lock" then return end
    self.uiState = "home"
    self._unlockDragging = false
    self._unlockKnobX = nil
    self:_rebuildScreen()
    self:_startAnim("unlock", 300)
    if self.settings.soundOnTabletToggle ~= false then self:playUISound("paging") end
    if FarmTabletFocus then FarmTabletFocus:setFocus(true, self.system.currentApp) end
end

function FarmTabletUI:lockNow()
    self.uiState = "lock"
    self._unlockKnobX = nil
    self._unlockDragging = false
    self:_rebuildScreen()
    self:_startAnim("lock", 200)
    self:playUISound("back")
end

function FarmTabletUI:goHome()
    local prev = self.system.currentApp
    self.uiState = "home"
    self:_rebuildScreen()
    local rect = self._appCellRects[prev] or self:_screenCenterSquare()
    self:_startAnim("home", 240, { id = prev, rect = rect })
    self:playUISound("back")
    if FarmTabletFocus then FarmTabletFocus:setFocus(true, prev) end
end

--- App-bar Back: step up one level. If the current app registered a back
--- handler that pops an in-app sub-page (returns true), refresh the content;
--- otherwise we're at the app root, so fall through to the springboard.
function FarmTabletUI:goBack()
    local appId = self.system and self.system.currentApp
    local fn    = appId and self._appBackHandlers and self._appBackHandlers[appId]
    if fn then
        local ok, handled = pcall(fn, self)
        if ok and handled then
            self:playUISound("back")
            self._contentScrollY   = 0
            self._contentScrollMax = 0
            if self.isOpen and self.uiState == "app" then
                self:_drawContent()
                self._contentTimer = 0
            end
            return
        elseif not ok and Logging and Logging.devWarning then
            Logging.devWarning("FarmTablet: back handler error for app '%s': %s",
                tostring(appId), tostring(handled))
        end
    end
    self:goHome()
end

--- Open the favourites page (from the app-bar star). Lands on the springboard
--- in "favourites" mode via the normal home transition.
function FarmTabletUI:openFavorites()
    self._homeMode   = "favorites"
    self._favEditing = false
    self._page       = 0
    self:goHome()
end

--- Springboard star toggle: flip between the full springboard and the
--- favourites page in place (no zoom — we're already on the home screen).
function FarmTabletUI:toggleFavoritesMode()
    self._homeMode   = (self._homeMode == "favorites") and "springboard" or "favorites"
    self._favEditing = false
    self._page       = 0
    self:_rebuildScreen()
    self:playUISound("click")
end

--- Launch an app from the springboard, with a zoom-open animation.
function FarmTabletUI:launchApp(appId, fromRect)
    local ok = self:switchApp(appId)   -- sets state=app + rebuilds + sound
    if ok and self.isOpen then
        self:_startAnim("launch", 280, { id = appId, rect = fromRect or self._appCellRects[appId] or self:_screenCenterSquare() })
    end
    return ok
end

-- ─────────────────────────────────────────────────────────
-- BUILD  (compute layout, then draw current screen)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_build()
    self:_computeLayout()
    self:_rebuildScreen()
end

function FarmTabletUI:_computeLayout()
    local scaleMultW = (self.settings.tabletScale or 1.0) * (self.settings.tabletWidthMult or 1.0)
    local scaleMultH = self.settings.tabletScale or 1.0
    local tw, th = getNormalizedScreenValues(FT.REF_W * scaleMultW, FT.REF_H * scaleMultH)

    local centreX = self.settings.tabletPosX or 0.5
    local centreY = self.settings.tabletPosY or 0.5
    local tx = centreX - tw/2
    local ty = centreY - th/2
    tx = math.max(0, math.min(1 - tw, tx))
    ty = math.max(0, math.min(1 - th, ty))

    FT.LAYOUT.scaleX = tw / FT.REF_W
    FT.LAYOUT.scaleY = th / FT.REF_H
    FT.LAYOUT.tabletX = tx;  FT.LAYOUT.tabletY = ty
    FT.LAYOUT.tabletW = tw;  FT.LAYOUT.tabletH = th

    local bL = FT.px(BEZEL_REF)
    local bR = FT.px(BEZEL_REF)
    local bT = FT.py(BEZEL_REF)
    local bB = FT.py(BEZEL_REF)

    -- Inner screen
    local sx = tx + bL
    local sy = ty + bB
    local sw = tw - bL - bR
    local sh = th - bT - bB
    FT.LAYOUT.screenX = sx;  FT.LAYOUT.screenY = sy
    FT.LAYOUT.screenW = sw;  FT.LAYOUT.screenH = sh

    -- Status bar (top of screen)
    local statusH = FT.py(STATUS_H_REF)
    FT.LAYOUT.statusH = statusH
    FT.LAYOUT.statusY = sy + sh - statusH

    -- Canvas (below status bar) — used by home/lock and as the app region base
    FT.LAYOUT.canvasY = sy
    FT.LAYOUT.canvasH = sh - statusH

    -- Keep legacy sidebar fields defined (edit-mode safety); width 0 now.
    FT.LAYOUT.sidebarX = sx; FT.LAYOUT.sidebarY = sy
    FT.LAYOUT.sidebarW = 0;  FT.LAYOUT.sidebarH = sh

    -- Default content zone (overridden per state in _drawAppView)
    FT.LAYOUT.contentX = sx;  FT.LAYOUT.contentY = sy
    FT.LAYOUT.contentW = sw;  FT.LAYOUT.contentH = sh - statusH
    FT.LAYOUT.topbarX = sx; FT.LAYOUT.topbarY = FT.LAYOUT.statusY
    FT.LAYOUT.topbarW = sw; FT.LAYOUT.topbarH = statusH
end

function FarmTabletUI:_rebuildScreen()
    self.r:destroyAll()
    self._iconBtns    = {}
    self._dockBtns    = {}
    self._pageDots    = {}
    self._contentBtns = {}
    self._iconQueue   = {}
    self._appCellRects = {}
    self._closeBtn = nil
    self._homeBtn  = nil
    self._backBtn  = nil
    self._starBtn  = nil
    self._homeStarBtn = nil
    self._favEditBtn  = nil
    self._unlockBtn = nil
    self._powerBtn  = nil

    self:_drawFrame()

    if self.uiState == "lock" then
        self._useWallpaper = true
        self:_drawStatusBar()
        self:_drawLock()
    elseif self.uiState == "app" then
        self._useWallpaper = false
        self:_drawStatusBar()
        self:_drawAppView()
    else
        self.uiState = "home"
        self._useWallpaper = true
        self:_drawStatusBar()
        self:_drawHome()
    end
end

-- ─────────────────────────────────────────────────────────
-- FRAME  (tablet body, bezel, gloss, hardware)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_drawFrame()
    local L = FT.LAYOUT
    local r = self.r
    r:clearCoverLayer()

    -- The tablet body — rounded bezel, camera, speaker grille, side buttons and
    -- the drop shadow — is a baked texture (gui/tablet_frame.dds) rendered in
    -- draw(), so the silhouette has real rounded corners. Here we only paint the
    -- screen surface and its border on top of that body.

    -- Screen backing: black under wallpaper (home/lock), bg-palette in apps.
    if self.uiState == "app" then
        local pal = FT.BG_PALETTE[self.settings.tabletBgColorIndex or 1] or FT.BG_PALETTE[1]
        r:rect(L.screenX, L.screenY, L.screenW, L.screenH, {0,0,0,1})
        r:rect(L.screenX, L.screenY, L.screenW, L.screenH, pal.color)
    else
        r:rect(L.screenX, L.screenY, L.screenW, L.screenH, {0.02,0.03,0.04,1})
    end

    -- Inner screen border (subtle)
    local stroke = FT.px(1)
    local accent = FT.appColor(self.system.currentApp)
    r:rect(L.screenX, L.screenY, L.screenW, stroke, {accent[1],accent[2],accent[3],0.30})
    r:rect(L.screenX, L.screenY + L.screenH - stroke, L.screenW, stroke, {accent[1],accent[2],accent[3],0.30})
    r:rect(L.screenX, L.screenY, stroke, L.screenH, {accent[1],accent[2],accent[3],0.18})
    r:rect(L.screenX + L.screenW - stroke, L.screenY, stroke, L.screenH, {accent[1],accent[2],accent[3],0.18})
end

-- ── Status bar (clock / battery / wifi / power) ───────────

function FarmTabletUI:_drawStatusBar()
    local L = FT.LAYOUT
    local r = self.r
    local sx, sw = L.screenX, L.screenW
    local y, h = L.statusY, L.statusH

    -- Translucent bar so wallpaper / content shows behind it
    r:rect(sx, y, sw, h, {0,0,0,0.30})
    r:rect(sx, y, sw, math.max(FT.py(1),0.0007), {1,1,1,0.06})

    -- Right cluster: wifi bars, battery, power/lock glyph
    local pad = FT.px(10)
    local cy  = y + h/2

    -- Power / lock button (far right)
    local pwrW = FT.px(16)
    local pwrX = sx + sw - pad - pwrW
    r:rect(pwrX, cy - FT.py(6), pwrW, FT.py(12), {1,1,1,0.0})  -- (hit padding only)
    -- power glyph: circle outline + top stem (drawn from rects)
    r:rect(pwrX + pwrW/2 - FT.px(1), cy + FT.py(1), FT.px(2), FT.py(5), {0.85,0.9,0.95,0.9})
    r:rect(pwrX + pwrW/2 - FT.px(5), cy - FT.py(5), FT.px(10), FT.px(1.6), {0.85,0.9,0.95,0.55})
    r:rect(pwrX + pwrW/2 - FT.px(5), cy - FT.py(5), FT.px(1.6), FT.py(7), {0.85,0.9,0.95,0.55})
    r:rect(pwrX + pwrW/2 + FT.px(4), cy - FT.py(5), FT.px(1.6), FT.py(7), {0.85,0.9,0.95,0.55})
    r:rect(pwrX + pwrW/2 - FT.px(5), cy + FT.py(2), FT.px(10), FT.px(1.6), {0.85,0.9,0.95,0.55})
    self._powerBtn = { x = pwrX - FT.px(3), y = y, w = pwrW + FT.px(6), h = h }

    -- Battery
    local batW = FT.px(22)
    local batH = FT.py(11)
    local batX = pwrX - FT.px(10) - batW
    local batY = cy - batH/2
    r:rect(batX, batY, batW, batH, {1,1,1,0.16})                 -- shell
    r:rect(batX + batW, cy - FT.py(3), FT.px(2), FT.py(6), {1,1,1,0.5}) -- nub
    local lvl = math.max(0, math.min(1, (self._battery or 80)/100))
    local bc  = (lvl > 0.4) and {0.35,0.85,0.45,0.95}
              or (lvl > 0.15) and {1.0,0.72,0.1,0.95}
              or {0.95,0.3,0.3,0.95}
    r:rect(batX + FT.px(1.5), batY + FT.py(1.5), (batW - FT.px(3)) * lvl, batH - FT.py(3), bc)

    -- Wifi bars (ascending)
    local wfX = batX - FT.px(10) - FT.px(14)
    for i = 0, 3 do
        local bh2 = FT.py(3 + i*2.5)
        r:rect(wfX + i*FT.px(4), cy - FT.py(4) , FT.px(2.4), bh2, {1,1,1,0.55})
    end

    self:_statusBarText()
end

-- Status-bar text only (re-added on the 1s clock refresh without a full rebuild).
function FarmTabletUI:_statusBarText()
    local L = FT.LAYOUT
    local r = self.r
    local sx, sw = L.screenX, L.screenW
    local cy = L.statusY + L.statusH/2 - FT.py(4)
    local data = self.system.data

    -- Left: clock
    local world = data and data:getWorldInfo()
    local timeStr = world and string.format("%02d:%02d", world.hour % 24, world.minute) or "--:--"
    r:text(sx + FT.px(12), cy, FT.FONT.SMALL, timeStr, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)

    -- Centre: farm name (+ day/season)
    local farmId = data and data:getPlayerFarmId()
    local farmName = (data and data:getFarmName(farmId)) or "My Farm"
    r:text(sx + sw/2, cy, FT.FONT.SMALL, farmName, RenderText.ALIGN_CENTER, FT.C.TEXT_NORMAL)

    -- Battery % (left of the battery icon cluster)
    r:text(sx + sw - FT.px(58), cy, FT.FONT.TINY,
        string.format("%d%%", math.floor(self._battery or 80)),
        RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
end

function FarmTabletUI:_refreshStatusBar()
    if not self.isOpen then return end
    -- Only persistent text lives in _texts (status bar + lock clock); safe to rebuild.
    self.r._texts = {}
    self:_statusBarText()
    if self.uiState == "lock" and self._lockText then self:_lockText() end
end

-- ─────────────────────────────────────────────────────────
-- APP VIEW  (full-screen content + top app bar)
-- ─────────────────────────────────────────────────────────

-- Draw a star (Favourites) button: pill background + 4-point star. When
-- `active` it glows in warm gold (a soft halo + brighter fill); otherwise it
-- is a dim gold star on the standard translucent pill. Shared by the app-bar
-- star and the springboard star toggle. Caller records the hit rect.
function FarmTabletUI:_drawStarGlyph(x, y, w, h, active)
    local r = self.r
    local cx, cy = x + w / 2, y + h / 2
    local len, halfW = FT.py(8), FT.px(2.6)
    if active then
        -- soft glow halo (expanding low-alpha gold rects)
        r:rect(x - FT.px(2), y - FT.py(2), w + FT.px(4), h + FT.py(4), {1.0, 0.82, 0.28, 0.12})
        r:rect(x + FT.px(1), y + FT.py(1), w - FT.px(2), h - FT.py(2), {1.0, 0.82, 0.28, 0.22})
        drawStar(r, cx, cy, len, halfW, {1.0, 0.88, 0.40, 1.0})
    else
        r:rect(x, y, w, h, {1, 1, 1, 0.06})
        drawStar(r, cx, cy, len, halfW, {1.0, 0.82, 0.28, 0.80})
    end
end

-- Just the star shape (no pill/glow), centred in the box. Used as the
-- "this app is a favourite" badge on icons in the favourites edit view.
function FarmTabletUI:_drawStarMark(x, y, w, h, color)
    drawStar(self.r, x + w / 2, y + h / 2, h * 0.45, h * 0.18, color)
end

function FarmTabletUI:_drawAppView()
    local L = FT.LAYOUT
    local r = self.r
    local accent = FT.appColor(self.system.currentApp)

    local appbarH = FT.py(APPBAR_H_REF)
    local barY = L.statusY - appbarH
    local sx, sw = L.screenX, L.screenW

    -- App bar background + accent underline
    r:rect(sx, barY, sw, appbarH, {0,0,0,0.22})
    r:rect(sx, barY, sw, FT.py(1.4), {accent[1],accent[2],accent[3],0.65})

    -- Top-left nav (#90): a little house (Home), a left-arrow (Back) and a
    -- star (Favourites). Home jumps to the springboard; Back steps up one
    -- level (sub-page → app root → springboard); the star opens the
    -- favourites page. Glyphs are built from rects (no triangle primitive).
    local btnH  = FT.py(20)
    local glyph = {0.92, 0.95, 0.99, 0.95}

    -- HOME — a little house
    local hbW = FT.px(34)
    local hbX = sx + FT.px(6)
    local hbY = barY + (appbarH - btnH) / 2
    r:rect(hbX, hbY, hbW, btnH, {1,1,1,0.08})
    local cx           = hbX + hbW / 2
    local bodyW, bodyH = FT.px(13), FT.py(7)
    local roofW, roofH = FT.px(18), FT.py(6)
    local houseBottom  = hbY + (btnH - (bodyH + roofH)) / 2
    r:rect(cx - bodyW / 2, houseBottom, bodyW, bodyH, glyph)                                       -- body
    r:rect(cx - FT.px(2), houseBottom, FT.px(4), FT.py(4.5), {accent[1], accent[2], accent[3], 1}) -- door
    drawTriUp(r, cx, houseBottom + bodyH, roofW, roofH, glyph)                                     -- roof
    self._homeBtn = { x = hbX, y = barY, w = hbW, h = appbarH }

    -- BACK — a left-pointing arrow
    local bbW = FT.px(30)
    local bbX = hbX + hbW + FT.px(6)
    r:rect(bbX, hbY, bbW, btnH, {1,1,1,0.06})
    local acy = hbY + btnH / 2
    local headW, headH, shaftH = FT.px(7), FT.py(12), FT.py(3)
    local tipX = bbX + FT.px(8)
    drawTriLeft(r, tipX, acy, headW, headH, glyph)                              -- arrowhead
    r:rect(tipX + headW * 0.5, acy - shaftH / 2, FT.px(10), shaftH, glyph)      -- shaft
    self._backBtn = { x = bbX, y = barY, w = bbW, h = appbarH }

    -- STAR — opens the favourites page
    local sbW = FT.px(30)
    local sbX = bbX + bbW + FT.px(6)
    self:_drawStarGlyph(sbX, hbY, sbW, btnH, false)
    self._starBtn = { x = sbX, y = barY, w = sbW, h = appbarH }

    -- App icon (small) + title (centre-left)
    local app = self.system.registry:get(self.system.currentApp)
    local appName = (app and g_i18n and app.name and g_i18n:hasText(app.name) and g_i18n:getText(app.name))
                    or (app and app.navLabel) or "App"
    local titleIconSz = FT.py(20)
    local tiX = sbX + sbW + FT.px(10)
    local tiY = barY + (appbarH - titleIconSz)/2
    table.insert(self._iconQueue, { appId = self.system.currentApp, x = tiX, y = tiY, size = titleIconSz,
                                    mono = (app and app.navLabel) or "?" })
    -- App name as a dim right-aligned breadcrumb (apps draw their own bright header)
    r:text(sx + sw - FT.px(12), barY + appbarH/2 - FT.py(5),
           FT.FONT.SMALL, appName, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)

    -- Content region = below the app bar, full width.
    L.contentX = sx
    L.contentY = L.canvasY
    L.contentW = sw
    L.contentH = (barY) - L.canvasY

    -- Cover strips clip scrolled content at the content edges.
    local coverColor = {0.02,0.03,0.04,1}
    if self.uiState == "app" then
        local pal = FT.BG_PALETTE[self.settings.tabletBgColorIndex or 1] or FT.BG_PALETTE[1]
        coverColor = pal.color
    end
    local topCoverY = L.contentY + L.contentH
    local topGap    = barY - topCoverY
    if topGap > 0 then r:coverRect(sx, topCoverY, sw, topGap, coverColor) end

    self:_drawContent()
end

function FarmTabletUI:_drawContent()
    self.r:clearAppLayer()
    self._contentBtns = {}
    local appId = self.system.currentApp
    local fn = self._appDrawers and self._appDrawers[appId]
    if fn then
        local ok, err = pcall(fn, self)
        if not ok then self:_drawError(err) end
    else
        self:_drawWelcome()
    end
end

-- Register an app drawer function (called by app files)
FarmTabletUI._appDrawers = {}
function FarmTabletUI:registerDrawer(appId, fn)
    FarmTabletUI._appDrawers[appId] = fn
end

-- Register an optional back handler for an app with in-app sub-pages.
-- fn(self) should pop one level and return true if it handled the back,
-- or false/nil when already at the app's root (then Back goes to the
-- springboard). Called by app files that have sub-views.
FarmTabletUI._appBackHandlers = {}
function FarmTabletUI:registerBackHandler(appId, fn)
    FarmTabletUI._appBackHandlers[appId] = fn
end

-- ─────────────────────────────────────────────────────────
-- SWITCH APP  (in-place refresh of the app view; no zoom anim)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:switchApp(appId)
    if not self.system.registry:has(appId) then return false end
    local app = self.system.registry:get(appId)
    if not app or not app.enabled then return false end

    local s = self.settings
    if s and s.soundEffects and s.soundOnAppSelect and appId ~= self.system.currentApp then
        self:playUISound("click")
    end

    self.system.currentApp = appId
    self._contentScrollY   = 0
    self._contentScrollMax = 0

    if self.isOpen then
        self.uiState = "app"
        self:_rebuildScreen()
    end

    FT_EventBus:emit(FT_EventBus.EVENTS.APP_SWITCHED, appId)
    if FarmTabletFocus then FarmTabletFocus:setFocus(self.isOpen, appId) end
    return true
end

-- ─────────────────────────────────────────────────────────
-- ANIMATION  (transient overlay drawn on top of the built screen)
-- ─────────────────────────────────────────────────────────

local function easeOutCubic(p) return 1 - (1 - p)^3 end
local function easeInCubic(p)  return p*p*p end

function FarmTabletUI:_startAnim(kind, dur, data)
    self._anim = { kind = kind, t = 0, dur = dur or 250, data = data or {} }
end

-- reusable fade/curtain rect (uses self._fx plain overlay)
function FarmTabletUI:_fxRect(x, y, w, h, col)
    if not self._fx then return end
    self._fx:setPosition(x, y)
    self._fx:setDimension(w, h)
    self._fx:setColor(col[1], col[2], col[3], col[4])
    self._fx:render()
end

-- Round the screen's four corners so the screen reads as a recessed, rounded
-- screen instead of a flat sheet pasted on the frame. The frame texture bakes a
-- rounded recess (gen_icons srad ≈ 3% of screen width), but the square screen
-- surface is painted over it and hides that rounding. We mask each corner's
-- outer nook with the body graphite. Drawn immediately, over the screen content.
function FarmTabletUI:_drawScreenCorners()
    if not self._fx then return end
    local L = FT.LAYOUT
    local R = L.screenW * 0.03           -- matches the baked recess radius
    if R <= 0 then return end
    local N    = 6
    local step = R / N
    local x0, x1 = L.screenX, L.screenX + L.screenW
    local y0, y1 = L.screenY, L.screenY + L.screenH   -- y0 = bottom, y1 = top
    local topC = {0.165, 0.176, 0.208, 1}             -- body graphite (top)
    local botC = {0.059, 0.067, 0.086, 1}             -- body graphite (bottom)
    for i = 0, N - 1 do
        local a    = (i + 0.5) * step                 -- inward from the outer edge
        local nook = R - math.sqrt(math.max(0, R*R - (R - a)*(R - a)))
        if nook > 0 then
            local h  = step * 1.5
            local yT = (y1 - a) - h * 0.5
            local yB = (y0 + a) - h * 0.5
            self:_fxRect(x0,        yT, nook, h, topC)   -- top-left
            self:_fxRect(x1 - nook, yT, nook, h, topC)   -- top-right
            self:_fxRect(x0,        yB, nook, h, botC)   -- bottom-left
            self:_fxRect(x1 - nook, yB, nook, h, botC)   -- bottom-right
        end
    end
end

function FarmTabletUI:_drawAnim()
    local a = self._anim
    if not a then return end
    local L = FT.LAYOUT
    local p = math.max(0, math.min(1, a.t / a.dur))
    local sx, sy, sw, scH = L.screenX, L.screenY, L.screenW, L.screenH

    if a.kind == "wake" then
        -- screen-on: black veil fades out
        self:_fxRect(sx, sy, sw, scH, {0,0,0, (1 - easeOutCubic(p)) * 0.95})

    elseif a.kind == "unlock" then
        -- lock curtain lifts upward + fades
        local e = easeInCubic(p)
        local off = scH * e
        self:_fxRect(sx, sy + off, sw, scH, {0.02,0.03,0.05, (1 - p) * 0.92})

    elseif a.kind == "lock" then
        self:_fxRect(sx, sy, sw, scH, {0.02,0.03,0.05, (1 - p) * 0.7})

    elseif a.kind == "launch" then
        -- app icon zooms from its grid cell to fill the screen, then dissolves
        local rect = a.data.rect or self:_screenCenterSquare()
        local e = easeOutCubic(p)
        local target = math.min(sw, scH) * 0.92
        local size = rect.w + (target - rect.w) * e
        local cx = (rect.x + rect.w/2) + ((sx + sw/2)  - (rect.x + rect.w/2)) * e
        local cy = (rect.y + rect.h/2) + ((sy + scH/2) - (rect.y + rect.h/2)) * e
        local alpha = 1 - easeInCubic(p)
        self:_fxRect(sx, sy, sw, scH, {1,1,1, (1 - p) * 0.10})
        if FT_Icons then FT_Icons.renderIcon(a.data.id, cx - size/2, cy - size/2, size, 1, alpha) end

    elseif a.kind == "home" then
        -- app icon shrinks from screen back to its grid cell
        local rect = a.data.rect or self:_screenCenterSquare()
        local e = easeOutCubic(p)
        local start = math.min(sw, scH) * 0.92
        local size = start + (rect.w - start) * e
        local cx = (sx + sw/2) + ((rect.x + rect.w/2) - (sx + sw/2)) * e
        local cy = (sy + scH/2) + ((rect.y + rect.h/2) - (sy + scH/2)) * e
        local alpha = (1 - easeInCubic(p)) * 0.9
        if FT_Icons then FT_Icons.renderIcon(a.data.id, cx - size/2, cy - size/2, size, 1, alpha) end
    end
end

-- A centred square fallback used when no source cell rect is known.
function FarmTabletUI:_screenCenterSquare()
    local L = FT.LAYOUT
    local s = math.min(L.screenW, L.screenH) * 0.32
    return { x = L.screenX + L.screenW/2 - s/2, y = L.screenY + L.screenH/2 - s/2, w = s, h = s }
end

-- ─────────────────────────────────────────────────────────
-- ICON RENDER PASS  (textured overlays, drawn above content)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_drawIconQueue()
    for _, ic in ipairs(self._iconQueue) do
        local scale, alpha = 1.0, 1.0
        if ic.appId == self._pressedIcon then
            scale, alpha = 0.90, 0.85
        end
        local isFallback = true
        if FT_Icons then
            isFallback = FT_Icons.renderIcon(ic.appId, ic.x, ic.y, ic.size, scale, alpha)
        end
        if isFallback and ic.mono then
            local s = ic.size * scale
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextColor(0.97, 0.98, 1.0, alpha)
            renderText(ic.x + ic.size/2, ic.y + ic.size/2 - FT.py(5), s * 0.34, tostring(ic.mono))
            setTextAlignment(RenderText.ALIGN_LEFT)
            setTextColor(1,1,1,1)
        end
    end
end

-- ─────────────────────────────────────────────────────────
-- DRAW / UPDATE (FS25 drawable interface)
-- ─────────────────────────────────────────────────────────

-- ── Home / lock wallpaper (custom image from savegame, or default) ──
function FarmTabletUI:_backgroundDir()
    if g_currentMission and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory then
        return g_currentMission.missionInfo.savegameDirectory .. "/FTBackground/"
    end
    return nil
end

function FarmTabletUI:_drawWallpaper()
    if not FT_Icons then return end
    local L = FT.LAYOUT
    local bg = self.settings.customBackground
    if bg and bg ~= "" then
        local dir = self:_backgroundDir()
        if dir and FT_Icons.renderAbs(dir .. bg, L.screenX, L.screenY, L.screenW, L.screenH, 1.0) then
            return
        end
    end
    FT_Icons.renderImage("wall", "wallpaper.dds", L.screenX, L.screenY, L.screenW, L.screenH, 1.0)
end

function FarmTabletUI:draw()
    if not self.isOpen then return end
    local L = FT.LAYOUT

    -- 0. Rounded tablet body (baked texture, transparent corners). The body maps
    --    to the tablet rect; the texture margin (mf) carries the drop shadow.
    local mf = 0.055
    local rW = L.tabletW / (1 - 2*mf)
    local rH = L.tabletH / (1 - 2*mf)
    local okFrame = false
    if FT_Icons then
        okFrame = FT_Icons.renderImage("frame", "tablet_frame.dds",
            L.tabletX - mf*rW, L.tabletY - mf*rH, rW, rH, 1.0)
    end
    if not okFrame then
        self:_fxRect(L.tabletX, L.tabletY, L.tabletW, L.tabletH, {0.10, 0.11, 0.13, 1})
    end

    -- 1. Screen surface + chrome (drawn over the body)
    self.r:flushBase()

    -- 2. Wallpaper (home / lock) — custom image if set, else default
    if self._useWallpaper then
        self:_drawWallpaper()
    end

    -- 3. Screen content (status bar, app content, labels, text)
    local clipY, clipH = nil, nil
    if self.uiState == "app" then clipY = L.contentY; clipH = L.contentH end
    self.r:flushContent(clipY, clipH)

    -- 4. App icons
    self:_drawIconQueue()

    -- 4b. Round the screen corners to match the baked frame recess
    self:_drawScreenCorners()

    -- 5. Transient animation overlay
    self:_drawAnim()

    -- 6. Edit-mode chrome
    self:_drawEditOverlay()
end

function FarmTabletUI:update(dt)
    if not self.isOpen then return end

    self:_updateEditMode(dt)

    if not self._editModeActive then
        if g_inputBinding and g_inputBinding.setShowMouseCursor then
            g_inputBinding:setShowMouseCursor(true)
        end
        if self._tabletCamRotX and g_cameraManager and setRotation then
            local cam = g_cameraManager:getActiveCamera()
            if cam and cam ~= 0 then
                setRotation(cam, self._tabletCamRotX, self._tabletCamRotY, self._tabletCamRotZ)
            end
        end
    end

    -- Animation tick (transient; no rebuild needed)
    if self._anim then
        self._anim.t = self._anim.t + dt
        if self._anim.t >= self._anim.dur then self._anim = nil end
    end

    -- Battery flavour: drain ~1% per real minute open
    self._sessionSec = (self._sessionSec or 0) + dt/1000
    if self._batteryStart == nil then self._batteryStart = self._battery or 80 end
    self._battery = math.max(3, self._batteryStart - math.floor(self._sessionSec / 60))

    -- Scroll / paging by state
    if self.uiState == "app" then
        self:_pollContentScroll()
        if self.system.currentApp == FT.APP.DIGGING and self.updateDiggingApp then
            self:updateDiggingApp(dt)
        end
    elseif self.uiState == "home" then
        self:_pollHomePaging()
    end

    -- 1s clock / battery text refresh
    self._clockTimer = (self._clockTimer or 0) + dt
    if self._clockTimer >= 1000 then
        self._clockTimer = 0
        self:_refreshStatusBar()
    end

    -- Live app content refresh (data stays current while open)
    self._contentTimer = (self._contentTimer or 0) + dt
    if self.uiState == "app" and self._contentTimer >= 4000 and not self._editModeActive then
        self._contentTimer = 0
        self:_drawContent()
    end
end

-- ─────────────────────────────────────────────────────────
-- HOME PAGING SCROLL  (wheel pages the springboard)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_pollHomePaging()
    if not self.isOpen then return end
    local L = FT.LAYOUT
    local px, py = self._mouseX, self._mouseY
    if not (px >= L.screenX and px <= L.screenX + L.screenW and
            py >= L.canvasY and py <= L.canvasY + L.canvasH) then
        self._hWheelUpWas = false; self._hWheelDownWas = false
        return
    end
    local upNow   = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP)
    local downNow = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN)
    local dir = nil
    if upNow   and not self._hWheelUpWas   then dir = -1 end
    if downNow and not self._hWheelDownWas then dir =  1 end
    self._hWheelUpWas   = upNow
    self._hWheelDownWas = downNow
    if dir == nil then return end
    local newPage = math.max(0, math.min((self._pageCount or 1) - 1, (self._page or 0) + dir))
    if newPage ~= self._page then
        self._page = newPage
        self:_rebuildScreen()
        self:playUISound("paging")
    end
end

-- ─────────────────────────────────────────────────────────
-- CONTENT AREA SCROLL  (Settings and other tall apps)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_pollContentScroll()
    if not self.isOpen then return end
    local L  = FT.LAYOUT
    local px = self._mouseX
    local py = self._mouseY
    if not (L.contentX and L.contentW) then return end
    if not (px >= L.contentX and px <= L.contentX + L.contentW and
            py >= L.contentY and py <= L.contentY + L.contentH) then
        self._cWheelUpWas   = false
        self._cWheelDownWas = false
        return
    end
    if (self._contentScrollMax or 0) <= 0 then
        self._cWheelUpWas   = false
        self._cWheelDownWas = false
        return
    end
    local upNow   = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP)
    local downNow = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN)
    local dir = nil
    if upNow   and not self._cWheelUpWas   then dir = -1 end
    if downNow and not self._cWheelDownWas then dir =  1 end
    self._cWheelUpWas   = upNow
    self._cWheelDownWas = downNow
    if dir == nil then return end
    local step    = self._contentScrollStep or FT.py(22)
    local newScroll = math.max(0, math.min((self._contentScrollY or 0) + dir * step, self._contentScrollMax or 0))
    if math.abs(newScroll - (self._contentScrollY or 0)) > 0.0001 then
        self._contentScrollY = newScroll
        self.r:clearAppLayer()
        self._contentBtns = {}
        self:_drawContent()
    end
end

-- ─────────────────────────────────────────────────────────
-- MOUSE INPUT  (dispatch by state)
-- ─────────────────────────────────────────────────────────

local function hit(b, px, py)
    return b and px >= b.x and px <= b.x + b.w and py >= b.y and py <= b.y + b.h
end

function FarmTabletUI:_onMouse(px, py, isDown, isUp, btn)
    if not self.isOpen then return false end
    -- While editing (move/resize) the dedicated edit handler owns the mouse.
    if self._editModeActive then return false end
    self._mouseX = px
    self._mouseY = py

    -- Consume scroll wheel so it never reaches the camera
    if isDown and (btn == Input.MOUSE_BUTTON_WHEEL_UP or btn == Input.MOUSE_BUTTON_WHEEL_DOWN) then
        return true
    end

    -- Lock screen gets its own handler (slide-to-unlock drag)
    if self.uiState == "lock" then
        return self:_onMouseLock(px, py, isDown, isUp, btn)
    end

    -- Power / lock button works in every non-lock state
    if isDown and btn == 1 and hit(self._powerBtn, px, py) then
        self:lockNow()
        return true
    end

    -- ── Springboard icon press / release (tactile launch) ──
    if self.uiState == "home" then
        if isDown and btn == 1 then
            -- Star toggle: springboard ↔ favourites page
            if hit(self._homeStarBtn, px, py) then
                self:toggleFavoritesMode(); return true
            end
            -- Favourites EDIT / DONE button
            if hit(self._favEditBtn, px, py) then
                self._favEditing = not self._favEditing
                self:_rebuildScreen(); self:playUISound("click"); return true
            end
            -- Page dots (work in every home mode)
            for _, pd in ipairs(self._pageDots) do
                if hit(pd, px, py) and pd.page ~= self._page then
                    self._page = pd.page
                    self:_rebuildScreen()
                    self:playUISound("paging")
                    return true
                end
            end
            -- Favourites edit mode: tapping an app toggles its favourite state
            if self._homeMode == "favorites" and self._favEditing then
                for _, ib in ipairs(self._iconBtns) do
                    if hit(ib, px, py) then
                        self:toggleFavorite(ib.appId)
                        self:_rebuildScreen(); self:playUISound("click")
                        return true
                    end
                end
                return true   -- swallow misses so nothing launches while editing
            end
            -- Normal: press an icon / dock app to launch
            for _, ib in ipairs(self._iconBtns) do
                if hit(ib, px, py) then
                    self._pressedIcon = ib.appId
                    self._pressedRect = { x = ib.x, y = ib.y, w = ib.w, h = ib.h }
                    self._pressMoved  = false
                    return true
                end
            end
            for _, db in ipairs(self._dockBtns) do
                if hit(db, px, py) then
                    self._pressedIcon = db.appId
                    self._pressedRect = { x = db.x, y = db.y, w = db.w, h = db.h }
                    self._pressMoved  = false
                    return true
                end
            end
        end

        -- moving with a pressed icon: cancel if dragged off it
        if not isDown and not isUp and self._pressedIcon then
            if not hit(self._pressedRect, px, py) then
                self._pressedIcon = nil
                self._pressedRect = nil
            end
            return true
        end

        if isUp and btn == 1 and self._pressedIcon then
            local appId = self._pressedIcon
            local rect  = self._pressedRect
            self._pressedIcon = nil
            self._pressedRect = nil
            if hit(rect, px, py) then
                -- zoom from the precise icon rect when known, else the cell
                self:launchApp(appId, self._appCellRects[appId] or rect)
            end
            return true
        end
        return false
    end

    -- ── App view ──
    if self.uiState == "app" then
        if isDown and btn == 1 then
            if hit(self._homeBtn, px, py) then self:goHome(); return true end
            if hit(self._backBtn, px, py) then self:goBack(); return true end
            if hit(self._starBtn, px, py) then self:openFavorites(); return true end

            for _, cb in ipairs(self._contentBtns) do
                if not cb._isText and hit(cb, px, py) then
                    if cb.meta and cb.meta.onClick then
                        cb.meta.onClick()
                        if self.isOpen and self.uiState == "app" then
                            self:_drawContent()
                            self._contentTimer = 0
                        end
                    end
                    return true
                end
            end
        end
        return false
    end

    return false
end

-- ─────────────────────────────────────────────────────────
-- CONTENT LAYOUT HELPERS  (used by app drawer functions)
-- (Unchanged API — apps depend on these signatures.)
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:getContentScrollY()
    return self._contentScrollY or 0
end

function FarmTabletUI:drawInfoIcon(stateKey, accentColor)
    local x, contentY, w, _ = self:contentInner()
    local ac = accentColor or FT.C.BRAND

    local iSz = FT.px(18)
    local iX  = x + w - iSz
    local iY  = contentY

    self.r:appRect(iX, iY, iSz, iSz, {ac[1], ac[2], ac[3], 0.18})

    local bdr = FT.px(1.2)
    local bc  = {ac[1], ac[2], ac[3], 0.65}
    self.r:appRect(iX,             iY,              iSz, bdr, bc)
    self.r:appRect(iX,             iY + iSz - bdr,  iSz, bdr, bc)
    self.r:appRect(iX,             iY,              bdr, iSz, bc)
    self.r:appRect(iX + iSz - bdr, iY,              bdr, iSz, bc)

    local dotW = FT.px(3)
    local dotH = FT.py(3)
    self.r:appRect(iX + (iSz - dotW) * 0.5, iY + iSz - FT.py(5) - dotH, dotW, dotH, {ac[1], ac[2], ac[3], 1.00})

    local stW = FT.px(2.5)
    local stH = FT.py(5.5)
    self.r:appRect(iX + (iSz - stW) * 0.5, iY + FT.py(3.5), stW, stH, {ac[1], ac[2], ac[3], 1.00})

    local sk    = stateKey
    local appId = self.system.currentApp
    local btn = {
        x = iX, y = iY, w = iSz, h = iSz,
        meta = { onClick = function()
            self[sk] = true
            self:switchApp(appId)
        end }
    }
    table.insert(self._contentBtns, btn)
    return btn
end

function FarmTabletUI:drawHelpPage(stateKey, appId, headerTitle, accentColor, entries)
    if not self[stateKey] then return false end

    local ac     = accentColor or FT.C.BRAND
    local startY = self:drawAppHeader(headerTitle, "Help")
    local x, contentY, w, _ = self:contentInner()
    local y = startY

    local bw = FT.px(52)
    local bh = FT.py(18)
    local backBtn = self.r:button(
        x + w - bw, startY + FT.py(2), bw, bh, "< BACK", FT.C.BTN_NEUTRAL,
        { onClick = function()
            self[stateKey] = false
            self:switchApp(appId)
        end }
    )
    table.insert(self._contentBtns, backBtn)

    y = y - FT.py(10)

    for _, entry in ipairs(entries) do
        if y < contentY + FT.py(12) then break end

        self.r:appRect(x - FT.px(4), y - FT.py(1), w + FT.px(8), FT.py(14), {ac[1], ac[2], ac[3], 0.12})
        self.r:appText(x, y, FT.FONT.SMALL, entry.title, RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(16)

        for line in ((entry.body or "") .. "\n"):gmatch("([^\n]*)\n") do
            if y < contentY + FT.py(8) then break end
            self.r:appText(x + FT.px(8), y, FT.FONT.TINY, line, RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            y = y - FT.py(13)
        end
        y = y - FT.py(5)
    end

    return true
end

function FarmTabletUI:setContentHeight(totalH)
    local _, _, _, ch = self:contentInner()
    self._contentScrollMax  = math.max(0, totalH - ch)
    self._contentScrollStep = FT.py(22)
    self._contentScrollY = math.min(self._contentScrollY or 0, self._contentScrollMax)
end

function FarmTabletUI:drawScrollBar()
    local scrollMax = self._contentScrollMax or 0
    if scrollMax <= 0 then return end

    local cx, cy, cw, ch = self:contentInner()
    local barX     = cx + cw + FT.px(4)
    local barY     = cy
    local barH     = ch
    local barW     = FT.px(4)

    self.r:appRect(barX, barY, barW, barH, {0.12, 0.14, 0.20, 0.85})

    local total    = ch + scrollMax
    local thumbH   = math.max(FT.py(14), barH * (ch / total))
    local scrolled = self._contentScrollY or 0
    local thumbY   = barY + barH - thumbH - (barH - thumbH) * (scrolled / scrollMax)

    self.r:appRect(barX, thumbY, barW, thumbH, {FT.C.BRAND[1], FT.C.BRAND[2], FT.C.BRAND[3], 0.80})

    self.r:appText(barX + barW + FT.px(4), barY + barH - FT.py(10),
        FT.FONT.TINY, "scroll", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
end

function FarmTabletUI:content()
    return FT.LAYOUT.contentX, FT.LAYOUT.contentY, FT.LAYOUT.contentW, FT.LAYOUT.contentH
end

function FarmTabletUI:contentInner()
    local px = FT.px(16)
    local py = FT.py(12)
    return FT.LAYOUT.contentX + px,
           FT.LAYOUT.contentY + py,
           FT.LAYOUT.contentW - px*2,
           FT.LAYOUT.contentH - py*2
end

function FarmTabletUI:drawAppHeader(title, subtitle)
    local x, y, w, h = self:contentInner()
    local topY = y + h - FT.py(2)
    local accent = FT.appColor(self.system.currentApp)

    self.r:appText(x, topY, FT.FONT.TITLE, title, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)

    if subtitle then
        self.r:appText(x + w, topY, FT.FONT.SMALL, subtitle, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
    end

    local divY = topY - FT.py(18)
    self.r:appRect(x, divY, w, math.max(FT.py(1.5), 0.001), {accent[1], accent[2], accent[3], 0.80})
    self.r:appRect(x, divY - FT.py(2), w, FT.py(3), {accent[1], accent[2], accent[3], 0.12})

    return divY - FT.py(6)
end

function FarmTabletUI:drawRow(y, label, value, labelC, valueC)
    local x, _, w, _ = self:contentInner()
    self.r:row(x, y, w, label, value, labelC, valueC)
    return y - FT.py(FT.SP.ROW)
end

function FarmTabletUI:drawSection(y, label)
    local x, _, w, _ = self:contentInner()
    self.r:sectionHeader(x, y, w, label)
    return y - FT.py(18)
end

function FarmTabletUI:drawRule(y, alpha)
    local x, _, w, _ = self:contentInner()
    self.r:rule(x, y, w, alpha)
    return y - FT.py(16)
end

function FarmTabletUI:drawBar(y, value, maxVal, color)
    local x, _, w, _ = self:contentInner()
    return self.r:progressBar(x, y, w, value, maxVal, color)
end

function FarmTabletUI:drawButton(y, label, color, meta)
    local x, _, w, _ = self:contentInner()
    local bw = FT.px(90)
    local bh = FT.py(22)
    local btn = self.r:button(x, y, bw, bh, label, color, meta)
    table.insert(self._contentBtns, btn)
    return y - bh - FT.py(4), btn
end

function FarmTabletUI:drawButtonPair(y, labelA, colorA, metaA, labelB, colorB, metaB)
    local x, _, w, _ = self:contentInner()
    local bw = FT.px(100)
    local bh = FT.py(22)
    local gap = FT.px(8)
    local btnA = self.r:button(x,        y, bw, bh, labelA, colorA, metaA)
    local btnB = self.r:button(x+bw+gap, y, bw, bh, labelB, colorB, metaB)
    table.insert(self._contentBtns, btnA)
    table.insert(self._contentBtns, btnB)
    return y - bh - FT.py(4), btnA, btnB
end

-- ─────────────────────────────────────────────────────────
-- DEFAULT SCREENS
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_drawWelcome()
    local startY = self:drawAppHeader("Farm Tablet", "v" .. FT.VERSION)
    local y = startY
    local x, _, w, _ = self:contentInner()

    y = y - FT.py(10)
    self.r:appText(x, y, FT.FONT.BODY, "Welcome! Tap an app to begin.", RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
    y = y - FT.py(22)
    self.r:appText(x, y, FT.FONT.SMALL, "Tap HOME to return to the app grid.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
end

function FarmTabletUI:_drawError(msg)
    local startY = self:drawAppHeader("App Error", "")
    local x, _, _, _ = self:contentInner()
    self.r:appText(x, startY - FT.py(8), FT.FONT.SMALL, tostring(msg), RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
end

-- ─────────────────────────────────────────────────────────
-- CLEANUP
-- ─────────────────────────────────────────────────────────

function FarmTabletUI:_destroy()
    if self._editModeActive then
        self:_exitEditMode()
    end
    if self._editBgOverlay then
        delete(self._editBgOverlay)
        self._editBgOverlay = nil
    end
    self.r:destroyAll()
    self._iconBtns    = {}
    self._dockBtns    = {}
    self._contentBtns = {}
    self._iconQueue   = {}
    self._closeBtn    = nil
    if self._fx and self._fx.delete then self._fx:delete() end
    self._fx = nil
end

function FarmTabletUI:delete()
    self:_destroy()
    -- Free the baked-icon overlay cache on mod unload.
    if FT_Icons and FT_Icons.deleteAll then FT_Icons.deleteAll() end
end

function FarmTabletUI:log(msg, ...)
    if self.settings.debugMode then
        Logging.info("[FarmTablet UI] " .. string.format(msg, ...))
    end
end

-- ── Sound helpers ─────────────────────────────────────────

function FarmTabletUI:playUISound(soundType)
    local s = self.settings
    if not (s and s.soundEffects) then return end
    pcall(function()
        if not (g_gui and g_gui.guiSoundPlayer) then return end
        if soundType == "click" then
            g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
        elseif soundType == "paging" then
            g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
        elseif soundType == "back" then
            g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.BACK)
        end
    end)
end
