-- =========================================================
-- FarmTablet v2 - App Store
-- Lists every installed app once, under the same domains as the springboard.
-- A supported companion that is not loaded is listed once, dimmed.
-- =========================================================

local function storeTitle(app, known)
    -- An absent companion is named by its MOD, not by the app behind its door. With the mod not
    -- installed this row is the only place the suite says it integrates with it, so "Seasonal
    -- Crop Stress" has to read as that and not as "Irrigation Suite" or the "IRRI" nav chip.
    -- Mod names are product names and are deliberately not localized; development's
    -- appstore-integration-row bar asserts these four by name.
    if app == nil and known ~= nil and known.label ~= nil and known.label ~= "" then
        return known.label
    end
    local key = nil
    if app ~= nil and app.name ~= nil then key = app.name end
    if key == nil and known ~= nil then key = known.name end
    if g_i18n ~= nil and key ~= nil and g_i18n.hasText ~= nil and g_i18n:hasText(key) then
        local title = g_i18n:getText(key)
        if title ~= nil and title ~= "" then return title end
    end
    if app ~= nil and app.navLabel ~= nil and app.navLabel ~= "" then
        return app.navLabel
    end
    if known ~= nil and known.navLabel ~= nil and known.navLabel ~= "" then
        return known.navLabel
    end
    return FT.l10n("ft_store_unnamed", "App")
end

