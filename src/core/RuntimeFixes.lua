-- =========================================================
-- FarmTablet v2.5.2.9 - final polish pass
-- - no mixed German/English/Russian leftovers in rendered labels
-- - faster, smoother content scrolling
-- - last UI text fallbacks translated at render time
-- Logic is UI-only and does not touch savegame gameplay data.
-- =========================================================
FT = FT or {}
FT.VERSION = "2.5.2.9"

local function ftLang()
    local lang = ""
    if g_languageShort ~= nil then lang = tostring(g_languageShort) end
    if (lang == "" or lang == "nil") and g_i18n ~= nil then
        lang = tostring(g_i18n.languageShort or g_i18n.currentLanguage or g_i18n.language or "")
    end
    lang = string.lower(lang)
    if lang:sub(1,2) == "de" or lang == "ger" or lang == "deutsch" then return "de" end
    if lang:sub(1,2) == "ru" or lang == "russian" then return "ru" end
    return lang
end

local DE = {
    -- settings / network / battery leftovers
    ["Battery drain"]="Akkuverbrauch", ["Controls when the tablet battery drains."]="Legt fest, wann der Tablet-Akku verbraucht wird.",
    ["Battery profile"]="Akku-Profil", ["Low, normal, high or custom drain speed."]="Niedrig, normal, hoch oder eigene Verbrauchswerte.",
    ["Always incl. standby"]="Immer inkl. Standby", ["Only while open"]="Nur wenn geöffnet", ["Off"]="Aus", ["On"]="An",
    ["Low"]="Niedrig", ["Normal"]="Normal", ["High"]="Hoch", ["Custom"]="Benutzerdefiniert",
    ["Change"]="Ändern", ["Toggle"]="Umschalten", ["Switch"]="Wechseln", ["Open"]="Öffnen", ["Open list"]="Liste öffnen",
    ["Daily fee"]="Grundgebühr", ["Provider"]="Anbieter", ["Network outages"]="Netzstörungen", ["Outage duration"]="Störungsdauer",
    ["Duration in ingame hours."]="Dauer in Spielstunden.", ["Display damage"]="Displayschaden", ["Random tablet damage from falling."]="Zufälliger Tabletschaden durch Sturz.",
    ["Provider selection"]="Anbieterauswahl", ["Opens the provider selection."]="Öffnet die Anbieterauswahl.",
    ["Switches to the next mobile provider."]="Wechselt zum nächsten Mobilfunkanbieter.",
    ["Off / Rare / Normal / Often"]="Aus / Selten / Normal / Häufig", ["Rare"]="Selten", ["Often"]="Häufig", ["Frequent"]="Häufig",
    ["Very good (4/4)"]="Sehr gut (4/4)", ["Reception"]="Empfang",

    -- changelog
    ["Favorites page for frequently used apps"]="Favoriten-Seite für häufig genutzte Apps",
    ["Favorite app selection is saved per savegame"]="App-Auswahl der Favoriten wird pro Spielstand gespeichert",
    ["Clearer Home and Back buttons"]="Klarere Home- und Zurück-Schaltflächen",
    ["App labels can be adjusted in settings"]="App-Beschriftungen können in den Einstellungen angepasst werden",
    ["Reworked status bar with battery, signal and time"]="Statusleiste mit Akku, Signal und Uhrzeit überarbeitet",
    ["App icons optimized and loaded more cleanly"]="App-Symbole optimiert und sauberer geladen",
    ["Worker list can be fully scrolled"]="Mitarbeiterliste kann vollständig gescrollt werden",
    ["New tablet start screen with lock screen"]="Neuer Tablet-Startbildschirm mit Sperrbildschirm",
    ["New app grid with dock and page indicator"]="Neues App-Raster mit Dock und Seitenanzeige",
    ["Apps open with a clean tablet animation"]="Apps öffnen mit sauberer Tablet-Animation",
    ["Custom background via FTBackground folder"]="Eigener Hintergrund über den FTBackground-Ordner",
    ["3D frame, screen glare and surface reworked"]="3D-Rahmen, Bildschirmglanz und Oberfläche überarbeitet",
    ["Fullscreen apps with Home and Back bar"]="Vollbild-Apps mit Home- und Zurück-Leiste",
    ["Personnel app for Pro Staff / Worker Costs"]="Personal-App für Pro Staff / Worker Costs",
    ["Worker list with sorting and filters"]="Mitarbeiterliste mit Sortierung und Filtern",
    ["Hiring, dismissal and wage overview for staff"]="Einstellung, Entlassung und Lohnübersicht für Personal",
    ["Version history"]="Versionsverlauf", ["Version"]="Version", ["New"]="Neu", ["Improved"]="Verbessert", ["Fixed"]="Behoben",

    -- app store / common rows
    ["App Store"]="App Store", ["25 installed"]="25 installiert", ["installed"]="installiert", ["not installed"]="nicht installiert",
    ["Integrated"]="Integriert", ["Built-in"]="Eingebaut", ["BUILT-IN"]="EINGEBAUT", ["FARMING"]="LANDWIRTSCHAFT", ["MOD INTEGRATIONS"]="MOD-INTEGRATIONEN",
    ["OPEN"]="ÖFFNEN", ["Install FS25_SoilFertilizer to enable"]="Installiere FS25_SoilFertilizer, um es zu aktivieren",
    ["Install FS25_MarketDynamics to enable"]="Installiere FS25_MarketDynamics, um es zu aktivieren",
    ["Install FS25_WorkerCosts to enable"]="Installiere FS25_WorkerCosts, um es zu aktivieren",
    ["Install FS25_RandomWorldEvents to enable"]="Installiere FS25_RandomWorldEvents, um es zu aktivieren",
    ["Install FS25_UsedPlus to enable"]="Installiere FS25_UsedPlus, um es zu aktivieren",

    -- apps / headers
    ["Dashboard"]="Übersicht", ["Farm Stats"]="Hofstatistik", ["Fleet Manager"]="Flottenmanager", ["Field Jobs"]="Feldarbeiten",
    ["Production"]="Produktion", ["Storage"]="Lager", ["Bucket Tracker"]="Schaufelzähler", ["Time Controls"]="Zeitsteuerung",
    ["Notes"]="Notizen", ["Farm Admin"]="Hof-Admin", ["Weather"]="Wetter", ["Workshop"]="Werkstatt", ["Animals"]="Tiere",
    ["AnimalAutoCare"]="Tier-AutoCare", ["Animal Vet"]="Tierarzt", ["Factory Week"]="Fabrik-Woche", ["Factory Week Schedule"]="Fabrik-Wochenplan",
    ["connected"]="verbunden", ["Connected"]="Verbunden", ["Available"]="Verfügbar", ["no active job"]="kein aktiver Auftrag",
    ["No job running"]="Kein Auftrag aktiv", ["START JOB"]="ARBEIT STARTEN", ["Recent Jobs"]="Letzte Arbeiten",
    ["No completed jobs yet."]="Noch keine abgeschlossenen Arbeiten.", ["No active job."]="Kein Auftrag aktiv.",
    ["ACTIVE VEHICLE"]="AKTIVES FAHRZEUG", ["LOADS"]="LADUNGEN", ["WEIGHT"]="GEWICHT", ["ITEMS"]="EINTRÄGE",
    ["LOAD HISTORY"]="LADEVERLAUF", ["No bucket vehicle detected nearby."]="Kein Schaufel-/Laderfahrzeug in der Nähe erkannt.", ["No loads recorded yet."]="Noch keine Ladungen aufgezeichnet.",
    ["INVENTORY"]="BESTAND", ["Silos are empty"]="Silos sind leer", ["BEST SELL PRICES (per 1,000 L)"]="BESTE VERKAUFSPREISE (pro 1.000 L)",
    ["No sell price data found"]="Keine Verkaufspreisdaten gefunden", ["PRICE COMPARISON (all stations)"]="PREISVERGLEICH (alle Stationen)",
    ["Single station — no comparison available"]="Nur eine Station – kein Vergleich verfügbar",
    ["TIME SCALE"]="ZEITSKALIERUNG", ["SKIP TO"]="SPRINGEN ZU", ["MIDNIGHT"]="MITTERNACHT", ["6 AM"]="6 UHR", ["12 PM"]="12 UHR", ["6 PM"]="18 UHR",
    ["NEW TODO"]="NEUE AUFGABE", ["TODO LIST"]="AUFGABENLISTE", ["+ ADD TODO"]="+ AUFGABE HINZUFÜGEN", ["No todos yet — add one above"]="Noch keine Aufgaben – oben eine hinzufügen", ["All done!"]="Alles erledigt!",
    ["MONEY"]="GELD", ["VEHICLES"]="FAHRZEUGE", ["REPAIR ALL"]="ALLE REPARIEREN", ["FILL FUEL"]="KRAFTSTOFF FÜLLEN",
    ["FINANCES"]="FINANZEN", ["Balance"]="Kontostand", ["Net Worth"]="Nettovermögen", ["Income"]="Einnahmen", ["Expenses"]="Ausgaben",
    ["FARM TOTALS"]="HOF-GESAMT", ["Fields"]="Felder", ["Area"]="Fläche", ["Vehicles"]="Fahrzeuge", ["Animal Pens"]="Tierställe",
    ["WORLD"]="WELT", ["Day"]="Tag", ["Season"]="Jahreszeit", ["Time"]="Zeit", ["Autumn"]="Herbst", ["Clear"]="Klar",
    ["Overall"]="Gesamt", ["Food"]="Futter", ["Water"]="Wasser", ["Straw"]="Stroh", ["Purchase Cost"]="Kosten Kauf", ["Care Cost"]="Kosten Pflege",
    ["Care Now"]="Jetzt versorgen", ["LAST ACTION"]="LETZTE AKTION", ["Last action"]="Letzte Aktion", ["Veterinarian"]="Tierarzt", ["Active Illnesses"]="Aktive Krankheiten",

    -- production/details
    ["INPUTS"]="EINGÄNGE", ["OUTPUTS"]="AUSGÄNGE", ["stalled"]="steht", ["No event"]="Kein Ereignis",
    ["Sun energy"]="Sonnenenergie", ["Electric charge"]="Elektrische Ladung", ["Silage"]="Silage", ["Hay"]="Heu", ["Stones"]="Steine", ["Sugar beet cut"]="Zuckerrübenschnitzel",
    ["Wheat"]="Weizen", ["Grass"]="Gras", ["Straw"]="Stroh", ["Water"]="Wasser", ["Sugar beet"]="Zuckerrüben",

    -- descriptions/help shown below app names
    ["Hofübersicht: Geld, Felder, Fahrzeuge, >"]="Hofübersicht: Geld, Felder, Fahrzeuge, >",
    ["Installed apps and updates"]="Installierte Apps und Updates", ["Changelog and update history"]="Änderungs- und Updateverlauf",
    ["FarmTablet settings"]="Tablet-Einstellungen", ["Current conditions and forecast"]="Aktuelles Wetter und Vorhersage",
    ["All owned fields with crop and growth state"]="Alle eigenen Felder mit Frucht- und Wachstumsstatus",
    ["Animal pens — food, water, cleanliness"]="Tierställe – Futter, Wasser, Sauberkeit",
    ["Nearby vehicle diagnostics"]="Fahrzeugdiagnose in der Nähe", ["Excavation tracking and soil scanner"]="Grabungsdaten und Bodenscanner",
    ["Bucket/loader load counter"]="Schaufel-/Lader-Ladungszähler", ["Silo inventory and current sell prices"]="Silobestand und aktuelle Verkaufspreise",
    ["Set time scale and skip to a time of day"]="Zeitskalierung ändern und zur Uhrzeit springen", ["Admin controls: money, time, vehicle repair/fuel"]="Admin-Steuerung: Geld, Zeit, Reparatur/Kraftstoff",
}

