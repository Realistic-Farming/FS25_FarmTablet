-- =========================================================
-- FarmTablet v2 – Production Buildings App
-- Owned production chains: building name, active status,
-- input and output fill types.
-- Data via g_currentMission.productionChainManager.
-- =========================================================

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

    local subtitle = #buildings == 1 and "1 building" or (#buildings .. " buildings")
    local startY   = self:drawAppHeader("Production", subtitle)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y       = startY + scrollY

    if #buildings == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "No production buildings owned.",
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(28), FT.FONT.SMALL,
            "Purchase a production placeable to track it here.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_prodHelp", AC)
        return
    end

    for _, b in ipairs(buildings) do
        -- ── Card background ───────────────────────────────
        local ioLines = math.max(#b.inputs, #b.outputs, 1)
        local cardH   = FT.py(22 + 14 + ioLines * 13 + 10)

        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4),
            cw + FT.px(8), cardH, {AC[1]*0.06, AC[2]*0.06, AC[3]*0.06, 0.80})

        -- ── Building name ─────────────────────────────────
        self.r:appText(x + FT.px(6), y - FT.py(10), FT.FONT.BODY,
            b.name, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)

        -- Status badge (top-right)
        local isActive   = b.activeCount > 0
        local statusText = isActive
            and (b.activeCount .. "/" .. b.totalCount .. " active")
            or  "stalled"
        local statusColor = isActive and FT.C.POSITIVE or FT.C.WARNING
        self.r:appText(x + cw - FT.px(6), y - FT.py(10), FT.FONT.TINY,
            statusText, RenderText.ALIGN_RIGHT, statusColor)

        -- Accent line below name
        self.r:appRect(x + FT.px(6), y - FT.py(16), cw - FT.px(12), FT.py(1),
            {AC[1], AC[2], AC[3], 0.30})

        local ioY = y - FT.py(22)

        -- ── Inputs column ─────────────────────────────────
        local colW = (cw - FT.px(12)) * 0.48
        self.r:appText(x + FT.px(6), ioY, FT.FONT.TINY,
            "INPUTS", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        ioY = ioY - FT.py(13)

        if #b.inputs == 0 then
            self.r:appText(x + FT.px(10), ioY, FT.FONT.TINY,
                "-", RenderText.ALIGN_LEFT, FT.C.MUTED)
            ioY = ioY - FT.py(13)
        else
            for _, inp in ipairs(b.inputs) do
                self.r:appText(x + FT.px(10), ioY, FT.FONT.TINY,
                    "- " .. inp, RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
                ioY = ioY - FT.py(13)
            end
        end

        -- ── Outputs column ────────────────────────────────
        local outX = x + FT.px(6) + colW + FT.px(8)
        local outY = y - FT.py(22)

        self.r:appText(outX, outY, FT.FONT.TINY,
            "OUTPUTS", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        outY = outY - FT.py(13)

        if #b.outputs == 0 then
            self.r:appText(outX + FT.px(4), outY, FT.FONT.TINY,
                "-", RenderText.ALIGN_LEFT, FT.C.MUTED)
        else
            for _, out2 in ipairs(b.outputs) do
                self.r:appText(outX + FT.px(4), outY, FT.FONT.TINY,
                    "- " .. out2, RenderText.ALIGN_LEFT,
                    isActive and FT.C.POSITIVE or FT.C.TEXT_DIM)
                outY = outY - FT.py(13)
            end
        end

        y = y - cardH - FT.py(6)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_prodHelp", AC)
end)
