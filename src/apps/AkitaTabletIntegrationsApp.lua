-- =========================================================
-- FarmTablet v2 - Akita83 companion integrations
-- Dedi-safe: FarmTablet is client-side; actions call companion-mod
-- functions only when those functions are present.
-- =========================================================

local function ftAkitaText(key, fallback)
    if g_i18n and key and g_i18n:hasText(key) then
        return g_i18n:getText(key)
    end
    return fallback or tostring(key or "")
end

local function ftAkitaBool(v)
    return v == true and ftAkitaText("ft_common_on", "On") or ftAkitaText("ft_common_off", "Off")
end

local function ftAkitaCurrentLang()
    local lang = ""
    if g_languageShort ~= nil then lang = tostring(g_languageShort) end
    if (lang == "" or lang == "nil") and g_i18n ~= nil then
        lang = tostring(g_i18n.languageShort or g_i18n.currentLanguage or g_i18n.language or "")
    end
    return string.lower(lang)
end

local function ftAkitaLineText(line)
    local t = tostring(line or "")
    local lang = ftAkitaCurrentLang()
    if lang:sub(1,2) ~= "de" then
        t = t:gsub("Gesamt", "Overall")
        t = t:gsub("Futter", "Food")
        t = t:gsub("Wasser", "Water")
        t = t:gsub("Stroh", "Straw")
        t = t:gsub("Auffüllen ab", "Refill below")
        t = t:gsub("Zielfüllung", "Target fill")
        t = t:gsub("Priorität", "Priority")
        t = t:gsub("Letzte Aktion", "Last action")
        t = t:gsub(": An", ": On")
        t = t:gsub(": Aus", ": Off")
    end
    return t
end


local function ftAkitaSafeCall(obj, name, ...)
    if obj ~= nil and type(obj[name]) == "function" then
        local ok, result = pcall(obj[name], obj, ...)
        if ok then return result end
        Logging.warning("[FarmTablet] Integration call failed: %s", tostring(name))
    end
    return nil
end

local function ftAkitaMoney(v)
    local n = math.floor(tonumber(v) or 0)
    if g_i18n then
        local ok, text = pcall(g_i18n.formatMoney, g_i18n, n, 0, true, true)
        if ok and text ~= nil then return text end
    end
    return tostring(n)
end