local RU = {
    ["Battery drain"]="Расход батареи", ["Controls when the tablet battery drains."]="Определяет, когда расходуется батарея планшета.",
    ["Battery profile"]="Профиль батареи", ["Low, normal, high or custom drain speed."]="Низкий, нормальный, высокий или пользовательский расход.",
    ["Always incl. standby"]="Всегда, включая ожидание", ["Only while open"]="Только при открытии", ["Off"]="Выкл.", ["On"]="Вкл.",
    ["Change"]="Изменить", ["Switch"]="Переключить", ["Open"]="Открыть", ["Open list"]="Открыть список",
    ["App Store"]="Магазин приложений", ["Settings"]="Настройки", ["Dashboard"]="Панель управления", ["Weather"]="Погода", ["Animals"]="Животные",
    ["Storage"]="Склад", ["Production"]="Производство", ["Farm Stats"]="Статистика фермы", ["Field Jobs"]="Полевые работы",
    ["Fleet Manager"]="Управление флотом", ["Bucket Tracker"]="Трекер ковша", ["Notes"]="Заметки", ["Farm Admin"]="Админ фермы",
    ["OPEN"]="ОТКРЫТЬ", ["Installed"]="Установлено", ["installed"]="установлено", ["not installed"]="не установлено", ["Integrated"]="Интегрировано", ["Built-in"]="Встроено",
    ["INPUTS"]="ВХОДЫ", ["OUTPUTS"]="ВЫХОДЫ", ["stalled"]="стоит", ["No event"]="Нет событий", ["Connected"]="Подключено",
    ["New"]="Новое", ["Improved"]="Улучшено", ["Fixed"]="Исправлено", ["Version history"]="История версий",
    ["No job running"]="Нет активной работы", ["START JOB"]="НАЧАТЬ РАБОТУ", ["No completed jobs yet."]="Завершённых работ пока нет.",
}

