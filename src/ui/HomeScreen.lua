-- =========================================================
-- FarmTablet v2 – HomeScreen (springboard)
-- Adds FarmTabletUI:_drawHome — a paged grid of glossy app icons
-- with a bottom dock, page dots and a home indicator.
-- Source AFTER FarmTabletUI.lua.
-- =========================================================

local DOCK_APPS    = { "dashboard", "weather", "app_store", "settings" }
local GRID_COLS    = 5
local DOCK_H_REF   = 78
local HOMEIND_REF  = 10

-- Localised, truncated app label for the grid.
local function appLabel(app, maxChars)
    local name = (app and g_i18n and app.name and g_i18n:hasText(app.name) and g_i18n:getText(app.name))
                 or (app and app.navLabel) or "?"
    if #name > maxChars then name = string.sub(name, 1, maxChars - 1) .. "." end
    return name
end

local function isDockApp(id)
    for _, d in ipairs(DOCK_APPS) do if d == id then return true end end
    return false
end

function FarmTabletUI:_drawHome()
    local L = FT.LAYOUT
    local r = self.r
    local sx, sw = L.screenX, L.screenW

    -- ── Zones ────────────────────────────────────────────
    local homeIndH = FT.py(HOMEIND_REF)
    local homeIndY = L.canvasY + FT.py(3)
    local dockH    = FT.py(DOCK_H_REF)
    local dockY    = homeIndY + homeIndH + FT.py(2)
    local dotsH    = FT.py(14)
    local dotsY    = dockY + dockH + FT.py(2)

    local gridX    = sx + FT.px(18)
    local gridW    = sw - FT.px(36)
    local gridTop  = L.canvasY + L.canvasH - FT.py(8)
    local gridBot  = dotsY + dotsH + FT.py(4)
    local gridH    = math.max(FT.py(40), gridTop - gridBot)

    -- ── App lists ────────────────────────────────────────
    local allApps = self.system.registry:getAll()
    local gridApps, dockApps = {}, {}
    for _, app in ipairs(allApps) do
        if isDockApp(app.id) then dockApps[app.id] = app
        else table.insert(gridApps, app) end
    end

    -- ── Grid geometry ────────────────────────────────────
    local cols   = GRID_COLS
    local cellW  = gridW / cols
    local targetCellH = FT.py(80)
    local rows   = math.max(1, math.floor(gridH / targetCellH))
    local cellH  = gridH / rows
    local perPage = cols * rows
    local iconSize = math.min(cellW * 0.58, cellH * 0.62)
    local labelH   = FT.py(13)

    self._pageCount = math.max(1, math.ceil(#gridApps / perPage))
    self._page = math.max(0, math.min(self._page or 0, self._pageCount - 1))

    local first = self._page * perPage
    for slot = 0, perPage - 1 do
        local app = gridApps[first + slot + 1]
        if app then
            local col = slot % cols
            local row = math.floor(slot / cols)
            local cellLeft   = gridX + col * cellW
            local cellTop    = gridTop - row * cellH
            local cellBottom = cellTop - cellH

            local iconCx = cellLeft + cellW/2
            local iconY  = cellBottom + labelH + (cellH - labelH - iconSize) * 0.5
            local iconX  = iconCx - iconSize/2

            table.insert(self._iconQueue, {
                appId = app.id, x = iconX, y = iconY, size = iconSize,
                mono = app.navLabel or string.upper(string.sub(app.id, 1, 2)),
            })
            self._appCellRects[app.id] = { x = iconX, y = iconY, w = iconSize, h = iconSize }

            -- label
            r:appText(iconCx, cellBottom + labelH * 0.25, FT.FONT.TINY,
                appLabel(app, 11), RenderText.ALIGN_CENTER, {0.95, 0.96, 0.98, 0.95})

            -- full-cell hitbox
            table.insert(self._iconBtns, { appId = app.id, x = cellLeft, y = cellBottom, w = cellW, h = cellH })
        end
    end

    -- ── Page dots ────────────────────────────────────────
    self._pageDots = {}
    if self._pageCount > 1 then
        local dotSz  = FT.px(6)
        local dotGap = FT.px(8)
        local totalW = self._pageCount * dotSz + (self._pageCount - 1) * dotGap
        local startX = sx + sw/2 - totalW/2
        local dy = dotsY + dotsH/2 - dotSz/2
        for pg = 0, self._pageCount - 1 do
            local dx = startX + pg * (dotSz + dotGap)
            local active = (pg == self._page)
            r:rect(dx, dy, dotSz, dotSz,
                active and {0.95,0.96,0.98,0.95} or {0.95,0.96,0.98,0.30})
            table.insert(self._pageDots, { x = dx - dotGap/2, y = dotsY, w = dotSz + dotGap, h = dotsH, page = pg })
        end
    end

    -- ── Dock ─────────────────────────────────────────────
    -- ordered list of dock apps that actually exist
    local dockList = {}
    for _, id in ipairs(DOCK_APPS) do
        if dockApps[id] then table.insert(dockList, dockApps[id]) end
    end
    local nDock = #dockList
    if nDock > 0 then
        local dockIcon = math.min(FT.py(48), dockH * 0.62)
        local dGap     = FT.px(18)
        local rowW     = nDock * dockIcon + (nDock - 1) * dGap
        local panelPad = FT.px(16)
        local panelW   = math.min(sw - FT.px(40), rowW + panelPad*2)
        local panelX   = sx + sw/2 - panelW/2
        local panelY   = dockY + (dockH - (dockIcon + FT.py(18)))/2
        local panelH   = dockIcon + FT.py(18)

        -- frosted dock panel
        r:rect(panelX, panelY, panelW, panelH, {1,1,1,0.06})
        r:rect(panelX, panelY, panelW, FT.py(1), {1,1,1,0.10})
        r:rect(panelX, panelY + panelH - FT.py(1), panelW, FT.py(1), {0,0,0,0.20})

        local startX = sx + sw/2 - rowW/2
        local iy = panelY + (panelH - dockIcon)/2
        for i, app in ipairs(dockList) do
            local ix = startX + (i-1) * (dockIcon + dGap)
            table.insert(self._iconQueue, {
                appId = app.id, x = ix, y = iy, size = dockIcon,
                mono = app.navLabel or "?",
            })
            self._appCellRects[app.id] = { x = ix, y = iy, w = dockIcon, h = dockIcon }
            table.insert(self._dockBtns, { appId = app.id, x = ix - dGap/2, y = panelY, w = dockIcon + dGap, h = panelH })
        end
    end

    -- ── Home indicator pill ──────────────────────────────
    local pillW = sw * 0.22
    r:rect(sx + sw/2 - pillW/2, homeIndY + homeIndH/2 - FT.py(1.5), pillW, FT.py(3), {1,1,1,0.45})
end
