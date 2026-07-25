-- =========================================================
-- FarmTablet v2 – Production Buildings App
-- Owned production chains: building name, active status,
-- input and output fill types.
-- Data via g_currentMission.productionChainManager.
-- =========================================================

local function PText(key, fallback)
    if FT_UI_TEXT ~= nil then return FT_UI_TEXT(key, fallback) end
    if g_i18n and key and g_i18n:hasText(key) then return g_i18n:getText(key) end
    return fallback or tostring(key or "")
end

FarmTabletUI:registerDrawer(FT.APP.PRODUCTION, function(self)
    local AC = FT.appColor(FT.APP.PRODUCTION)

    if self:drawHelpPage("_prodHelp", FT.APP.PRODUCTION, "Production", AC, {
        { title = "BUILDING LIST",
          body  = "Shows every production building your farm owns.\n" ..
                  "Each entry shows the building name and how many of its\n" ..
                  "production lines are currently active." },
        { title = "ACTIVE / STALLED",
          body  = "Active: at least one production chain is enabled and\n" ..
                  "the building has the inputs it needs.\n" ..
                  "Stalled: no productions are enabled (check the building\n" ..
                  "management menu to turn them on)." },
        { title = "INPUTS / OUTPUTS",
          body  = "Lists the fill types the building consumes and produces.\n" ..
                  "Check your Storage app to ensure inputs are stocked.\n" ..
                  "Outputs pile up if the unloading station is full — check\n" ..
                  "your silo capacity." },
        { title = "NO BUILDINGS SHOWN",
          body  = "Production buildings must be owned by your farm.\n" ..
                  "Purchase a cheese factory, bakery, or other production\n" ..
                  "placeable from the shop to see it here." },
    }) then return end

    local data    = self.system.data
    local farmId  = data:getPlayerFarmId()
    local buildings = data:getProductionBuildings(farmId)

    local subtitle = #buildings == 1 and PText("ft_production_one_building", "1 building") or string.format(PText("ft_production_buildings_fmt", "%d buildings"), #buildings)
    local startY   = self:drawAppHeader(PText("ft_app_production", "Production"), subtitle)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y       = startY - FT.py(8) + scrollY

    if #buildings == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            PText("ft_production_none", "No production buildings owned."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(28), FT.FONT.SMALL,
            PText("ft_production_buy_hint", "Purchase a production placeable to track it here."),
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_prodHelp", AC)
        return
    end

    for _, b in ipairs(buildings) do
        -- ── Card background ───────────────────────────────
        local ioLines = math.max(#b.inputs, #b.outputs, 1)
        local cardH   = FT.py(30 + ioLines * 14 + 14)

        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4),
            cw + FT.px(8), cardH, {AC[1]*0.06, AC[2]*0.06, AC[3]*0.06, 0.80})
        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4), FT.px(3), cardH,
            {AC[1], AC[2], AC[3], 0.55})

        -- Status badge (top-right) first so the name can reserve space.
        local isActive   = b.activeCount > 0
        local statusText = isActive
            and string.format(PText("ft_production_active_fmt", "%d/%d active"), b.activeCount, b.totalCount)
            or  PText("ft_production_stalled", "stalled")
        local statusColor = isActive and FT.C.POSITIVE or FT.C.WARNING
        self.r:appText(x + cw - FT.px(6), y - FT.py(10), FT.FONT.TINY,
            statusText, RenderText.ALIGN_RIGHT, statusColor)

        -- ── Building name ─────────────────────────────────
        local nameMax = math.max(10, math.floor((cw - FT.px(90)) / FT.px(6.5)))
        self.r:appText(x + FT.px(10), y - FT.py(10), FT.FONT.SMALL,
            FT_Renderer.truncate(b.name, nameMax), RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)

        -- Accent line below name
        self.r:appRect(x + FT.px(10), y - FT.py(18), cw - FT.px(20), FT.py(1),
            {AC[1], AC[2], AC[3], 0.30})

        local ioY = y - FT.py(27)

        -- ── Inputs column ─────────────────────────────────
        local colW = (cw - FT.px(28)) * 0.48
        self.r:appText(x + FT.px(14), ioY, FT.FONT.TINY,
            PText("ft_production_inputs", "Inputs"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        ioY = ioY - FT.py(13)

        if #b.inputs == 0 then
            self.r:appText(x + FT.px(14), ioY, FT.FONT.TINY,
                "-", RenderText.ALIGN_LEFT, FT.C.MUTED)
            ioY = ioY - FT.py(13)
        else
            local fillMax = math.max(8, math.floor(colW / FT.px(6)))
            for _, inp in ipairs(b.inputs) do
                self.r:appText(x + FT.px(14), ioY, FT.FONT.TINY,
                    "- " .. FT_Renderer.truncate(inp, fillMax), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
                ioY = ioY - FT.py(13)
            end
        end

        -- ── Outputs column ────────────────────────────────
        local outX = x + FT.px(18) + colW + FT.px(18)
        local outY = y - FT.py(27)

        self.r:appText(outX, outY, FT.FONT.TINY,
            PText("ft_production_outputs", "Outputs"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        outY = outY - FT.py(13)

        if #b.outputs == 0 then
            self.r:appText(outX + FT.px(4), outY, FT.FONT.TINY,
                "-", RenderText.ALIGN_LEFT, FT.C.MUTED)
        else
            local fillMax = math.max(8, math.floor(colW / FT.px(6)))
            for _, out2 in ipairs(b.outputs) do
                self.r:appText(outX + FT.px(4), outY, FT.FONT.TINY,
                    "- " .. FT_Renderer.truncate(out2, fillMax), RenderText.ALIGN_LEFT,
                    isActive and FT.C.POSITIVE or FT.C.TEXT_DIM)
                outY = outY - FT.py(13)
            end
        end

        y = y - cardH - FT.py(8)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_prodHelp", AC)
end)
