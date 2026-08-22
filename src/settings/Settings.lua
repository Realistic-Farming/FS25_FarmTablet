-- =========================================================
-- FarmTablet v2 – Settings
-- Value object that holds all user preferences.
-- Loaded/saved via SettingsManager; validated on every load.
-- =========================================================
---@class Settings

Settings = Settings or {}
local Settings_mt = Class(Settings)

-- Startup app migration helper
local STARTUP_MAP = {
    [1] = "dashboard",
    [2] = "app_store",
    [3] = "weather",
    [4] = "excavator",
}

function Settings.new(manager)
    local self = setmetatable({}, Settings_mt)
    self.manager = manager
    
    self:resetToDefaults(false)
    
    Logging.info("Farm Tablet: Settings initialized")
    
    return self
end

function Settings:resetToDefaults(saveImmediately)
    saveImmediately = saveImmediately ~= false

    self.enabled                 = true
    self.tabletKeybind           = "T"
    self.showTabletNotifications = true
    self.startupApp              = "dashboard"
    self.vibrationFeedback       = true
    self.soundEffects            = true
    self.soundOnAppSelect        = true   -- sound when clicking a sidebar app
    self.soundOnHelpOpen         = true   -- sound when help panel opens/closes
    self.soundOnTabletToggle     = true   -- sound when tablet opens or closes
    self.lockScreenEnabled       = true   -- show lock screen (slide to unlock) on open
    self.customBackground        = ""     -- PNG filename in savegame/FTBackground (empty = default wallpaper)
    self.debugMode               = false
    self.tabletBatteryLevel      = 100
    self.tabletBatteryDrainMs    = 0
    self.tabletBatteryDrainEnabled = true
    self.tabletBatteryDrainMode    = "standby"  -- off/open/standby
    self.tabletBatteryDrainProfile = "normal"   -- low/normal/high/custom
    self.tabletBatteryOpenMinutes  = 10
    self.tabletBatteryStandbyMinutes = 15

    -- HUD / tablet window position and scale (saved across sessions)
    self.tabletPosX              = 0.503646   -- normalized, centre-anchored
    self.tabletPosY              = 0.519491
    self.tabletScale             = 1.607672   -- multiplier (0.5 – 2.0)
    self.tabletWidthMult         = 1.0   -- independent width stretch (0.5 – 2.0)
    self.contentFontScale        = 1.0   -- app text size multiplier (0.8 / 1.0 / 1.25 / 1.5)
    self.tabletBgColorIndex      = 1     -- index into FT.BG_PALETTE (1 = Deep Space)

    -- Dashboard widget visibility (comma-separated widget IDs)
    self.dashWidgets = "balance,loan,income,expenses,net_pl,fields,vehicles,season,day,time,weather"

    -- Favourite apps shown on the springboard's star/favourites page
    -- (comma-separated app IDs). Seeded with the default dock apps.
    self.favoriteApps = "dashboard,weather,app_store,settings"

    -- App-icon label appearance on the springboard
    self.iconLabelsShow = true   -- draw the text label under each icon
    self.iconLabelSize  = 2      -- 1 = small, 2 = medium, 3 = large
    self.iconLabelColor = 1      -- 1 = white, 2 = gold, 3 = app accent

    if saveImmediately then
        self:save()
        Logging.info("Farm Tablet: Settings reset to defaults")
    end
end

function Settings:getStartupAppName()
    return string.upper(tostring(self.startupApp or "dashboard"))
end

function Settings:load()
    self.manager:loadSettings(self)
    self:validateSettings()
    
    Logging.info("Farm Tablet: Settings Loaded. Enabled: %s, Key: %s, Startup: %s", 
        tostring(self.enabled), self.tabletKeybind, self:getStartupAppName())
end

