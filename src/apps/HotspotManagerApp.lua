-- =========================================================
-- FarmTablet v2 – Hotspot Manager App
-- View map hotspots/pins; multi-select remove; add pin at player.
-- =========================================================

-- ── Category labels ───────────────────────────────────────

local function hs_getCategoryLabel(cat)
    if MapHotspot then
        if cat == MapHotspot.CATEGORY_FIELD      then return "Field"      end
        if cat == MapHotspot.CATEGORY_ANIMAL     then return "Animal"     end
        if cat == MapHotspot.CATEGORY_MISSION    then return "Mission"    end
        if cat == MapHotspot.CATEGORY_STEERABLE  then return "Vehicle"    end
        if cat == MapHotspot.CATEGORY_COMBINE    then return "Combine"    end
        if cat == MapHotspot.CATEGORY_TRAILER    then return "Trailer"    end
        if cat == MapHotspot.CATEGORY_TOOL       then return "Tool"       end
        if cat == MapHotspot.CATEGORY_UNLOADING  then return "Unloading"  end
        if cat == MapHotspot.CATEGORY_LOADING    then return "Loading"    end
        if cat == MapHotspot.CATEGORY_PRODUCTION then return "Production" end
        if cat == MapHotspot.CATEGORY_SHOP       then return "Shop"       end
        if cat == MapHotspot.CATEGORY_AI         then return "AI"         end
        if cat == MapHotspot.CATEGORY_PLAYER     then return "Player"     end
        if cat == MapHotspot.CATEGORY_TOUR       then return "Tour"       end
        if cat == MapHotspot.CATEGORY_OTHER      then return "Other"      end
    end
    return "Pin"
end

local function hs_getName(hotspot)
    local ok, name = pcall(function() return hotspot:getName() end)
    if ok and name and name ~= "" then return name end
    if hotspot.name and hotspot.name ~= "" then return hotspot.name end
    return "(unnamed)"
end

local function hs_getIngameMap()
    return g_currentMission
        and g_currentMission.hud
        and g_currentMission.hud.ingameMap
end

local function hs_hotspotKey(hs)
    if hs == nil then return "?" end
    local n = hs_getName(hs)
    local x = tonumber(hs.worldX or hs.xMapPos) or 0
    local z = tonumber(hs.worldZ or hs.zMapPos) or 0
    return string.format("%s|%.1f|%.1f|%s", tostring(hs.category or ""), x, z, n)
end

-- Hotspot removal is a LOCAL client-side operation — it only affects this player's
-- map view. Other players' maps and the server are not affected. System hotspots
-- (shops, missions) will reappear on server re-sync; this is intentional.
local function hs_removeHotspot(hotspot)
    local im = hs_getIngameMap()
    if not im then return false end
    local ok = pcall(function()
        if im.removeMapHotspot then
            im:removeMapHotspot(hotspot)
        elseif g_currentMission and g_currentMission.removeMapHotspot then
            g_currentMission:removeMapHotspot(hotspot)
        end
        if hotspot.delete then hotspot:delete() end
    end)
    return ok == true
end

--- Add a custom pin at the local player's world position (client map only).
local function hs_addPinAtPlayer()
    local px, pz
    if g_localPlayer and g_localPlayer.rootNode then
        local ok, x, _, z = pcall(getWorldTranslation, g_localPlayer.rootNode)
        if ok and x then px, pz = x, z end
    end
    if px == nil and g_currentMission and g_currentMission.player and g_currentMission.player.rootNode then
        local ok, x, _, z = pcall(getWorldTranslation, g_currentMission.player.rootNode)
        if ok and x then px, pz = x, z end
    end
    if px == nil then return false, "No player position" end

    local hotspot = nil
    local okCreate = pcall(function()
        if PlaceableHotspot ~= nil and PlaceableHotspot.new then
            hotspot = PlaceableHotspot.new()
            if hotspot.setName then hotspot:setName("Farm Tablet pin") end
            if hotspot.setWorldPosition then hotspot:setWorldPosition(px, pz) end
            if PlaceableHotspot.TYPE and PlaceableHotspot.TYPE.EXCLAMATION_MARK then
                hotspot.placeableType = PlaceableHotspot.TYPE.EXCLAMATION_MARK
            end
        elseif MapHotspot ~= nil and MapHotspot.new then
            local cat = MapHotspot.CATEGORY_OTHER or MapHotspot.CATEGORY_DEFAULT
            hotspot = MapHotspot.new("Farm Tablet pin", cat)
            if hotspot.setWorldPosition then
                hotspot:setWorldPosition(px, pz)
            elseif hotspot.setPosition then
                hotspot:setPosition(px, pz)
            end
            if hotspot.setText then hotspot:setText("Farm Tablet pin") end
        end
    end)
    if not okCreate or hotspot == nil then
        return false, "Hotspot API unavailable"
    end

    local okAdd = pcall(function()
        local im = hs_getIngameMap()
        if im and im.addMapHotspot then
            im:addMapHotspot(hotspot)
        elseif g_currentMission and g_currentMission.addMapHotspot then
            g_currentMission:addMapHotspot(hotspot)
        else
            error("no addMapHotspot")
        end
    end)
    if not okAdd then
        pcall(function() if hotspot.delete then hotspot:delete() end end)
        return false, "Could not add pin"
    end
    return true, nil
