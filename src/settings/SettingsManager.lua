-- =========================================================
-- FarmTablet v2 – SettingsManager
-- Handles XML serialisation of Settings to/from the
-- per-savegame config file (modName.xml in savegame dir).
-- =========================================================
---@class SettingsManager
SettingsManager = {}
local SettingsManager_mt = Class(SettingsManager)

SettingsManager.MOD_NAME = g_currentModName
SettingsManager.XMLTAG = "FarmTablet"

SettingsManager.defaultConfig = {
    enabled = true,
    tabletKeybind = "T",
    showTabletNotifications = true,
    startupApp = "dashboard",  -- stored as string ID (see Settings.lua FT.APP constants)
    vibrationFeedback = true,
    soundEffects = true,
    debugMode = false,
    tabletBatteryLevel = 100,
    tabletBatteryDrainMs = 0,
    tabletBatteryDrainEnabled = true,
    tabletBatteryDrainMode = "standby",
    tabletBatteryDrainProfile = "normal",
    tabletBatteryOpenMinutes = 15,
    tabletBatteryStandbyMinutes = 60
}

function SettingsManager.new()
    return setmetatable({}, SettingsManager_mt)
end

function SettingsManager:getSavegameXmlFilePath()
    if g_currentMission == nil or g_currentMission.missionInfo == nil then
        return nil
    end
    if g_currentMission.missionInfo.savegameDirectory then
        return ("%s/%s.xml"):format(g_currentMission.missionInfo.savegameDirectory, SettingsManager.MOD_NAME)
    end
    return nil
end

