-- =========================================================
-- FarmTablet v2 – LockScreen
-- Adds FarmTabletUI:_drawLock / _lockText / _onMouseLock.
-- A real lock screen: big clock, date, farm name and a
-- slide-to-unlock control. Source AFTER FarmTabletUI.lua.
-- =========================================================

local CLOCK_SIZE = 0.040   -- normalised text height for the big clock

-- Geometry shared by draw + hit-test (computed from the stable screen rect).
local function lockGeom()
    local L = FT.LAYOUT
    local trackW = L.screenW * 0.52
    local trackH = FT.py(34)
    local trackX = L.screenX + L.screenW/2 - trackW/2
    local trackY = L.screenY + L.screenH * 0.15
    local knobW  = FT.px(56)
    local knobH  = trackH - FT.py(4)
    return {
        trackX = trackX, trackY = trackY, trackW = trackW, trackH = trackH,
        knobW = knobW, knobH = knobH, knobY = trackY + FT.py(2),
        knobMin = trackX + FT.py(2),
        knobMax = trackX + trackW - knobW - FT.py(2),
    }
end

function FarmTabletUI:_drawLock()
    local L = FT.LAYOUT
    local r = self.r

    -- Legibility veil over the wallpaper
    r:rect(L.screenX, L.screenY, L.screenW, L.screenH, {0,0,0,0.28})

    -- Padlock glyph above the clock
    local cx = L.screenX + L.screenW/2
    local lockY = L.screenY + L.screenH * 0.72
    local bodyW, bodyH = FT.px(22), FT.py(16)
    r:rect(cx - bodyW/2, lockY, bodyW, bodyH, {0.95,0.96,0.98,0.92})       -- body
    r:rect(cx - FT.px(7), lockY + bodyH, FT.px(2.5), FT.py(8), {0.95,0.96,0.98,0.8}) -- shackle L
    r:rect(cx + FT.px(4.5), lockY + bodyH, FT.px(2.5), FT.py(8), {0.95,0.96,0.98,0.8}) -- shackle R
    r:rect(cx - FT.px(7), lockY + bodyH + FT.py(6), FT.px(14), FT.px(2.5), {0.95,0.96,0.98,0.8}) -- shackle top
    r:rect(cx - FT.px(1.5), lockY + FT.py(4), FT.px(3), FT.py(6), {0.2,0.22,0.28,1})  -- keyhole

    -- Slide-to-unlock track
    local g = lockGeom()
    self._unlockTrack = g
    r:rect(g.trackX, g.trackY, g.trackW, g.trackH, {1,1,1,0.10})
    r:rect(g.trackX, g.trackY, g.trackW, FT.py(1), {1,1,1,0.10})
    r:rect(g.trackX, g.trackY + g.trackH - FT.py(1), g.trackW, FT.py(1), {0,0,0,0.25})

    -- Knob
    local knobX = self._unlockKnobX or g.knobMin
    knobX = math.max(g.knobMin, math.min(g.knobMax, knobX))
    local accent = FT.C.BRAND
    r:rect(knobX, g.knobY, g.knobW, g.knobH, {accent[1],accent[2],accent[3],0.95})
    r:rect(knobX, g.knobY + g.knobH - FT.py(2), g.knobW, FT.py(2), {0,0,0,0.20})
    -- chevrons ">>"
    local chx = knobX + g.knobW/2
    local chy = g.knobY + g.knobH/2
    for k = 0, 1 do
        local ox = chx - FT.px(6) + k*FT.px(7)
        r:rect(ox,            chy - FT.py(5), FT.px(2), FT.py(6), {1,1,1,0.95})
        r:rect(ox - FT.px(2), chy - FT.py(3), FT.px(2), FT.py(2), {1,1,1,0.95})
        r:rect(ox - FT.px(2), chy + FT.py(1), FT.px(2), FT.py(2), {1,1,1,0.95})
    end

    self:_lockText()
end

-- Text-only pieces (re-added on the 1s clock refresh without a full rebuild).
function FarmTabletUI:_lockText()
    local L = FT.LAYOUT
    local r = self.r
    local data = self.system.data
    local cx = L.screenX + L.screenW/2

    local world = data and data:getWorldInfo()
    local timeStr = world and string.format("%02d:%02d", world.hour % 24, world.minute) or "--:--"
    local clockY = L.screenY + L.screenH * 0.50
    r:text(cx, clockY, CLOCK_SIZE, timeStr, RenderText.ALIGN_CENTER, {0.98,0.99,1.0,1.0})

    -- date / season line
    if world then
        local seasonStr = (data.getSeasonName and data:getSeasonName(world.season)) or ""
        local dateStr = string.format("%s  -  Day %d", seasonStr, world.day or 1)
        r:text(cx, clockY - FT.py(26), FT.FONT.SMALL, dateStr, RenderText.ALIGN_CENTER, {0.85,0.88,0.92,0.9})
    end

    -- farm name
    local farmId = data and data:getPlayerFarmId()
    local farmName = (data and data:getFarmName(farmId)) or "My Farm"
    r:text(cx, clockY - FT.py(42), FT.FONT.TINY, farmName, RenderText.ALIGN_CENTER, {0.7,0.74,0.8,0.85})

    -- slide hint
    if self._unlockTrack then
        local g = self._unlockTrack
        r:text(g.trackX + g.trackW/2 + FT.px(14), g.trackY + g.trackH/2 - FT.py(4),
            FT.FONT.SMALL, "slide to unlock", RenderText.ALIGN_CENTER, {1,1,1,0.45})
    end
end

-- Slide-to-unlock interaction.
function FarmTabletUI:_onMouseLock(px, py, isDown, isUp, btn)
    -- Power button = sleep (close the tablet) on the lock screen.
    local pb = self._powerBtn
    if isDown and btn == 1 and pb and px >= pb.x and px <= pb.x+pb.w and py >= pb.y and py <= pb.y+pb.h then
        self:closeTablet()
        return true
    end

    local g = self._unlockTrack
    if not g then return false end

    local onTrack = (px >= g.trackX and px <= g.trackX + g.trackW and
                     py >= g.trackY - FT.py(6) and py <= g.trackY + g.trackH + FT.py(6))

    if isDown and btn == 1 and onTrack then
        self._unlockDragging = true
        self._unlockKnobX = math.max(g.knobMin, math.min(g.knobMax, px - g.knobW/2))
        self:_rebuildScreen()
        return true
    end

    if not isDown and not isUp and self._unlockDragging then
        self._unlockKnobX = math.max(g.knobMin, math.min(g.knobMax, px - g.knobW/2))
        self:_rebuildScreen()
        return true
    end

    if isUp and btn == 1 and self._unlockDragging then
        self._unlockDragging = false
        local travel = (self._unlockKnobX or g.knobMin) - g.knobMin
        local span   = math.max(0.0001, g.knobMax - g.knobMin)
        if travel / span >= 0.7 then
            self._unlockKnobX = g.knobMax
            self:unlock()
        else
            self._unlockKnobX = nil
            self:_rebuildScreen()
        end
        return true
    end

    return false
end