end

-- ── Module state ──────────────────────────────────────────

local _confirmClear = false
local _confirmTimer = 0
local _selected = {}   -- [hotspotKey] = true
local _statusMsg = nil
local _statusTimer = 0

-- ── Drawer ────────────────────────────────────────────────

FarmTabletUI:registerDrawer(FT.APP.HOTSPOT_MGR, function(self)
    local AC = FT.appColor(FT.APP.HOTSPOT_MGR)

    if self:drawHelpPage("_hotspotHelp", FT.APP.HOTSPOT_MGR, "Hotspot Manager", AC, {
        { title = "WHAT IS THIS?",
          body  = "Shows all active map hotspots / pins.\n" ..
                  "Tick the checkbox beside a pin, then REMOVE SELECTED.\n" ..
                  "ADD PIN HERE drops a custom pin at your feet.\n\n" ..
                  "Removing system hotspots (Missions, Shops) may break\n" ..
                  "game features — be careful. System pins can return\n" ..
                  "after a map re-sync." },
        { title = "CLEAR ALL",
          body  = "Press CLEAR ALL once — it turns red and asks\n" ..
                  "for confirmation. Press it again within 4 seconds\n" ..
                  "to remove every hotspot from the map." },
    }) then return end

    local im = hs_getIngameMap()
    local hotspots = im and im.hotspots or {}
    local total = #hotspots

    -- Decay confirm / status timers (approx frames)
    _confirmTimer = math.max(0, _confirmTimer - 1)
    if _confirmTimer == 0 then _confirmClear = false end
    _statusTimer = math.max(0, _statusTimer - 1)
    if _statusTimer == 0 then _statusMsg = nil end

    -- Drop stale selection keys
    local liveKeys = {}
    for _, hs in ipairs(hotspots) do
        liveKeys[hs_hotspotKey(hs)] = true
    end
    for k, _ in pairs(_selected) do
        if not liveKeys[k] then _selected[k] = nil end
    end

    local selectedCount = 0
    for _, v in pairs(_selected) do
        if v then selectedCount = selectedCount + 1 end
    end

    local startY = self:drawAppHeader("Hotspot Manager",
        total > 0 and (total .. " total") or "Empty")
    local x, cy, cw, ch = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY
    local BTN_H = FT.py(20)
    local GAP   = FT.py(5)
    local bottomPad = FT.py(28)

    -- ── Action row: ADD / REMOVE SELECTED / CLEAR ALL ─────
    y = y - FT.py(2)
    local gapX = FT.px(4)
    local btnW = (cw - gapX * 2) / 3

    local btnAdd = self.r:button(x, y - BTN_H, btnW, BTN_H, "ADD PIN HERE", FT.C.BTN_PRIMARY, {
        onClick = function()
            local ok, err = hs_addPinAtPlayer()
            _statusMsg = ok and "Pin added at your position." or (err or "Add failed")
            _statusTimer = 180
        end
    })
    table.insert(self._contentBtns, btnAdd)

    local rmLabel = selectedCount > 0
        and string.format("REMOVE (%d)", selectedCount) or "REMOVE"
    local rmColor = selectedCount > 0 and FT.C.BTN_DANGER or FT.C.BTN_NEUTRAL
    local btnRmSel = self.r:button(x + btnW + gapX, y - BTN_H, btnW, BTN_H, rmLabel, rmColor, {
        onClick = function()
            if selectedCount == 0 then
                _statusMsg = "Tick pins to remove first."
                _statusTimer = 120
                return
            end
            local toRemove = {}
            for _, hs in ipairs(im.hotspots or {}) do
                if _selected[hs_hotspotKey(hs)] then
                    toRemove[#toRemove + 1] = hs
                end
            end
            for _, hs in ipairs(toRemove) do
                hs_removeHotspot(hs)
                _selected[hs_hotspotKey(hs)] = nil
            end
            _statusMsg = string.format("Removed %d pin(s).", #toRemove)
            _statusTimer = 180
        end
    })
    table.insert(self._contentBtns, btnRmSel)

    if total > 0 then
        local clearLabel = _confirmClear
            and "CONFIRM CLEAR" or "CLEAR ALL"
        local clearColor = _confirmClear and FT.C.BTN_DANGER or FT.C.BTN_NEUTRAL
        local btnClear = self.r:button(x + (btnW + gapX) * 2, y - BTN_H, btnW, BTN_H,
            clearLabel, clearColor, {
            onClick = function()
                if _confirmClear then
                    local toRemove = {}
                    for _, hs in ipairs(im.hotspots) do table.insert(toRemove, hs) end
                    for _, hs in ipairs(toRemove) do hs_removeHotspot(hs) end
                    _selected = {}
                    _confirmClear = false
                    _confirmTimer = 0
                    _statusMsg = "All pins cleared."
                    _statusTimer = 180
                else
                    _confirmClear = true
                    _confirmTimer = 240
                end
            end
        })
        table.insert(self._contentBtns, btnClear)
    end
    y = y - BTN_H - FT.py(6)

    if _statusMsg then
        self.r:appText(x, y - FT.py(2), FT.FONT.TINY, _statusMsg,
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        y = y - FT.py(14)
    end

    -- ── Hotspot list with checkboxes ──────────────────────
    y = self:drawRule(y - FT.py(2), 0.3)
    y = y - FT.py(6)
    y = self:drawSection(y, "HOTSPOTS  (tick to select)")
    y = y - GAP

    if total == 0 then
        self.r:appText(x + cw / 2, y - FT.py(12), FT.FONT.SMALL,
            "No hotspots on the map — use ADD PIN HERE.",
            RenderText.ALIGN_CENTER, FT.C.TEXT_DIM)
        y = y - FT.py(24)
    else
        local checkW = FT.px(22)
        local catW   = FT.px(58)
        local nameW  = cw - checkW - catW - FT.px(8)
        local rowH   = FT.py(20)

        for i, hs in ipairs(hotspots) do
            if y < cy + bottomPad then break end

            local key       = hs_hotspotKey(hs)
            local checked   = _selected[key] == true
            local catLabel  = hs_getCategoryLabel(hs.category)
            local nameLabel = FT_Renderer.truncate(hs_getName(hs), 22)

            -- Checkbox
            local boxCol = checked and FT.C.BTN_PRIMARY or FT.C.BTN_NEUTRAL
            -- ASCII marks only (engine font may not draw unicode ticks).
            local mark   = checked and "x" or "-"
            local capturedKey = key
            local btnChk = self.r:button(x, y - rowH + FT.py(2), checkW, rowH - FT.py(2),
                mark, boxCol, {
                onClick = function()
                    if _selected[capturedKey] then
                        _selected[capturedKey] = nil
                    else
                        _selected[capturedKey] = true
                    end
                end
            })
            table.insert(self._contentBtns, btnChk)

            self.r:appText(x + checkW + FT.px(4), y - FT.py(5), FT.FONT.TINY,
                catLabel, RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            self.r:appText(x + checkW + catW, y - FT.py(5), FT.FONT.SMALL,
                nameLabel, RenderText.ALIGN_LEFT,
                checked and FT.C.TEXT_BRIGHT or FT.C.TEXT_NORMAL)

            y = y - rowH - GAP
        end
    end

    self:setContentHeight(startY - y + scrollY + bottomPad)
    self:drawInfoIcon("_hotspotHelp", AC)
    self:drawScrollBar()
end)