function SettingsManager:loadSettings(settingsObject)
    local xmlPath = self:getSavegameXmlFilePath()
    if xmlPath and fileExists(xmlPath) then
        local xml = XMLFile.load("ft_Config", xmlPath)
        if xml then
            settingsObject.enabled                 = xml:getBool(self.XMLTAG..".enabled",                 self.defaultConfig.enabled)
            settingsObject.tabletKeybind           = xml:getString(self.XMLTAG..".tabletKeybind",         self.defaultConfig.tabletKeybind)
            settingsObject.showTabletNotifications = xml:getBool(self.XMLTAG..".showTabletNotifications", self.defaultConfig.showTabletNotifications)
            -- Load as string; fall back to getInt for legacy saves that stored a numeric index.
            local savedApp = xml:getString(self.XMLTAG..".startupApp", "")
            if savedApp ~= nil and savedApp ~= "" then
                settingsObject.startupApp = savedApp
            else
                local legacyIdx = xml:getInt(self.XMLTAG..".startupApp", 0)
                settingsObject.startupApp = legacyIdx > 0 and legacyIdx or self.defaultConfig.startupApp
            end
            settingsObject.vibrationFeedback       = xml:getBool(self.XMLTAG..".vibrationFeedback",       self.defaultConfig.vibrationFeedback)
            settingsObject.soundEffects            = xml:getBool(self.XMLTAG..".soundEffects",            self.defaultConfig.soundEffects)
            settingsObject.soundOnAppSelect        = xml:getBool(self.XMLTAG..".soundOnAppSelect",        true)
            settingsObject.soundOnHelpOpen         = xml:getBool(self.XMLTAG..".soundOnHelpOpen",         true)
            settingsObject.soundOnTabletToggle     = xml:getBool(self.XMLTAG..".soundOnTabletToggle",     true)
            settingsObject.lockScreenEnabled       = xml:getBool(self.XMLTAG..".lockScreenEnabled",       true)
            settingsObject.customBackground        = xml:getString(self.XMLTAG..".customBackground",      "")
            settingsObject.debugMode               = xml:getBool(self.XMLTAG..".debugMode",               self.defaultConfig.debugMode)
            settingsObject.tabletBatteryLevel      = xml:getFloat(self.XMLTAG..".tabletBatteryLevel",      self.defaultConfig.tabletBatteryLevel)
            settingsObject.tabletBatteryDrainMs    = xml:getFloat(self.XMLTAG..".tabletBatteryDrainMs",    self.defaultConfig.tabletBatteryDrainMs)
            settingsObject.tabletBatteryDrainEnabled = xml:getBool(self.XMLTAG..".tabletBatteryDrainEnabled", self.defaultConfig.tabletBatteryDrainEnabled)
            settingsObject.tabletBatteryDrainMode    = xml:getString(self.XMLTAG..".tabletBatteryDrainMode", self.defaultConfig.tabletBatteryDrainMode)
            settingsObject.tabletBatteryDrainProfile = xml:getString(self.XMLTAG..".tabletBatteryDrainProfile", self.defaultConfig.tabletBatteryDrainProfile)
            settingsObject.tabletBatteryOpenMinutes  = xml:getInt(self.XMLTAG..".tabletBatteryOpenMinutes", self.defaultConfig.tabletBatteryOpenMinutes)
            settingsObject.tabletBatteryStandbyMinutes = xml:getInt(self.XMLTAG..".tabletBatteryStandbyMinutes", self.defaultConfig.tabletBatteryStandbyMinutes)
            settingsObject.tabletPosX              = xml:getFloat(self.XMLTAG..".tabletPosX",             0.5)
            settingsObject.tabletPosY              = xml:getFloat(self.XMLTAG..".tabletPosY",             0.5)
            settingsObject.tabletScale             = xml:getFloat(self.XMLTAG..".tabletScale",            1.0)
            settingsObject.tabletWidthMult         = xml:getFloat(self.XMLTAG..".tabletWidthMult",        1.0)
            settingsObject.contentFontScale        = xml:getFloat(self.XMLTAG..".contentFontScale",       1.0)
            settingsObject.tabletBgColorIndex      = xml:getInt(self.XMLTAG..".tabletBgColorIndex",       1)
            settingsObject.dashWidgets             = xml:getString(self.XMLTAG..".dashWidgets",
                "balance,loan,income,expenses,net_pl,fields,vehicles,season,day,time,weather")
            -- Favourites: "__none__" sentinel preserves a deliberately empty list
            local favStr = xml:getString(self.XMLTAG..".favoriteApps",
                "dashboard,weather,app_store,settings")
            if favStr == "__none__" then favStr = "" end
            settingsObject.favoriteApps            = favStr
            -- App-icon label appearance
            settingsObject.iconLabelsShow          = xml:getBool(self.XMLTAG..".iconLabelsShow", true)
            settingsObject.iconLabelSize           = xml:getInt(self.XMLTAG..".iconLabelSize",  2)
            settingsObject.iconLabelColor          = xml:getInt(self.XMLTAG..".iconLabelColor", 1)
            xml:delete()
            return
        end
    end
    settingsObject.enabled = self.defaultConfig.enabled
    settingsObject.tabletKeybind = self.defaultConfig.tabletKeybind
    settingsObject.showTabletNotifications = self.defaultConfig.showTabletNotifications
    settingsObject.startupApp = self.defaultConfig.startupApp  -- string ID
    settingsObject.vibrationFeedback = self.defaultConfig.vibrationFeedback
    settingsObject.soundEffects = self.defaultConfig.soundEffects
    settingsObject.debugMode = self.defaultConfig.debugMode
    settingsObject.tabletBatteryLevel = self.defaultConfig.tabletBatteryLevel
    settingsObject.tabletBatteryDrainMs = self.defaultConfig.tabletBatteryDrainMs
    settingsObject.tabletBatteryDrainEnabled = self.defaultConfig.tabletBatteryDrainEnabled
    settingsObject.tabletBatteryDrainMode = self.defaultConfig.tabletBatteryDrainMode
    settingsObject.tabletBatteryDrainProfile = self.defaultConfig.tabletBatteryDrainProfile
    settingsObject.tabletBatteryOpenMinutes = self.defaultConfig.tabletBatteryOpenMinutes
    settingsObject.tabletBatteryStandbyMinutes = self.defaultConfig.tabletBatteryStandbyMinutes
    settingsObject.tabletBgColorIndex = 1
end