function Settings:validateSettings()
    -- Migration: if startupApp is a number, convert to ID
    if type(self.startupApp) == "number" then
        self.startupApp = STARTUP_MAP[self.startupApp] or "dashboard"
    end

    -- Digging + Bucket Tracker merged into Excavator
    if self.startupApp == "digging" or self.startupApp == "bucket_tracker" then
        self.startupApp = "excavator"
    end

    -- Ensure startup app is valid
    if self.startupApp == nil or self.startupApp == "" then
        self.startupApp = "dashboard"
    end

    -- Migrate favourites that still reference the old app ids
    if type(self.favoriteApps) == "string" then
        local seen, out = {}, {}
        for id in string.gmatch(self.favoriteApps, "([^,]+)") do
            id = id:gsub("^%s+", ""):gsub("%s+$", "")
            if id == "digging" or id == "bucket_tracker" then
                id = "excavator"
            end
            if id ~= "" and not seen[id] then
                seen[id] = true
                out[#out + 1] = id
            end
        end
        self.favoriteApps = table.concat(out, ",")
    end
    
    -- Ensure keybind is valid
    if self.tabletKeybind == nil or self.tabletKeybind == "" then
        self.tabletKeybind = "T"
    end
    
    -- Boolean validation
    self.enabled                 = not not self.enabled
    self.debugMode               = not not self.debugMode
    self.showTabletNotifications = not not self.showTabletNotifications
    self.soundEffects            = not not self.soundEffects
    self.soundOnAppSelect        = self.soundOnAppSelect    == nil and true or not not self.soundOnAppSelect
    self.soundOnHelpOpen         = self.soundOnHelpOpen     == nil and true or not not self.soundOnHelpOpen
    self.soundOnTabletToggle     = self.soundOnTabletToggle == nil and true or not not self.soundOnTabletToggle
    self.vibrationFeedback       = not not self.vibrationFeedback
    self.lockScreenEnabled       = self.lockScreenEnabled == nil and true or not not self.lockScreenEnabled
    if type(self.customBackground) ~= "string" then self.customBackground = "" end

    -- Numeric range clamping
    self.tabletScale         = math.max(0.5, math.min(2.0, self.tabletScale         or 1.0))
    self.tabletWidthMult     = math.max(0.5, math.min(2.0, self.tabletWidthMult     or 1.0))
    self.contentFontScale    = math.max(0.8, math.min(1.5, self.contentFontScale    or 1.0))
    self.tabletPosX          = math.max(0.0, math.min(1.0, self.tabletPosX          or 0.5))
    self.tabletPosY          = math.max(0.0, math.min(1.0, self.tabletPosY          or 0.5))
    self.tabletBgColorIndex  = math.max(1, math.floor(self.tabletBgColorIndex or 1))

    -- Dashboard widgets: ensure it's a non-empty string
    if type(self.dashWidgets) ~= "string" or self.dashWidgets == "" then
        self.dashWidgets = "balance,loan,income,expenses,net_pl,fields,vehicles,season,day,time,weather"
    end

    -- Favourites: may be empty (user cleared them); just guarantee a string.
    if type(self.favoriteApps) ~= "string" then
        self.favoriteApps = "dashboard,weather,app_store,settings"
    end

    -- Icon labels: guarantee a boolean + clamp the size/colour indices.
    if type(self.iconLabelsShow) ~= "boolean" then self.iconLabelsShow = true end
    self.iconLabelSize  = math.max(1, math.min(3, math.floor(self.iconLabelSize  or 2)))
    self.iconLabelColor = math.max(1, math.min(3, math.floor(self.iconLabelColor or 1)))

    -- Tablet battery is saved per savegame. Clamp strictly so old/broken XML values
    -- cannot make the UI stay at 100% or jump to invalid states.
    self.tabletBatteryLevel   = math.max(0, math.min(100, math.floor(tonumber(self.tabletBatteryLevel) or 100)))
    self.tabletBatteryDrainMs = math.max(0, tonumber(self.tabletBatteryDrainMs) or 0)
    self.tabletBatteryDrainEnabled = self.tabletBatteryDrainEnabled == nil and true or not not self.tabletBatteryDrainEnabled
    if self.tabletBatteryDrainEnabled == false then
        self.tabletBatteryDrainMode = "off"
    end
    local mode = tostring(self.tabletBatteryDrainMode or "standby")
    if mode ~= "off" and mode ~= "open" and mode ~= "standby" then mode = "standby" end
    self.tabletBatteryDrainMode = mode
    local profile = tostring(self.tabletBatteryDrainProfile or "normal")
    if profile ~= "low" and profile ~= "normal" and profile ~= "high" and profile ~= "custom" then profile = "normal" end
    self.tabletBatteryDrainProfile = profile
    self.tabletBatteryOpenMinutes = math.max(5, math.min(60, math.floor(tonumber(self.tabletBatteryOpenMinutes) or 10)))
    self.tabletBatteryStandbyMinutes = math.max(5, math.min(180, math.floor(tonumber(self.tabletBatteryStandbyMinutes) or 15)))
    self.tabletBatteryDrainEnabled = (self.tabletBatteryDrainMode ~= "off")
end

function Settings:save(silent)
    self.manager:saveSettings(self)
    -- Kein Log-Spam mehr: das Speichern passiert auch automatisch durch Akku-,
    -- UI- und Hintergrundwerte. Diese Routine schreibt nur die XML.
end

function Settings:setStartupApp(appId)
    if appId and appId ~= "" then
        self.startupApp = tostring(appId)
        Logging.info("Farm Tablet: Startup app changed to: %s", self:getStartupAppName())
    end
end

function Settings:setKeybind(key)
    if key and key ~= "" then
        self.tabletKeybind = key
        Logging.info("Farm Tablet: Keybind changed to: %s", key)
    end
end