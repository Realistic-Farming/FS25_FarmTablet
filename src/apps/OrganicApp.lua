-- =========================================================
-- FarmTablet - Organic Management (Arissani brief)
-- =========================================================
-- Read-only hub over Soil Fertilizer organic certification.
-- CERTIFICATION + PRACTICES + COMPOST display built; LIVESTOCK / MARKET stub.
-- Opt-in / opt-out via SF requestOptIn / requestOptOut only.
-- =========================================================

local STATE_LABEL = {
    conventional   = "Conventional",
    in_transition  = "In transition",
    certified      = "Certified",
}

local STATE_COLOR = {
    conventional   = FT.C.TEXT_DIM,
    in_transition  = FT.C.WARNING,
    certified      = FT.C.POSITIVE,
}

local function _mgr()
    return (g_currentMission and g_currentMission.soilFertilityManager)
        or getfenv(0)["g_SoilFertilityManager"]
end

local function _pcall(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c
end

local function _stateKey(st)
    if st == nil then return "conventional" end
    local s = tostring(st.state or "")
    if s == "certified" or st.certified == true then return "certified" end
    if s == "in_transition" or s == "transition" then return "in_transition" end
    -- SoilConstants may use uppercase / numeric enums; treat certified flag first.
    if type(s) == "string" and s:lower():find("cert", 1, true) then return "certified" end
    if type(s) == "string" and s:lower():find("trans", 1, true) then return "in_transition" end
    return "conventional"
end

local function _practiceLines(info)
    local lines = {}
    if info == nil then
        return { FT.l10n("ft_organic_practice_no_data", "No soil data for this field yet.") }
    end
    local om = tonumber(info.organicMatter) or 0
    if om < 3.0 then
        lines[#lines + 1] = FT.l10n("ft_organic_practice_om_low", "OM low - plow in manure/compost or chop straw.")
    elseif om < 4.0 then
        lines[#lines + 1] = FT.l10n("ft_organic_practice_om_fair", "OM fair - keep organic inputs coming.")
    else
        lines[#lines + 1] = FT.l10n("ft_organic_practice_om_healthy", "OM healthy - maintain cover and residues.")
    end

    local rot = tostring(info.rotationStatus or "OK")
    local last = tostring(info.lastCrop or "-")
    local last2 = tostring(info.lastCrop2 or "-")
    if rot == "Fatigue" then
        lines[#lines + 1] = FT.l10nFormat("ft_organic_practice_fatigue_fmt",
            "Rotation fatigue after %s / %s - plant a legume next.", last, last2)
    elseif rot == "Bonus" then
        lines[#lines + 1] = FT.l10nFormat("ft_organic_practice_bonus_fmt",
            "Rotation bonus active (%s / %s) - protect it with diversity.", last, last2)
    else
        lines[#lines + 1] = FT.l10nFormat("ft_organic_practice_rotation_fmt",
            "Rotation %s (%s / %s) - keep a legume in the cycle.", rot, last, last2)
    end

    if info.needsFertilization then
        lines[#lines + 1] = FT.l10n("ft_organic_practice_needs_fert", "Needs fertility - prefer approved organic inputs.")
    end
    return lines
end

FarmTabletUI:registerDrawer(FT.APP.ORGANIC, function(self)
    local AC = FT.appColor(FT.APP.ORGANIC)

    if self:drawHelpPage("_organicHelp", FT.APP.ORGANIC, FT.l10n("ft_ui_app_organic", "Organic"), AC, {
        { title = "WHAT THIS IS",
          body  = FT.l10n("ft_organic_help_what_body", "Organic certification and practice advice for your\nfields. Reads Soil Fertilizer. Owns no organic state."), literalBody = true },
        { title = FT.l10n("ft_organic_certification", "CERTIFICATION"),
          body  = FT.l10n("ft_organic_help_cert_body", "Per-field state: Conventional, In transition, or\nCertified, plus the transition countdown. OPT IN /\nOPT OUT asks Soil Fertilizer (admin-gated there)."), literalTitle = true, literalBody = true },
        { title = FT.l10n("ft_organic_practices", "PRACTICES"),
          body  = FT.l10n("ft_organic_help_practices_body", "Cover-crop and rotation tips framed for organic,\nfrom the same soil data as the Soil Fertilizer app."), literalTitle = true, literalBody = true },
        { title = FT.l10n("ft_organic_help_later_title", "COMING LATER"),
          body  = FT.l10n("ft_organic_help_later_body", "Compost, livestock feed, and market premium sections\nstay stubs until those sims expose read APIs."), literalTitle = true, literalBody = true },
    }, true) then return end

    local startY = self:drawAppHeader(FT.l10n("ft_ui_app_organic", "Organic"), FT.l10n("ft_organic_subtitle", "Management"), true, true)
    local x, cyBottom, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY
    local bottomPad = FT.py(28)

    local mgr = _mgr()
    if mgr == nil or mgr.soilSystem == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Soil Fertilizer not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_SoilFertilizer to use this app.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_organicHelp", AC)
        return
    end

    local organic = mgr.organic
    local soil = mgr.soilSystem
    local farmId = self.system.data:getPlayerFarmId()
    local fields = self.system.data:getOwnedFields(farmId) or {}

    ------------------------------------------------------------------
    -- CERTIFICATION
    ------------------------------------------------------------------
    y = self:drawSection(y, FT.l10n("ft_organic_certification", "CERTIFICATION"), true)
    if organic == nil or type(organic.getFieldOrganicState) ~= "function" then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_cert_unavailable", "Organic certification not available on this Soil build."),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(22)
    elseif #fields == 0 then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_no_fields_yet", "No owned fields yet."), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(22)
    else
        local selected = self.system.organicSelectedField
        if selected == nil then
            selected = fields[1].id
            self.system.organicSelectedField = selected
        end

        local btnW = FT.px(64)
        local btnH = FT.py(16)
        local rowH = FT.py(34)

        for _, field in ipairs(fields) do
            local st = _pcall(function() return organic:getFieldOrganicState(field.id) end)
            local key = _stateKey(st)
            local label = STATE_LABEL[key] or "Unknown"
            local col = STATE_COLOR[key] or FT.C.MUTED
            local isSel = (field.id == selected)

            if isSel then
                self.r:appRect(x - FT.px(2), y - rowH + FT.py(6), cw + FT.px(4), rowH,
                    { AC[1] * 0.12, AC[2] * 0.12, AC[3] * 0.12, 0.95 })
            end

            self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
                FT.l10nFormat("ft_organic_field_fmt", "Field #%s", tostring(field.id)),
                RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT, true)
            self.r:appText(x + cw - btnW - FT.px(8), y - FT.py(2), FT.FONT.SMALL,
                label, RenderText.ALIGN_RIGHT, col)
            y = y - FT.py(14)

            local countdown = ""
            if key == "in_transition" and st ~= nil then
                local accrued = tonumber(st.daysAccrued) or 0
                local need = tonumber(st.transitionDaysNeeded) or 0
                local left = math.max(0, need - accrued)
                countdown = FT.l10nFormat("ft_organic_countdown_fmt", "%d / %d days  (%d left)",
                    math.floor(accrued + 0.5), math.floor(need + 0.5), math.floor(left + 0.5))
            elseif key == "certified" then
                local breaches = st and tonumber(st.breaches) or 0
                countdown = FT.l10nFormat("ft_organic_breaches_fmt", "Breaches: %d", breaches)
            else
                countdown = FT.l10n("ft_organic_not_in_programme", "Not in the organic programme")
            end
            self.r:appText(x, y - FT.py(1), FT.FONT.TINY, countdown,
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)

            local selBtn = self.r:button(x + cw - btnW, y - FT.py(2), btnW, btnH,
                FT.l10nAuto(isSel and "VIEW" or "SELECT"), isSel and AC or FT.C.BTN_NEUTRAL, {
                    onClick = function()
                        self.system.organicSelectedField = field.id
                    end
                }, true)
            table.insert(self._contentBtns, selBtn)
            y = y - FT.py(20)
        end

        -- Actions for selected field
        local selSt = _pcall(function() return organic:getFieldOrganicState(selected) end)
        local selKey = _stateKey(selSt)
        y = y - FT.py(4)
        self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
            FT.l10nFormat("ft_organic_selected_field_fmt", "Selected field #%s", tostring(selected)),
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT, true)
        y = y - FT.py(16)

        local gap = FT.px(6)
        local half = (cw - gap) / 2
        local canIn = (selKey == "conventional")
        local canOut = (selKey == "in_transition" or selKey == "certified")
        if type(organic.requestOptIn) == "function" and canIn then
            local bIn = self.r:button(x, y - FT.py(20), half, FT.py(20), FT.l10n("ft_organic_opt_in", "OPT IN"),
                FT.C.BTN_PRIMARY, {
                    onClick = function()
                        pcall(function() organic:requestOptIn(selected) end)
                    end
                }, true)
            table.insert(self._contentBtns, bIn)
        else
            self.r:appText(x, y - FT.py(8), FT.FONT.TINY,
                canIn and FT.l10n("ft_organic_opt_in_unavailable", "Opt-in unavailable")
                    or FT.l10n("ft_organic_already_opted_in", "Already opted in"),
                RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        end
        if type(organic.requestOptOut) == "function" and canOut then
            local bOut = self.r:button(x + half + gap, y - FT.py(20), half, FT.py(20),
                FT.l10n("ft_organic_opt_out", "OPT OUT"), FT.C.BTN_DANGER, {
                    onClick = function()
                        pcall(function() organic:requestOptOut(selected) end)
                    end
                }, true)
            table.insert(self._contentBtns, bOut)
        end
        y = y - FT.py(28)
    end

    ------------------------------------------------------------------
    -- PRACTICES
    ------------------------------------------------------------------
    y = self:drawRule(y, 0.3)
    y = self:drawSection(y, FT.l10n("ft_organic_practices", "PRACTICES"), true)
    local sel = self.system.organicSelectedField
    if sel == nil and #fields > 0 then sel = fields[1].id end
    if sel == nil then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_select_field", "Select a field to see practice advice."), RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(20)
    else
        local info = _pcall(function() return soil:getFieldInfo(sel) end)
        self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
            FT.l10nFormat("ft_organic_field_fmt", "Field #%s", tostring(sel)),
            RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT, true)
        y = y - FT.py(14)
        for _, line in ipairs(_practiceLines(info)) do
            self.r:appText(x, y - FT.py(1), FT.FONT.SMALL, line,
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            y = y - FT.py(14)
        end
        y = y - FT.py(6)
    end

    ------------------------------------------------------------------
    -- STUBS
    ------------------------------------------------------------------
    y = self:drawRule(y, 0.3)
    y = self:drawSection(y, FT.l10n("ft_organic_compost", "COMPOST"), true)
    local compost = (g_currentMission ~= nil and g_currentMission.compostManager) or nil
    if compost == nil or type(compost.getBatchRows) ~= "function" then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_compost_na", "not available - install SoilFertilizer"), RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(22)
    else
        local rows = _pcall(function() return compost:getBatchRows(farmId) end) or {}
        if #rows == 0 then
            self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
                FT.l10n("ft_organic_compost_none", "No compost batches. Start one from the SoilFertilizer console."),
                RenderText.ALIGN_LEFT, FT.C.MUTED, true)
            -- Advance past the line (same step as the not-available branch) so the
            -- LIVESTOCK header does not land on top of it.
            y = y - FT.py(22)
        else
            for _, b in ipairs(rows) do
                local days = math.floor(b.daysRemaining or 0)
                local state = b.ready
                    and FT.l10nFormat("ft_organic_batch_ready_fmt", "READY - %d L", math.floor(b.outputLitres or 0))
                    or (days == 1 and FT.l10nFormat("ft_organic_batch_day_left_fmt", "%d day left", days)
                        or FT.l10nFormat("ft_organic_batch_days_left_fmt", "%d days left", days))
                local tag = b.organicSafe and FT.l10n("ft_organic_batch_safe", "organic-safe")
                    or FT.l10n("ft_organic_batch_unsafe", "not organic-safe")
                self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
                    FT.l10nFormat("ft_organic_batch_fmt", "Batch #%d: %s  (%s)", b.batchId, state, tag),
                    RenderText.ALIGN_LEFT, b.ready and FT.C.POSITIVE or FT.C.TEXT_DIM, true)
                y = y - FT.py(14)
            end
        end
        y = y - FT.py(8)
    end

    y = self:drawSection(y, FT.l10n("ft_organic_livestock", "LIVESTOCK"), true)
    local dcMgr = (g_currentMission and g_currentMission.dairyCoreManager)
        or getfenv(0)["g_dairyCoreManager"]
    if dcMgr == nil then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_livestock_na", "not available - install DairyCore"),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(22)
    else
        local barnRows = {}
        if type(dcMgr.getBarnRows) == "function" then
            local ok, result = pcall(function() return dcMgr:getBarnRows() end)
            if ok and type(result) == "table" then barnRows = result end
        end
        local farmBarns = {}
        for _, row in ipairs(barnRows) do
            if row.farmId == farmId then farmBarns[#farmBarns + 1] = row end
        end

        if #farmBarns == 0 then
            self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
                FT.l10n("ft_organic_no_barns", "No dairy barns on this farm."),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
            y = y - FT.py(22)
        else
            local fp = dcMgr.feedProvenance
            local farmOrgFrac = 0
            if fp ~= nil and type(fp.organicFeedFraction) == "function" then
                local ok2, frac = pcall(function() return fp:organicFeedFraction(farmId) end)
                if ok2 and type(frac) == "number" then farmOrgFrac = frac end
            end

            local orgPct = math.floor(farmOrgFrac * 100 + 0.5)
            local orgCol = orgPct >= 80 and FT.C.POSITIVE
                or orgPct >= 40 and FT.C.WARNING or FT.C.TEXT_DIM
            self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
                FT.l10n("ft_organic_feed_share", "Farm organic feed share"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
            self.r:appText(x + cw, y - FT.py(2), FT.FONT.TINY,
                string.format("%d%%", orgPct), RenderText.ALIGN_RIGHT, orgCol, true)
            y = y - FT.py(14)

            for _, barn in ipairs(farmBarns) do
                local health = math.floor(tonumber(barn.herdHealth) or 0)
                local hCol = health >= 85 and FT.C.POSITIVE
                    or health >= 60 and FT.C.TEXT_NORMAL
                    or health >= 35 and FT.C.WARNING or FT.C.NEGATIVE
                local myc = tonumber(barn.mycotoxin) or 0
                local feedFlag = barn.feedDiseaseFlag == true

                self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
                    FT.l10nFormat("ft_organic_barn_fmt", "Barn %s", tostring(barn.barnId)),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT, true)
                y = y - FT.py(14)

                self.r:appText(x, y - FT.py(1), FT.FONT.TINY,
                    FT.l10n("ft_organic_herd_health", "Herd health"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
                self.r:appText(x + cw, y - FT.py(1), FT.FONT.TINY,
                    string.format("%d", health), RenderText.ALIGN_RIGHT, hCol, true)
                y = y - FT.py(12)

                if myc > 0 then
                    self.r:appText(x, y - FT.py(1), FT.FONT.TINY,
                        FT.l10n("ft_organic_mycotoxin", "Mycotoxin penalty"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
                    self.r:appText(x + cw, y - FT.py(1), FT.FONT.TINY,
                        string.format("-%d", myc), RenderText.ALIGN_RIGHT, FT.C.NEGATIVE, true)
                    y = y - FT.py(12)
                end

                if feedFlag then
                    local feedLabel = barn.feedDiseaseCropName or FT.l10n("ft_organic_elevated_risk", "Elevated risk")
                    self.r:appText(x, y - FT.py(1), FT.FONT.TINY,
                        FT.l10n("ft_organic_feed_disease", "Feed disease"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
                    self.r:appText(x + cw, y - FT.py(1), FT.FONT.TINY,
                        tostring(feedLabel), RenderText.ALIGN_RIGHT, FT.C.NEGATIVE)
                    y = y - FT.py(12)
                end
                y = y - FT.py(4)
            end

            if orgPct < 80 then
                self.r:appText(x, y - FT.py(1), FT.FONT.TINY,
                    FT.l10n("ft_organic_feed_tip", "Tip: certify more feed fields organic to raise the share above 80%."),
                    RenderText.ALIGN_LEFT, FT.C.MUTED, true)
                y = y - FT.py(14)
            end
        end
        y = y - FT.py(6)
    end

    ------------------------------------------------------------------
    -- TRACEABILITY (read-only chain: field -> storage -> sale)
    ------------------------------------------------------------------
    y = self:drawRule(y, 0.3)
    y = self:drawSection(y, FT.l10n("ft_organic_traceability", "TRACEABILITY"), true)
    if organic == nil then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_trace_na", "not available - organic certification not loaded"),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(22)
    elseif #fields == 0 then
        self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
            FT.l10n("ft_organic_no_fields", "No owned fields."), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(22)
    else
        self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
            "FIELD", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x + cw * 0.35, y - FT.py(2), FT.FONT.TINY,
            "CROP", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x + cw, y - FT.py(2), FT.FONT.TINY,
            "STATUS", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        y = y - FT.py(12)

        for _, field in ipairs(fields) do
            local st = _pcall(function() return organic:getFieldOrganicState(field.id) end)
            local key = _stateKey(st)
            local col = STATE_COLOR[key] or FT.C.MUTED
            local info = _pcall(function() return soil:getFieldInfo(field.id) end)
            local crop = (info and tostring(info.lastCrop)) or "-"

            self.r:appText(x, y - FT.py(1), FT.FONT.TINY,
                string.format("#%s", tostring(field.id)),
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + cw * 0.35, y - FT.py(1), FT.FONT.TINY,
                crop, RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + cw, y - FT.py(1), FT.FONT.TINY,
                STATE_LABEL[key] or "?", RenderText.ALIGN_RIGHT, col)
            y = y - FT.py(12)
        end
        y = y - FT.py(4)

        local dcMgrTrace = (g_currentMission and g_currentMission.dairyCoreManager)
            or getfenv(0)["g_dairyCoreManager"]
        local fpTrace = dcMgrTrace and dcMgrTrace.feedProvenance
        if fpTrace and type(fpTrace.organicFeedFraction) == "function" then
            local okF, frac = pcall(function() return fpTrace:organicFeedFraction(farmId) end)
            if okF and type(frac) == "number" then
                local pct = math.floor(frac * 100 + 0.5)
                local fCol = pct >= 80 and FT.C.POSITIVE
                    or pct >= 40 and FT.C.WARNING or FT.C.TEXT_DIM
                self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
                    FT.l10n("ft_organic_storage_fraction", "Storage organic fraction"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
                self.r:appText(x + cw, y - FT.py(2), FT.FONT.TINY,
                    string.format("%d%%", pct), RenderText.ALIGN_RIGHT, fCol, true)
                y = y - FT.py(14)
            end
        end

        self.r:appText(x, y - FT.py(2), FT.FONT.TINY,
            FT.l10n("ft_organic_sale_premium", "Sale premium: pending MDM contract"),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(14)
    end

    y = self:drawSection(y, FT.l10n("ft_organic_market", "MARKET"), true)
    self.r:appText(x, y - FT.py(4), FT.FONT.SMALL,
        FT.l10n("ft_organic_market_na", "not available - waiting on organic premium / MDM contract"),
        RenderText.ALIGN_LEFT, FT.C.MUTED, true)
    y = y - FT.py(22)

    self:setContentHeight(startY - y + scrollY + bottomPad)
    self:drawInfoIcon("_organicHelp", AC)
    self:drawScrollBar()
end)