FarmTabletUI:registerDrawer(FT.APP.ANIMAL_AUTO_CARE, function(self)
    local AC = FT.appColor(FT.APP.ANIMAL_AUTO_CARE)
    local core = g_currentMission and g_currentMission.animalAutoCareCore or nil
    local startY = self:drawAppHeader(
        ftAkitaText("ft_ui_app_animal_auto_care", "AnimalAutoCare"),
        core and ftAkitaText("ft_common_connected", "Connected") or ftAkitaText("ft_common_inactive", "Inactive")
    )
    local x, _, _, _ = self:contentInner()
    local y = startY + self:getContentScrollY()

    if core == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            ftAkitaText("ft_aac_not_detected", "AnimalAutoCare was not detected."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        return
    end

    local data = ftAkitaSafeCall(core, "getMCCData") or {}
    y = self:drawSection(y, ftAkitaText("ft_common_status", "STATUS"))
    y = self:drawRow(y, ftAkitaText("ft_aac_overall", "Overall"), ftAkitaBool(data.isEnabled), nil, data.isEnabled and FT.C.POSITIVE or FT.C.WARNING)
    y = self:drawRow(y, ftAkitaText("ft_aac_food", "Food"), ftAkitaBool(data.autoFutterEnabled))
    y = self:drawRow(y, ftAkitaText("ft_aac_water", "Water"), ftAkitaBool(data.autoWasserEnabled))
    y = self:drawRow(y, ftAkitaText("ft_aac_straw", "Straw"), ftAkitaBool(data.autoStrohEnabled))
    y = self:drawRow(y, ftAkitaText("ft_aac_purchase_cost", "Purchase Cost"), ftAkitaMoney(data.lastNotKaufCost))
    y = self:drawRow(y, ftAkitaText("ft_aac_care_cost", "Care Cost"), ftAkitaMoney(data.lastWorkerCost))

    local farmId = self.system.data:getPlayerFarmId()
    local btn = self.r:button(x, y - FT.py(8), FT.px(170), FT.py(22),
        ftAkitaText("ft_aac_care_now", "Care Now"), AC, {
            onClick = function()
                local c = g_currentMission and g_currentMission.animalAutoCareCore or nil
                if c and type(c.performDailyPflegeForFarm) == "function" then
                    c:performDailyPflegeForFarm(farmId, true)
                end
            end
        })
    table.insert(self._contentBtns, btn)
    y = y - FT.py(40)

    y = self:drawSection(y, ftAkitaText("ft_aac_last_action", "LAST ACTION"))
    local lines = data.lines or ftAkitaSafeCall(core, "getMCCLines") or {}
    local shown = 0
    for _, line in ipairs(lines) do
        line = tostring(line or "")
        if line ~= "" and not line:find("^Status:") and shown < 10 then
            self.r:appText(x + FT.px(8), y, FT.FONT.TINY, ftAkitaLineText(line), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            y = y - FT.py(12)
            shown = shown + 1
        end
    end
    if shown == 0 then
        self.r:appText(x + FT.px(8), y, FT.FONT.SMALL,
            ftAkitaText("ft_aac_no_action", "No action has been recorded yet."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    end
    self:setContentHeight(startY - y + FT.py(20))
    self:drawScrollBar()
end)

FarmTabletUI:registerDrawer(FT.APP.ANIMAL_VET, function(self)
    local AC = FT.appColor(FT.APP.ANIMAL_VET)
    local avs = g_currentMission and (g_currentMission.animalVetSystem or g_currentMission.animalVet) or nil
    local sick = avs and avs.sickStables or {}
    local count = avs and (ftAkitaSafeCall(avs, "getActiveIllnessCount") or 0) or 0
    local startY = self:drawAppHeader(
        ftAkitaText("ft_ui_app_animal_vet_system", "AnimalVetSystem"),
        avs and string.format(ftAkitaText("ft_vet_active_cases", "%d active cases"), count) or ftAkitaText("ft_common_inactive", "Inactive")
    )
    local x, _, cw, _ = self:contentInner()
    local y = startY + self:getContentScrollY()
    if avs == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            ftAkitaText("ft_vet_not_detected", "AnimalVetSystem was not detected."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        return
    end

    y = self:drawSection(y, ftAkitaText("ft_common_overview", "OVERVIEW"))
    y = self:drawRow(y, ftAkitaText("ft_vet_active_illnesses", "Active Illnesses"), tostring(count), nil, count > 0 and FT.C.WARNING or FT.C.POSITIVE)
    y = self:drawRow(y, ftAkitaText("ft_vet_veterinarian", "Veterinarian"), avs.vetBusy == true and ftAkitaText("ft_common_busy", "Busy") or ftAkitaText("ft_common_available", "Available"), nil, avs.vetBusy == true and FT.C.WARNING or FT.C.POSITIVE)
    if count <= 0 then
        self.r:appText(x + FT.px(8), y - FT.py(12), FT.FONT.SMALL,
            ftAkitaText("ft_vet_no_sick_pens", "No sick animal pens reported."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    else
        y = y - FT.py(6)
        y = self:drawSection(y, ftAkitaText("ft_vet_cases", "CASES"))
        for stableId, d in pairs(sick) do
            local name = tostring(d.stableName or d.animalName or stableId or ftAkitaText("ft_vet_pen", "Pen"))
            local illness = tostring(d.illnessName or ftAkitaText("ft_vet_illness", "Illness"))
            local rem = math.max(0, math.floor((tonumber(d.remainingMs) or 0) / 60000))
            local status = d.vetCalled and ftAkitaText("ft_vet_veterinarian", "Veterinarian")
                or d.workerTreatment and ftAkitaText("ft_vet_worker", "Worker")
                or tostring(d.treatmentMode or ftAkitaText("ft_vet_self", "Self"))
            self.r:appRect(x - FT.px(4), y - FT.py(50), cw + FT.px(8), FT.py(54), {AC[1]*0.08, AC[2]*0.08, AC[3]*0.08, 0.85})
            self.r:appText(x + FT.px(6), y - FT.py(10), FT.FONT.BODY,
                FT_Renderer.truncate(name, 20), RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
            self.r:appText(x + cw - FT.px(6), y - FT.py(10), FT.FONT.TINY,
                FT_Renderer.truncate(status, 14), RenderText.ALIGN_RIGHT, FT.C.TEXT_ACCENT)
            self.r:appText(x + FT.px(10), y - FT.py(28), FT.FONT.TINY,
                string.format(ftAkitaText("ft_vet_case_line", "%s - %d animals - about %d min"), illness, tonumber(d.animalCount) or 0, rem),
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            y = y - FT.py(60)
        end
    end
    self:setContentHeight(startY - y + FT.py(20))
    self:drawScrollBar()
end)

FarmTabletUI:registerDrawer(FT.APP.FACTORY_WEEK, function(self)
    local AC = FT.appColor(FT.APP.FACTORY_WEEK)
    local offlineFrozen = self._signalOutageActive == true
    local fws = g_currentMission and g_currentMission.fws_weekSchedule or nil
    local liveOpen, liveTotal = 0, 0
    if fws and fws.getOpenFactoryCountForHud then liveOpen, liveTotal = fws:getOpenFactoryCountForHud() end
    if fws ~= nil and offlineFrozen ~= true then
        self._fwsTabletCache = {
            open = liveOpen,
            total = liveTotal,
            hudDayName = fws.hudDayName,
            hudTimeText = fws.hudTimeText,
            fireAutoEnabled = fws.fireAutoEnabled,
            hudEventSummaryText = fws.hudEventSummaryText,
            factoriesForHud = fws.factoriesForHud,
        }
    end
    local fwsView = (offlineFrozen and self._fwsTabletCache) or fws
    local open, total = liveOpen, liveTotal
    if offlineFrozen and self._fwsTabletCache ~= nil then
        open, total = tonumber(self._fwsTabletCache.open) or 0, tonumber(self._fwsTabletCache.total) or 0
    end
    local startY = self:drawAppHeader(
        ftAkitaText("ft_ui_app_factory_week_schedule", "FactoryWeekSchedule"),
        fwsView and string.format(ftAkitaText("ft_fws_open_count", "%d/%d open"), open, total) or ftAkitaText("ft_common_inactive", "Inactive")
    )
    local x, _, cw, _ = self:contentInner()
    local y = startY + self:getContentScrollY()
    if fwsView == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            ftAkitaText("ft_fws_not_detected", "FactoryWeekSchedule was not detected."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        return
    end

    y = self:drawSection(y, ftAkitaText("ft_common_status", "STATUS"))
    y = self:drawRow(y, ftAkitaText("ft_common_time", "Time"), tostring((fwsView.hudDayName or "-") .. " " .. (fwsView.hudTimeText or "-")))
    y = self:drawRow(y, ftAkitaText("ft_fws_factories_open", "Factories Open"), tostring(open) .. " / " .. tostring(total), nil, open > 0 and FT.C.POSITIVE or FT.C.WARNING)
    y = self:drawRow(y, ftAkitaText("ft_fws_fire_system", "Fire System"), ftAkitaBool(fwsView.fireAutoEnabled == true))
    if fwsView.hudEventSummaryText ~= nil and tostring(fwsView.hudEventSummaryText) ~= "" then
        y = self:drawRow(y, ftAkitaText("ft_common_event", "Event"), tostring(fwsView.hudEventSummaryText), nil, FT.C.WARNING)
    end

    y = y - FT.py(6)
    y = self:drawSection(y, ftAkitaText("ft_fws_factories", "FACTORIES"))
    local list = fwsView.factoriesForHud or {}
    if #list == 0 then
        self.r:appText(x + FT.px(8), y - FT.py(12), FT.FONT.SMALL,
            ftAkitaText("ft_fws_no_factories", "No factories are in the FactoryWeekSchedule HUD cache yet."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    end
    for i, fac in ipairs(list) do
        if type(fac) == "table" then
            local name = tostring(fac.displayName or fac.name or fac.title or (ftAkitaText("ft_fws_factory", "Factory") .. " " .. i))
            local state = fac.isOpen == true and ftAkitaText("ft_common_open", "Open") or ftAkitaText("ft_common_closed", "Closed")
            local worker = tostring(fac.workerText or fac.workersText or "")
            local event = tostring(fac.hudEventText or fac.eventText or "")
            self.r:appRect(x - FT.px(4), y - FT.py(48), cw + FT.px(8), FT.py(52), {AC[1]*0.08, AC[2]*0.08, AC[3]*0.08, 0.85})
            self.r:appText(x + FT.px(6), y - FT.py(10), FT.FONT.BODY,
                FT_Renderer.truncate(name, 20), RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
            self.r:appText(x + cw - FT.px(6), y - FT.py(10), FT.FONT.TINY, state,
                RenderText.ALIGN_RIGHT, fac.isOpen and FT.C.POSITIVE or FT.C.WARNING)
            local line = worker ~= "" and worker or (event ~= "" and event or ftAkitaText("ft_fws_no_event", "No event"))
            self.r:appText(x + FT.px(10), y - FT.py(28), FT.FONT.TINY,
                FT_Renderer.truncate(line, 40), RenderText.ALIGN_LEFT, event ~= "" and FT.C.WARNING or FT.C.TEXT_NORMAL)
            y = y - FT.py(58)
        end
    end
    self:setContentHeight(startY - y + FT.py(20))
    self:drawScrollBar()
end)

local function ftRDGetDealer()
    if g_currentMission ~= nil then
        if g_currentMission.realisticDealer ~= nil then return g_currentMission.realisticDealer end
        if g_currentMission.RealisticDealer ~= nil then return g_currentMission.RealisticDealer end
    end
    if g_realisticDealer ~= nil then return g_realisticDealer end
    if RealisticDealer ~= nil and RealisticDealer.instance ~= nil then return RealisticDealer.instance end
    return nil
end

local function ftRDStatusText(c)
    local st = tostring((c and (c.statusText or c.enforcementStatus or c.status)) or "")
    if st == "repossession" or (c and (c.repossession == true or c.repossessionPending == true)) then return ftAkitaText("ft_rd_status_repossession", "Repossession running") end
    if st == "repossessed" or (c and c.repossessed == true) then return ftAkitaText("ft_rd_status_repossessed", "Repossessed") end
    if st == "paid" then return ftAkitaText("ft_rd_status_paid", "Paid") end
    if st == "overdue" or st == "defaulted" then return ftAkitaText("ft_rd_status_overdue", "Overdue") end
    if st == "active" or st == "none" or st == "" then return ftAkitaText("ft_rd_status_active", "Active") end
    return st
end

FarmTabletUI:registerDrawer(FT.APP.REALISTIC_DEALER, function(self)
    local AC = FT.appColor(FT.APP.REALISTIC_DEALER)
    local rd = ftRDGetDealer()
    local fm = rd ~= nil and rd.financeManager or nil
    local farmId = self.system.data:getPlayerFarmId()
    local startY = self:drawAppHeader(
        ftAkitaText("ft_ui_app_realistic_dealer", "RealisticDealer"),
        rd and ftAkitaText("ft_common_connected", "Connected") or ftAkitaText("ft_common_inactive", "Inactive")
    )
    local x, _, cw, _ = self:contentInner()
    local y = startY + self:getContentScrollY()

    if rd == nil or fm == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            ftAkitaText("ft_rd_not_detected", "RealisticDealer was not detected."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:setContentHeight(FT.py(80))
        return
    end

    local data = ftAkitaSafeCall(fm, "getFarmOSData", farmId) or {}
    local contracts = data.contracts
    if type(contracts) ~= "table" then
        contracts = ftAkitaSafeCall(fm, "getActiveContracts", farmId) or {}
    end

    local active = tonumber(data.active) or #contracts
    local debt = tonumber(data.debt) or ftAkitaSafeCall(fm, "getActiveDebt", farmId) or 0
    local credit = tonumber(data.creditScore) or ftAkitaSafeCall(fm, "getCreditScore", farmId) or 0
    local overdue = tonumber(data.overdue) or 0
    local repoCount = 0
    for _, c in ipairs(contracts or {}) do
        if type(c) == "table" and (c.repossession == true or c.repossessionPending == true or tostring(c.enforcementStatus or "") == "repossession") then
            repoCount = repoCount + 1
        end
        if type(c) == "table" and (tonumber(c.missedInstallments) or 0) > 0 then
            overdue = math.max(overdue, 1)
        end
    end

    y = self:drawSection(y, ftAkitaText("ft_common_overview", "OVERVIEW"))
    y = self:drawRow(y, ftAkitaText("ft_rd_active_financing", "Active Financing"), tostring(active), nil, active > 0 and FT.C.WARNING or FT.C.POSITIVE)
    y = self:drawRow(y, ftAkitaText("ft_rd_remaining_debt", "Remaining Debt"), ftAkitaMoney(debt), nil, debt > 0 and FT.C.WARNING or FT.C.POSITIVE)
    y = self:drawRow(y, ftAkitaText("ft_rd_credit_score", "Credit Score"), tostring(math.floor(credit)) .. "/100", nil, credit >= 60 and FT.C.POSITIVE or FT.C.WARNING)
    y = self:drawRow(y, ftAkitaText("ft_rd_open_notices", "Open Notices"), tostring(overdue), nil, overdue > 0 and FT.C.WARNING or FT.C.POSITIVE)
    y = self:drawRow(y, ftAkitaText("ft_rd_repossessions", "Repossessions"), tostring(repoCount), nil, repoCount > 0 and FT.C.NEGATIVE or FT.C.TEXT_NORMAL)

    local btn = self.r:button(x, y - FT.py(8), FT.px(160), FT.py(22),
        ftAkitaText("ft_rd_check_repo", "Check Repo"), AC, {
            onClick = function()
                local dealer = ftRDGetDealer()
                local f = dealer ~= nil and dealer.financeManager or nil
                if f ~= nil and type(f.forceRepoTick) == "function" then
                    pcall(f.forceRepoTick, f, 3500)
                end
            end
        })
    table.insert(self._contentBtns, btn)
    y = y - FT.py(42)

    y = self:drawSection(y, ftAkitaText("ft_rd_contracts", "CONTRACTS"))
    if #contracts == 0 then
        self.r:appText(x + FT.px(8), y - FT.py(12), FT.FONT.SMALL,
            ftAkitaText("ft_rd_no_contracts", "No active financing contracts."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(34)
    else
        for _, c in ipairs(contracts) do
            if type(c) == "table" then
                local name = tostring(c.name or c.vehicleName or c.itemKey or ftAkitaText("ft_rd_vehicle", "Vehicle"))
                local remaining = tonumber(c.remainingAmount or c.remainingDebt or c.remaining) or 0
                local rate = tonumber(c.installmentAmount or c.rateAmount) or 0
                local paid = tonumber(c.paidInstallments) or 0
                local total = tonumber(c.totalInstallments or c.selectedInstallments) or 0
                local missed = tonumber(c.missedInstallments) or 0
                local status = ftRDStatusText(c)
                local statusColor = (missed > 0 or c.repossession == true or c.repossessionPending == true) and FT.C.WARNING or FT.C.POSITIVE
                if c.repossessed == true or tostring(c.status or "") == "repossessed" then statusColor = FT.C.NEGATIVE end

                self.r:appRect(x - FT.px(4), y - FT.py(58), cw + FT.px(8), FT.py(62), {AC[1]*0.10, AC[2]*0.10, AC[3]*0.10, 0.85})
                self.r:appText(x + FT.px(6), y - FT.py(10), FT.FONT.BODY, name, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
                self.r:appText(x + cw - FT.px(6), y - FT.py(10), FT.FONT.TINY, status, RenderText.ALIGN_RIGHT, statusColor)
                self.r:appText(x + FT.px(10), y - FT.py(28), FT.FONT.TINY,
                    string.format(ftAkitaText("ft_rd_money_line", "Remaining: %s | Rate: %s"), ftAkitaMoney(remaining), ftAkitaMoney(rate)),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
                local inst = string.format(ftAkitaText("ft_rd_installment_line", "Installments: %d/%d"), paid, total)
                if missed > 0 then
                    inst = inst .. " | " .. string.format(ftAkitaText("ft_rd_notices_line", "Notices: %d"), missed)
                end
                self.r:appText(x + FT.px(10), y - FT.py(44), FT.FONT.TINY, inst, RenderText.ALIGN_LEFT, missed > 0 and FT.C.WARNING or FT.C.TEXT_DIM)
                y = y - FT.py(68)
            end
        end
    end

    y = self:drawSection(y, ftAkitaText("ft_common_note", "NOTE"))
    self.r:appText(x + FT.px(8), y - FT.py(10), FT.FONT.TINY,
        ftAkitaText("ft_rd_server_note", "Vehicle repossessions still run through RealisticDealer server-side."),
        RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    y = y - FT.py(24)

    self:setContentHeight(startY - y + FT.py(20))
    self:drawScrollBar()
end)
