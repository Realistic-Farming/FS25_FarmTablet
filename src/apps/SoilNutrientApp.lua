-- =========================================================
-- FarmTablet - Soil Fertilizer field-card redesign (FT #101)
-- =========================================================
-- One scrollable card per owned field: current vs expected bars
-- (N/P/K/pH/OM/Weed/Pest/Disease) + TREATMENT prescriptions.
-- Mirrors SoilTreatmentDialog rate/action rules (local copy —
-- those helpers are file-local in SF and not exportable yet).
-- English body strings; title via ft_ui_app_soil_fertilizer.
-- =========================================================

local PRESSURE_ACTION_THRESH = 20
local OM_TARGET = 4.0
local OM_MAX = 10.0

local function _soilConstants()
    return SoilConstants or getfenv(0)["SoilConstants"]
end

local function _manager()
    return (g_currentMission and g_currentMission.soilFertilityManager)
        or getfenv(0)["g_SoilFertilityManager"]
end

local function _pcall(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function _statusColor(status)
    if status == "Good" then return FT.C.POSITIVE end
    if status == "Fair" then return FT.C.WARNING end
    return FT.C.NEGATIVE
end

local function _barColor(ratio, invert)
    -- invert=true for pressures (high is bad)
    local r = tonumber(ratio) or 0
    if invert then
        if r >= 0.20 then return FT.C.NEGATIVE end
        if r >= 0.10 then return FT.C.WARNING end
        return FT.C.POSITIVE
    end
    if r >= 0.85 then return FT.C.POSITIVE end
    if r >= 0.55 then return FT.C.WARNING end
    return FT.C.NEGATIVE
end

local function _urgencyColor(u)
    u = tonumber(u) or 0
    if u >= 0.55 then return FT.C.NEGATIVE end
    if u >= 0.30 then return FT.C.WARNING end
    return FT.C.POSITIVE
end

local function _urgencyLabel(u)
    u = tonumber(u) or 0
    if u >= 0.55 then return "URGENT" end
    if u >= 0.30 then return "WATCH" end
    return "OK"
end

--- "PRODUCT 220 kg/ha (1056 kg)" — mirrors SoilTreatmentDialog._rateString
local function _rateString(SC, profileKey, nutrientKey, deficit, rrMult, fieldArea)
    if deficit <= 0 or SC == nil then return nil end
    local profiles = SC.FERTILIZER_PROFILES
    local baseRates = SC.SPRAYER_RATE and SC.SPRAYER_RATE.BASE_RATES
    local profile = profiles and profiles[profileKey]
    local baseRate = baseRates and baseRates[profileKey]
    if not profile or not profile[nutrientKey] or profile[nutrientKey] == 0 then return nil end

    local coeff = profile[nutrientKey]
    local ratePerHa = deficit * 1000 / (coeff * rrMult)
    local total = ratePerHa * fieldArea
    local isDry = baseRate and baseRate.unit == "dry"
    local mgr = _manager()
    local useImp = mgr and mgr.settings and mgr.settings.useImperialUnits

    local displayRate, displayTotal, unit, totalUnit
    if useImp and SC.SPRAYER_RATE then
        if isDry then
            displayRate = math.ceil(ratePerHa * (SC.SPRAYER_RATE.KG_PER_HA_TO_LB_PER_AC or 0.892))
            displayTotal = math.ceil(total * 2.20462)
            unit, totalUnit = "lb/ac", "lb"
        else
            displayRate = math.ceil(ratePerHa * (SC.SPRAYER_RATE.L_PER_HA_TO_GAL_PER_AC or 0.107))
            displayTotal = math.ceil(total * 0.26417)
            unit, totalUnit = "gal/ac", "gal"
        end
    else
        displayRate = math.ceil(ratePerHa)
        displayTotal = math.ceil(total)
        unit, totalUnit = isDry and "kg/ha" or "L/ha", isDry and "kg" or "L"
    end

    return string.format("%s %d %s (%d %s)", profileKey, displayRate, unit, displayTotal, totalUnit)
end

local function _nutrientActionText(SC, currentVal, targetVal, rrMult, fieldArea, products, staticFallback)
    local deficit = math.max(0, targetVal - currentVal)
    local parts = {}
    for _, prod in ipairs(products) do
        local s = _rateString(SC, prod[1], prod[2], deficit, rrMult, fieldArea)
        if s then parts[#parts + 1] = s end
    end
    if #parts == 0 then return staticFallback end
    return table.concat(parts, "  ·  ")
end

--- Build TREATMENT rows mirroring SoilTreatmentDialog:_populateData.
--- Disease uses discovery-gated shownDiseasePressure (nil = Unscouted).
local function _buildTreatments(info, SC, settings)
    local rows = {}
    if info == nil or SC == nil then
        return { { label = "—", text = "no data", color = FT.C.MUTED } }
    end

    local thresh = SC.STATUS_THRESHOLDS or {}
    local nT = thresh.nitrogen or { poor = 30, fair = 50 }
    local pT = thresh.phosphorus or { poor = 25, fair = 40 }
    local kT = thresh.potassium or { poor = 20, fair = 40 }
    local fieldArea = info.fieldArea or 1.0
    local rrIdx = (settings and settings.replenishmentRate) or 3
    local rrMult = 1.0
    if SC.DIFFICULTY and SC.DIFFICULTY.REPLENISHMENT_MULTIPLIERS then
        rrMult = SC.DIFFICULTY.REPLENISHMENT_MULTIPLIERS[rrIdx] or 1.0
    end
    local ct = info.cropTargets
    local targetN = (ct and ct.N and ct.N.opt) or (nT.fair or 50)
    local targetP = (ct and ct.P and ct.P.opt) or (pT.fair or 40)
    local targetK = (ct and ct.K and ct.K.opt) or (kT.fair or 40)

    local ph = math.floor(((info.pH or 7.0) * 10) + 0.5) / 10
    if ph < 6.5 then
        rows[#rows + 1] = { label = "pH", text = "Apply LIME or LIQUID LIME to raise pH.", color = FT.C.NEGATIVE }
    elseif ph > 7.5 then
        rows[#rows + 1] = { label = "pH", text = "Apply GYPSUM to lower pH / improve structure.", color = FT.C.WARNING }
    else
        rows[#rows + 1] = { label = "pH", text = "OK", color = FT.C.POSITIVE }
    end

    local om = info.organicMatter or 3.5
    if om < 3.0 then
        rows[#rows + 1] = { label = "OM", text = "Plow in MANURE, COMPOST, or chop straw.", color = FT.C.NEGATIVE }
    elseif om < 4.0 then
        rows[#rows + 1] = { label = "OM", text = "Monitor. Maintain organic inputs.", color = FT.C.WARNING }
    else
        rows[#rows + 1] = { label = "OM", text = "OK", color = FT.C.POSITIVE }
    end

    local nVal = info.nitrogen and info.nitrogen.value or 0
    if nVal < (nT.poor or 30) then
        rows[#rows + 1] = {
            label = "N",
            text = _nutrientActionText(SC, nVal, targetN, rrMult, fieldArea,
                { { "UREA", "N" }, { "UAN32", "N" } }, "Apply UREA or UAN32"),
            color = FT.C.NEGATIVE,
        }
    elseif nVal < (nT.fair or 50) then
        rows[#rows + 1] = {
            label = "N",
            text = _nutrientActionText(SC, nVal, targetN, rrMult, fieldArea,
                { { "AMS", "N" }, { "AN", "N" } }, "Apply AMS or AN"),
            color = FT.C.WARNING,
        }
    else
        rows[#rows + 1] = { label = "N", text = "OK", color = FT.C.POSITIVE }
    end

    local pVal = info.phosphorus and info.phosphorus.value or 0
    if pVal < (pT.poor or 25) then
        rows[#rows + 1] = {
            label = "P",
            text = _nutrientActionText(SC, pVal, targetP, rrMult, fieldArea,
                { { "MAP", "P" }, { "DAP", "P" } }, "Apply MAP or DAP"),
            color = FT.C.NEGATIVE,
        }
    elseif pVal < (pT.fair or 40) then
        rows[#rows + 1] = {
            label = "P",
            text = _nutrientActionText(SC, pVal, targetP, rrMult, fieldArea,
                { { "LIQUID_MAP", "P" }, { "LIQUID_DAP", "P" } }, "Top-up with Liquid MAP or Liquid DAP"),
            color = FT.C.WARNING,
        }
    else
        rows[#rows + 1] = { label = "P", text = "OK", color = FT.C.POSITIVE }
    end

    local kVal = info.potassium and info.potassium.value or 0
    if kVal < (kT.poor or 20) then
        rows[#rows + 1] = {
            label = "K",
            text = _nutrientActionText(SC, kVal, targetK, rrMult, fieldArea,
                { { "POTASH", "K" }, { "LIQUID_POTASH", "K" } }, "Apply POTASH"),
            color = FT.C.NEGATIVE,
        }
    elseif kVal < (kT.fair or 40) then
        rows[#rows + 1] = {
            label = "K",
            text = _nutrientActionText(SC, kVal, targetK, rrMult, fieldArea,
                { { "POTASH", "K" }, { "LIQUID_POTASH", "K" } }, "Top-up with POTASH or Liquid POTASH"),
            color = FT.C.WARNING,
        }
    else
        rows[#rows + 1] = { label = "K", text = "OK", color = FT.C.POSITIVE }
    end

    if (info.weedPressure or 0) >= PRESSURE_ACTION_THRESH then
        rows[#rows + 1] = { label = "Weed", text = "Apply HERBICIDE or use mechanical WEEDER/HOE.", color = FT.C.NEGATIVE }
    else
        rows[#rows + 1] = { label = "Weed", text = "OK", color = FT.C.POSITIVE }
    end

    if (info.pestPressure or 0) >= PRESSURE_ACTION_THRESH then
        rows[#rows + 1] = { label = "Pest", text = "Apply INSECTICIDE immediately.", color = FT.C.NEGATIVE }
    else
        rows[#rows + 1] = { label = "Pest", text = "OK", color = FT.C.POSITIVE }
    end

    local shownD = info.shownDiseasePressure
    if shownD == nil then
        rows[#rows + 1] = { label = "Disease", text = "Unscouted", color = FT.C.MUTED }
    elseif shownD >= PRESSURE_ACTION_THRESH then
        rows[#rows + 1] = { label = "Disease", text = "Apply FUNGICIDE immediately.", color = FT.C.NEGATIVE }
    else
        rows[#rows + 1] = { label = "Disease", text = "OK", color = FT.C.POSITIVE }
    end

    return rows
end

local function _drawMetricBar(self, x, y, cw, label, valueText, ratio, color)
    self.r:appText(x + FT.px(8), y, FT.FONT.TINY, label, RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    self.r:appText(x + cw - FT.px(8), y, FT.FONT.TINY, valueText, RenderText.ALIGN_RIGHT, FT.C.TEXT_NORMAL)
    y = y - FT.py(11)
    local barW = cw - FT.px(16)
    self.r:progressBar(x + FT.px(8), y, barW, math.max(0, math.min(1, ratio or 0)), 1.0, color)
    return y - FT.py(10)
end

FarmTabletUI:registerDrawer(FT.APP.SOIL_FERT, function(self)
    local AC = FT.appColor(FT.APP.SOIL_FERT)

    if self:drawHelpPage("_soilHelp", FT.APP.SOIL_FERT, "Soil Fertilizer", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "One card per owned field: N / P / K / pH / OM /\n" ..
                  "Weed / Pest / Disease as current vs expected bars,\n" ..
                  "plus a TREATMENT plan with rates when a nutrient\n" ..
                  "or pressure needs work." },
        { title = "URGENCY ORDER",
          body  = "Cards are sorted by SoilFertilizer urgency so the\n" ..
                  "fields that need attention first rise to the top.\n" ..
                  "Left tick: green OK · yellow WATCH · red URGENT." },
        { title = "TREATMENT",
          body  = "Prescriptions mirror the Shift+T Soil Treatment\n" ..
                  "dialog (product rates + protection actions).\n" ..
                  "Disease stays Unscouted until you scout the field." },
        { title = "NUTRIENT COLOURS",
          body  = "Green = on target  |  Yellow = fair  |  Red = poor.\n" ..
                  "Bars show current / expected (ppm for N/P/K)." },
        { title = "pH + ORGANIC MATTER",
          body  = "Optimal pH is 6.5 (band ~6.0–7.5).\n" ..
                  "OM is a 0–10 soil scale (not a percent).\n" ..
                  "Healthy band sits around 3.5–5.0." },
    }) then return end

    local startY = self:drawAppHeader("Soil Fertilizer", "")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    local mgr = _manager()
    if not mgr then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Soil Fertilizer mod not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_SoilFertilizer to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_soilHelp", AC)
        return
    end

    local soilSys = mgr.soilSystem
    local settings = mgr.settings
    if not soilSys or not soilSys.isInitialized then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Soil system is initializing...", RenderText.ALIGN_LEFT, FT.C.WARNING)
        self:drawInfoIcon("_soilHelp", AC)
        return
    end

    if settings then
        local en = settings.enabled ~= false
        self.r:appRect(x - FT.px(4), y - FT.py(22), cw + FT.px(8), FT.py(20),
            { AC[1] * 0.10, AC[2] * 0.10, AC[3] * 0.10, 0.95 })
        self.r:appText(x, y - FT.py(18), FT.FONT.SMALL,
            en and "Active" or "DISABLED", RenderText.ALIGN_LEFT, en and FT.C.POSITIVE or FT.C.WARNING)
        if soilSys.PFActive then
            self.r:appText(x + cw, y - FT.py(18), FT.FONT.TINY,
                "PF DLC active", RenderText.ALIGN_RIGHT, FT.C.INFO)
        end
        y = y - FT.py(26)
    end

    local farmId = self.system.data:getPlayerFarmId()
    local ownedFields = self.system.data:getOwnedFields(farmId) or {}
    if #ownedFields == 0 then
        self.r:appText(x, y - FT.py(10), FT.FONT.BODY,
            "No owned fields found.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_soilHelp", AC)
        return
    end

    local SC = _soilConstants()
    local ppm = (SC and SC.PPM_DISPLAY) or { N = 1, P = 1, K = 1 }
    local phOpt = (SC and SC.PH_OPTIMAL) or 6.5

    -- Cache + urgency sort once per open (FieldJobs / Rotation pattern).
    local cache = self.system._soilCardCache
    local idParts = {}
    for _, f in ipairs(ownedFields) do
        idParts[#idParts + 1] = tostring(f.id)
    end
    table.sort(idParts)
    -- Refresh periodically so nutrient/treatment values stay live while open.
    local now = (g_time and g_time) or 0
    local cacheKey = tostring(farmId) .. "|" .. table.concat(idParts, ",")
    local stale = cache == nil or cache.key ~= cacheKey
        or (cache.at ~= nil and (now - cache.at) > 2000)
    if stale then
        local cards = {}
        for _, f in ipairs(ownedFields) do
            local info = _pcall(function() return soilSys:getFieldInfo(f.id) end)
            local urgency = 0
            if type(soilSys.getFieldUrgency) == "function" then
                urgency = _pcall(function() return soilSys:getFieldUrgency(f.id) end) or 0
            end
            cards[#cards + 1] = {
                id = f.id,
                area = f.area or (info and info.fieldArea) or 0,
                crop = (info and info.lastCrop) or f.cropName or "Empty",
                info = info,
                urgency = tonumber(urgency) or 0,
            }
        end
        table.sort(cards, function(a, b)
            if a.urgency == b.urgency then return a.id < b.id end
            return a.urgency > b.urgency
        end)
        cache = { key = cacheKey, at = now, cards = cards }
        self.system._soilCardCache = cache
    end

    y = self:drawSection(y, string.format("FIELDS  (%d)", #cache.cards))

    for _, card in ipairs(cache.cards) do
        local info = card.info
        local uCol = _urgencyColor(card.urgency)
        local cardTop = y
        local pad = FT.px(6)
        local innerX = x + pad
        local innerW = cw - pad * 2

        -- Estimate height for background (header + 8 bars + treatment block).
        local estH = FT.py(300)
        self.r:appRect(x - FT.px(2), y - estH + FT.py(4), cw + FT.px(4), estH, FT.C.BG_CARD)
        self.r:appRect(x - FT.px(2), y - estH + FT.py(4), FT.px(3), estH, uCol)

        -- Header
        self.r:appText(innerX, y - FT.py(2), FT.FONT.SMALL,
            string.format("Field #%s  ·  %s", tostring(card.id), tostring(card.crop)),
            RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
        local haTxt = (card.area and card.area > 0) and string.format("%.1f ha", card.area) or ""
        self.r:appText(x + cw - FT.px(4), y - FT.py(2), FT.FONT.TINY,
            haTxt, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
        y = y - FT.py(14)
        local badgeW = self.r:badge(innerX, y, _urgencyLabel(card.urgency), uCol)
        if info and info.needsFertilization then
            self.r:badge(innerX + badgeW + FT.px(4), y, "FERT", FT.C.WARNING)
        end
        y = y - FT.py(16)

        if info == nil then
            self.r:appText(innerX, y, FT.FONT.SMALL, "No soil data for this field.",
                RenderText.ALIGN_LEFT, FT.C.MUTED)
            y = y - FT.py(18)
        else
            local ct = info.cropTargets
            local thresh = (SC and SC.STATUS_THRESHOLDS) or {}
            local tN = (ct and ct.N and ct.N.opt) or ((thresh.nitrogen and thresh.nitrogen.fair) or 50)
            local tP = (ct and ct.P and ct.P.opt) or ((thresh.phosphorus and thresh.phosphorus.fair) or 40)
            local tK = (ct and ct.K and ct.K.opt) or ((thresh.potassium and thresh.potassium.fair) or 40)

            local function ppmVal(v, factor)
                return math.floor((tonumber(v) or 0) * (factor or 1) + 0.5)
            end

            local nVal = info.nitrogen and info.nitrogen.value or 0
            local pVal = info.phosphorus and info.phosphorus.value or 0
            local kVal = info.potassium and info.potassium.value or 0
            y = _drawMetricBar(self, innerX, y, innerW, "N",
                string.format("%d / %d ppm", ppmVal(nVal, ppm.N), ppmVal(tN, ppm.N)),
                nVal / math.max(tN, 1), _statusColor(info.nitrogen and info.nitrogen.status))
            y = _drawMetricBar(self, innerX, y, innerW, "P",
                string.format("%d / %d ppm", ppmVal(pVal, ppm.P), ppmVal(tP, ppm.P)),
                pVal / math.max(tP, 1), _statusColor(info.phosphorus and info.phosphorus.status))
            y = _drawMetricBar(self, innerX, y, innerW, "K",
                string.format("%d / %d ppm", ppmVal(kVal, ppm.K), ppmVal(tK, ppm.K)),
                kVal / math.max(tK, 1), _statusColor(info.potassium and info.potassium.status))

            local ph = info.pH or 7.0
            local phRatio = 1.0 - math.min(1.0, math.abs(ph - phOpt) / 2.0)
            local phCol = (ph >= 6.0 and ph <= 7.5) and FT.C.POSITIVE or FT.C.WARNING
            y = _drawMetricBar(self, innerX, y, innerW, "pH",
                string.format("%.1f / %.1f", ph, phOpt), phRatio, phCol)

            local om = info.organicMatter or 0
            local omCol = (om >= 3.5) and FT.C.POSITIVE or ((om >= 3.0) and FT.C.WARNING or FT.C.NEGATIVE)
            y = _drawMetricBar(self, innerX, y, innerW, "OM",
                string.format("%.1f / %.1f", om, OM_TARGET), om / OM_MAX, omCol)

            local weed = info.weedPressure or 0
            y = _drawMetricBar(self, innerX, y, innerW, "Weed",
                string.format("%.0f / <%d", weed, PRESSURE_ACTION_THRESH),
                weed / 100, _barColor(weed / 100, true))

            local pest = info.pestPressure or 0
            y = _drawMetricBar(self, innerX, y, innerW, "Pest",
                string.format("%.0f / <%d", pest, PRESSURE_ACTION_THRESH),
                pest / 100, _barColor(pest / 100, true))

            local shownD = info.shownDiseasePressure
            if shownD == nil then
                y = _drawMetricBar(self, innerX, y, innerW, "Disease",
                    "Unscouted", 0, FT.C.MUTED)
            else
                y = _drawMetricBar(self, innerX, y, innerW, "Disease",
                    string.format("%.0f / <%d", shownD, PRESSURE_ACTION_THRESH),
                    shownD / 100, _barColor(shownD / 100, true))
            end

            self.r:appText(innerX, y, FT.FONT.TINY, "TREATMENT", RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
            y = y - FT.py(12)
            local treats = _buildTreatments(info, SC, settings)
            for _, row in ipairs(treats) do
                self.r:appText(innerX, y, FT.FONT.TINY, row.label, RenderText.ALIGN_LEFT, row.color or FT.C.TEXT_DIM)
                local txt = tostring(row.text or "")
                if #txt > 42 then txt = txt:sub(1, 40) .. "…" end
                self.r:appText(innerX + FT.px(44), y, FT.FONT.TINY, txt,
                    RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
                y = y - FT.py(11)
            end
        end

        -- Tighten leftover estimated card padding.
        local used = cardTop - y
        if used < estH - FT.py(8) then
            -- leave the oversized BG; spacing below card
        end
        y = y - FT.py(10)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_soilHelp", AC)
    self:drawScrollBar()
end)
