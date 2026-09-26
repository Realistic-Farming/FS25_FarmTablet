-- =========================================================
-- FarmTablet - ProStaff Co-Op (Tyson green light 2026-07-25)
-- =========================================================
-- Investment / ladder summary over g_currentMission.proStaffManager.
-- Not PersonnelApp (that is WorkerCosts HR). Buy via buyLevel when available.
-- =========================================================

local function _ps()
    return (g_currentMission and g_currentMission.proStaffManager)
        or getfenv(0)["g_proStaffCoOp"]
end

local function _money(n)
    n = tonumber(n) or 0
    if g_i18n ~= nil and g_i18n.formatMoney ~= nil then
        local ok, s = pcall(function() return g_i18n:formatMoney(n, 0, true, true) end)
        if ok and s then return s end
    end
    return string.format("$%.0f", n)
end

local function _levelName(level)
    level = tonumber(level) or 0
    if level <= 0 then return FT.l10n("ft_prostaff_level_none", "None") end
    -- ProStaff's own display name (MAINTENANCE row 142): its getter reads ProStaff's i18n,
    -- which this mod's cannot reach, and answers nil outside its ladder. A colon call, like
    -- getLevel; an older ProStaff without it, a getter that raises or an empty answer falls
    -- through to the English table below.
    local mgr = _ps()
    if type(mgr) == "table" and type(mgr.getLevelDisplayName) == "function" then
        local ok, name = pcall(mgr.getLevelDisplayName, mgr, level)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if ProStaffConstants ~= nil and type(ProStaffConstants.LEVEL_NAMES) == "table" then
        return ProStaffConstants.LEVEL_NAMES[level] or FT.l10nFormat("ft_prostaff_level_n", "Level %d", level)
    end
    return FT.l10nFormat("ft_prostaff_level_n", "Level %d", level)
end

local function _modLine(label, value, neutral)
    if value == nil then return nil end
    if type(value) == "boolean" then
        if value == false then return nil end
        return FT.l10nFormat("ft_prostaff_mod_on", "%s: on", label)
    end
    local n = tonumber(value)
    if n == nil then return nil end
    if neutral ~= nil and math.abs(n - neutral) < 0.0001 then return nil end
    if n < 1.0 then
        return string.format("%s: %d%%", label, math.floor(n * 100 + 0.5))
    end
    return string.format("%s: x%.2f", label, n)
end

