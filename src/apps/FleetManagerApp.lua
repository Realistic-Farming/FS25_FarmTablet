-- =========================================================
-- FarmTablet v2 – Fleet Manager App
-- All owned motorized vehicles with fuel, wear, and hours.
-- Sorted by fuel level ascending (most urgent first).
-- =========================================================

FarmTabletUI:registerDrawer(FT.APP.FLEET, function(self)
    local AC = FT.appColor(FT.APP.FLEET)

    if self:drawHelpPage("_fleetHelp", FT.APP.FLEET, "Fleet Manager", AC, {
        { title = "VEHICLE LIST",
          body  = "Shows every motorized vehicle your farm owns.\n" ..
                  "Sorted by fuel level — emptiest machines appear first\n" ..
                  "so you can spot what needs refuelling at a glance." },
        { title = "FUEL BAR",
          body  = "Current fuel as a percentage of tank capacity.\n" ..
                  "Litres remaining and total capacity shown beside the bar.\n" ..
                  "Green >= 50%  |  Yellow >= 20%  |  Red < 20%." },
        { title = "WEAR BAR",
          body  = "Component wear percentage (0% = new, 100% = worn out).\n" ..
                  "High wear reduces efficiency — repair before reaching 80%.\n" ..
                  "Green <= 30%  |  Yellow <= 65%  |  Red > 65%." },
        { title = "HOURS / STATUS",
          body  = "Operating hours: total engine time in whole hours.\n" ..
                  "AI badge appears when the vehicle is driven by a hired worker.\n" ..
                  "No badge = parked or player-controlled." },
    }) then return end

    local data    = self.system.data
    local farmId  = data:getPlayerFarmId()
    local fleet   = data:getFleetVehicles(farmId)

    local subtitle = #fleet == 1 and "1 vehicle" or (#fleet .. " vehicles")
    local startY   = self:drawAppHeader("Fleet Manager", subtitle)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y       = startY + scrollY

    if #fleet == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "No vehicles owned.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(28), FT.FONT.SMALL,
            "Purchase motorized vehicles to track them here.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_fleetHelp", AC)
        return
    end

    local barW    = cw * 0.42
    local barH    = FT.py(7)
    local col2X   = x + cw * 0.52

    for _, v in ipairs(fleet) do
        -- ── Row background ────────────────────────────────
        local rowH = FT.py(52)
        self.r:appRect(x - FT.px(4), y - rowH + FT.py(4),
            cw + FT.px(8), rowH, {AC[1]*0.06, AC[2]*0.06, AC[3]*0.06, 0.80})

        -- Name + AI badge
        local nameColor = v.aiActive and FT.C.INFO or FT.C.TEXT_BRIGHT
        self.r:appText(x + FT.px(6), y - FT.py(10), FT.FONT.BODY,
            v.name, RenderText.ALIGN_LEFT, nameColor)
        if v.aiActive then
            self.r:appText(x + cw - FT.px(6), y - FT.py(10), FT.FONT.TINY,
                "[AI]", RenderText.ALIGN_RIGHT, FT.C.INFO)
        end

        -- ── Fuel bar ──────────────────────────────────────
        local fuelColor = v.fuelPct >= 50 and FT.C.POSITIVE
                       or v.fuelPct >= 20 and FT.C.WARNING
                       or FT.C.NEGATIVE
        local fuelY = y - FT.py(24)

        self.r:appText(x + FT.px(6), fuelY + FT.py(1), FT.FONT.TINY,
            "FUEL", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        local barX = x + FT.px(32)
        -- bar track
        self.r:appRect(barX, fuelY - FT.py(2), barW, barH,
            {0.14, 0.15, 0.18, 0.90})
        -- fill
        local fuelFill = math.max(barW * (v.fuelPct / 100), 0)
        if fuelFill > 0 then
            self.r:appRect(barX, fuelY - FT.py(2), fuelFill, barH,
                {fuelColor[1], fuelColor[2], fuelColor[3], 0.85})
        end

        local fuelLabel = string.format("%d%%  (%dL / %dL)",
            v.fuelPct, v.fuelLitres, v.fuelCap)
        self.r:appText(barX + barW + FT.px(6), fuelY + FT.py(1),
            FT.FONT.TINY, fuelLabel, RenderText.ALIGN_LEFT, fuelColor)

        -- ── Wear bar ──────────────────────────────────────
        local wearColor = v.wearPct <= 30 and FT.C.POSITIVE
                       or v.wearPct <= 65 and FT.C.WARNING
                       or FT.C.NEGATIVE
        local wearY = y - FT.py(38)

        self.r:appText(x + FT.px(6), wearY + FT.py(1), FT.FONT.TINY,
            "WEAR", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        -- bar track
        self.r:appRect(barX, wearY - FT.py(2), barW, barH,
            {0.14, 0.15, 0.18, 0.90})
        -- fill
        local wearFill = barW * (v.wearPct / 100)
        if wearFill > 0 then
            self.r:appRect(barX, wearY - FT.py(2), wearFill, barH,
                {wearColor[1], wearColor[2], wearColor[3], 0.85})
        end

        self.r:appText(barX + barW + FT.px(6), wearY + FT.py(1),
            FT.FONT.TINY, v.wearPct .. "%", RenderText.ALIGN_LEFT, wearColor)

        -- Hours (shown in wear row right side if no AI)
        if not v.aiActive then
            self.r:appText(x + cw - FT.px(6), wearY + FT.py(1), FT.FONT.TINY,
                v.opHours .. "h", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        end

        y = y - rowH - FT.py(6)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_fleetHelp", AC)
end)
