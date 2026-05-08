-- =========================================================
-- FarmTablet v2 – Farm Stats App
-- Comprehensive snapshot: finances, farm totals, session P&L
-- All values are live / session-based — no historical data.
-- =========================================================

FarmTabletUI:registerDrawer(FT.APP.FARM_STATS, function(self)
    local AC = FT.appColor(FT.APP.FARM_STATS)

    if self:drawHelpPage("_statsHelp", FT.APP.FARM_STATS, "Farm Stats", AC, {
        { title = "FINANCES",
          body  = "Balance: your current available money.\n" ..
                  "Loan: outstanding loan amount (0 if debt-free).\n" ..
                  "Net Worth: balance minus loan — your true financial position." },
        { title = "SESSION P&L",
          body  = "Income and expenses tracked since this session started\n" ..
                  "(since the last time the savegame was loaded).\n" ..
                  "Net P/L = income minus expenses for the session." },
        { title = "FARM TOTALS",
          body  = "Fields: count of fields your farm owns (with crop or empty).\n" ..
                  "Area: total farmland owned in hectares.\n" ..
                  "Vehicles: motorized vehicles owned by your farm.\n" ..
                  "Animals: number of animal pens on your farm.\n" ..
                  "Production: production buildings you own." },
        { title = "WORLD",
          body  = "Current in-game day, season (if Seasons mod is active),\n" ..
                  "and time of day." },
    }) then return end

    local data   = self.system.data
    local farmId = data:getPlayerFarmId()

    local balance    = data:getBalance(farmId)
    local loan       = data:getLoan(farmId)
    local netWorth   = balance - loan

    local income     = data:getIncome(farmId)
    local expenses   = data:getExpenses(farmId)
    local netPL      = income - expenses

    local fieldCount  = data:getActiveFieldCount(farmId)
    local farmArea    = data:getTotalFarmArea(farmId)
    local vehCount    = data:getVehicleCount(farmId)
    local animalPens  = data:getAnimalPens(farmId)
    local productions = data:getProductionBuildings(farmId)
    local world       = data:getWorldInfo()

    local farmName = data:getFarmName(farmId) or ("Farm " .. farmId)
    local startY   = self:drawAppHeader("Farm Stats", farmName)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y        = startY + scrollY

    -- ── FINANCES ──────────────────────────────────────────
    y = self:drawSection(y, "FINANCES")

    local balColor = balance >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE
    y = self:drawRow(y, "Balance", data:formatMoney(balance), nil, balColor)

    if loan > 0 then
        y = self:drawRow(y, "Loan", data:formatMoney(loan), nil, FT.C.WARNING)
    end

    local nwColor = netWorth >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE
    y = self:drawRow(y, "Net Worth", data:formatMoney(netWorth), nil, nwColor)

    y = y - FT.py(4)
    y = self:drawRule(y, 0.25)

    -- ── SESSION P&L ───────────────────────────────────────
    y = self:drawSection(y, "SESSION P&L")

    y = self:drawRow(y, "Income",   data:formatMoney(income),   nil, FT.C.POSITIVE)
    y = self:drawRow(y, "Expenses", data:formatMoney(expenses), nil, FT.C.NEGATIVE)

    local plColor = netPL >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE
    y = self:drawRow(y, "Net P/L",  data:formatMoney(netPL),    nil, plColor)

    y = y - FT.py(4)
    y = self:drawRule(y, 0.25)

    -- ── FARM TOTALS ───────────────────────────────────────
    y = self:drawSection(y, "FARM TOTALS")

    y = self:drawRow(y, "Fields",     tostring(fieldCount),
        nil, FT.C.TEXT_NORMAL)
    y = self:drawRow(y, "Area",
        string.format("%.1f ha", farmArea),
        nil, FT.C.TEXT_NORMAL)
    y = self:drawRow(y, "Vehicles",   tostring(vehCount),
        nil, FT.C.TEXT_NORMAL)
    y = self:drawRow(y, "Animal Pens", tostring(#animalPens),
        nil, FT.C.TEXT_NORMAL)
    y = self:drawRow(y, "Production", tostring(#productions),
        nil, FT.C.TEXT_NORMAL)

    y = y - FT.py(4)
    y = self:drawRule(y, 0.25)

    -- ── WORLD ─────────────────────────────────────────────
    y = self:drawSection(y, "WORLD")

    if world then
        local timeStr = string.format("%02d:%02d",
            world.hour or 0, world.minute or 0)
        local dayStr  = "Day " .. (world.day or 1)

        y = self:drawRow(y, "Day",  dayStr,  nil, FT.C.TEXT_NORMAL)

        local seasonName = data:getSeasonName(world.season)
        if seasonName then
            y = self:drawRow(y, "Season", seasonName, nil, FT.C.INFO)
        end

        y = self:drawRow(y, "Time", timeStr, nil, FT.C.TEXT_NORMAL)
    else
        y = self:drawRow(y, "World data", "unavailable", nil, FT.C.MUTED)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_statsHelp", AC)
end)
