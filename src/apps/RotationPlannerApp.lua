-- =========================================================
-- FarmTablet - Crop Rotation Planner (Wizard UI brief #739)
-- =========================================================
-- Read-only farm-wide rotation standing + per-field candidate compare.
-- Detects SF via g_currentMission.soilFertilityManager.
-- Same engine as SoilFieldDetailDialog foresight (projectRotation).
-- =========================================================

local STATUS_COLOR = {
    bonus    = FT.C.POSITIVE,
    ok       = FT.C.TEXT_DIM,
    fatigue  = FT.C.WARNING,
    unknown  = FT.C.MUTED,
}

local function _rp()
    -- Prefer SF shared helper when the Soil mod has loaded it; else thin local mirror.
    if RotationPlannerData ~= nil then return RotationPlannerData end
    return nil
end

local function _soilMgr()
    return (g_currentMission and g_currentMission.soilFertilityManager)
        or getfenv(0)["g_SoilFertilityManager"]
end

-- Local fallback if RotationPlannerData is not visible across mod sandboxes.
local LEGUME  = { "soybean", "peas", "clover", "alfalfa" }
local NEUTRAL = { "wheat", "barley", "maize", "canola" }

local function pickCandidates(currentCrop, soil)
    local RP = _rp()
    if RP ~= nil and RP.pickCandidates ~= nil then
        return RP.pickCandidates(currentCrop, soil)
    end
    -- Prefer blessed pool on the soil system when SF shared helper is not visible.
    local legumes, neutrals = LEGUME, NEUTRAL
    if soil ~= nil and type(soil.getRotationCandidatePool) == "function" then
        local ok, pool = pcall(function() return soil:getRotationCandidatePool() end)
        if ok and type(pool) == "table" and type(pool.LEGUME) == "table" and type(pool.NEUTRAL) == "table" then
            legumes, neutrals = pool.LEGUME, pool.NEUTRAL
        end
    end
    local cur = currentCrop and string.lower(currentCrop) or ""
    local legume, neutral
    for _, c in ipairs(legumes) do if c ~= cur then legume = c break end end
    for _, c in ipairs(neutrals) do if c ~= cur and c ~= legume then neutral = c break end end
    return { (cur ~= "" and cur or nil), legume, neutral }
end

local function cropLabel(name)
    local RP = _rp()
    if RP ~= nil and RP.cropLabel ~= nil then return RP.cropLabel(name) end
    if name == nil or name == "" then return "-" end
    return name
end

local function standingLine(info)
    local RP = _rp()
    if RP ~= nil and RP.standingLine ~= nil then return RP.standingLine(info) end
    if info == nil or info.lastCrop == nil or info.lastCrop == "" then
        return "Unknown · No crop history yet", "unknown"
    end
    local st = info.rotationStatus or "OK"
    local kind = (st == "Bonus" and "bonus") or (st == "Fatigue" and "fatigue")
        or (st == "OK" and "ok") or "unknown"
    return tostring(st) .. " · " .. cropLabel(info.lastCrop) .. " / " .. cropLabel(info.lastCrop2), kind
end

local function effectText(proj)
    local RP = _rp()
    if RP ~= nil and RP.effectText ~= nil then return RP.effectText(proj) end
    if proj == nil or proj.status == nil then return "no change" end
    return tostring(proj.status)
end

local function statusWord(status)
    local RP = _rp()
    if RP ~= nil and RP.statusWord ~= nil then return RP.statusWord(status) end
    return tostring(status or "Unknown"), "unknown"
end

FarmTabletUI:registerDrawer(FT.APP.ROTATION_PLANNER, function(self)
    local AC = FT.appColor(FT.APP.ROTATION_PLANNER)

    if self:drawHelpPage("_rotationPlannerHelp", FT.APP.ROTATION_PLANNER, "Rotation Planner", AC, {
        { title = "WHAT THIS IS",
          body  = "Farm-wide crop rotation standing and a what-if compare\n" ..
                  "for the next crop on any field. Numbers come from Soil\n" ..
                  "Fertilizer's own rotation scoring, not a second model." },
        { title = "WHERE DO I STAND",
          body  = "Each owned field shows recent crops and whether the\n" ..
                  "ground is Bonus-primed, OK, or Fatigue. Kinds, not grades." },
        { title = "WHAT IF",
          body  = "Select a field, then read the same curated candidates\n" ..
                  "the soil field-detail dialog uses (same crop, a legume,\n" ..
                  "a neutral cereal) with the sim's own consequence words." },
        { title = "HONEST DEGRADE",
          body  = "Until the soil data surface publishes a third season and\n" ..
                  "bonus countdown, this app shows two seasons and no timer.\n" ..
                  "A field with no history reads Unknown, never invented." },
    }) then return end

    local startY = self:drawAppHeader("Rotation Planner", "")
    local x, cyBottom, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    local mgr = _soilMgr()
    if mgr == nil or mgr.soilSystem == nil then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Soil Fertilizer not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_SoilFertilizer. This app stays hidden when absent.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_rotationPlannerHelp", AC)
        return
    end

    local soil = mgr.soilSystem
    if not soil.isInitialized then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Soil system is initializing...", RenderText.ALIGN_LEFT, FT.C.WARNING)
        self:drawInfoIcon("_rotationPlannerHelp", AC)
        return
    end

    local farmId = self.system.data:getPlayerFarmId()
    local fields = self.system.data:getOwnedFields(farmId) or {}

    -- Per-open cache of getFieldInfo
    local cache = { soil = soil, byId = {} }
    local RP = _rp()
    if RP ~= nil and RP.cacheForFields ~= nil then
        local ids = {}
        for _, f in ipairs(fields) do ids[#ids + 1] = f.id end
        cache = RP.cacheForFields(ids)
    else
        for _, f in ipairs(fields) do
            local ok, info = pcall(function() return soil:getFieldInfo(f.id) end)
            if ok then cache.byId[f.id] = info end
        end
    end

    local selected = self.system.rotationPlannerSelectedField
    if selected == nil and #fields > 0 then
        selected = fields[1].id
        self.system.rotationPlannerSelectedField = selected
    end

    self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
        string.format("%d fields · same engine as soil foresight", #fields),
        RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    y = y - FT.py(16)
    y = self:drawRule(y, 0.4)

    if #fields == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "You do not own any fields yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:setContentHeight(startY - y + scrollY)
        self:drawInfoIcon("_rotationPlannerHelp", AC)
        return
    end

    local bandTop = startY
    local bandBot = cyBottom
    local rowH = FT.py(22)
    local btnW = FT.px(56)
    local btnH = FT.py(16)

    for _, field in ipairs(fields) do
        local info = cache.byId[field.id]
        local line, kind = standingLine(info)
        local col = STATUS_COLOR[kind] or FT.C.MUTED
        local isSel = (field.id == selected)
        local rowVisible = (y <= bandTop + rowH) and (y >= bandBot - rowH)

        if rowVisible then
            if isSel then
                self.r:appRect(x - FT.px(2), y - FT.py(4), cw + FT.px(4), rowH,
                    { AC[1] * 0.12, AC[2] * 0.12, AC[3] * 0.12, 0.95 })
            end

            local label = string.format("#%s  %s", tostring(field.id), line)
            self.r:appText(x, y - FT.py(2), FT.FONT.SMALL, label, RenderText.ALIGN_LEFT, col)

            local bx = x + cw - btnW
            local by = y - FT.py(2)
            local btn = self.r:button(bx, by, btnW, btnH, isSel and "VIEW" or "SELECT", AC, {
                onClick = function()
                    self.system.rotationPlannerSelectedField = field.id
                end
            })
            table.insert(self._contentBtns, btn)
        end
        y = y - rowH
    end

    y = y - FT.py(6)
    y = self:drawRule(y, 0.4)
    y = y - FT.py(4)

    self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
        string.format("What if · field #%s", tostring(selected or "?")),
        RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
    y = y - FT.py(18)

    local info = selected and cache.byId[selected] or nil
    if info == nil or info.lastCrop == nil or info.lastCrop == "" then
        self.r:appText(x, y - FT.py(10), FT.FONT.BODY,
            "No crop history on this field yet. Grow a crop before comparing.",
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(28)
    else
        local candidates = pickCandidates(info.lastCrop, soil)
        for i = 1, 3 do
            local cand = candidates[i]
            if cand ~= nil then
                local proj = nil
                if RP ~= nil and RP.project ~= nil then
                    proj = RP.project(cache, selected, cand)
                else
                    local ok, p = pcall(function() return soil:projectRotation(selected, cand) end)
                    if ok then proj = p end
                end
                local sw, sk = statusWord(proj and proj.status)
                local scol = STATUS_COLOR[sk] or FT.C.MUTED
                local effect = effectText(proj)
                self.r:appText(x, y - FT.py(14), FT.FONT.BODY,
                    cropLabel(cand), RenderText.ALIGN_LEFT, FT.C.TEXT)
                self.r:appText(x + FT.px(140), y - FT.py(14), FT.FONT.SMALL,
                    sw, RenderText.ALIGN_LEFT, scol)
                self.r:appText(x + cw, y - FT.py(14), FT.FONT.SMALL,
                    effect, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
                y = y - FT.py(20)
            end
        end
    end

    self:setContentHeight(startY - y + scrollY + FT.py(12))
    self:drawScrollBar()
    self:drawInfoIcon("_rotationPlannerHelp", AC)
end)
