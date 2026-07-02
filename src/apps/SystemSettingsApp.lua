-- =========================================================
-- FarmTablet v2 - SystemSettingsApp
-- Read-only overview of every setting registered with the ecosystem
-- Settings Hub (FS25_SettingsHub), grouped by mod. Reads the cross-mod
-- handle that mod publishes at mission load:
--   g_currentMission.settingsHub   (bridge field)
--   getfenv(0)["g_settingsHub"]    (same instance, engine global)
-- Soft lookup only: when SettingsHub is absent the app renders an install
-- hint. Display only for now; editing rides SettingsHub:setValue() and is
-- a follow-up. Data shape verified against FS25_SettingsHub getModules():
--   { { modId, settings = { { id, type, value, default, adminOnly,
--       min, max, step, values, label }, ... } }, ... }
-- =========================================================

local function fmtValue(setting)
    local v = setting.value
    if v == nil then v = setting.default end
    if type(v) == "boolean" then
        return v and "On" or "Off"
    end
    return tostring(v)
end

FarmTabletUI:registerDrawer(FT.APP.SYSTEM_SETTINGS, function(self)
    local AC = FT.appColor(FT.APP.SYSTEM_SETTINGS)

    if self:drawHelpPage("_sysSetHelp", FT.APP.SYSTEM_SETTINGS, "System Settings", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Every setting the Realistic Farming mods have\n" ..
                  "registered with the Settings Hub, grouped by mod,\n" ..
                  "with its current value." },
        { title = "ADMIN VS LOCAL",
          body  = "Admin settings are shared by the server and apply\n" ..
                  "to everyone in multiplayer. Local settings are your\n" ..
                  "own and stay on this machine." },
        { title = "EDITING",
          body  = "This overview is read-only for now. Change values\n" ..
                  "from each mod's own settings for the moment." },
    }) then return end

    local startY = self:drawAppHeader("System Settings", "Settings Hub")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y   = startY + scrollY
    local hub = (g_currentMission and g_currentMission.settingsHub)
             or getfenv(0)["g_settingsHub"]

    if not hub then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Settings Hub is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_SettingsHub to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_sysSetHelp", AC)
        return
    end

    local modules = {}
    if hub.getModules then
        local ok, res = pcall(function() return hub:getModules() end)
        if ok and type(res) == "table" then modules = res end
    end

    if #modules == 0 then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "No ecosystem settings registered yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Realistic Farming mods appear here as they load.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_sysSetHelp", AC)
        return
    end

    for _, mod in ipairs(modules) do
        local settings = mod.settings or {}
        y = y - FT.py(4)
        y = self:drawSection(y, tostring(mod.modId) .. "  (" .. #settings .. ")")
        for _, setting in ipairs(settings) do
            local label = setting.label or setting.id
            local scope = setting.adminOnly and "admin" or "local"
            local col = setting.adminOnly and FT.C.WARNING or FT.C.TEXT_DIM
            y = self:drawRow(y, tostring(label), fmtValue(setting) .. "   [" .. scope .. "]", nil, col)
        end
    end

    self:drawInfoIcon("_sysSetHelp", AC)
end)
