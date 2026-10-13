-- =========================================================
-- FarmTablet v2 - Excavator App
-- Merges Digging (terrain depth readout) + Bucket Tracker
-- (session loads / weight / history). Bucket session state
-- lives on FarmTabletSystem and updates every frame so
-- counting continues when this page (or the tablet) is closed.
-- =========================================================

local ExcavatorState = {
    lastScan = 0,
}

local function resolvePlayerPose()
    local px, py, pz = 0, 0, 0
    local hasPlayer = false

    if g_localPlayer then
        if g_localPlayer.getIsInVehicle and g_localPlayer:getIsInVehicle() then
            local veh = g_localPlayer.getCurrentVehicle and g_localPlayer:getCurrentVehicle()
            if veh then
                local se = veh.spec_enterable
                local camNode = se and se.activeCamera and se.activeCamera.cameraNode
                if camNode and camNode ~= 0 then
                    local ok, cx, cy, cz = pcall(getWorldTranslation, camNode)
                    if ok and cx then
                        hasPlayer = true
                        px, py, pz = cx, cy, cz
                    end
                end
                if not hasPlayer and veh.rootNode and veh.rootNode ~= 0 then
                    local ok, vx, vy, vz = pcall(getWorldTranslation, veh.rootNode)
                    if ok and vx then
                        hasPlayer = true
                        px, py, pz = vx, vy, vz
                    end
                end
            end
        end
        if not hasPlayer and g_localPlayer.rootNode then
            local ok, rx, ry, rz = pcall(getWorldTranslation, g_localPlayer.rootNode)
            if ok and rx then
                hasPlayer = true
                px, py, pz = rx, ry, rz
            end
        end
    end

    return hasPlayer, px, py, pz
end

