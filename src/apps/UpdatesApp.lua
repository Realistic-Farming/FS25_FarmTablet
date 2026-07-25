-- =========================================================
-- FarmTablet – Aktualisierungen / Versionsverlauf
-- Saubere, deutsch lesbare Darstellung ohne englische Debug-Zeilen
-- =========================================================


local function ftSafeText(key, fallback)
    local raw = fallback or tostring(key or "")
    if ftUiText ~= nil then
        local v = ftUiText(key, raw)
        if v ~= nil and v ~= tostring(key or "") and v ~= raw then return v end
    end
    if FT ~= nil and FT.l10n ~= nil then return FT.l10n(key, raw) end
    if FT ~= nil and FT.l10nAuto ~= nil then return FT.l10nAuto(raw) end
    return raw
end

local function py(v) return (FT and FT.py and FT.py(v)) or v end
local function px(v) return (FT and FT.px and FT.px(v)) or v end
local function col(c, fallback) return c or fallback or {1,1,1,1} end

local CHANGELOG = {
    {
        version = "2.5.3.0", date = "2026",
        neu = {
            ftSafeText("ft_changelog_253_new_1", "Rotation Planner app: plan crop rotations using Soil & Fertilizer's own recommendations"),
            ftSafeText("ft_changelog_253_new_2", "Irrigation Suite app: a read-only operating picture for Seasonal Crop Stress irrigation"),
            ftSafeText("ft_changelog_253_new_3", "Weather app reads the new WeatherGuard service: a real forecast plus a World Weather dial"),
        },
        verbessert = {
            ftSafeText("ft_changelog_253_imp_1", "App text now scales with the tablet, with a new font-size setting"),
            ftSafeText("ft_changelog_253_imp_2", "New app icons for Rotation Planner, Irrigation Suite and System Settings"),
            ftSafeText("ft_changelog_253_imp_3", "Soil app redesigned with cleaner per-field nutrient cards"),
        },
        behoben = {
            ftSafeText("ft_changelog_253_fix_1", "FieldSentry admin gate is now fail-closed, so it locks down when permissions are unclear"),
        },
    },
    {
        version = "2.5.1.0", date = "2026",
        neu = {
            ftSafeText("ft_changelog_251_new_1", "Favorites page for frequently used apps"),
            ftSafeText("ft_changelog_251_new_2", "Favorite app selection is saved per savegame"),
            ftSafeText("ft_changelog_251_new_3", "Clearer Home and Back buttons"),
            ftSafeText("ft_changelog_251_new_4", "App labels can be adjusted in settings"),
        },
        verbessert = {
            ftSafeText("ft_changelog_251_imp_1", "Reworked status bar with battery, signal and time"),
            ftSafeText("ft_changelog_251_imp_2", "App icons optimized and loaded more cleanly"),
            ftSafeText("ft_changelog_251_imp_3", "Worker list can be fully scrolled"),
        },
    },
    {
        version = "2.5.0.0", date = "2026",
        neu = {
            ftSafeText("ft_changelog_250_new_1", "New tablet start screen with lock screen"),
            ftSafeText("ft_changelog_250_new_2", "New app grid with dock and page indicator"),
            ftSafeText("ft_changelog_250_new_3", "Apps open with a clean tablet animation"),
            ftSafeText("ft_changelog_250_new_4", "Custom background via FTBackground folder"),
        },
        verbessert = {
            ftSafeText("ft_changelog_250_imp_1", "3D frame, screen glare and surface reworked"),
            ftSafeText("ft_changelog_250_imp_2", "Fullscreen apps with Home and Back bar"),
        },
    },
    {
        version = "2.4.0.0", date = "2026",
        neu = {
            ftSafeText("ft_changelog_240_new_1", "Personnel app for Pro Staff / Worker Costs"),
            ftSafeText("ft_changelog_240_new_2", "Worker list with sorting and filters"),
            ftSafeText("ft_changelog_240_new_3", "Hiring, dismissal and wage overview for staff"),
        },
        verbessert = {
            ftSafeText("ft_changelog_240_imp_1", "Multiplayer actions are synchronized through the host"),
        },
    },
    {
        version = "2.3.2.4", date = "2026",
        neu = { ftSafeText("ft_changelog_2324_new_1", "Worker Costs app now shows staff, hours, jobs and fatigue") },
        verbessert = { ftSafeText("ft_changelog_2324_imp_1", "Personnel area can be scrolled") },
    },
    {
        version = "2.3.2.3", date = "2026",
        behoben = {
            ftSafeText("ft_changelog_2323_fix_1", "Arrows and toggles react immediately"),
            ftSafeText("ft_changelog_2323_fix_2", "Production shows running processes correctly"),
            ftSafeText("ft_changelog_2323_fix_3", "Vehicle camera no longer zooms when scrolling in the tablet"),
        },
        verbessert = { ftSafeText("ft_changelog_2323_imp_1", "Soil values now match the HUD") },
    },
    {
        version = "2.2.0.0", date = "2026",
        neu = { ftSafeText("ft_changelog_220_new_1", "Ukrainian translation added") },
        verbessert = { ftSafeText("ft_changelog_220_imp_1", "Scroll help added for long app content") },
    },
    {
        version = "2.1.9.0", date = "2026",
        neu = { ftSafeText("ft_changelog_219_new_1", "Storage app saves historical best prices per savegame") },
        verbessert = { ftSafeText("ft_changelog_219_imp_1", "Price comparison sorts selling stations by best price") },
    },
    {
        version = "2.1.8.0", date = "2026",
        neu = {
            ftSafeText("ft_changelog_218_new_1", "Time controls with time jumps"),
            ftSafeText("ft_changelog_218_new_2", "Hotspot manager for map markers"),
            ftSafeText("ft_changelog_218_new_3", "Notes app with todo list"),
            ftSafeText("ft_changelog_218_new_4", "Farm Admin for money, time, repair and refuelling"),
        },
        behoben = { ftSafeText("ft_changelog_218_fix_1", "Tablet content updates regularly while open") },
    },
    {
        version = "2.1.7.0", date = "2026",
        neu = { ftSafeText("ft_changelog_217_new_1", "Storage app"), ftSafeText("ft_changelog_217_new_2", "Invoices app"), ftSafeText("ft_changelog_217_new_3", "UsedPlus integration"), ftSafeText("ft_changelog_217_new_4", "RoleplayPhone foundation") },
        behoben = { ftSafeText("ft_changelog_217_fix_1", "Camera and mouse remain locked correctly when the tablet is open") },
    },
    {
        version = "2.1.5.0", date = "2026",
        neu = { ftSafeText("ft_changelog_215_new_1", "Info area in settings") },
        behoben = { ftSafeText("ft_changelog_215_fix_1", "App Store and Updates can be fully scrolled") },
    },
    {
        version = "2.1.4.0", date = "2026",
        neu = { ftSafeText("ft_changelog_214_new_1", "Market Dynamics app"), ftSafeText("ft_changelog_214_new_2", "Worker Costs app"), ftSafeText("ft_changelog_214_new_3", "Random World Events app") },
        behoben = { ftSafeText("ft_changelog_214_fix_1", "Improved detection of other mods") },
    },
    {
        version = "2.1.3.0", date = "2025",
        neu = { ftSafeText("ft_changelog_213_new_1", "Colour selection for backgrounds") },
        behoben = { ftSafeText("ft_changelog_213_fix_1", "Missing translations in ZIP package"), ftSafeText("ft_changelog_213_fix_2", "Settings key alignment") },
    },
    {
        version = "2.1.2.0", date = "2025",
        neu = { ftSafeText("ft_changelog_212_new_1", "26 languages"), ftSafeText("ft_changelog_212_new_2", "Info icon per app"), ftSafeText("ft_changelog_212_new_3", "Multiplayer and dedicated server support") },
    },
    {
        version = "2.1.0.0", date = "2025",
        neu = { ftSafeText("ft_changelog_210_new_1", "Complete V2 rebuild"), ftSafeText("ft_changelog_210_new_2", "New interface"), ftSafeText("ft_changelog_210_new_3", "Central drawing functions"), ftSafeText("ft_changelog_210_new_4", "All apps reworked") },
    },
    {
        version = "1.1.2", date = "2024",
        neu = { ftSafeText("ft_changelog_112_new_1", "Soil Fertilizer, Seasonal Crop Stress and NPC Favor integration") },
        behoben = { ftSafeText("ft_changelog_112_fix_1", "Navigation buttons no longer overflow") },
    },
    {
        version = "1.0.0", date = "2024",
        neu = { ftSafeText("ft_changelog_100_new_1", "First release with dashboard, weather, fields, animals and workshop") },
    },
}

