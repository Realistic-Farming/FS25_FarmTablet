-- =========================================================
-- FarmTablet - DairyCore app (Tyson green light 2026-07-25)
-- =========================================================
-- Read-only barn cards from DairyCoreManager:getBarnRows().
-- Shows only fields the live API returns - no invented litres/collection.
-- Handle: g_currentMission.dairyCoreManager or getfenv(0)["g_dairyCoreManager"]
-- =========================================================

local function _dairyMgr()
    return (g_currentMission and g_currentMission.dairyCoreManager)
        or getfenv(0)["g_dairyCoreManager"]
end

local function healthColor(pct)
    local p = tonumber(pct) or 0
    if p >= 85 then return FT.C.POSITIVE
    elseif p >= 60 then return FT.C.TEXT_NORMAL
    elseif p >= 35 then return FT.C.WARNING
    else return FT.C.NEGATIVE end
end

local function spoilageColor(status)
    local s = tostring(status or "")
    if s == "Fresh" then return FT.C.POSITIVE
    elseif s == "Ageing" then return FT.C.WARNING
    elseif s == "At Risk" or s == "Condemned" then return FT.C.NEGATIVE
    end
    return FT.C.TEXT_DIM
end

local function tierColor(tier)
    local t = tostring(tier or "")
    if t == "Premium" then return FT.C.POSITIVE
    elseif t == "Standard" then return FT.C.TEXT_NORMAL
    elseif t == "Reduced" then return FT.C.WARNING
    elseif t == "Poor" then return FT.C.NEGATIVE
    end
    return FT.C.TEXT_DIM
end