FarmTabletUI:registerDrawer(FT.APP.EXCAVATOR, function(self)
    local AC = FT.appColor(FT.APP.EXCAVATOR)

    if self:drawHelpPage("_excavatorHelp", FT.APP.EXCAVATOR, FT.l10n("ft_ui_app_excavator", "Excavator"), AC, {
        { title = FT.l10n("ft_excavator_help_terrain_title", "TERRAIN READOUT"),
          body  = FT.l10n("ft_excavator_help_terrain_body", "Shows your current world position, vehicle name and\nspeed, ground height, and how far above or below the\nterrain surface you are. Values refresh while this\npage is open."), literalTitle = true, literalBody = true },
        { title = FT.l10n("ft_excavator_help_bucket_title", "BUCKET COUNTING"),
          body  = FT.l10n("ft_excavator_help_bucket_body", "Load counting runs in the background whenever you\ndrive a wheel loader, excavator, or material handler.\nIt keeps going if you leave this page or close the\ntablet. No setup required."), literalTitle = true, literalBody = true },
        { title = "SUMMARY CARDS",
          body  = FT.l10n("ft_excavator_help_cards_body", "LOADS = dump cycles recorded this session.\nWEIGHT = total material moved in tonnes.\nITEMS = number of history entries kept."), literalBody = true },
        { title = "LOAD HISTORY",
          body  = FT.l10n("ft_excavator_help_history_body", "Lists recent dump cycles with material name and\nestimated weight. Older rows scroll off the list."), literalBody = true },
        { title = "RESET",
          body  = FT.l10n("ft_excavator_help_reset_body", "Clears load history and session totals. Use at the\nstart of a new job to track productivity separately."), literalBody = true },
    }, true) then return end

    local bt = self.system.bucket
    local startY = self:drawAppHeader(FT.l10n("ft_ui_app_excavator", "Excavator"),
        FT.l10n("ft_excavator_subtitle", "Terrain + Bucket"), true, true)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    local hasPlayer, px, py, pz = resolvePlayerPose()
    y = self:drawSection(y, "POSITION")
    if hasPlayer then
        y = self:drawRow(y, "X", string.format("%.1f", px), nil, nil, nil, true)
        y = self:drawRow(y, "Y", string.format("%.1f", py), nil, nil, nil, true)
        y = self:drawRow(y, "Z", string.format("%.1f", pz), nil, nil, nil, true)
    else
        self.r:appText(x, y - FT.py(4), FT.FONT.BODY,
            "Player position unavailable.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(22)
    end

    local vehicle = g_currentMission and g_currentMission.controlledVehicle
    if vehicle then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.25)
        y = self:drawSection(y, "VEHICLE")
        local nm = (vehicle.getFullName and vehicle:getFullName()) or "Unknown"
        if FT.utf8Len(nm) > 20 then nm = FT.utf8Sub(nm, 18) .. ".." end
        y = self:drawRow(y, "Name", nm)
        if vehicle.lastSpeed then
            y = self:drawRow(y, "Speed", FT.l10nFormat("ft_excavator_speed_fmt", "%.1f km/h", math.abs(vehicle.lastSpeed) * 3600), nil, nil, nil, true)
        end
        if vehicle.getAttachedImplements then
            local impls = vehicle:getAttachedImplements()
            if impls and #impls > 0 then
                local names = {}
                for _, imp in ipairs(impls) do
                    if imp.object then
                        local iname = (imp.object.getFullName and imp.object:getFullName()) or FT.l10nAuto("Implement")
                        if FT.utf8Len(iname) > 16 then iname = FT.utf8Sub(iname, 14) .. ".." end
                        table.insert(names, iname)
                        if #names >= 2 then break end
                    end
                end
                if #names > 0 then y = self:drawRow(y, "Attached", table.concat(names, ", ")) end
            end
        end
    end

    if hasPlayer then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.25)
        y = self:drawSection(y, "TERRAIN AT POSITION")
        local groundY = nil
        if getTerrainHeightAtWorldPos and g_terrainNode then
            local ok, val = pcall(getTerrainHeightAtWorldPos, g_terrainNode, px, 0, pz)
            if ok then groundY = val end
        end
        if groundY then
            local above = py - groundY
            y = self:drawRow(y, "Ground Level", string.format("%.2f m", groundY))
            y = self:drawRow(y, "Above Ground", string.format("%.2f m", above), nil,
                above < 0 and FT.C.NEGATIVE or above < 0.5 and FT.C.WARNING or FT.C.TEXT_ACCENT)
        else
            y = self:drawRow(y, "Ground Level", "N/A", nil, FT.C.TEXT_DIM)
        end
    end

    y = y - FT.py(6)
    y = self:drawRule(y, 0.35)
    y = self:drawSection(y, FT.l10n("ft_excavator_bucket_session", "BUCKET SESSION"), true)

    y = y - FT.py(4)
    local cardW = (cw - FT.px(8)) / 3
    local cards = {
        { label = "LOADS",  value = tostring(bt.totalLoads) },
        { label = "WEIGHT", value = string.format("%.0ft", (bt.totalWeight or 0) / 1000) },
        { label = "ITEMS",  value = tostring(#bt.history) },
    }
    for i, card in ipairs(cards) do
        local cx = x + (i - 1) * (cardW + FT.px(4))
        self.r:appRect(cx, y - FT.py(34), cardW, FT.py(38), FT.C.BG_CARD)
        self.r:appText(cx + cardW / 2, y - FT.py(10), FT.FONT.HUGE, card.value,
            RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)
        self.r:appText(cx + cardW / 2, y - FT.py(28), FT.FONT.TINY, card.label,
            RenderText.ALIGN_CENTER, FT.C.TEXT_DIM)
    end
    y = y - FT.py(40)

    if bt.vehicle then
        local fi = self.system:_getBucketFillInfo(bt.vehicle)
        local nm = (bt.vehicle.getFullName and bt.vehicle:getFullName()) or "Unknown"
        if FT.utf8Len(nm) > 22 then nm = FT.utf8Sub(nm, 20) .. ">" end
        y = self:drawSection(y, FT.l10n("ft_excavator_active_bucket", "ACTIVE BUCKET"), true)
        y = self:drawRow(y, "Vehicle", nm)
        y = self:drawRow(y, "Fill",
            string.format("%.0f / %.0f L  (%s)", fi.total, fi.cap, fi.name), nil, FT.C.TEXT_ACCENT)
        y = y + FT.py(FT.SP.ROW) - FT.py(8)
        y = self:drawBar(y, fi.total, fi.cap, FT.C.BRAND)
        y = y - FT.py(4)
    else
        y = self:drawSection(y, FT.l10n("ft_excavator_active_bucket", "ACTIVE BUCKET"), true)
        self.r:appText(x, y, FT.FONT.SMALL, FT.l10n("ft_excavator_no_bucket", "No bucket vehicle detected."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(20)
    end

    y = self:drawRule(y, 0.35)
    y = self:drawSection(y, FT.l10nFormat("ft_excavator_history_fmt", "LOAD HISTORY  (%d)", #bt.history), true)
    local minY = contentY + FT.py(32)

    if #bt.history == 0 then
        self.r:appText(x, y, FT.FONT.SMALL, "No loads recorded yet.",
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(20)
    else
        self.r:appText(x,             y, FT.FONT.TINY, "#",        RenderText.ALIGN_LEFT,  FT.C.TEXT_DIM, true)
        self.r:appText(x + FT.px(20), y, FT.FONT.TINY, "MATERIAL", RenderText.ALIGN_LEFT,  FT.C.TEXT_DIM)
        self.r:appText(x + cw,        y, FT.FONT.TINY, "WEIGHT",   RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        y = y - FT.py(14)
        for i = #bt.history, 1, -1 do
            local load = bt.history[i]
            self.r:appText(x,             y, FT.FONT.TINY,  tostring(load.n),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            self.r:appText(x + FT.px(20), y, FT.FONT.SMALL, load.typeName or "Unknown",
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + cw,        y, FT.FONT.SMALL,
                FT.l10nFormat("ft_excavator_kg_fmt", "%.0f kg", load.weight or 0),
                RenderText.ALIGN_RIGHT, FT.C.TEXT_ACCENT, true)
            y = y - FT.py(18)
        end
    end

    if y > minY + FT.py(4) then
        self:drawButton(minY + FT.py(2), FT.l10nAuto("RESET"), FT.C.BTN_DANGER, {
            onClick = function()
                self.system:resetBucket()
                self:switchApp(FT.APP.EXCAVATOR)
            end,
        }, true)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_excavatorHelp", AC)
    self:drawScrollBar()
end)

function FarmTabletUI:updateExcavatorApp(dt)
    if self.system.currentApp ~= FT.APP.EXCAVATOR then return end
    ExcavatorState.lastScan = (ExcavatorState.lastScan or 0) + dt
    if ExcavatorState.lastScan >= 500 then
        ExcavatorState.lastScan = 0
        self.r:clearAppLayer()
        self._contentBtns = {}
        self:_drawContent()
    end
end
