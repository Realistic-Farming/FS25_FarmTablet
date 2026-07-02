-- =========================================================
-- FarmTablet v2 – Fleet Manager App
-- All owned motorized vehicles with fuel, wear, and hours.
-- Sorted by fuel level ascending (most urgent first).
-- =========================================================

local function ftFleetText(key, fallback)
    if FT_UI_TEXT ~= nil then return FT_UI_TEXT(key, fallback) end
    if g_i18n and key and g_i18n:hasText(key) then return g_i18n:getText(key) end
    return fallback or tostring(key or "")
end

FarmTabletUI:registerDrawer(FT.APP.FLEET, function(self)
    local AC = FT.appColor(FT.APP.FLEET)

    if self:drawHelpPage("_fleetHelp", FT.APP.FLEET, ftFleetText("ft_ui_app_fleet_manager", "Fleet Manager"), AC, {
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

    local subtitle = #fleet == 1 and ftFleetText("ft_fleet_one_vehicle", "1 vehicle") or (#fleet .. " " .. ftFleetText("ft_fleet_vehicles", "vehicles"))
    local startY   = self:drawAppHeader(ftFleetText("ft_ui_app_fleet_manager", "Fleet Manager"), subtitle)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y       = startY + scrollY

    if #fleet == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            ftFleetText("ft_fleet_no_vehicles", "No vehicles owned."), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(28), FT.FONT.SMALL,
            ftFleetText("ft_fleet_no_vehicles_hint", "Purchase motorized vehicles to track them here."),
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_fleetHelp", AC)
        return
    end

    local barW    = cw * 0.46
    local barH    = FT.py(6)
    local labelW  = FT.px(58)
    local valueX  = x + cw - FT.px(135)

    for idx, v in ipairs(fleet) do
        -- Saubere Kartenoptik statt zusammengequetschter Debug-Liste.
        local rowH = FT.py(62)
        local rowY = y - rowH + FT.py(4)
        local bgA  = (idx % 2 == 0) and 0.58 or 0.72
        self.r:appRect(x - FT.px(4), rowY, cw + FT.px(8), rowH,
            {AC[1]*0.10, AC[2]*0.10, AC[3]*0.10, bgA})
        self.r:appRect(x - FT.px(4), rowY + rowH - FT.py(2), cw + FT.px(8), FT.py(1.4),
            {AC[1], AC[2], AC[3], 0.28})

        local nameColor = v.aiActive and FT.C.INFO or FT.C.TEXT_BRIGHT
        self.r:appText(x + FT.px(8), y - FT.py(11), FT.FONT.BODY,
            tostring(v.name or "-"), RenderText.ALIGN_LEFT, nameColor)
        if v.aiActive then
            self.r:appText(x + cw - FT.px(8), y - FT.py(11), FT.FONT.TINY,
                ftFleetText("ft_ai_active_short", "HELFER"), RenderText.ALIGN_RIGHT, FT.C.INFO)
        end

        local fuelPct = tonumber(v.fuelPct) or 0
        local fuelColor = fuelPct >= 50 and FT.C.POSITIVE
                       or fuelPct >= 20 and FT.C.WARNING
                       or FT.C.NEGATIVE
        local fuelY = y - FT.py(29)
        local barX = x + labelW
        self.r:appText(x + FT.px(8), fuelY + FT.py(1), FT.FONT.TINY,
            ftFleetText("ft_fleet_fuel", "Fuel"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appRect(barX, fuelY - FT.py(2), barW, barH, {0.11, 0.12, 0.15, 0.92})
        local fuelFill = math.max(barW * (fuelPct / 100), 0)
        if fuelFill > 0 then
            self.r:appRect(barX, fuelY - FT.py(2), fuelFill, barH,
                {fuelColor[1], fuelColor[2], fuelColor[3], 0.90})
        end
        self.r:appText(valueX, fuelY + FT.py(1), FT.FONT.TINY,
            string.format("%d%%  %d/%d L", fuelPct, tonumber(v.fuelLitres) or 0, tonumber(v.fuelCap) or 0),
            RenderText.ALIGN_LEFT, fuelColor)

        local wearPct = tonumber(v.wearPct) or 0
        local wearColor = wearPct <= 30 and FT.C.POSITIVE
                       or wearPct <= 65 and FT.C.WARNING
                       or FT.C.NEGATIVE
        local wearY = y - FT.py(45)
        self.r:appText(x + FT.px(8), wearY + FT.py(1), FT.FONT.TINY,
            ftFleetText("ft_fleet_wear", "Wear"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appRect(barX, wearY - FT.py(2), barW, barH, {0.11, 0.12, 0.15, 0.92})
        local wearFill = barW * (wearPct / 100)
        if wearFill > 0 then
            self.r:appRect(barX, wearY - FT.py(2), wearFill, barH,
                {wearColor[1], wearColor[2], wearColor[3], 0.90})
        end
        self.r:appText(valueX, wearY + FT.py(1), FT.FONT.TINY,
            string.format("%d%%", wearPct), RenderText.ALIGN_LEFT, wearColor)

        if not v.aiActive then
            self.r:appText(x + cw - FT.px(8), wearY + FT.py(1), FT.FONT.TINY,
                string.format(ftFleetText("ft_fleet_hours_fmt", "%d h"), tonumber(v.opHours) or 0), RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        end

        y = y - rowH - FT.py(5)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_fleetHelp", AC)
end)
