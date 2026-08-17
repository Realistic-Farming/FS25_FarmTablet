-- =========================================================
-- FarmTablet – Einstellungen
-- Professionelles Karten-Layout, bessere Lesbarkeit und saubere deutsche Texte
-- =========================================================

local function refresh(ui)
    if ui and ui._rebuildScreen then ui:_rebuildScreen() end
end

local function playClickSound(settings)
    if settings and settings.soundEffects and g_FarmTablet and g_FarmTablet.playSound then
        pcall(function() g_FarmTablet:playSound("click") end)
    end
end

local function ftSettingsIsGerman()
    local lang = ""
    if g_languageShort ~= nil then lang = tostring(g_languageShort) end
    if (lang == "" or lang == "nil") and g_i18n ~= nil then
        lang = tostring(g_i18n.languageShort or g_i18n.currentLanguage or g_i18n.language or "")
    end
    lang = string.lower(lang)
    return lang == "de" or lang == "ger" or lang == "deutsch" or lang:sub(1,2) == "de"
end

local FT_SETTINGS_DE = {
    ft_settings_battery_drain = "Akkuverbrauch",
    ft_settings_hint_battery_drain = "Legt fest, ob der Tablet-Akku mit der Zeit leer wird.",
    ft_settings_scroll_help = "Mausrad über diesem Fenster scrollt die Einstellungen.",
    ft_settings_console_help = "Befehl „tablet“ zeigt Konsolenbefehle.",
    ft_settings_all_settings = "Alle Einstellungen",
    ft_settings_default_values = "Standardwerte",
    ft_settings_hint_reset_all = "Setzt alle Tablet-Einstellungen zurück.",
    ft_settings_reset_all = "Alles zurücksetzen",
    ft_settings_apps_loaded = "Apps geladen",
    ft_settings_open_key = "Öffnen-Taste",
    ft_common_author = "Autor",
    ft_common_version = "Version",
    ft_settings_general = "Allgemein",
    ft_settings_notifications = "Meldungen",
    ft_settings_hint_notifications2 = "Tablet-Meldungen beim Laden und bei Ereignissen.",
    ft_settings_start_app_title = "Start-App",
    ft_settings_hint_start_app2 = "Diese App öffnet zuerst nach dem Entsperren.",
    ft_settings_debug_mode = "Debug-Modus",
    ft_settings_hint_debug2 = "Schreibt zusätzliche Diagnosemeldungen in die Log.",
    ft_settings_network_repair = "Netzwerk und Reparatur",
    ft_settings_provider = "Anbieter",
    ft_settings_daily_fee = "Grundgebühr",
    ft_settings_reception = "Empfang",
    ft_settings_network_outages = "Netzstörungen",
    ft_settings_outage_duration = "Störungsdauer",
    ft_settings_display_damage = "Displayschaden",
    ft_settings_provider_selection = "Anbieterauswahl",
    ft_settings_hint_provider_select = "Öffnet die Anbieterauswahl.",
    ft_common_toggle = "Umschalten",
    ft_common_switch = "Wechseln",
    ft_common_change = "Ändern",
    ft_common_open = "Öffnen",
    ft_common_open_list = "Liste öffnen",
    ft_common_on = "An",
    ft_common_off = "Aus",
    ft_common_reset = "Zurücksetzen",
    ft_common_default = "Standard",

    ft_battery_mode_off = "Aus",
    ft_battery_mode_open = "Nur geöffnet",
    ft_battery_mode_standby = "Immer (auch im Standby)",
    ft_settings_hint_battery_drain_mode = "Legt fest, wann der Tablet-Akku verbraucht wird.",
    ft_settings_battery_profile = "Akkuprofil",
    ft_settings_hint_battery_profile = "Niedrig, normal, hoch oder eigene Werte.",
    ft_battery_profile_low = "Niedrig",
    ft_battery_profile_normal = "Normal",
    ft_battery_profile_high = "Hoch",
    ft_battery_profile_custom = "Benutzerdefiniert",
    ft_settings_battery_open_rate = "Verbrauch geöffnet",
    ft_settings_hint_battery_open_rate = "Akkuverbrauch, wenn das Tablet geöffnet ist.",
    ft_settings_battery_standby_rate = "Verbrauch Standby",
    ft_settings_hint_battery_standby_rate = "Akkuverbrauch, wenn das Tablet geschlossen ist.",
    ft_battery_rate_minutes = "1 %% / %d Min.",
    ft_settings_appearance = "Darstellung",
    ft_settings_background_color = "Hintergrundfarbe",
    ft_settings_hint_screen_color2 = "Ändert die Bildschirmfarbe des Tablets.",
    ft_settings_home_image = "Home-Bild",
    ft_settings_hint_home_image = "Eigene PNG-Dateien aus dem Ordner FTBackground nutzen.",
    ft_settings_app_labels = "App-Beschriftungen",
    ft_settings_hint_app_labels = "Text unter den App-Symbolen anzeigen.",
    ft_settings_text_size = "Textgröße",
    ft_settings_hint_text_size = "Größe der App-Beschriftungen.",
    ft_settings_text_color = "Textfarbe",
    ft_settings_hint_text_color = "Farbe der App-Beschriftungen.",
    ft_settings_sound = "Ton",
    ft_settings_sound_effects = "Töne",
    ft_settings_hint_sound_effects = "Hauptschalter für alle Tablet-Töne.",
    ft_settings_app_sound = "App-Ton",
    ft_settings_hint_app_sound = "Ton beim Wechseln von Apps.",
    ft_settings_help_sound = "Hilfe-Ton",
    ft_settings_hint_help_sound = "Ton beim Öffnen und Schließen der Hilfe.",
    ft_settings_tablet_sound = "Tablet-Ton",
    ft_settings_hint_tablet_sound = "Ton beim Öffnen und Schließen mit T.",
}