FarmTabletUI:registerDrawer(FT.APP.PROSTAFF, function(self)
    local AC = FT.appColor(FT.APP.PROSTAFF)

    if self:drawHelpPage("_prostaffHelp", FT.APP.PROSTAFF, "Pro-Staff Co-Op", AC, {
        { title = "WHAT THIS IS",
          body  = "Your farm's Pro-Staff Co-Op membership level,\n" ..
                  "next investment cost, and active modifiers.\n" ..
                  "This is not the Personnel / Worker Costs roster." },
        { title = "INVEST",
          body  = "BUY NEXT LEVEL spends the listed cost on the host\n" ..
                  "via ProStaff's own buyLevel path. Pure clients need\n" ..
                  "the host / NetworkSync to complete the purchase." },
        { title = "MODIFIERS",
          body  = "Only non-neutral effects at your current level are\n" ..
                  "listed (wages, fatigue, fertilizer, dairy, flags)." },
    }) then return end

    local startY = self:drawAppHeader("Pro-Staff Co-Op", "Investment")
    local x, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY
    local bottomPad = FT.py(28)

    local mgr = _ps()
    if mgr == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Pro-Staff Co-Op not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_ProStaffCoOp to use this app.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_prostaffHelp", AC)
        return
    end

    local level = 0
    if type(mgr.getLevel) == "function" then
        local ok, v = pcall(function() return mgr:getLevel() end)
        if ok then level = tonumber(v) or 0 end
    end
    local nextCost = nil
    if type(mgr.getNextLevelCost) == "function" then
        local ok, v = pcall(function() return mgr:getNextLevelCost() end)
        if ok then nextCost = v end
    end
    local invested = nil
    if type(mgr.farms) == "table" then
        local farmId = self.system.data:getPlayerFarmId()
        local rec = mgr.farms[farmId]
        if rec ~= nil then invested = rec.investmentTotal end
    end

    y = self:drawSection(y, "MEMBERSHIP")
    y = self:drawRow(y, "Level", string.format("%d  ·  %s", level, _levelName(level)),
        nil, FT.C.TEXT_BRIGHT)
    if invested ~= nil then
        y = self:drawRow(y, "Invested", _money(invested), nil, FT.C.TEXT_NORMAL)
    end
    if nextCost ~= nil then
        y = self:drawRow(y, "Next level cost", _money(nextCost), nil, FT.C.WARNING)
    else
        y = self:drawRow(y, "Next level cost", "MAX", nil, FT.C.POSITIVE)
    end
    y = y - FT.py(6)

    if nextCost ~= nil and type(mgr.buyLevel) == "function" then
        local btn = self.r:button(x, y - FT.py(22), cw, FT.py(22),
            "BUY NEXT LEVEL", FT.C.BTN_PRIMARY, {
                onClick = function()
                    pcall(function() mgr:buyLevel() end)
                end
            })
        table.insert(self._contentBtns, btn)
        y = y - FT.py(30)
    else
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            "No further levels available.", RenderText.ALIGN_LEFT, FT.C.MUTED)
        y = y - FT.py(22)
    end

    y = self:drawRule(y, 0.3)
    y = self:drawSection(y, "ACTIVE MODIFIERS")

    local mods = {}
    local function try(label, fnName, neutral)
        if type(mgr[fnName]) ~= "function" then return end
        local ok, v = pcall(function() return mgr[fnName](mgr) end)
        if not ok then return end
        local line = _modLine(label, v, neutral)
        if line then mods[#mods + 1] = line end
    end
    try(FT.l10n("ft_prostaff_mod_wage_cost", "Wage cost"), "getWageModifier", 1.0)
    try(FT.l10n("ft_prostaff_mod_fatigue_mitigation", "Fatigue mitigation"), "getFatigueMitigation", 1.0)
    try(FT.l10n("ft_prostaff_mod_fatigue_recovery", "Fatigue recovery"), "getFatigueRecoveryBonus", 1.0)
    try(FT.l10n("ft_prostaff_mod_global_effectiveness", "Global effectiveness"), "getGlobalEffectivenessBonus", 1.0)
    try(FT.l10n("ft_prostaff_mod_fertilizer_cost", "Fertilizer cost"), "getFertilizerDiscount", 1.0)
    try(FT.l10n("ft_prostaff_mod_fungicide_cost", "Fungicide cost"), "getFungicideDiscount", 1.0)
    try(FT.l10n("ft_prostaff_mod_fungicide_effect", "Fungicide effect"), "getFungicideEffectivenessBonus", 1.0)
    try(FT.l10n("ft_prostaff_mod_spray_cost", "Spray cost"), "getSprayCostModifier", 1.0)
    try(FT.l10n("ft_prostaff_mod_vet_supplies", "Vet supplies"), "getVetSupplyDiscount", 1.0)
    try(FT.l10n("ft_prostaff_mod_dairy_logistics", "Dairy logistics"), "getDairyLogisticsBonus", 1.0)
    try(FT.l10n("ft_prostaff_mod_bulk_procurement", "Bulk procurement"), "getBulkProcurementBonus", 1.0)
    try(FT.l10n("ft_prostaff_mod_bulk_transport", "Bulk transport"), "getBulkTransportDiscount", 1.0)
    try(FT.l10n("ft_prostaff_mod_market_intel", "Market intel"), "hasMarketIntel", nil)
    try(FT.l10n("ft_prostaff_mod_forecast_access", "Forecast access"), "hasForecastAccess", nil)
    try(FT.l10n("ft_prostaff_mod_predictive_control", "Predictive control"), "hasPredictiveControl", nil)
    try(FT.l10n("ft_prostaff_mod_early_warning", "Early warning"), "hasEarlyWarning", nil)

    if #mods == 0 then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            "No active modifiers at this level yet.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        y = y - FT.py(20)
    else
        for _, line in ipairs(mods) do
            self.r:appText(x, y - FT.py(1), FT.FONT.SMALL, line,
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            y = y - FT.py(14)
        end
    end

    self:setContentHeight(startY - y + scrollY + bottomPad)
    self:drawInfoIcon("_prostaffHelp", AC)
    self:drawScrollBar()
end)
