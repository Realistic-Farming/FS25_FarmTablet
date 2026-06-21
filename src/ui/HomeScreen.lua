-- =========================================================
-- FarmTablet v2 – HomeScreen (springboard)
-- Adds FarmTabletUI:_drawHome — a paged grid of glossy app icons
-- with a bottom dock, page dots and a home indicator.
--
-- Also hosts the FAVOURITES page: a star toggle in the top toolbar flips
-- the grid between "all apps" (springboard) and the user's starred apps.
-- An EDIT button on the favourites page lets the user pick favourites by
-- tapping icons (mirrors the Dashboard app's customize flow). Choices
-- persist to settings.favoriteApps.
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

-- ── Favourites list helpers (persisted to settings.favoriteApps) ──
local function splitCSV(s)
    local t = {}
    for id in string.gmatch(s or "", "([^,]+)") do
        id = id:gsub("^%s+", ""):gsub("%s+$", "")
        if id ~= "" then t[#t + 1] = id end
    end
    return t
end

function FarmTabletUI:getFavoriteApps()
    return splitCSV(self.settings and self.settings.favoriteApps)
end

function FarmTabletUI:isFavoriteApp(id)
    for _, fid in ipairs(self:getFavoriteApps()) do
        if fid == id then return true end
    end
    return false
end

-- Add/remove an app from favourites and persist immediately (matches the
-- Dashboard customize pattern: mutate the setting then settings:save()).
function FarmTabletUI:toggleFavorite(id)
    local list  = self:getFavoriteApps()
    local found = false
    for i, fid in ipairs(list) do
        if fid == id then table.remove(list, i); found = true; break end
    end
    if not found then list[#list + 1] = id end
    if self.settings then
        self.settings.favoriteApps = table.concat(list, ",")
        if self.settings.save then self.settings:save() end
    end
end

function FarmTabletUI:_drawHome()
    local L = FT.LAYOUT
    local r = self.r
    local sx, sw = L.screenX, L.screenW
    local favMode = (self._homeMode == "favorites")
    local editing = favMode and self._favEditing

    -- ── Bottom furniture zones (home indicator, dock, page dots) ──
    local homeIndH = FT.py(HOMEIND_REF)
    local homeIndY = L.canvasY + FT.py(3)
    local dockH    = FT.py(DOCK_H_REF)
    local dockY    = homeIndY + homeIndH + FT.py(2)
    local dotsH    = FT.py(14)
    -- Favourites mode hides the dock, so dots drop down to reclaim the space.
    local dotsY    = favMode and (homeIndY + homeIndH + FT.py(6))
                              or (dockY + dockH + FT.py(2))

    -- ── Top toolbar: star toggle (+ favourites title / EDIT button) ──
    local toolH   = FT.py(22)
    local toolTop = L.canvasY + L.canvasH - FT.py(2)
    local toolBot = toolTop - toolH

    local starW, starH = FT.px(30), FT.py(20)
    local starX = sx + FT.px(14)
    local starY = toolBot + (toolH - starH) / 2
    self:_drawStarGlyph(starX, starY, starW, starH, favMode)
    self._homeStarBtn = { x = starX - FT.px(3), y = starY - FT.py(3),
                          w = starW + FT.px(6), h = starH + FT.py(6) }

    if favMode then
        r:text(starX + starW + FT.px(10), toolBot + toolH / 2 - FT.py(5),
            FT.FONT.SMALL, "Favourites", RenderText.ALIGN_LEFT, {0.95, 0.96, 0.98, 0.95})

        local edW, edH = FT.px(48), FT.py(18)
        local edX = sx + sw - FT.px(14) - edW
        local edY = toolBot + (toolH - edH) / 2
        r:rect(edX, edY, edW, edH, editing and {0.20, 0.55, 0.32, 0.88} or {0.18, 0.20, 0.26, 0.78})
        r:text(edX + edW / 2, edY + edH / 2 - FT.py(4), FT.FONT.TINY,
            editing and "DONE" or "EDIT", RenderText.ALIGN_CENTER, {0.95, 0.97, 0.99, 0.95})
        self._favEditBtn = { x = edX, y = edY, w = edW, h = edH }
    end

    -- ── Grid zone ────────────────────────────────────────
    local gridX   = sx + FT.px(18)
    local gridW   = sw - FT.px(36)
    local gridTop = toolBot - FT.py(6)
    local gridBot = dotsY + dotsH + FT.py(4)
    local gridH   = math.max(FT.py(40), gridTop - gridBot)

    -- ── App lists ────────────────────────────────────────
    local allApps = self.system.registry:getAll()
    local gridApps, dockApps = {}, {}
    for _, app in ipairs(allApps) do
        if isDockApp(app.id) then dockApps[app.id] = app end
    end

    if editing then
        -- Edit: show every app so the user can star/unstar any of them.
        for _, app in ipairs(allApps) do table.insert(gridApps, app) end
    elseif favMode then
        -- View: only favourites, in saved order.
        local byId = {}
        for _, app in ipairs(allApps) do byId[app.id] = app end
        for _, id in ipairs(self:getFavoriteApps()) do
            if byId[id] then table.insert(gridApps, byId[id]) end
        end
    else
        -- Springboard: all non-dock apps (dock shown separately below).
        for _, app in ipairs(allApps) do
            if not isDockApp(app.id) then table.insert(gridApps, app) end
        end
    end

    -- ── Empty-state for the favourites view ───────────────
    if favMode and not editing and #gridApps == 0 then
        local midY = gridBot + gridH / 2
        r:text(sx + sw / 2, midY + FT.py(4), FT.FONT.BODY,
            "No favourites yet", RenderText.ALIGN_CENTER, {0.85, 0.87, 0.92, 0.95})
        r:text(sx + sw / 2, midY - FT.py(14), FT.FONT.SMALL,
            "Tap EDIT, then pick your apps", RenderText.ALIGN_CENTER, {0.62, 0.65, 0.72, 0.9})
        local pillW = sw * 0.22
        r:rect(sx + sw / 2 - pillW / 2, homeIndY + homeIndH / 2 - FT.py(1.5), pillW, FT.py(3), {1, 1, 1, 0.45})
        return
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

    -- Icon-label appearance (Settings ▸ Appearance)
    local s          = self.settings or {}
    local showLabels = (s.iconLabelsShow ~= false)
    local LBL_SIZES  = { 0.0062, 0.0076, 0.0092 }   -- small / medium / large
    local LBL_CHARS  = { 13, 11, 9 }
    local szIdx      = s.iconLabelSize or 2
    local lblFont    = LBL_SIZES[szIdx] or LBL_SIZES[2]
    local lblMax     = LBL_CHARS[szIdx] or 11
    local lblMode    = s.iconLabelColor or 1
    local lblH       = showLabels and labelH or 0   -- 0 → recentre icon in cell

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

            local iconCx = cellLeft + cellW / 2
            local iconY  = cellBottom + lblH + (cellH - lblH - iconSize) * 0.5
            local iconX  = iconCx - iconSize / 2

            table.insert(self._iconQueue, {
                appId = app.id, x = iconX, y = iconY, size = iconSize,
                mono = app.navLabel or string.upper(string.sub(app.id, 1, 2)),
            })
            self._appCellRects[app.id] = { x = iconX, y = iconY, w = iconSize, h = iconSize }

            -- Favourite badge: in edit mode, mark which apps are starred.
            if editing and self:isFavoriteApp(app.id) then
                local bs = FT.px(14)
                local bx = iconX + iconSize - bs * 0.55
                local by = iconY + iconSize - bs * 0.55
                r:rect(bx, by, bs, bs, {0.10, 0.10, 0.13, 0.70})
                self:_drawStarMark(bx, by, bs, bs, {1.0, 0.86, 0.35, 1.0})
            end

            -- label (size + colour from settings; can be hidden entirely)
            if showLabels then
                local lblColor
                if lblMode == 2 then
                    lblColor = {1.0, 0.86, 0.40, 0.97}        -- gold
                elseif lblMode == 3 then
                    local ac = FT.appColor(app.id)
                    lblColor = {ac[1], ac[2], ac[3], 0.97}    -- app accent
                else
                    lblColor = {0.95, 0.96, 0.98, 0.95}       -- white
                end
                r:appText(iconCx, cellBottom + labelH * 0.25, lblFont,
                    appLabel(app, lblMax), RenderText.ALIGN_CENTER, lblColor)
            end

            -- full-cell hitbox
            table.insert(self._iconBtns, { appId = app.id, x = cellLeft, y = cellBottom, w = cellW, h = cellH })
        end
    end

    -- ── Edit-mode hint ───────────────────────────────────
    if editing then
        r:text(sx + sw / 2, gridBot - FT.py(2), FT.FONT.TINY,
            "Tap an app to add or remove it from favourites",
            RenderText.ALIGN_CENTER, {0.62, 0.65, 0.72, 0.9})
    end

    -- ── Page dots ────────────────────────────────────────
    self._pageDots = {}
    if self._pageCount > 1 then
        local dotSz  = FT.px(6)
        local dotGap = FT.px(8)
        local totalW = self._pageCount * dotSz + (self._pageCount - 1) * dotGap
        local startX = sx + sw / 2 - totalW / 2
        local dy = dotsY + dotsH / 2 - dotSz / 2
        for pg = 0, self._pageCount - 1 do
            local dx = startX + pg * (dotSz + dotGap)
            local active = (pg == self._page)
            r:rect(dx, dy, dotSz, dotSz,
                active and {0.95, 0.96, 0.98, 0.95} or {0.95, 0.96, 0.98, 0.30})
            table.insert(self._pageDots, { x = dx - dotGap / 2, y = dotsY, w = dotSz + dotGap, h = dotsH, page = pg })
        end
    end

    -- ── Dock (springboard mode only) ──────────────────────
    if not favMode then
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
            local panelW   = math.min(sw - FT.px(40), rowW + panelPad * 2)
            local panelX   = sx + sw / 2 - panelW / 2
            local panelY   = dockY + (dockH - (dockIcon + FT.py(18))) / 2
            local panelH   = dockIcon + FT.py(18)

            -- frosted dock panel
            r:rect(panelX, panelY, panelW, panelH, {1, 1, 1, 0.06})
            r:rect(panelX, panelY, panelW, FT.py(1), {1, 1, 1, 0.10})
            r:rect(panelX, panelY + panelH - FT.py(1), panelW, FT.py(1), {0, 0, 0, 0.20})

            local startX = sx + sw / 2 - rowW / 2
            local iy = panelY + (panelH - dockIcon) / 2
            for i, app in ipairs(dockList) do
                local ix = startX + (i - 1) * (dockIcon + dGap)
                table.insert(self._iconQueue, {
                    appId = app.id, x = ix, y = iy, size = dockIcon,
                    mono = app.navLabel or "?",
                })
                self._appCellRects[app.id] = { x = ix, y = iy, w = dockIcon, h = dockIcon }
                table.insert(self._dockBtns, { appId = app.id, x = ix - dGap / 2, y = panelY, w = dockIcon + dGap, h = panelH })
            end
        end
    end

    -- ── Home indicator pill ──────────────────────────────
    local pillW = sw * 0.22
    r:rect(sx + sw / 2 - pillW / 2, homeIndY + homeIndH / 2 - FT.py(1.5), pillW, FT.py(3), {1, 1, 1, 0.45})
end
