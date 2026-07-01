-- =========================================================
-- FarmTablet v2 – Animal Husbandry App
-- =========================================================

FarmTabletUI:registerDrawer(FT.APP.ANIMALS, function(self)
    local AC = FT.appColor(FT.APP.ANIMALS)

    if self:drawHelpPage("_animalsHelp", FT.APP.ANIMALS, FT.l10n("ft_ui_app_animals", "Animals"), AC, {
        { title = FT.l10n("ft_animals_help_pen_cards_title", "PEN CARDS"),
          body  = FT.l10n("ft_animals_help_pen_cards_body", "Each card shows the animal type, current count, and the\npen capacity (e.g. Cows  (12 / 20)).\nEmpty pens are shown dimmed.") },
        { title = FT.l10n("ft_animals_help_food_title", "FOOD BAR"),
          body  = FT.l10n("ft_animals_help_food_body", "Percentage of the food trough that is filled.\nGreen >= 60%  |  Yellow >= 25%  |  Red < 25%.\nRefill before hitting red to maintain productivity.") },
        { title = FT.l10n("ft_animals_help_water_title", "WATER BAR"),
          body  = FT.l10n("ft_animals_help_water_body", "Percentage of the water trough that is filled.\nSame colour thresholds as food.\nAnimals without water lose productivity quickly.") },
        { title = FT.l10n("ft_animals_help_straw_title", "STRAW / CLEANLINESS BAR"),
          body  = FT.l10n("ft_animals_help_straw_body", "How clean the pen is — straw level for pigs and cows,\ncleanliness percentage for chickens and sheep.\nLow cleanliness reduces output and animal happiness.") },
        { title = FT.l10n("ft_animals_help_productivity_title", "PRODUCTIVITY"),
          body  = FT.l10n("ft_animals_help_productivity_body", "Overall animal productivity is driven by food, water,\nand cleanliness together. Keeping all three bars green\nmaximises milk, eggs, wool, and manure output.") },
    }) then return end

    local data   = self.system.data
    local farmId = data:getPlayerFarmId()
    local pens   = data:getAnimalPens(farmId)

    local startY = self:drawAppHeader(FT.l10n("ft_ui_app_animals", "Animals"), FT.l10nFormat(#pens == 1 and "ft_count_pen" or "ft_count_pens", "%d pens", #pens))
    local x, contentY, cw, contentH = self:contentInner()

    if #pens == 0 then
        self.r:appText(x, startY - FT.py(12), FT.FONT.BODY,
            FT.l10n("ft_animals_no_pens", "No animal pens owned."), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, startY - FT.py(30), FT.FONT.SMALL,
            FT.l10n("ft_animals_purchase_pen", "Purchase a pen to start raising animals."), RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_animalsHelp", AC)
        return
    end

    local scrollY = self:getContentScrollY()
    local y    = startY + scrollY
    local minY = contentY + FT.py(8)

    local function barColor(pct)
        if pct >= 60 then return FT.C.POSITIVE
        elseif pct >= 25 then return FT.C.WARNING
        else return FT.C.NEGATIVE end
    end

    for _, pen in ipairs(pens) do
        local cardH = FT.py(10)
            + (pen.hasFood        and pen.foodPct  ~= nil and FT.py(24) or 0)
            + (pen.hasWater       and pen.waterPct ~= nil and FT.py(24) or 0)
            + (pen.hasCleanliness and pen.cleanPct ~= nil and FT.py(24) or 0)
            + FT.py(18)
        cardH = math.max(cardH, FT.py(30))

        self.r:appRect(x - FT.px(4), y - cardH, cw + FT.px(8), cardH, FT.C.BG_CARD)

        local header = pen.typeName
        if pen.numAnimals > 0 then
            header = header .. "  (" .. pen.numAnimals .. " / " .. pen.maxAnimals .. ")"
        else
            header = header .. "  (" .. FT.l10n("ft_common_empty_lower", "empty") .. ")"
        end
        y = y - FT.py(4)
        self.r:appText(x + FT.px(8), y, FT.FONT.BODY, header, RenderText.ALIGN_LEFT,
            pen.numAnimals > 0 and FT.C.TEXT_BRIGHT or FT.C.TEXT_DIM)
        y = y - FT.py(18)

        if pen.hasFood and pen.foodPct ~= nil then
            local pct = math.max(0, math.min(100, pen.foodPct))
            self.r:appText(x + FT.px(8), y, FT.FONT.TINY,
                FT.l10nFormat("ft_animals_food_pct", "FOOD  %d%%", pct), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(10)
            y = self.r:progressBar(x + FT.px(4), y, cw - FT.px(8), pct, 100, barColor(pct))
        end
        if pen.hasWater and pen.waterPct ~= nil then
            local pct = math.max(0, math.min(100, pen.waterPct))
            self.r:appText(x + FT.px(8), y, FT.FONT.TINY,
                FT.l10nFormat("ft_animals_water_pct", "WATER  %d%%", pct), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(10)
            y = self.r:progressBar(x + FT.px(4), y, cw - FT.px(8), pct, 100, barColor(pct))
        end
        if pen.hasCleanliness and pen.cleanPct ~= nil then
            local pct = math.max(0, math.min(100, pen.cleanPct))
            self.r:appText(x + FT.px(8), y, FT.FONT.TINY,
                FT.l10nFormat("ft_animals_straw_clean_pct", "STRAW/CLEAN  %d%%", pct), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(10)
            y = self.r:progressBar(x + FT.px(4), y, cw - FT.px(8), pct, 100, barColor(pct))
        end
        y = y - FT.py(6)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_animalsHelp", AC)
    self:drawScrollBar()
    end)