local function ftSafeText(key, fallback)
    if ftSettingsIsGerman() and key ~= nil and FT_SETTINGS_DE[tostring(key)] ~= nil then
        return FT_SETTINGS_DE[tostring(key)]
    end
    if ftUiText ~= nil then return ftUiText(key, fallback) end
    return fallback
end

local function ftSafeFormat(key, fallback, ...)
    if ftUiFormat ~= nil then return ftUiFormat(key, fallback, ...) end
    return string.format(fallback, ...)
end

local function ftAuto(text)
    if FT ~= nil and FT.l10nAuto ~= nil then return FT.l10nAuto(text) end
    return tostring(text or "")
end

local function ftOnOff(v)
    return v and ftSafeText("ft_common_on", "On") or ftSafeText("ft_common_off", "Off")
end

local function short(text, maxLen)
    text = tostring(text or "")
    maxLen = maxLen or 34
    if string.len(text) <= maxLen then return text end
    return string.sub(text, 1, maxLen - 1) .. "."
end

FarmTabletUI:registerDrawer(FT.APP.SETTINGS, function(self)
    local AC = FT.appColor(FT.APP.SETTINGS)

    if self:drawHelpPage("_settingsHelp", FT.APP.SETTINGS, ftSafeText("ft_auto_settings", "Settings"), AC, {
        { title = ftSafeText("ft_settings_help_display_title", "DISPLAY"), body = ftSafeText("ft_settings_help_display_body", "Tablet position, size, background and app labels.") },
        { title = ftSafeText("ft_settings_help_sound_title", "SOUND"), body = ftSafeText("ft_settings_help_sound_body2", "Switch tablet sounds on or off individually or globally.") },
        { title = ftSafeText("ft_settings_help_network_title", "NETWORK"), body = ftSafeText("ft_settings_help_network_body", "Provider, reception, network outages and display repairs.") },
        { title = ftSafeText("ft_settings_help_scroll_title", "SCROLL"), body = ftSafeText("ft_settings_help_scroll_body", "Use the mouse wheel over the tablet window to scroll settings.") },
    }) then return end

    local s = self.settings
    local cx, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local afterHeader = self:drawAppHeader(ftSafeText("ft_auto_settings", "Settings"), "FarmTablet v" .. tostring(FT.VERSION or ""))
    local y = afterHeader + scrollY

    local cardPadX = FT.px(10)
    local cardH = FT.py(40)
    local rowGap = FT.py(7)
    local sectionGap = FT.py(8)
    local btnW = math.min(FT.px(210), cw * 0.36)
    local btnH = FT.py(22)

    local function section(label)
        y = y - FT.py(4)
        y = self:drawSection(y, label)
        y = y - sectionGap
    end

    local function infoRow(label, value)
        self.r:appRect(cx - FT.px(4), y - cardH + FT.py(6), cw + FT.px(8), cardH, {0.10, 0.12, 0.15, 0.70})
        self.r:appText(cx + cardPadX, y - FT.py(8), FT.FONT.BODY, tostring(label or ""), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
        self.r:appText(cx + cw - cardPadX, y - FT.py(8), FT.FONT.BODY, tostring(value or ""), RenderText.ALIGN_RIGHT, FT.C.BRAND)
        y = y - cardH - rowGap
    end

    local function actionRow(title, value, hint, buttonLabel, color, onClick)
        local h = FT.py(54)
        local x0 = cx - FT.px(4)
        local w0 = cw + FT.px(8)
        self.r:appRect(x0, y - h + FT.py(6), w0, h, {0.10, 0.12, 0.15, 0.74})

        local leftX = cx + cardPadX
        local rightPad = cardPadX
        local bx = cx + cw - btnW - rightPad
        local textW = math.max(FT.px(260), bx - leftX - FT.px(18))

        self.r:appText(leftX, y - FT.py(7), FT.FONT.BODY, short(tostring(title or ""), 42), RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
        if value ~= nil and tostring(value) ~= "" then
            self.r:appText(leftX, y - FT.py(22), FT.FONT.BODY, short(tostring(value), 44), RenderText.ALIGN_LEFT, FT.C.BRAND)
        end
        if hint ~= nil and tostring(hint) ~= "" then
            self.r:appText(leftX, y - FT.py(38), FT.FONT.SMALL, short(tostring(hint), 66), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
        end
        if buttonLabel ~= nil then
            local by = y - FT.py(32)
            local b = self.r:button(bx, by, btnW, btnH, short(tostring(buttonLabel), 24), color or FT.C.BTN_NEUTRAL, { onClick = onClick })
            table.insert(self._contentBtns, b)
        end
        y = y - h - rowGap
    end

    -- Anzeige ------------------------------------------------
    section(ftSafeText("ft_auto_display", "Display"))
    local posStr = string.format("X %.2f   Y %.2f", s.tabletPosX or 0.5, s.tabletPosY or 0.5)
    local scaleStr = string.format(ftSafeText("ft_settings_scale_format", "%.0f%% / width %.0f%%"), (s.tabletScale or 1.0) * 100, (s.tabletWidthMult or 1.0) * 100)
    infoRow(ftSafeText("ft_auto_position", "Position"), posStr)
    infoRow(ftSafeText("ft_auto_scale", "Scale"), scaleStr)

    local editActive = (g_FarmTablet and g_FarmTablet.ui and g_FarmTablet.ui._editModeActive) or false
    actionRow(
        ftSafeText("ft_settings_edit_position", "Tablet-Position"),
        editActive and ftSafeText("ft_common_active", "Active") or ftSafeText("ft_common_off", "Off"),
        ftSafeText("ft_settings_hint_edit_position", "Adjust tablet position and size directly on screen."),
        editActive and ftSafeText("ft_settings_edit_stop", "Stop edit") or ftSafeText("ft_settings_edit_position", "Edit position"),
        editActive and FT.C.POSITIVE or FT.C.BTN_NEUTRAL,
        function()
            playClickSound(s)
            if g_FarmTablet and g_FarmTablet.ui then g_FarmTablet.ui:toggleEditMode() end
            refresh(self)
        end
    )
    actionRow(ftSafeText("ft_settings_reset_position", "Reset position"), ftSafeText("ft_common_default", "Default"), ftSafeText("ft_settings_hint_reset_position", "Resets position, size and width."), ftSafeText("ft_common_reset", "Reset"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s)
        s.tabletPosX = 0.5; s.tabletPosY = 0.5; s.tabletScale = 1.0; s.tabletWidthMult = 1.0
        s:save()
        if g_FarmTablet and g_FarmTablet.ui then g_FarmTablet.ui:applyPositionFromSettings() end
        refresh(self)
    end)

    -- Darstellung -------------------------------------------
    section(ftSafeText("ft_settings_appearance", "Appearance"))
    local BG_PALETTE = FT.BG_PALETTE or {}
    local bgIdx = s.tabletBgColorIndex or 1
    local bgEntry = BG_PALETTE[bgIdx] or { label = ftSafeText("ft_common_default", "Default") }
    actionRow(ftSafeText("ft_settings_background_color", "Background colour"), ftAuto(tostring(bgEntry.label or ftSafeText("ft_common_default", "Default"))), ftSafeText("ft_settings_hint_screen_color2", "Changes the tablet screen colour."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s)
        if #BG_PALETTE > 0 then s.tabletBgColorIndex = (bgIdx % #BG_PALETTE) + 1 end
        s:save(); refresh(self)
    end)

    local bgDir = (g_currentMission and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory) and (g_currentMission.missionInfo.savegameDirectory .. "/FTBackground/") or nil
    local BG_CANDIDATES = { "background.png", "background1.png", "background2.png", "background3.png", "background4.png", "background5.png", "background6.png", "background7.png", "background8.png", "background9.png" }
    local bgOptions = { { label = ftSafeText("ft_common_default", "Default"), file = "" } }
    if bgDir then
        for _, name in ipairs(BG_CANDIDATES) do
            if fileExists(bgDir .. name) then table.insert(bgOptions, { label = string.upper(name), file = name }) end
        end
    end
    local curBg = s.customBackground or ""
    local bgOptIdx = 1
    for i, o in ipairs(bgOptions) do if o.file == curBg then bgOptIdx = i; break end end
    local curBgOpt = bgOptions[bgOptIdx] or bgOptions[1]
    actionRow(ftSafeText("ft_settings_home_image_title", "Home image"), ftAuto(tostring(curBgOpt.label or ftSafeText("ft_common_default", "Default"))), ftSafeText("ft_settings_hint_home_image", "Use your own PNG files from the FTBackground folder."), ftSafeText("ft_common_switch", "Switch"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s)
        local nextIdx = (bgOptIdx % #bgOptions) + 1
        local chosen = bgOptions[nextIdx]
        s.customBackground = chosen.file
        if FT_Icons and FT_Icons.invalidate and bgDir and chosen.file ~= "" then FT_Icons.invalidate(bgDir .. chosen.file) end
        s:save(); refresh(self)
    end)

    local lblShow = (s.iconLabelsShow ~= false)
    local lblSize = math.max(1, math.min(3, s.iconLabelSize or 2))
    local lblColIx = math.max(1, math.min(3, s.iconLabelColor or 1))
    local sizeNames = { ftSafeText("ft_size_small", "Small"), ftSafeText("ft_size_medium", "Medium"), ftSafeText("ft_size_large", "Large") }
    local colorNames = { ftSafeText("ft_color_white", "White"), ftSafeText("ft_color_gold", "Gold"), ftSafeText("ft_color_app", "App colour") }
    actionRow(ftSafeText("ft_settings_app_labels", "App labels"), ftOnOff(lblShow), ftSafeText("ft_settings_hint_icon_text", "Show text below app icons."), lblShow and ftSafeText("ft_common_turn_off", "Turn off") or ftSafeText("ft_common_turn_on", "Turn on"), lblShow and FT.C.POSITIVE or FT.C.MUTED, function()
        playClickSound(s); s.iconLabelsShow = not lblShow; s:save(); refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_text_size_title", "Text size"), sizeNames[lblSize], ftSafeText("ft_settings_hint_text_size2", "Size of app labels."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); s.iconLabelSize = (lblSize % 3) + 1; s:save(); refresh(self)
    end)

    local FONT_SCALES = { 0.8, 1.0, 1.25, 1.5 }
    local fontScaleNames = {
        ftSafeText("ft_font_scale_small",  "Small (0.8x)"),
        ftSafeText("ft_font_scale_normal", "Normal (1.0x)"),
        ftSafeText("ft_font_scale_large",  "Large (1.25x)"),
        ftSafeText("ft_font_scale_huge",   "Huge (1.5x)"),
    }
    local curFontScale = s.contentFontScale or 1.0
    local fsIdx = 2
    for i, v in ipairs(FONT_SCALES) do if math.abs(v - curFontScale) < 0.01 then fsIdx = i; break end end
    actionRow(ftSafeText("ft_settings_content_font_title", "Content text size"), fontScaleNames[fsIdx], ftSafeText("ft_settings_hint_content_font", "Size of the text inside apps. Larger is easier to read on big screens."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s)
        s.contentFontScale = FONT_SCALES[(fsIdx % #FONT_SCALES) + 1]
        s:save()
        if g_FarmTablet and g_FarmTablet.ui then g_FarmTablet.ui:_build() end
        refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_text_color_title", "Text colour"), colorNames[lblColIx], ftSafeText("ft_settings_hint_text_color2", "Colour of app labels."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); s.iconLabelColor = (lblColIx % 3) + 1; s:save(); refresh(self)
    end)

    -- Ton ----------------------------------------------------
    section(ftSafeText("ft_settings_sound_section", "Sound"))
    actionRow(ftSafeText("ft_settings_sounds", "Sounds"), ftOnOff(s.soundEffects), ftSafeText("ft_settings_hint_sounds", "Main switch for all tablet sounds."), s.soundEffects and ftSafeText("ft_common_turn_off", "Turn off") or ftSafeText("ft_common_turn_on", "Turn on"), s.soundEffects and FT.C.POSITIVE or FT.C.MUTED, function()
        s.soundEffects = not s.soundEffects; s:save(); refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_app_sound", "App sound"), ftOnOff(s.soundOnAppSelect), ftSafeText("ft_settings_hint_app_sound", "Sound when switching apps."), ftSafeText("ft_common_toggle", "Toggle"), (s.soundEffects and s.soundOnAppSelect) and FT.C.POSITIVE or FT.C.MUTED, function()
        playClickSound(s); s.soundOnAppSelect = not s.soundOnAppSelect; s:save(); refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_help_sound", "Help sound"), ftOnOff(s.soundOnHelpOpen), ftSafeText("ft_settings_hint_help_sound", "Sound when opening and closing help."), ftSafeText("ft_common_toggle", "Toggle"), (s.soundEffects and s.soundOnHelpOpen) and FT.C.POSITIVE or FT.C.MUTED, function()
        playClickSound(s); s.soundOnHelpOpen = not s.soundOnHelpOpen; s:save(); refresh(self)
    end)
    local tabletSound = (s.soundOnTabletToggle ~= false)
    actionRow(ftSafeText("ft_settings_tablet_sound", "Tablet sound"), ftOnOff(tabletSound), ftSafeText("ft_settings_hint_tablet_sound", "Sound when opening and closing with T."), ftSafeText("ft_common_toggle", "Toggle"), (s.soundEffects and tabletSound) and FT.C.POSITIVE or FT.C.MUTED, function()
        playClickSound(s); s.soundOnTabletToggle = not tabletSound; s:save(); refresh(self)
    end)

    -- Allgemein ---------------------------------------------
    section(ftSafeText("ft_settings_general", "General"))
    actionRow(ftSafeText("ft_settings_notifications", "Notifications"), ftOnOff(s.showTabletNotifications), ftSafeText("ft_settings_hint_notifications2", "Tablet messages on load and events."), ftSafeText("ft_common_toggle", "Toggle"), s.showTabletNotifications and FT.C.POSITIVE or FT.C.MUTED, function()
        playClickSound(s); s.showTabletNotifications = not s.showTabletNotifications; s:save(); refresh(self)
    end)
    local modeOrder = {"off", "open", "standby"}
    local modeLabels = {
        off = ftSafeText("ft_battery_mode_off", "Off"),
        open = ftSafeText("ft_battery_mode_open", "Only when open"),
        standby = ftSafeText("ft_battery_mode_standby", "Always (incl. standby)"),
    }
    local curMode = tostring(s.tabletBatteryDrainMode or (s.tabletBatteryDrainEnabled == false and "off" or "standby"))
    if curMode ~= "off" and curMode ~= "open" and curMode ~= "standby" then curMode = "standby" end
    actionRow(ftSafeText("ft_settings_battery_drain", "Battery drain"), modeLabels[curMode] or curMode, ftSafeText("ft_settings_hint_battery_drain_mode", "Controls when the tablet battery drains."), ftSafeText("ft_common_change", "Change"), curMode ~= "off" and FT.C.POSITIVE or FT.C.MUTED, function()
        playClickSound(s)
        local idx = 1
        for i, v in ipairs(modeOrder) do if v == curMode then idx = i; break end end
        s.tabletBatteryDrainMode = modeOrder[(idx % #modeOrder) + 1]
        s.tabletBatteryDrainEnabled = (s.tabletBatteryDrainMode ~= "off")
        s.tabletBatteryDrainMs = 0
        s:save(); refresh(self)
    end)

    local profileOrder = {"low", "normal", "high", "custom"}
    local profileLabels = {
        low = ftSafeText("ft_battery_profile_low", "Low"),
        normal = ftSafeText("ft_battery_profile_normal", "Normal"),
        high = ftSafeText("ft_battery_profile_high", "High"),
        custom = ftSafeText("ft_battery_profile_custom", "Custom"),
    }
    local curProfile = tostring(s.tabletBatteryDrainProfile or "normal")
    if curProfile ~= "low" and curProfile ~= "normal" and curProfile ~= "high" and curProfile ~= "custom" then curProfile = "normal" end
    actionRow(ftSafeText("ft_settings_battery_profile", "Battery profile"), profileLabels[curProfile] or curProfile, ftSafeText("ft_settings_hint_battery_profile", "Low, normal, high or custom values."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s)
        local idx = 2
        for i, v in ipairs(profileOrder) do if v == curProfile then idx = i; break end end
        s.tabletBatteryDrainProfile = profileOrder[(idx % #profileOrder) + 1]
        s.tabletBatteryDrainMs = 0
        s:save(); refresh(self)
    end)

    if curProfile == "custom" then
        local openValues = {5,10,15,20,30,45,60}
        local standbyValues = {5,10,15,20,30,45,60,90,120}
        local openMin = math.max(5, math.min(60, tonumber(s.tabletBatteryOpenMinutes) or 10))
        local standbyMin = math.max(5, math.min(180, tonumber(s.tabletBatteryStandbyMinutes) or 15))
        actionRow(ftSafeText("ft_settings_battery_open_rate", "Open drain"), ftSafeFormat("ft_battery_rate_minutes", "1%% / %d min", openMin), ftSafeText("ft_settings_hint_battery_open_rate", "Battery use while the tablet is open."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
            playClickSound(s)
            local idx = 3
            for i, v in ipairs(openValues) do if v == openMin then idx = i; break end end
            s.tabletBatteryOpenMinutes = openValues[(idx % #openValues) + 1]
            s.tabletBatteryDrainMs = 0
            s:save(); refresh(self)
        end)
        actionRow(ftSafeText("ft_settings_battery_standby_rate", "Standby drain"), ftSafeFormat("ft_battery_rate_minutes", "1%% / %d min", standbyMin), ftSafeText("ft_settings_hint_battery_standby_rate", "Battery use while the tablet is closed."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
            playClickSound(s)
            local idx = 3
            for i, v in ipairs(standbyValues) do if v == standbyMin then idx = i; break end end
            s.tabletBatteryStandbyMinutes = standbyValues[(idx % #standbyValues) + 1]
            s.tabletBatteryDrainMs = 0
            s:save(); refresh(self)
        end)
    end
    local ALL_STARTUP = {
        { id = "dashboard", label = ftSafeText("ft_ui_app_dashboard", "Dashboard") }, { id = "app_store", label = ftSafeText("ft_ui_app_store", "App Store") }, { id = "weather", label = ftSafeText("ft_ui_app_weather", "Weather") },
        { id = "field_status", label = ftSafeText("ft_ui_app_field_status", "Fields") }, { id = "animals", label = ftSafeText("ft_ui_app_animals", "Animals") }, { id = "workshop", label = ftSafeText("ft_ui_app_workshop", "Workshop") }, { id = "excavator", label = ftSafeText("ft_ui_app_excavator", "Excavator") },
    }
    local curStartup = s.startupApp or "dashboard"
    local sIdx = 1
    for i, e in ipairs(ALL_STARTUP) do if e.id == curStartup then sIdx = i; break end end
    local sEntry = ALL_STARTUP[sIdx] or ALL_STARTUP[1]
    actionRow(ftSafeText("ft_settings_start_app_title", "Startup app"), sEntry.label, ftSafeText("ft_settings_hint_start_app2", "This app opens first after unlocking."), ftSafeText("ft_common_switch", "Switch"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); local next = (sIdx % #ALL_STARTUP) + 1; s.startupApp = ALL_STARTUP[next].id; s:save(); refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_debug_mode", "Debug mode"), ftOnOff(s.debugMode), ftSafeText("ft_settings_hint_debug2", "Writes additional diagnostic messages to the log."), ftSafeText("ft_common_toggle", "Toggle"), s.debugMode and FT.C.WARNING or FT.C.MUTED, function()
        playClickSound(s); s.debugMode = not s.debugMode; s:save(); refresh(self)
    end)

    -- Netzwerk ----------------------------------------------
    section(ftSafeText("ft_settings_network_repair", "Network and repair"))
    local providers = self._signalProviders or {}
    local curProviderId = tostring(self._signalProviderId or "")
    local pIdx = 1
    if #providers > 0 then
        for i, pvd in ipairs(providers) do if tostring(pvd.id or "") == curProviderId then pIdx = i; break end end
    end
    local curProvider = providers[pIdx] or { id = tostring(self._signalProviderId or "default"), name = tostring(self._signalProvider or "Realistic Farming Mobile") }
    if self._updateSignalSystem ~= nil then pcall(function() self:_updateSignalSystem(0, true) end) end
    local bars = math.max(0, math.min(4, tonumber(self._signalBars) or 0))
    local netLabel = (bars >= 4 and ftSafeText("ft_signal_very_good", "Very good")) or (bars == 3 and ftSafeText("ft_signal_good", "Good")) or (bars == 2 and ftSafeText("ft_signal_medium", "Medium")) or (bars == 1 and ftSafeText("ft_signal_weak", "Weak")) or ftSafeText("ft_signal_none", "No signal")
    if self._signalOutageActive == true then netLabel = ftSafeText("ft_settings_outage", "Outage") end
    local providerName = tostring(self._signalProvider or curProvider.name or "Realistic Farming Mobile")
    if string.find(string.lower(providerName), "realistic", 1, true) ~= nil then providerName = "Realistic Mobile" end
    infoRow(ftSafeText("ft_settings_provider", "Provider"), short(providerName, 28))
    local dailyFee = 0
    if self._getSignalProviderDailyFee ~= nil then dailyFee = tonumber(self:_getSignalProviderDailyFee(curProvider.id)) or 0 else dailyFee = tonumber(curProvider.dailyFee) or 0 end
    infoRow(ftSafeText("ft_settings_daily_fee", "Daily fee"), ftSafeFormat("ft_price_per_day", "%d €/day", math.floor(dailyFee)))
    infoRow(ftSafeText("ft_settings_reception", "Reception"), string.format("%s (%d/4)", netLabel, bars))

    actionRow(ftSafeText("ft_settings_provider", "Provider"), short(providerName, 28), ftSafeText("ft_settings_hint_provider2", "Switches to the next mobile provider."), ftSafeText("ft_common_switch", "Switch"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s)
        if #providers > 0 then
            local chosen = providers[(pIdx % #providers) + 1]
            self._signalProvider = chosen.name or "Realistic Farming Mobile"
            self._signalProviderId = chosen.id or "default"
            self._signalProviderSelected = true
            self._providerPending = chosen
            self._signalLastNotify = nil
            if self._saveSignalProviderSelection ~= nil then self:_saveSignalProviderSelection(chosen) end
            if self._updateSignalSystem ~= nil then self:_updateSignalSystem(0, true) end
        end
        refresh(self)
    end)

    local outageFreq = (self._getSignalOutageFrequencyLabel ~= nil and self:_getSignalOutageFrequencyLabel()) or ftSafeText("ft_common_off", "Off")
    local outageDuration = tonumber(self._signalOutageDurationHours) or 2
    actionRow(ftSafeText("ft_settings_network_outages", "Network outages"), tostring(outageFreq), ftSafeText("ft_settings_hint_frequency", "Off / Rare / Normal / Often"), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); if self._cycleSignalOutageFrequency ~= nil then self:_cycleSignalOutageFrequency() end; refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_outage_duration", "Outage duration"), ftSafeFormat("ft_duration_hours_short", "%d hrs", math.floor(outageDuration)), ftSafeText("ft_settings_hint_outage_duration", "Duration in ingame hours."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); if self._cycleSignalOutageDuration ~= nil then self:_cycleSignalOutageDuration() end; refresh(self)
    end)
    local repairFreq = (self._getTabletRepairFrequencyLabel ~= nil and self:_getTabletRepairFrequencyLabel()) or ftSafeText("ft_common_off", "Off")
    actionRow(ftSafeText("ft_settings_display_damage", "Display damage"), tostring(repairFreq), ftSafeText("ft_settings_hint_display_damage2", "Random tablet damage from falling."), ftSafeText("ft_common_change", "Change"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); if self._cycleTabletRepairFrequency ~= nil then self:_cycleTabletRepairFrequency() end; refresh(self)
    end)
    actionRow(ftSafeText("ft_settings_provider_selection", "Provider selection"), ftSafeText("ft_common_open_list", "Open list"), ftSafeText("ft_settings_hint_provider_select", "Opens the provider selection."), ftSafeText("ft_common_open", "Open"), FT.C.BTN_NEUTRAL, function()
        playClickSound(s); self.uiState = "provider"; self._providerPending = curProvider; self:_rebuildScreen()
    end)

    -- Info ---------------------------------------------------
    section(ftSafeText("ft_common_info", "Info"))
    infoRow(ftSafeText("ft_common_version", "Version"), "v" .. tostring(FT.VERSION or ""))
    infoRow(ftSafeText("ft_common_author", "Author"), "TisonK")
    infoRow(ftSafeText("ft_settings_apps_loaded", "Apps loaded"), tostring(#self.system.registry:getAll()))
    infoRow(ftSafeText("ft_settings_open_key", "Open key"), g_FarmTablet and g_FarmTablet.inputHandler and g_FarmTablet.inputHandler:getKeybindString()
        or InputHandler.DEFAULT_KEY_LABEL)

    local hintH = FT.py(44)
    self.r:appRect(cx - FT.px(4), y - hintH + FT.py(6), cw + FT.px(8), hintH, {0.10, 0.12, 0.15, 0.76})
    self.r:appText(cx + cardPadX, y - FT.py(9), FT.FONT.BODY, ftSafeText("ft_settings_scroll_help", "Mouse wheel over this window scrolls the settings."), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
    self.r:appText(cx + cardPadX, y - FT.py(25), FT.FONT.BODY, ftSafeText("ft_settings_console_help", "Command 'tablet' shows console commands."), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
    y = y - hintH - rowGap

    -- Reset --------------------------------------------------
    section(ftSafeText("ft_settings_reset_section", "Reset"))
    actionRow(ftSafeText("ft_settings_all_settings", "All settings"), ftSafeText("ft_settings_default_values", "Default values"), ftSafeText("ft_settings_hint_reset_all", "Resets all tablet settings."), ftSafeText("ft_settings_reset_all", "Reset all"), FT.C.BTN_DANGER, function()
        playClickSound(s); self.settings:resetToDefaults(true)
        if g_FarmTablet and g_FarmTablet.ui then g_FarmTablet.ui:applyPositionFromSettings() end
        refresh(self)
    end)

    -- Generous safety padding: some FS25 UI scales report a smaller content area than
    -- expected, which made the lower settings (display damage, reset, etc.) unreachable.
    self:setContentHeight(math.max(0, afterHeader - y + scrollY + FT.py(900)))
    self:drawInfoIcon("_settingsHelp", AC)
    self:drawScrollBar()
end)
