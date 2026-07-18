-- =========================================================
-- FarmTablet v2 – FieldSentry App  (#83)
-- =========================================================
-- Per-field soil-sim status with sleep / meadow toggles, mirroring S&F's own
-- ESC-menu FieldSentry controls. Reads + toggles go through the cross-mod bridge
-- S&F publishes on g_currentMission.fieldSentry (the plain FieldSentry_API global is
-- per-mod scoped and invisible here). Reads are safe on any peer; toggles are
-- client->server request events that S&F admin-gates and validates server-side.
--
-- The general "Soil Fertilizer" nutrient app (FT.APP.SOIL_FERT) is separate and
-- lives elsewhere; this file owns only the FieldSentry view.
-- =========================================================

-- Reason enum -> status colour (matches FieldSentry_Core.BLACKLIST).
local FS_REASON_COLOR = {
    [0] = FT.C.POSITIVE,  -- NONE / active
    [1] = FT.C.WARNING,   -- MANUAL (player asleep)
    [2] = FT.C.WARNING,   -- FARMLAND
    [3] = FT.C.MUTED,     -- OWNERSHIP
    [4] = FT.C.INFO,      -- NPC contract
    [5] = FT.C.MUTED,     -- DECO
    [6] = FT.C.MUTED,     -- INACTIVE
}

FarmTabletUI:registerDrawer(FT.APP.FIELD_SENTRY, function(self)
    local AC = FT.appColor(FT.APP.FIELD_SENTRY)

    if self:drawHelpPage("_sentryHelp", FT.APP.FIELD_SENTRY, "Field Sentry", AC, {
        { title = "WHAT THIS IS",
          body  = "FieldSentry decides which fields the soil simulation runs\n" ..
                  "on. Sleeping fields are skipped to save performance and to\n" ..
                  "leave NPC-contracted or decorative land alone." },
        { title = "STATUS",
          body  = "ACTIVE = simulated normally.\n" ..
                  "MANUAL = you put it to sleep.\n" ..
                  "NPC    = asleep under an AI/NPC contract.\n" ..
                  "DECO   = decorative / fake field (auto-detected)." },
        { title = "SLEEP TOGGLE",
          body  = "Force a field to sleep (or wake it). Your choice persists\n" ..
                  "and is independent of contract/decorative states." },
        { title = "MEADOW TOGGLE",
          body  = "Mark a field as permanent grassland. It still simulates,\n" ..
                  "just on meadow rules. Independent of the sleep state." },
        { title = "MULTIPLAYER",
          body  = "Toggles are admin-only and validated by the host. Clients\n" ..
                  "without admin see the list read-only." },
    }) then return end

    local FS = g_currentMission and g_currentMission.fieldSentry
    local startY = self:drawAppHeader("Field Sentry", "")
    local x, cyBottom, cw, contentH = self:contentInner()

    if FS == nil or FS.getUIStatus == nil then
        self.r:appText(x, startY - FT.py(14), FT.FONT.BODY,
            "FieldSentry is not available.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, startY - FT.py(32), FT.FONT.SMALL,
            "Update FS25_SoilFertilizer to a build that ships the bridge.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        self:drawInfoIcon("_sentryHelp", AC)
        return
    end

    local data   = self.system.data
    local farmId  = data:getPlayerFarmId()
    local fields  = data:getOwnedFields(farmId)
    local isAdmin = (FS.isPlayerAdmin ~= nil) and (FS.isPlayerAdmin() == true)

    -- Summary count (asleep = simulation disabled for any reason).
    local asleep = 0
    for _, f in ipairs(fields) do
        local st = FS.getUIStatus(f.id)
        if st and st.isSimulationDisabled then asleep = asleep + 1 end
    end

    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    -- Sub-header line: counts + admin note.
    self.r:appText(x, y - FT.py(2), FT.FONT.SMALL,
        string.format("%d fields  ·  %d asleep", #fields, asleep),
        RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    self.r:appText(x + cw, y - FT.py(2), FT.FONT.SMALL,
        isAdmin and "Admin" or "View only (admin needed)",
        RenderText.ALIGN_RIGHT, isAdmin and FT.C.TEXT_ACCENT or FT.C.WARNING)
    y = y - FT.py(16)
    y = self:drawRule(y, 0.4)

    if #fields == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "You don't own any fields yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:setContentHeight(startY - y + scrollY)
        self:drawInfoIcon("_sentryHelp", AC)
        return
    end

    -- Visible band for click-culling buttons that have scrolled out of view.
    local bandTop = startY
    local bandBot = cyBottom

    local rowH  = FT.py(24)
    local btnW  = FT.px(58)
    local btnH  = FT.py(18)
    local btnGap = FT.px(4)
    -- Two toggle buttons hug the right edge.
    local meadowX = x + cw - btnW
    local sleepX  = meadowX - btnGap - btnW
    local altBg   = {0.09, 0.11, 0.16, 0.50}

    for i, field in ipairs(fields) do
        local st       = FS.getUIStatus(field.id)
        local reason   = (st and st.reason) or 0
        local isManual = FS.isFieldManual and FS.isFieldManual(field.id)
        local isMeadow = FS.isFieldMeadow and FS.isFieldMeadow(field.id)
        local dotCol   = FS_REASON_COLOR[reason] or FT.C.MUTED

        -- Localized reason label, falling back to the English reasonName.
        local label = (st and st.reasonName) or "?"
        if st and FS.reasonL10nKey then
            local key = FS.reasonL10nKey(reason)
            if key and g_i18n and g_i18n:hasText(key) then
                label = g_i18n:getText(key)
            end
        end

        local rowVisible = (y <= bandTop + rowH) and (y >= bandBot - rowH)

        if rowVisible then
            if i % 2 == 0 then
                self.r:appRect(x - FT.px(4), y - FT.py(4), cw + FT.px(8), rowH, altBg)
            end
            -- Status dot + field id + reason label.
            self.r:appRect(x + FT.px(2), y + FT.py(5), FT.px(6), FT.py(6), dotCol)
            self.r:appText(x + FT.px(14), y, FT.FONT.SMALL,
                "#" .. tostring(field.id), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + FT.px(54), y, FT.FONT.SMALL, label, RenderText.ALIGN_LEFT, dotCol)
            if isMeadow then
                self.r:appText(x + FT.px(54), y - FT.py(11), FT.FONT.TINY,
                    "meadow", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            end

            -- Sleep toggle (manual blacklist).
            local sleepCol = isManual and FT.C.WARNING or FT.C.BTN_NEUTRAL
            local sleepBtn = self.r:button(sleepX, y - FT.py(2), btnW, btnH,
                isManual and "WAKE" or "SLEEP", sleepCol, isAdmin and {
                    onClick = function()
                        if FS.toggleSleep then FS.toggleSleep(field.id, not isManual) end
                    end
                } or nil)
            if isAdmin then table.insert(self._contentBtns, sleepBtn) end

            -- Meadow toggle.
            local meadowCol = isMeadow and FT.C.BTN_ACTIVE or FT.C.BTN_NEUTRAL
            local meadowBtn = self.r:button(meadowX, y - FT.py(2), btnW, btnH,
                "MEADOW", meadowCol, isAdmin and {
                    onClick = function()
                        if FS.toggleMeadow then FS.toggleMeadow(field.id, not isMeadow) end
                    end
                } or nil)
            if isAdmin then table.insert(self._contentBtns, meadowBtn) end
        end

        y = y - rowH
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_sentryHelp", AC)
end)