local function trLiteral(raw)
    local lang = ftLang()
    local map = (lang == "de" and DE) or (lang == "ru" and RU) or nil
    if map == nil then return raw end
    if map[raw] ~= nil then return map[raw] end
    local out = raw
    -- preserve bullets and translate the visible phrase after it
    local bullet, rest = out:match("^(%s*[%-%•]%s*)(.+)$")
    if bullet and map[rest] then return bullet .. map[rest] end
    if lang == "de" then
        out = out:gsub("(%d+)%s+installed", "%1 installiert")
        out = out:gsub("(%d+)%s+vehicles", "%1 Fahrzeuge"):gsub("(%d+)%s+Fahrzeuge", "%1 Fahrzeuge")
        out = out:gsub("(%d+)%s+buildings", "%1 Gebäude"):gsub("(%d+)%s+Gebäude", "%1 Gebäude")
        out = out:gsub("(%d+)%s+fields", "%1 Felder"):gsub("(%d+)%s+pens", "%1 Ställe")
        out = out:gsub("(%d+)%s+owned", "%1 im Besitz")
        out = out:gsub("(%d+)%s+active", "%1 aktiv"):gsub("(%d+)%s+pending", "%1 offen"):gsub("(%d+)%s+done", "%1 erledigt")
        out = out:gsub("no active job", "kein aktiver Auftrag"):gsub("none active", "keine aktiv")
        out = out:gsub("Day%s+(%d+)", "Tag %1")
        out = out:gsub("Autumn", "Herbst"):gsub("Spring", "Frühling"):gsub("Summer", "Sommer"):gsub("Winter", "Winter")
        out = out:gsub("Clear", "Klar"):gsub("Warm", "Warm")
        out = out:gsub("KRAFTSTAUS", "KRAFTSTOFF")
        out = out:gsub("width", "Breite")
    elseif lang == "ru" then
        out = out:gsub("(%d+)%s+installed", "%1 установлено")
        out = out:gsub("(%d+)%s+vehicles", "%1 машин"):gsub("(%d+)%s+fields", "%1 полей")
        out = out:gsub("Day%s+(%d+)", "День %1")
        out = out:gsub("Autumn", "Осень"):gsub("Spring", "Весна"):gsub("Summer", "Лето"):gsub("Winter", "Зима")
    end
    if map[out] ~= nil then return map[out] end
    return out
