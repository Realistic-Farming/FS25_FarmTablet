-- =========================================================
-- FarmTablet v2 -- ProStaff Co-Op App
-- =========================================================
-- Read-only dashboard for the 20-level Co-Op progression
-- system. Shows current level, investment progress, active
-- benefits, and next-level preview. Pulls all data from
-- g_currentMission.proStaffManager via the ProStaffAPI
-- getter proxy. No write actions from this tab.
-- =========================================================

FarmTabletUI:registerDrawer(FT.APP.PROSTAFF, function(self)
    local AC = FT.appColor(FT.APP.PROSTAFF)

    if self:drawHelpPage("_prostaffHelp", FT.APP.PROSTAFF, "ProStaff Co-Op", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays your farm's 20-level Co-Op progression\n" ..
                  "status: current level, investment progress, active\n" ..
                  "benefits, and what the next level unlocks." },
        { title = "LEVELS",
          body  = "Each level costs a one-time investment. Costs\n" ..
                  "scale exponentially (level^2.2 * baseCost) and\n" ..
                  "carry a wealth bracket premium at L10+." },
        { title = "BENEFITS",
          body  = "Active modifiers are listed by category: wages,\n" ..
                  "fertilizer, fatigue, dairy, and feature flags.\n" ..
                  "Benefits stack as you level up." },
        { title = "INVESTMENT",
          body  = "The progress bar shows total invested vs the\n" ..
                  "next level cost. Purchase levels via the console\n" ..
                  "command: proStaffBuy" },
    }) then return end

    local ACENT = AC
    local startY = self:drawAppHeader("ProStaff Co-Op", "Progression")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY
    local minY = contentY + FT.py(8)

    local psm = g_currentMission and g_currentMission.proStaffManager
    if not psm then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "ProStaff Co-Op is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_ProStaffCoOp to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_prostaffHelp", ACENT)
        return
    end

    -- Resolve local farm
    local farmId = nil
    pcall(function()
        if g_currentMission.getFarmId then
            farmId = g_currentMission:getFarmId()
        end
    end)

    local level = 0
    pcall(function() level = psm:getLevel(farmId) end)
    local levelName = (ProStaffConstants and ProStaffConstants.LEVEL_NAMES and ProStaffConstants.LEVEL_NAMES[level])
                  or "Unranked"
    local maxLevel = (ProStaffConstants and ProStaffConstants.MAX_LEVEL) or 20

    -- Investment data
    local investmentTotal = 0
    local rec = psm.farms and psm.farms[farmId]
    if rec then
        investmentTotal = rec.investmentTotal or 0
    end

    local nextCost = nil
    pcall(function() nextCost = psm:getNextLevelCost(farmId) end)

    -- ── LEVEL HERO ─────────────────────────────────────────
    local heroColor = level >= 10 and FT.C.POSITIVE or level >= 1 and ACENT or FT.C.TEXT_DIM
    self.r:appRect(x - FT.px(4), y - FT.py(24), cw + FT.px(8), FT.py(22),
        {heroColor[1]*0.12, heroColor[2]*0.12, heroColor[3]*0.12, 0.95})
    self.r:appText(x, y - FT.py(20), FT.FONT.BODY,
        "Level " .. level .. "  " .. levelName, RenderText.ALIGN_LEFT, heroColor)
    self.r:appText(x + cw, y - FT.py(20), FT.FONT.SMALL,
        level .. " / " .. maxLevel, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
    y = y - FT.py(28)

    -- ── PROGRESS BAR ───────────────────────────────────────
    if level < maxLevel and nextCost and nextCost > 0 then
        local pct = math.min(100, math.floor((investmentTotal / (investmentTotal + nextCost)) * 100))
        y = self:drawRow(y, "Progress", tostring(pct) .. "%")
        y = y + FT.py(FT.SP.ROW) - FT.py(8)
        y = self:drawBar(y, pct, 100, ACENT)
        y = y - FT.py(4)
        y = self:drawRow(y, "Invested",
            (g_i18n and g_i18n:formatMoney(math.floor(investmentTotal), 0, true, true))
            or ("$" .. math.floor(investmentTotal)))
        y = self:drawRow(y, "Next Level",
            (g_i18n and g_i18n:formatMoney(nextCost, 0, true, true))
            or ("$" .. nextCost))
    elseif level >= maxLevel then
        self.r:appText(x, y - FT.py(8), FT.FONT.BODY,
            "MAX LEVEL REACHED", RenderText.ALIGN_LEFT, FT.C.POSITIVE)
        y = y - FT.py(20)
    end

    -- ── ACTIVE BENEFITS ────────────────────────────────────
    y = y - FT.py(4)
    y = self:drawRule(y, 0.3)
    y = self:drawSection(y, "ACTIVE BENEFITS")

    local function safeGet(funcName, ...)
        local result = nil
        pcall(function()
            result = psm[funcName](psm, ...)
        end)
        return result
    end

    local function pctLabel(mult, inverse)
        if not mult or mult == 1.0 then return nil end
        if inverse then
            return string.format("-%d%%", math.floor((1 - mult) * 100 + 0.5))
        else
            local delta = mult - 1.0
            if delta > 0 then
                return string.format("+%d%%", math.floor(delta * 100 + 0.5))
            else
                return string.format("%d%%", math.floor(mult * 100 + 0.5))
            end
        end
    end

    -- WorkerCosts benefits
    local wageMult = safeGet("getWageModifier", farmId)
    local fatigueMit = safeGet("getFatigueMitigation", farmId)
    local fatigueRec = safeGet("getFatigueRecoveryBonus", farmId)
    local globalEff = safeGet("getGlobalEffectivenessBonus", farmId)

    local hasWorkerBenefits = (wageMult and wageMult ~= 1.0)
                           or (fatigueMit and fatigueMit ~= 1.0)
                           or (fatigueRec and fatigueRec ~= 1.0)
                           or (globalEff and globalEff ~= 1.0)

    if hasWorkerBenefits then
        y = self:drawRow(y, "Worker Costs", "", nil, FT.C.TEXT_DIM)
        if wageMult and wageMult ~= 1.0 then
            y = self:drawRow(y, "  Wage Modifier", pctLabel(wageMult, true))
        end
        if fatigueMit and fatigueMit ~= 1.0 then
            y = self:drawRow(y, "  Fatigue Mitigation", pctLabel(fatigueMit, true))
        end
        if fatigueRec and fatigueRec ~= 1.0 then
            y = self:drawRow(y, "  Fatigue Recovery", pctLabel(fatigueRec, false))
        end
        if globalEff and globalEff ~= 1.0 then
            y = self:drawRow(y, "  Global Effectiveness", pctLabel(globalEff, false))
        end
    end

    -- SoilFertilizer benefits
    local fertDisc = safeGet("getFertilizerDiscount", farmId)
    local fungDisc = safeGet("getFungicideDiscount", farmId)
    local fungEff = safeGet("getFungicideEffectivenessBonus", farmId)
    local sprayCost = safeGet("getSprayCostModifier", farmId)

    local hasSoilBenefits = (fertDisc and fertDisc ~= 1.0)
                         or (fungDisc and fungDisc ~= 1.0)
                         or (fungEff and fungEff ~= 1.0)
                         or (sprayCost and sprayCost ~= 1.0)

    if hasSoilBenefits then
        y = self:drawRow(y, "Soil & Crop Protection", "", nil, FT.C.TEXT_DIM)
        if fertDisc and fertDisc ~= 1.0 then
            y = self:drawRow(y, "  Fertilizer Discount", pctLabel(fertDisc, true))
        end
        if fungDisc and fungDisc ~= 1.0 then
            y = self:drawRow(y, "  Fungicide Discount", pctLabel(fungDisc, true))
        end
        if fungEff and fungEff ~= 1.0 then
            y = self:drawRow(y, "  Fungicide Effectiveness", pctLabel(fungEff, false))
        end
        if sprayCost and sprayCost ~= 1.0 then
            y = self:drawRow(y, "  Spray Cost", pctLabel(sprayCost, true))
        end
    end

    -- DairyCore / RLRM benefits
    local vetDisc = safeGet("getVetSupplyDiscount", farmId)
    local dairyLog = safeGet("getDairyLogisticsBonus", farmId)
    local bulkProc = safeGet("getBulkProcurementBonus", farmId)
    local bulkTrans = safeGet("getBulkTransportDiscount", farmId)

    local hasDairyBenefits = (vetDisc and vetDisc ~= 1.0)
                          or (dairyLog and dairyLog ~= 1.0)
                          or (bulkProc and bulkProc ~= 1.0)
                          or (bulkTrans and bulkTrans ~= 1.0)

    if hasDairyBenefits then
        y = self:drawRow(y, "Dairy & Logistics", "", nil, FT.C.TEXT_DIM)
        if vetDisc and vetDisc ~= 1.0 then
            y = self:drawRow(y, "  Vet Supply Discount", pctLabel(vetDisc, true))
        end
        if dairyLog and dairyLog ~= 1.0 then
            y = self:drawRow(y, "  Dairy Logistics", pctLabel(dairyLog, false))
        end
        if bulkProc and bulkProc ~= 1.0 then
            y = self:drawRow(y, "  Bulk Procurement", pctLabel(bulkProc, false))
        end
        if bulkTrans and bulkTrans ~= 1.0 then
            y = self:drawRow(y, "  Bulk Transport", pctLabel(bulkTrans, true))
        end
    end

    -- Feature flags
    local hasForecast = false
    local hasMarketIntel = false
    local hasPredictive = false
    local hasEarlyWarn = false
    pcall(function() hasForecast = psm:hasForecastAccess(farmId) end)
    pcall(function() hasMarketIntel = psm:hasMarketIntel(farmId) end)
    pcall(function() hasPredictive = psm:hasPredictiveControl(farmId) end)
    pcall(function() hasEarlyWarn = psm:hasEarlyWarning(farmId) end)

    local hasAnyFlag = hasForecast or hasMarketIntel or hasPredictive or hasEarlyWarn
    if hasAnyFlag then
        y = self:drawRow(y, "Feature Access", "", nil, FT.C.TEXT_DIM)
        if hasForecast then
            y = self:drawRow(y, "  Agronomy Reports", "Active", nil, FT.C.POSITIVE)
        end
        if hasMarketIntel then
            y = self:drawRow(y, "  Market Intel", "Active", nil, FT.C.POSITIVE)
        end
        if hasPredictive then
            y = self:drawRow(y, "  Predictive Control", "Active", nil, FT.C.POSITIVE)
        end
    end

    -- Check if there are NO active benefits at all
    if not hasWorkerBenefits and not hasSoilBenefits and not hasDairyBenefits and not hasAnyFlag then
        self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
            "No active benefits yet. Level up to unlock modifiers.",
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(16)
    end

    -- ── COMING SOON ────────────────────────────────────────
    y = y - FT.py(4)
    y = self:drawRule(y, 0.3)
    y = self:drawSection(y, "COMING SOON")

    local comingSoon = {
        { name = "L9 Herdsman Wage Rebate", desc = "3% post-deduction rebate on herdsman wages (pending base-game confirmation)" },
        { name = "L20 Early Warning", desc = "Market event probability signals (pending MarketDynamics getEligibleEvents)" },
    }
    for _, item in ipairs(comingSoon) do
        if y <= minY + FT.py(16) then break end
        self.r:appText(x, y, FT.FONT.SMALL, item.name, RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x + cw, y, FT.FONT.TINY, "NOT YET", RenderText.ALIGN_RIGHT, FT.C.WARNING)
        y = y - FT.py(12)
        self.r:appText(x + FT.px(8), y, FT.FONT.TINY, item.desc, RenderText.ALIGN_LEFT, FT.C.MUTED)
        y = y - FT.py(14)
    end

    -- ── NEXT LEVEL PREVIEW ─────────────────────────────────
    if level < maxLevel then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.3)
        local nextName = (ProStaffConstants and ProStaffConstants.LEVEL_NAMES and ProStaffConstants.LEVEL_NAMES[level + 1])
                      or "Unknown"
        y = self:drawSection(y, "NEXT: L" .. (level + 1) .. " " .. string.upper(nextName))

        -- Describe what the next level unlocks based on the level table
        local nextUnlockDesc = nil
        local NEXT_LEVEL_EFFECTS = {
            [1] = "5% hiring discount (WorkerCosts)",
            [2] = "1.5% fertilizer discount + 5% fungicide + 5% vet supply discount",
            [3] = "+5% worker efficiency + dairy collection bonus",
            [4] = "Fatigue mitigation tier 1",
            [5] = "2.5% wage reduction",
            [6] = "+7% load/unload speed + tanker efficiency",
            [7] = "4% fertilizer discount + Co-Op Agronomy Reports",
            [8] = "Fatigue mitigation tier 2",
            [9] = "5% wage reduction + NPC loyalty lock + herdsman rebate",
            [10] = "Skilled Staff tier unlock",
            [11] = "Fatigue recovery 1.75x",
            [12] = "6% fertilizer + Precision Spray + 10% fungicide effectiveness + 10% vet discount",
            [13] = "Fatigue mitigation tier 3 + Co-Op Spray Cooperative (-8%)",
            [14] = "7.5% bulk transport discount + Co-Op fleet rebate",
            [15] = "7.5% fertilizer discount + Market Intel + Syndicate Dairy Contract",
            [16] = "Legendary tier + NPC field scouting + Legendary dairy routes",
            [17] = "10% wage reduction",
            [18] = "Fatigue recovery 1.85x global + 3-day disease forecast",
            [19] = "+5% global effectiveness",
            [20] = "+15% global effectiveness + Market early warning",
        }
        nextUnlockDesc = NEXT_LEVEL_EFFECTS[level + 1]

        if nextUnlockDesc then
            self.r:appText(x + FT.px(8), y - FT.py(8), FT.FONT.SMALL,
                nextUnlockDesc, RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            y = y - FT.py(22)
        end

        if nextCost then
            y = self:drawRow(y, "Cost",
                (g_i18n and g_i18n:formatMoney(nextCost, 0, true, true))
                or ("$" .. nextCost))
        end
    end

    self:setContentHeight(startY - y + scrollY + FT.py(28))
    self:drawInfoIcon("_prostaffHelp", ACENT)
    self:drawScrollBar()
end)
