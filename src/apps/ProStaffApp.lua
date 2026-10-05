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
        y = self:drawRow(y, "Invested", _money(invested), nil, FT.C.TEXT_NORMAL, nil, true)
    end
    if nextCost ~= nil then
        y = self:drawRow(y, "Next level cost", _money(nextCost), nil, FT.C.WARNING, nil, true)
    else
        y = self:drawRow(y, "Next level cost", "MAX", nil, FT.C.POSITIVE)
    end
    y = y - FT.py(6)

    if nextCost ~= nil and type(mgr.buyLevel) == "function" then
        local btn = self.r:button(x, y - FT.py(22), cw, FT.py(22),
            FT.l10nAuto("BUY NEXT LEVEL"), FT.C.BTN_PRIMARY, {
                onClick = function()
                    pcall(function() mgr:buyLevel() end)
                end
            }, true)
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

    -- F166: herd advisories from DairyCore after active modifiers.
    local function _psTr(key, fallback)
        if FT ~= nil and FT.l10n ~= nil then
            return FT.l10n(key, fallback)
        end
        return fallback or key
    end
    local function _psTrFormat(key, fallbackFmt, ...)
        local args = { ... }
        local fmt = _psTr(key, fallbackFmt)
        local function try(f)
            if type(f) ~= "string" or f == "" then return nil end
            local ok, text = pcall(string.format, f, unpack(args))
            if not ok or type(text) ~= "string" or text == "" then return nil end
            local lower = text:lower()
            if lower == tostring(key):lower()
                or text == ("$l10n_" .. tostring(key))
                or lower:find("^missing%s")
                or lower:find("^missing_")
            then
                return nil
            end
            return text
        end
        local text = try(fmt)
        if text ~= nil then return text end
        text = try(fallbackFmt)
        if text ~= nil then return text end
        local bits = {}
        for i = 1, #args do bits[#bits + 1] = tostring(args[i] or "") end
        return table.concat(bits, " ")
    end
    local function _psReason(code)
        if code == "HEALTH_ATTENTION" then
            return _psTr("ft_prostaff_advisory_reason_health",
                "Herd health needs attention; check feed and care")
        end
        if code == "MILK_AGEING" then
            return _psTr("ft_prostaff_advisory_reason_milk",
                "Milk is ageing; check collection.")
        end
        return nil
    end
    local function _psUtf8Chars(s)
        s = tostring(s or "")
        local chars = {}
        local i = 1
        local n = #s
        while i <= n do
            local b = s:byte(i)
            local len = 1
            if b >= 240 then len = 4
            elseif b >= 224 then len = 3
            elseif b >= 192 then len = 2 end
            if i + len - 1 > n then len = 1 end
            chars[#chars + 1] = s:sub(i, i + len - 1)
            i = i + len
        end
        return chars
    end
    -- Engine getTextWidth(fontSize, utf8string) per LUADOC Text Rendering.
    -- Returns normalized width. maxWidth from contentInner()/FT.px is already
    -- normalized (FT.LAYOUT.scaleX), so production wrap units match getTextWidth.
    -- Do not pass raw XML pixel widths into this path. Harness may stub getTextWidth;
    -- fallback approximates CJK vs Latin advance in the same units as maxWidth.
    local function _psTextWidth(fontSize, text)
        fontSize = tonumber(fontSize) or FT.FONT.SMALL
        text = tostring(text or "")
        if type(getTextWidth) == "function" then
            local ok, w = pcall(getTextWidth, fontSize, text)
            if ok and type(w) == "number" then return w end
        end
        local w = 0
        for _, ch in ipairs(_psUtf8Chars(text)) do
            local b = ch:byte(1) or 0
            if b >= 224 then
                w = w + fontSize * 1.05
            else
                w = w + fontSize * 0.55
            end
        end
        return w
    end
    local function _psSplitToken(token, maxWidth, fontSize)
        local chars = _psUtf8Chars(token)
        if #chars == 0 then return { "" } end
        if _psTextWidth(fontSize, token) <= maxWidth then return { token } end
        local parts = {}
        local cur = ""
        for _, ch in ipairs(chars) do
            local trial = cur .. ch
            if cur ~= "" and _psTextWidth(fontSize, trial) > maxWidth then
                parts[#parts + 1] = cur
                cur = ch
            else
                cur = trial
            end
        end
        if cur ~= "" then parts[#parts + 1] = cur end
        return parts
    end
    local function _psWrapLines(text, maxWidth, fontSize)
        text = tostring(text or "")
        if text == "" then return { "" } end
        fontSize = tonumber(fontSize) or FT.FONT.SMALL
        maxWidth = tonumber(maxWidth) or FT.px(280)
        if maxWidth < fontSize * 4 then maxWidth = fontSize * 4 end
        local lines = {}
        for paragraph in string.gmatch(text .. "\n", "(.-)\n") do
            if paragraph == "" then
                lines[#lines + 1] = ""
            else
                local tokens = {}
                local any = false
                for w in string.gmatch(paragraph, "%S+") do
                    any = true
                    for _, piece in ipairs(_psSplitToken(w, maxWidth, fontSize)) do
                        tokens[#tokens + 1] = piece
                    end
                end
                if not any then
                    for _, piece in ipairs(_psSplitToken(paragraph, maxWidth, fontSize)) do
                        tokens[#tokens + 1] = piece
                    end
                end
                local cur = ""
                for _, w in ipairs(tokens) do
                    if cur == "" then
                        cur = w
                    else
                        local trial = cur .. " " .. w
                        if _psTextWidth(fontSize, trial) <= maxWidth then
                            cur = trial
                        else
                            lines[#lines + 1] = cur
                            cur = w
                        end
                    end
                end
                if cur ~= "" then lines[#lines + 1] = cur end
            end
        end
        if #lines == 0 then lines[1] = text end
        return lines
    end
    local function _psAdmit(raw, farmId)
        if type(raw) ~= "table" or farmId == nil then return {} end
        local out = {}
        local i = 1
        while raw[i] ~= nil do
            local row = raw[i]
            i = i + 1
            if type(row) == "table"
                and (type(row.barnId) == "string" or type(row.barnId) == "number")
                and row.farmId == farmId
                and type(row.label) == "string"
                and type(row.reasons) == "table"
            then
                local ordered = {}
                local hasH, hasM = false, false
                local ri = 1
                while row.reasons[ri] ~= nil do
                    local code = row.reasons[ri]
                    ri = ri + 1
                    if code == "HEALTH_ATTENTION" then hasH = true
                    elseif code == "MILK_AGEING" then hasM = true end
                end
                if hasH then ordered[#ordered + 1] = "HEALTH_ATTENTION" end
                if hasM then ordered[#ordered + 1] = "MILK_AGEING" end
                if #ordered > 0 then
                    out[#out + 1] = {
                        barnId = row.barnId,
                        label = row.label,
                        reasons = ordered,
                    }
                end
            end
        end
        return out
    end

    local farmIdStrict = nil
    if self.system ~= nil and self.system.data ~= nil
        and type(self.system.data.getPlayerFarmIdStrict) == "function" then
        farmIdStrict = self.system.data:getPlayerFarmIdStrict()
    end
    local dairy = g_currentMission and g_currentMission.dairyCoreManager
    if farmIdStrict ~= nil and dairy ~= nil and type(dairy.getHerdAdvisories) == "function" then
        local ok, raw = pcall(function() return dairy:getHerdAdvisories(farmIdStrict) end)
        local rows = ok and _psAdmit(raw, farmIdStrict) or {}
        if #rows > 0 then
            y = self:drawRule(y, 0.3)
            y = self:drawSection(y, _psTr("ft_prostaff_advisory_heading", "Herd advice"), true)
            local counts = {}
            for _, row in ipairs(rows) do
                counts[row.label] = (counts[row.label] or 0) + 1
            end
            local join = _psTr("ft_prostaff_advisory_join", "; ")
            local maxWidth = cw or FT.px(280)
            local fontSize = FT.FONT.SMALL
            for _, row in ipairs(rows) do
                local label = row.label
                if counts[label] > 1 then
                    label = tostring(label) .. " (" .. tostring(row.barnId) .. ")"
                end
                local parts = {}
                for _, code in ipairs(row.reasons) do
                    local t = _psReason(code)
                    if t ~= nil then parts[#parts + 1] = t end
                end
                if #parts > 0 then
                    local line = _psTrFormat(
                        "ft_prostaff_advisory_line",
                        "%s: %s",
                        label,
                        table.concat(parts, join)
                    )
                    for _, wrapped in ipairs(_psWrapLines(line, maxWidth, fontSize)) do
                        self.r:appText(x, y - FT.py(1), fontSize, wrapped,
                            RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL, true)
                        y = y - FT.py(14)
                    end
                end
            end
        end
    end


    self:setContentHeight(startY - y + scrollY + bottomPad)
    self:drawInfoIcon("_prostaffHelp", AC)
    self:drawScrollBar()
end)
