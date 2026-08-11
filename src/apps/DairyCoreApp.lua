-- =========================================================
-- FarmTablet v2 – DairyCore App
-- Companion integration for FS25_DairyCore
-- Detects g_currentMission.dairyCoreManager (with getfenv fallback)
-- Shows barn health, milk quality, spoilage, contracts.
-- =========================================================

FarmTabletUI:registerDrawer(FT.APP.DAIRY_CORE, function(self)
    local AC = FT.appColor(FT.APP.DAIRY_CORE)

    if self:drawHelpPage("_dairyCoreHelp", FT.APP.DAIRY_CORE, "Dairy Core", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Integrates with FS25_DairyCore to display\n" ..
                  "barn health, milk quality, spoilage rates,\n" ..
                  "and active dairy contracts at a glance." },
        { title = "BARN HEALTH",
          body  = "Overall health score for each dairy barn.\n" ..
                  "Green >= 80  |  Yellow >= 50  |  Red < 50.\n" ..
                  "Low health reduces milk quality and yield." },
        { title = "MILK QUALITY",
          body  = "Current milk quality percentage per barn.\n" ..
                  "Higher quality commands better contract prices.\n" ..
                  "Maintain clean barns and healthy cows to improve." },
        { title = "SPOILAGE",
          body  = "Shows how quickly milk spoils per barn.\n" ..
                  "Higher spoilage means more product is lost\n" ..
                  "before it can be sold or delivered." },
        { title = "CONTRACTS",
          body  = "Lists active dairy contracts with buyer,\n" ..
                  "volume, price per litre, and time remaining.\n" ..
                  "Fulfil contracts to earn reputation and income." },
    }) then return end

    local startY = self:drawAppHeader("Dairy Core", "Integration")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y    = startY + scrollY
    local minY = contentY + FT.py(8)

    local mgr = (g_currentMission and g_currentMission.dairyCoreManager)
             or getfenv(0)["g_dairyCoreManager"]

    if not mgr then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "DairyCore is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_DairyCore to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_dairyCoreHelp", AC)
        return
    end

    -- ── Settings banner ──────────────────────────────────────
    local settings = mgr.settings
    if settings and settings.enabled ~= nil then
        local en = settings.enabled
        self.r:appRect(x - FT.px(4), y - FT.py(22), cw + FT.px(8), FT.py(20),
            {AC[1]*0.10, AC[2]*0.10, AC[3]*0.10, 0.95})
        self.r:appText(x, y - FT.py(18), FT.FONT.SMALL,
            en and "Active" or "DISABLED",
            RenderText.ALIGN_LEFT, en and FT.C.POSITIVE or FT.C.WARNING)
        y = y - FT.py(36)
    end

    -- ── BARN HEALTH ──────────────────────────────────────────
    local barns = mgr.barns or mgr.dairyBarns or {}

    if #barns == 0 then
        self.r:appText(x, y - FT.py(10), FT.FONT.BODY,
            "No dairy barns detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(26), FT.FONT.SMALL,
            "Build a dairy barn to start producing milk.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_dairyCoreHelp", AC)
        self:setContentHeight(startY - y + scrollY + FT.py(28))
        self:drawScrollBar()
        return
    end

    y = self:drawSection(y, "BARNS  (" .. #barns .. ")")

    for _, barn in ipairs(barns) do
        if y <= minY + FT.py(16) then break end

        local health    = math.floor(barn.health or barn.overallHealth or 100)
        local milkQual  = math.floor(barn.milkQuality or barn.quality or 100)
        local spoilage  = math.floor(barn.spoilage or barn.spoilageRate or 0)

        local hColor = health >= 80 and FT.C.POSITIVE
                    or health >= 50 and FT.C.WARNING
                    or FT.C.NEGATIVE

        local qColor = milkQual >= 80 and FT.C.POSITIVE
                    or milkQual >= 50 and FT.C.WARNING
                    or FT.C.TEXT_DIM

        local sColor = spoilage <= 5 and FT.C.POSITIVE
                    or spoilage <= 15 and FT.C.WARNING
                    or FT.C.NEGATIVE

        local name = barn.name or barn.barnName or ("Barn " .. tostring(_))
        if #name > 22 then name = name:sub(1, 20) .. ">" end

        -- Barn header row
        self.r:appText(x, y, FT.FONT.BODY, name, RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
        self.r:appText(x + cw, y, FT.FONT.BODY,
            string.format("HP: %d", health), RenderText.ALIGN_RIGHT, hColor)
        y = y - FT.py(FT.SP.ROW)

        -- Health bar
        y = y + FT.py(FT.SP.ROW) - FT.py(8)
        self.r:progressBar(x, y, cw, health, 100, hColor)
        y = y - FT.py(10)

        -- Quality and spoilage detail row
        self.r:appText(x, y, FT.FONT.SMALL,
            string.format("Quality: %d%%", milkQual), RenderText.ALIGN_LEFT, qColor)
        self.r:appText(x + cw, y, FT.FONT.SMALL,
            string.format("Spoilage: %d%%", spoilage), RenderText.ALIGN_RIGHT, sColor)
        y = y - FT.py(14)

        y = y - FT.py(4)
    end

    -- ── ACTIVE CONTRACTS ─────────────────────────────────────
    local contracts = mgr.contracts or mgr.activeContracts or {}
    local activeContracts = {}
    for _, c in ipairs(contracts) do
        if c and c.active ~= false then table.insert(activeContracts, c) end
    end

    if #activeContracts > 0 then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.3)
        y = self:drawSection(y, "CONTRACTS  (" .. #activeContracts .. ")")

        for _, contract in ipairs(activeContracts) do
            if y <= minY + FT.py(16) then break end

            local buyer  = contract.buyer or contract.buyerName or "Unknown"
            local volume = contract.volume or contract.targetVolume or 0
            local price  = contract.price or contract.pricePerLitre or 0
            local timeLeft = contract.timeRemaining or contract.hoursLeft or 0

            local buyerLabel = tostring(buyer)
            if #buyerLabel > 18 then buyerLabel = buyerLabel:sub(1, 16) .. ">" end

            self.r:appText(x, y, FT.FONT.SMALL, buyerLabel,
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + cw, y, FT.FONT.SMALL,
                string.format("%dL @ %s", volume,
                    (g_i18n and g_i18n:formatMoney(price, 0, true, true)) or tostring(price)),
                RenderText.ALIGN_RIGHT, FT.C.POSITIVE)
            y = y - FT.py(13)

            local hoursLeft = math.floor(timeLeft / 3600000)
            self.r:appText(x, y, FT.FONT.TINY,
                string.format("%d hours remaining", hoursLeft),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(11)

            y = y - FT.py(4)
        end
    else
        y = y - FT.py(4)
        y = self:drawRule(y, 0.3)
        y = self:drawSection(y, "CONTRACTS")
        self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
            "No active dairy contracts.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(16)
    end

    self:setContentHeight(startY - y + scrollY + FT.py(28))
    self:drawInfoIcon("_dairyCoreHelp", AC)
    self:drawScrollBar()
end)