function SettingsManager:saveSettings(settingsObject)
    local xmlPath = self:getSavegameXmlFilePath()
    if not xmlPath then return end
    
    local xml = XMLFile.create("ft_Config", xmlPath, self.XMLTAG)
    if xml then
        xml:setBool(self.XMLTAG..".enabled",                 settingsObject.enabled)
        xml:setString(self.XMLTAG..".tabletKeybind",         settingsObject.tabletKeybind)
        xml:setBool(self.XMLTAG..".showTabletNotifications", settingsObject.showTabletNotifications)
        xml:setString(self.XMLTAG..".startupApp",            tostring(settingsObject.startupApp or "dashboard"))
        xml:setBool(self.XMLTAG..".vibrationFeedback",       settingsObject.vibrationFeedback)
        xml:setBool(self.XMLTAG..".soundEffects",            settingsObject.soundEffects)
        xml:setBool(self.XMLTAG..".soundOnAppSelect",        settingsObject.soundOnAppSelect)
        xml:setBool(self.XMLTAG..".soundOnHelpOpen",         settingsObject.soundOnHelpOpen)
        xml:setBool(self.XMLTAG..".soundOnTabletToggle",     settingsObject.soundOnTabletToggle)
        xml:setBool(self.XMLTAG..".lockScreenEnabled",       settingsObject.lockScreenEnabled)
        xml:setString(self.XMLTAG..".customBackground",      settingsObject.customBackground or "")
        xml:setBool(self.XMLTAG..".debugMode",               settingsObject.debugMode)
        xml:setFloat(self.XMLTAG..".tabletBatteryLevel",      tonumber(settingsObject.tabletBatteryLevel) or 100)
        xml:setFloat(self.XMLTAG..".tabletBatteryDrainMs",    tonumber(settingsObject.tabletBatteryDrainMs) or 0)
        xml:setBool(self.XMLTAG..".tabletBatteryDrainEnabled", settingsObject.tabletBatteryDrainEnabled ~= false)
        xml:setString(self.XMLTAG..".tabletBatteryDrainMode", tostring(settingsObject.tabletBatteryDrainMode or "standby"))
        xml:setString(self.XMLTAG..".tabletBatteryDrainProfile", tostring(settingsObject.tabletBatteryDrainProfile or "normal"))
        xml:setInt(self.XMLTAG..".tabletBatteryOpenMinutes", tonumber(settingsObject.tabletBatteryOpenMinutes) or 15)
        xml:setInt(self.XMLTAG..".tabletBatteryStandbyMinutes", tonumber(settingsObject.tabletBatteryStandbyMinutes) or 60)
        xml:setFloat(self.XMLTAG..".tabletPosX",             settingsObject.tabletPosX or 0.5)
        xml:setFloat(self.XMLTAG..".tabletPosY",             settingsObject.tabletPosY or 0.5)
        xml:setFloat(self.XMLTAG..".tabletScale",            settingsObject.tabletScale or 1.0)
        xml:setFloat(self.XMLTAG..".tabletWidthMult",        settingsObject.tabletWidthMult or 1.0)
        xml:setFloat(self.XMLTAG..".contentFontScale",       settingsObject.contentFontScale or 1.0)
        xml:setInt(self.XMLTAG..".tabletBgColorIndex",       settingsObject.tabletBgColorIndex or 1)
        xml:setString(self.XMLTAG..".dashWidgets",
            settingsObject.dashWidgets or
            "balance,loan,income,expenses,net_pl,fields,vehicles,season,day,time,weather")
        local favSave = settingsObject.favoriteApps
        if favSave == nil then
            favSave = "dashboard,weather,app_store,settings"
        elseif favSave == "" then
            favSave = "__none__"   -- preserve an intentionally empty list
        end
        xml:setString(self.XMLTAG..".favoriteApps", favSave)
        xml:setBool(self.XMLTAG..".iconLabelsShow", settingsObject.iconLabelsShow ~= false)
        xml:setInt(self.XMLTAG..".iconLabelSize",  settingsObject.iconLabelSize  or 2)
        xml:setInt(self.XMLTAG..".iconLabelColor", settingsObject.iconLabelColor or 1)

        xml:save()
        xml:delete()
    end
end