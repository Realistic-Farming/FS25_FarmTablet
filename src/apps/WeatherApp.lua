-- =========================================================
-- FarmTablet v2 – Weather App
-- =========================================================
-- Prefers WeatherGuard (shared weather truth) when present.
-- World Weather dial chips call weatherGuard:requestWeatherMode.
-- Falls back to engine reads + projected forecast without WG.
-- =========================================================

local MODE_LABELS = { "Real", "Arid", "Normal", "Wet" }
local MODE_COLORS = {
    { 0.55, 0.58, 0.62, 1.0 },
    { 0.78, 0.62, 0.28, 1.0 },
    { 0.35, 0.72, 0.48, 1.0 },
    { 0.28, 0.55, 0.88, 1.0 },
}

local function _wg()
    local wg = g_currentMission and g_currentMission.weatherGuard
    if wg ~= nil then return wg end
    local ok, alt = pcall(function()
        local env = getfenv(0)
        return env["g_weatherGuard"] or env["g_WeatherGuard"]
    end)
    if ok then return alt end
    return nil
end

FarmTabletUI:registerDrawer(FT.APP.WEATHER, function(self)
    local AC = FT.appColor(FT.APP.WEATHER)

    if self:drawHelpPage("_weatherHelp", FT.APP.WEATHER, "Weather", AC, {
        { title = "CURRENT CONDITION",
          body  = "Shows the current weather at the top with a colour-coded\n" ..
                  "left edge: blue = rain, orange = storm, grey = overcast,\n" ..
                  "white = clear, dark = fog." },
        { title = "WEATHERGUARD",
          body  = "When FS25_WeatherGuard is installed, this app reads the\n" ..
                  "shared weather truth (same sky every mod uses) and a real\n" ..
                  "engine forecast instead of a guessed projection." },
        { title = "WORLD WEATHER DIAL",
          body  = "Real / Arid / Normal / Wet chips set the shared world\n" ..
                  "weather mode (admin-only in multiplayer). Same meaning\n" ..
                  "as the World Climate control in Soil Fertilizer." },
        { title = "TEMPERATURE",
          body  = "Current air temperature in Celsius with a feel label:\n" ..
                  "Freezing (<0)  Cold (<8)  Cool (<16)  Mild (<24)\n" ..
                  "Warm (<32)  Hot (32+)." },
        { title = "FORECAST",
          body  = "With WeatherGuard: real Day +1.. outlook from the game\n" ..
                  "forecast (about 9 days filled; we show up to five).\n" ..
                  "Without WeatherGuard: a projected estimate only." },
    }) then return end

    local data = self.system.data
    local w    = data:getWeather()

    local startY = self:drawAppHeader("Weather", "")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY
    local accent = AC

    if not w then
        self.r:appText(x, y - FT.py(10), FT.FONT.BODY,
            "Weather data unavailable.", RenderText.ALIGN_LEFT, FT.C.WARNING)
        self.r:appText(x, y - FT.py(28), FT.FONT.SMALL,
            "Environment not loaded yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_weatherHelp", AC)
        return
    end

    -- Source strip
    local viaWg = w.source == "weatherguard"
    self.r:appRect(x - FT.px(4), y - FT.py(20), cw + FT.px(8), FT.py(18),
        { accent[1] * 0.10, accent[2] * 0.10, accent[3] * 0.10, 0.95 })
    self.r:appText(x, y - FT.py(16), FT.FONT.SMALL,
        viaWg and "Via WeatherGuard" or "Engine (no WeatherGuard)",
        RenderText.ALIGN_LEFT, viaWg and FT.C.POSITIVE or FT.C.WARNING)
    if viaWg and w.forecastHorizonDays then
        self.r:appText(x + cw, y - FT.py(16), FT.FONT.TINY,
            string.format("~%.0f day forecast", w.forecastHorizonDays),
            RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
    end
    y = y - FT.py(24)

    -- World Weather dial (WeatherGuard only)
    local wg = _wg()
    if wg ~= nil and type(wg.requestWeatherMode) == "function" then
        y = self:drawSection(y, "WORLD WEATHER")
        local mode = tonumber(w.weatherMode) or 3
        local chipGap = FT.px(4)
        local chipW = (cw - chipGap * 3) / 4
        local chipH = FT.py(28)
        for i = 1, 4 do
            local cx = x + (i - 1) * (chipW + chipGap)
            local selected = (mode == i)
            local col = MODE_COLORS[i]
            local bg = selected
                and { col[1] * 0.35, col[2] * 0.35, col[3] * 0.35, 0.95 }
                or FT.C.BG_PANEL
            self.r:appRect(cx, y - chipH, chipW, chipH, bg)
            if selected then
                self.r:appRect(cx, y - FT.py(2), chipW, FT.py(2), col)
            end
            self.r:appText(cx + chipW * 0.5, y - chipH * 0.55, FT.FONT.TINY,
                MODE_LABELS[i], RenderText.ALIGN_CENTER,
                selected and FT.C.TEXT_BRIGHT or FT.C.TEXT_DIM)
            local btn = self.r:button(cx, y - chipH, chipW, chipH, "",
                { 0, 0, 0, 0.01 },
                { onClick = function()
                    pcall(function() wg:requestWeatherMode(i) end)
                    if self.system and self.system.data and self.system.data.invalidate then
                        self.system.data:invalidate()
                    end
                    self:switchApp(FT.APP.WEATHER)
                end })
            table.insert(self._contentBtns, btn)
        end
        y = y - chipH - FT.py(6)
        self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
            "Shared world setting · admin-only in multiplayer",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        y = y - FT.py(16)
        y = self:drawRule(y, 0.3)
    end

    -- Condition hero card
    y = y - FT.py(4)
    local heroH = FT.py(52)
    self.r:appRect(x, y - heroH, cw, heroH, FT.C.BG_CARD)

    local condColor = accent
    if     w.isStorming             then condColor = FT.C.WEATHER_STORM
    elseif w.isRaining              then condColor = FT.C.WEATHER_RAIN
    elseif w.isFoggy                then condColor = FT.C.WEATHER_FOG
    elseif w.condKey == "clear"     then condColor = FT.C.WEATHER_SUN
    elseif w.condKey == "overcast"  then condColor = { 0.55, 0.57, 0.65, 1.00 }
    end
    self.r:appRect(x, y - heroH, FT.px(4), heroH, condColor)

    local condLabel = {
        storm = "STORM", rain = "RAIN", fog = "FOG", snow = "SNOW",
        overcast = "OVC", cloudy = "CLOUD", clear = "CLEAR",
    }
    self.r:appText(x + FT.px(10), y - heroH / 2 + FT.py(2),
        FT.FONT.HEADER, condLabel[w.condKey] or "?", RenderText.ALIGN_LEFT, condColor)
    local tempStr = w.temperature ~= nil and string.format("%.1f C", w.temperature) or "-- C"
    self.r:appText(x + FT.px(62), y - heroH / 2 + FT.py(2),
        FT.FONT.BODY, tempStr, RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    if w.windSpeed and w.windSpeed > 0 then
        self.r:appText(x + cw - FT.px(10), y - heroH / 2 + FT.py(10),
            FT.FONT.BODY, string.format("%.0f km/h", w.windSpeed), RenderText.ALIGN_RIGHT, FT.C.TEXT_NORMAL)
        self.r:appText(x + cw - FT.px(10), y - heroH / 2 - FT.py(6),
            FT.FONT.TINY, "WIND", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        if w.windDir and w.windDir ~= "" then
            self.r:appText(x + cw - FT.px(10), y - heroH / 2 - FT.py(16),
                FT.FONT.TINY, w.windDir, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        end
    end
    y = y - heroH - FT.py(6)
    y = self:drawRule(y, 0.35)

    -- Detail rows
    y = self:drawSection(y, "CONDITIONS")
    if w.temperature ~= nil then
        local tempColor = w.temperature < 0 and FT.C.INFO or w.temperature > 32 and FT.C.NEGATIVE
            or w.temperature > 25 and FT.C.WARNING or FT.C.TEXT_ACCENT
        local feelStr = w.temperature < 0 and "Freezing" or w.temperature < 8 and "Cold"
            or w.temperature < 16 and "Cool" or w.temperature < 24 and "Mild"
            or w.temperature < 32 and "Warm" or "Hot"
        y = self:drawRow(y, "Temperature",
            string.format("%.1f C  (%s)", w.temperature, feelStr), nil, tempColor)
    end
    if w.cloudCover ~= nil then
        local cp = math.floor(w.cloudCover * 100)
        local cs = cp < 20 and "Clear" or cp < 40 and "Partly Cloudy"
            or cp < 70 and "Mostly Cloudy" or "Overcast"
        y = self:drawRow(y, "Cloud Cover", string.format("%d%%  (%s)", cp, cs))
    end
    if w.humidity ~= nil then
        y = self:drawRow(y, "Humidity", string.format("%.0f%%", w.humidity * 100))
    end
    if w.windSpeed and w.windSpeed > 0 then
        local ws = string.format("%.1f km/h", w.windSpeed)
        if w.windDir and w.windDir ~= "" then ws = ws .. "  " .. w.windDir end
        y = self:drawRow(y, "Wind Speed", ws)
    end
    if w.isStorming then
        y = self:drawRow(y, "Precipitation", "Heavy Storm", nil, FT.C.WEATHER_STORM)
        if w.rainScale then
            y = y + FT.py(FT.SP.ROW) - FT.py(8)
            y = self:drawBar(y, math.floor(w.rainScale * 100), 100, FT.C.WEATHER_STORM)
        end
    elseif w.isRaining then
        local intensity = w.rainScale and w.rainScale > 0.4 and "Moderate" or "Light"
        y = self:drawRow(y, "Precipitation", intensity .. " Rain", nil, FT.C.WEATHER_RAIN)
        if w.rainScale then
            y = y + FT.py(FT.SP.ROW) - FT.py(8)
            y = self:drawBar(y, math.floor(w.rainScale * 100), 100, FT.C.WEATHER_RAIN)
        end
    end
    if w.isFoggy then
        y = self:drawRow(y, "Fog", "Present", nil, FT.C.WEATHER_FOG)
    end

    -- Forecast
    if w.forecast and #w.forecast > 0 then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.25)
        local fcTitle = w.forecastIsReal and "FORECAST  (engine)" or "FORECAST  (projected)"
        y = self:drawSection(y, fcTitle)
        for i = 1, math.min(5, #w.forecast) do
            local f = w.forecast[i]
            if f and y > contentY + FT.py(8) then
                local cond = f.condition or "Unknown"
                local tempF = f.temperature ~= nil and string.format("%.0f C", f.temperature) or nil
                local rainBit = f.rainProb ~= nil and string.format("  %d%% rain", f.rainProb) or ""
                local right = (tempF and (cond .. "  " .. tempF) or cond) .. rainBit
                y = self:drawRow(y, "Day +" .. i, right, nil, FT.C.TEXT_DIM)
            end
        end
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_weatherHelp", AC)
    self:drawScrollBar()
end)