local function drawChangeGroup(ui, x, y, w, title, list, color)
    if list == nil or #list == 0 then return y end
    ui.r:appText(x, y, FT.FONT.SMALL, title, RenderText.ALIGN_LEFT, color)
    y = y - py(14)
    for _, text in ipairs(list) do
        ui.r:appText(x + px(10), y, FT.FONT.BODY, "• " .. tostring(text), RenderText.ALIGN_LEFT, col(FT.C.TEXT_NORMAL, {0.9,0.9,0.9,1}))
        y = y - py(13)
    end
    return y - py(4)
end

FarmTabletUI:registerDrawer(FT.APP.UPDATES, function(self)
    local AC = FT.appColor(FT.APP.UPDATES)

    if self:drawHelpPage("_updatesHelp", FT.APP.UPDATES, ftSafeText("ft_auto_updates", "Aktualisierungen"), AC, {
        { title = ftSafeText("ft_updates_help_history_title", "VERSION HISTORY"), body = ftSafeText("ft_updates_help_history_body", "Shows FarmTablet changes sorted by version.") },
        { title = ftSafeText("ft_updates_help_structure_title", "STRUCTURE"), body = ftSafeText("ft_updates_help_structure_body", "Each version is split into New, Improved and Fixed.") },
    }) then return end

    local scrollY  = self:getContentScrollY()
    local afterHdr = self:drawAppHeader(ftSafeText("ft_auto_updates", "Aktualisierungen"), ftSafeText("ft_updates_version_history", "Version history"))
    local x, _, cw, _ = self:contentInner()
    local y = afterHdr + scrollY

    for _, entry in ipairs(CHANGELOG) do
        local counts = 0
        counts = counts + ((entry.neu and #entry.neu or 0) + (entry.verbessert and #entry.verbessert or 0) + (entry.behoben and #entry.behoben or 0))
        local cardH = py(42 + counts * 15 + 28)
        self.r:appRect(x - px(4), y - cardH + py(6), cw + px(8), cardH, {0.11, 0.13, 0.16, 0.82})
        self.r:appRect(x - px(4), y - py(2), cw + px(8), py(2), {AC[1], AC[2], AC[3], 0.85})

        self.r:appText(x + px(8), y - py(14), FT.FONT.TITLE, ftSafeText("ft_updates_version", "Version") .. " " .. tostring(entry.version), RenderText.ALIGN_LEFT, col(FT.C.TEXT_BRIGHT, {1,1,1,1}))
        self.r:appText(x + cw - px(8), y - py(14), FT.FONT.SMALL, tostring(entry.date or ""), RenderText.ALIGN_RIGHT, col(FT.C.TEXT_DIM, {0.75,0.75,0.75,1}))
        y = y - py(34)

        y = drawChangeGroup(self, x + px(14), y, cw - px(28), ftSafeText("ft_updates_new", "New"), entry.neu, col(FT.C.BRAND, FT.C.TEXT_ACCENT))
        y = drawChangeGroup(self, x + px(14), y, cw - px(28), ftSafeText("ft_updates_improved", "Improved"), entry.verbessert, col(FT.C.POSITIVE, FT.C.TEXT_ACCENT))
        y = drawChangeGroup(self, x + px(14), y, cw - px(28), ftSafeText("ft_updates_fixed", "Fixed"), entry.behoben, col(FT.C.WARNING, FT.C.TEXT_ACCENT))
        y = y - py(12)
    end

    self:setContentHeight(math.max(0, afterHdr - y + scrollY + py(120)))
    self:drawInfoIcon("_updatesHelp", AC)
    self:drawScrollBar()
end)