end

local _prevL10n = FT.l10n
function FT.l10n(key, fallback)
    if g_i18n ~= nil and key ~= nil and g_i18n.hasText ~= nil and g_i18n:hasText(key) then
        local text = g_i18n:getText(key)
        if text ~= nil and text ~= "" and text ~= tostring(key) then return text end
    end
    local lang = ftLang()
    local map = (lang == "de" and DE) or (lang == "ru" and RU) or nil
    if map ~= nil then
        local k = tostring(key or "")
        if map[k] ~= nil then return map[k] end
        if fallback ~= nil then return trLiteral(tostring(fallback)) end
    end
    return _prevL10n ~= nil and _prevL10n(key, fallback) or (fallback or tostring(key or ""))
end

local _prevAuto = FT.l10nAuto
function FT.l10nAuto(text)
    if text == nil then return "" end
    local raw = tostring(text)
    if raw == "" then return raw end
    local lang = ftLang()
    local prev = _prevAuto ~= nil and _prevAuto(raw) or raw
    if lang == "de" or lang == "ru" then
        local direct = trLiteral(raw)
        if direct ~= raw then return direct end
        local second = trLiteral(prev)
        if second ~= prev then return second end
    end
    return prev
end

-- Make app scrolling noticeably faster.  This is intentionally applied after all
-- app code is loaded so every app uses the same clean scroll feel.
if FarmTabletUI ~= nil then
    local oldSetContentHeight = FarmTabletUI.setContentHeight
    function FarmTabletUI:setContentHeight(totalH)
        if oldSetContentHeight ~= nil then oldSetContentHeight(self, totalH) end
        self._contentScrollStep = FT.py(145)
    end
end