FarmTabletUI:registerDrawer(FT.APP.APP_STORE, function(self)
    local AC = FT.appColor(FT.APP.APP_STORE)

    if self:drawHelpPage("_appStoreHelp", FT.APP.APP_STORE, FT.l10n("ft_ui_app_store", "App Store"), AC, {
        { title = FT.l10n("ft_store_help_domains_title", "DOMAINS"),
          body  = FT.l10n("ft_store_help_domains_body",
                  "Every installed app is listed once, under the same domain\n" ..
                  "it uses on the springboard: Core, Finance, Fields and Soil,\n" ..
                  "Social and World, Equipment and Yard, Livestock, and Labor.\n" ..
                  "Empty domains are left out."), literalTitle = true, literalBody = true },
        { title = FT.l10n("ft_store_help_open_title", "OPEN"),
          body  = FT.l10n("ft_store_help_open_body",
                  "Click OPEN to switch to that app.\n" ..
                  "You can also open it from its icon on the springboard."), literalTitle = true, literalBody = true },
        { title = FT.l10n("ft_store_help_missing_title", "NOT INSTALLED"),
          body  = FT.l10n("ft_store_help_missing_body",
                  "A supported companion that is not loaded is listed once,\n" ..
                  "dimmed, under Not installed. It is not repeated in a domain.\n" ..
                  "When that mod is in the save, the app moves into its domain."), literalTitle = true, literalBody = true },
        { title = FT.l10n("ft_store_help_version_title", "VERSION"),
          body  = FT.l10n("ft_store_help_version_body",
                  "The version sits on the right\n" ..
                  "of each installed row."), literalTitle = true, literalBody = true },
    -- literalHeader: the header came from FT.l10n so it is already resolved. Sixth positional arg.
    }, true) then return end

    local apps    = self.system.registry:getAll()
    local scrollY = self:getContentScrollY()
        local afterHdr = self:drawAppHeader(FT.l10n("ft_ui_app_store", "App Store"), FT.l10nFormat("ft_appstore_installed_count", "%d installed", #apps), true, true)
    local x, contentY, cw, _ = self:contentInner()
    local y = afterHdr - FT.py(8) + scrollY

    local buckets = {}
    for _, app in ipairs(apps) do
        local gid = app.group or "core"
        buckets[gid] = buckets[gid] or {}
        buckets[gid][#buckets[gid] + 1] = app
    end

    local groups = (AppRegistry and AppRegistry.GROUPS) or {}
    for _, g in ipairs(groups) do
        local list = buckets[g.id]
        if list ~= nil and #list > 0 then
            table.sort(list, function(a, b)
                local oa = a.order or 0
                local ob = b.order or 0
                if oa ~= ob then return oa < ob end
                return tostring(a.id) < tostring(b.id)
            end)
            local title = g.label or g.id
            if FT.l10n ~= nil then
                title = FT.l10n(g.labelKey, g.label)
            end
            y = self:drawSection(y, title, true)
            for _, app in ipairs(list) do
                y = self:_drawAppRow(y, app, storeTitle(app, nil), x, cw, false)
            end
            y = y - FT.py(4)
        end
    end

    local knownList = (AppRegistry and AppRegistry.KNOWN_COMPANIONS) or {}
    local seenAbsent = {}
    local printedMissing = false
    for _, known in ipairs(knownList) do
        local appId = known.appId
        if appId ~= nil and not seenAbsent[appId] and not self.system.registry:has(appId) then
            seenAbsent[appId] = true
            if not printedMissing then
                printedMissing = true
                y = self:drawSection(y, FT.l10n("ft_store_not_installed", "Not installed"), true)
            end
            y = self:_drawAppRow(y, nil, storeTitle(nil, known), x, cw, true, known)
        end
    end

    self:setContentHeight(afterHdr - y + scrollY)
    self:drawInfoIcon("_appStoreHelp", AC)
    self:drawScrollBar()
end)


-- Byte budget, then step back to a whole UTF-8 character.

-- ── Row renderer helper ───────────────────────────────────
-- dimmed   = true for uninstalled companion mods
-- known    = absent companion from AppRegistry.KNOWN_COMPANIONS
function FarmTabletUI:_drawAppRow(y, app, dispName, x, cw, dimmed, known)
    local alpha = dimmed and 0.35 or 1.00

    -- Card background
    self.r:appRect(x - FT.px(4), y - FT.py(38), cw + FT.px(8), FT.py(38),
        dimmed and {0.08, 0.09, 0.12, 0.50} or FT.C.BG_CARD)

    -- App name (keep clear of version / OPEN on the right)
    local nameColor = dimmed
        and {FT.C.TEXT_DIM[1], FT.C.TEXT_DIM[2], FT.C.TEXT_DIM[3], alpha}
        or FT.C.TEXT_BRIGHT
    local nameMax = dimmed and 22 or 18
    self.r:appText(x + FT.px(10), y - FT.py(18), FT.FONT.BODY,
        FT_Renderer.truncate(dispName, nameMax), RenderText.ALIGN_LEFT, nameColor, true)

    -- Description / hint
    local desc
    if dimmed and known then
        desc = FT.l10nFormat("ft_appstore_install_to_enable", "Install %s to enable", known.mod)
    elseif app then
        -- Text that already came from a key is resolved. Handing it back to FT.l10nAuto is a second
        -- translation, which reads as English in every locale once the auto map misses.
        local fromKey = (app.descriptionKey ~= nil and g_i18n ~= nil
            and g_i18n:hasText(app.descriptionKey)) and true or false
        desc = (fromKey and g_i18n:getText(app.descriptionKey))
            or app.description
            or ""
        if not fromKey then desc = FT.l10nAuto(desc) end
        if FT.utf8Len(desc) > 72 then desc = FT.utf8Sub(desc, 70) .. ">" end
    else
        desc = ""
    end
    self.r:appText(x + FT.px(10), y - FT.py(33), FT.FONT.TINY,
        desc, RenderText.ALIGN_LEFT,
        {FT.C.TEXT_DIM[1], FT.C.TEXT_DIM[2], FT.C.TEXT_DIM[3], alpha}, true)

    -- Version on the top-right; OPEN alone on the lower right (no developer clash).
    if app and not dimmed then
        self.r:appText(x + cw - FT.px(8), y - FT.py(13), FT.FONT.TINY,
            FT.l10nAuto(app.version or "Built-in"), RenderText.ALIGN_RIGHT, FT.C.BRAND, true)
    elseif dimmed then
        -- The same corner on a dimmed row says why it is dimmed. Without this the row was greyed out and
        -- unlabelled, and only the hint line underneath explained it. Carried in development's exact form,
        -- FT.l10nAuto on a literal, rather than inventing a new key: a new key would be undefined in all 26
        -- locale files on day one, which is the defect class FINDING-074 records.
        self.r:appText(x + cw - FT.px(8), y - FT.py(13), FT.FONT.TINY,
            FT.l10nAuto("not installed"), RenderText.ALIGN_RIGHT,
            {FT.C.MUTED[1], FT.C.MUTED[2], FT.C.MUTED[3], 0.45}, true)
    elseif dimmed then
        self.r:appText(x + cw - FT.px(8), y - FT.py(13), FT.FONT.TINY,
            FT.l10n("ft_store_not_installed", "Not installed"), RenderText.ALIGN_RIGHT,
            {FT.C.MUTED[1], FT.C.MUTED[2], FT.C.MUTED[3], 0.45}, true)
    end

    -- OPEN button (only for installed apps)
    if app and not dimmed then
        local appId = app.id
        local btn = self.r:button(x + cw - FT.px(48), y - FT.py(36), FT.px(44), FT.py(15),
            FT.l10nAuto("OPEN"), FT.C.BTN_PRIMARY, { onClick = function() self:switchApp(appId) end }, true)
        table.insert(self._contentBtns, btn)
    end

    return y - FT.py(42)
end