FarmTabletUI:registerDrawer(FT.APP.DAIRY, function(self)
    local AC = FT.appColor(FT.APP.DAIRY)

    if self:drawHelpPage("_dairyHelp", FT.APP.DAIRY, FT.l10n("ft_ui_app_dairy", "Dairy"), AC, {
        { title = FT.l10n("ft_dairy_help_barns_title", "BARN CARDS"),
          body  = FT.l10n("ft_dairy_help_barns_body",
              "Each card is one dairy barn tracked by DairyCore.\n" ..
              "Herd health, milk quality tier, and spoilage come\n" ..
              "straight from DairyCore - FarmTablet does not invent values.") },
        { title = FT.l10n("ft_dairy_help_ritter_title", "RITTER MODE"),
          body  = FT.l10n("ft_dairy_help_ritter_body",
              "When Realistic Livestock is active, barn cards also show\n" ..
              "healthy / sick / pregnant counts and average genetics.\n" ..
              "Individual animals stay in Ritter's own menu.") },
        { title = FT.l10n("ft_dairy_help_feed_title", "FEED WARNINGS"),
          body  = FT.l10n("ft_dairy_help_feed_body",
              "A feed disease flag means elevated risk on a designated\n" ..
              "feed field. The disease name appears only when DairyCore\n" ..
              "has revealed it (scout or Co-Op report). Mycotoxin is a\n" ..
              "read-only herd-health penalty.") },
        { title = FT.l10n("ft_dairy_help_readonly_title", "READ-ONLY"),
          body  = FT.l10n("ft_dairy_help_readonly_body",
              "This tab does not schedule collections, edit contracts,\n" ..
              "or designate feed fields. It surfaces DairyCore's live\n" ..
              "read model only.") },
    }) then return end

    local mgr = _dairyMgr()
    local rows = {}
    if mgr ~= nil and type(mgr.getBarnRows) == "function" then
        local ok, result = pcall(function() return mgr:getBarnRows() end)
        if ok and type(result) == "table" then
            rows = result
        end
    end

    table.sort(rows, function(a, b)
        return tostring(a.barnId or "") < tostring(b.barnId or "")
    end)

    local startY = self:drawAppHeader(
        FT.l10n("ft_ui_app_dairy", "Dairy"),
        FT.l10nFormat(#rows == 1 and "ft_dairy_count_barn" or "ft_dairy_count_barns",
            "%d barns", #rows))
    local x, _, cw, _ = self:contentInner()

    if mgr == nil then
        self.r:appText(x, startY - FT.py(12), FT.FONT.BODY,
            FT.l10n("ft_dairy_no_manager", "DairyCore not detected."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, startY - FT.py(30), FT.FONT.SMALL,
            FT.l10n("ft_dairy_install_hint", "Install FS25_DairyCore. This app stays hidden when absent."),
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_dairyHelp", AC)
        return
    end

    if #rows == 0 then
        self.r:appText(x, startY - FT.py(12), FT.FONT.BODY,
            FT.l10n("ft_dairy_no_barns", "No dairy barns tracked yet."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, startY - FT.py(30), FT.FONT.SMALL,
            FT.l10n("ft_dairy_no_barns_hint", "Own a dairy barn and DairyCore will list it here."),
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_dairyHelp", AC)
        return
    end

    local scrollY = self:getContentScrollY()
    local y = startY + scrollY
    local pad = FT.px(8)
    local lineH = FT.py(14)

    local function drawKV(rowY, label, value, valueCol)
        self.r:appText(x + pad, rowY, FT.FONT.TINY, label,
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x + cw - pad, rowY, FT.FONT.TINY, tostring(value),
            RenderText.ALIGN_RIGHT, valueCol or FT.C.TEXT_NORMAL)
        return rowY - lineH
    end

    for _, row in ipairs(rows) do
        local lines = 3  -- health, tier, spoilage
        if row.ritterMode then
            lines = lines + 1  -- mode
            if type(row.counts) == "table" then
                lines = lines + 2  -- counts + genetics
            end
        else
            lines = lines + 1  -- Standard mode label
        end
        if (tonumber(row.mycotoxin) or 0) > 0 then
            lines = lines + 1
        end
        if row.feedDiseaseFlag then
            lines = lines + 1
        end
        if row.contractId ~= nil then
            lines = lines + 1
        end

        local headerH = FT.py(22)
        local cardH = headerH + lines * lineH + FT.py(10)
        local cardBottom = y - cardH

        self.r:appRect(x - FT.px(4), cardBottom, cw + FT.px(8), cardH, FT.C.BG_CARD)

        local header = FT.l10nFormat("ft_dairy_barn_id", "Barn %s", tostring(row.barnId or "?"))
        self.r:appText(x + pad, y - FT.py(6), FT.FONT.BODY, header,
            RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)

        local rowY = y - headerH
        local modeLabel = row.ritterMode
            and FT.l10n("ft_dairy_mode_ritter", "Ritter")
            or FT.l10n("ft_dairy_mode_standard", "Standard")
        rowY = drawKV(rowY, FT.l10n("ft_dairy_label_mode", "MODE"), modeLabel, AC)

        local health = math.floor(tonumber(row.herdHealth) or 0)
        rowY = drawKV(rowY, FT.l10n("ft_dairy_label_health", "HERD HEALTH"),
            string.format("%d", health), healthColor(health))

        local tier = tostring(row.qualityTier or "-")
        rowY = drawKV(rowY, FT.l10n("ft_dairy_label_tier", "QUALITY TIER"),
            tier, tierColor(tier))

        local spoil = tostring(row.spoilage or "-")
        rowY = drawKV(rowY, FT.l10n("ft_dairy_label_spoilage", "SPOILAGE"),
            spoil, spoilageColor(spoil))

        if row.ritterMode and type(row.counts) == "table" then
            local c = row.counts
            local countStr = string.format("%d / %d / %d",
                tonumber(c.healthy) or 0,
                tonumber(c.sick) or 0,
                tonumber(c.pregnant) or 0)
            rowY = drawKV(rowY, FT.l10n("ft_dairy_label_counts", "HEALTHY / SICK / PREG"),
                countStr, FT.C.TEXT_NORMAL)
            local gene = tonumber(c.avgGenetics)
            if gene ~= nil then
                rowY = drawKV(rowY, FT.l10n("ft_dairy_label_genetics", "AVG GENETICS"),
                    string.format("%.2f", gene), FT.C.TEXT_NORMAL)
            end
        end

        local myc = tonumber(row.mycotoxin) or 0
        if myc > 0 then
            rowY = drawKV(rowY, FT.l10n("ft_dairy_label_mycotoxin", "MYCOTOXIN"),
                string.format("-%d", myc), FT.C.NEGATIVE)
        end

        if row.feedDiseaseFlag then
            local feedVal = FT.l10n("ft_dairy_feed_flag", "Elevated risk")
            if row.feedDiseaseCropName ~= nil and tostring(row.feedDiseaseCropName) ~= "" then
                feedVal = tostring(row.feedDiseaseCropName)
            end
            rowY = drawKV(rowY, FT.l10n("ft_dairy_label_feed", "FEED DISEASE"),
                feedVal, FT.C.NEGATIVE)
        end

        if row.contractId ~= nil then
            rowY = drawKV(rowY, FT.l10n("ft_dairy_label_contract", "CONTRACT"),
                tostring(row.contractId), FT.C.TEXT_NORMAL)
        end

        y = cardBottom - FT.py(8)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_dairyHelp", AC)
    self:drawScrollBar()
end)
