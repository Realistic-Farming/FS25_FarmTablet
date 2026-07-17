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
--
-- Each mod is a collapsible section: tap its header to fold/unfold its
-- settings (state kept per session in self._sysCollapsed). The body
-- scrolls (setContentHeight + drawScrollBar) and culls off-screen rows.
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
        { title = "COLLAPSE / EXPAND",
          body  = "Tap a mod's header to fold or unfold its settings.\n" ..
                  "The list scrolls when it runs past the screen." },
        { title = "ADMIN VS LOCAL",
          body  = "Admin settings are shared by the server and apply\n" ..
                  "to everyone in multiplayer. Local settings are your\n" ..
                  "own and stay on this machine." },
        { title = "EDITING",
          body  = "This overview is read-only for now. Change values\n" ..
                  "from each mod's own settings for the moment." },
    }) then return end

    local startY = self:drawAppHeader("System Settings", "Settings Hub")
    local x, contentY, cw = self:contentInner()
    local minY    = contentY + FT.py(8)
    local scrollY = self:getContentScrollY()
    local y       = startY + scrollY

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

    self._sysCollapsed = self._sysCollapsed or {}
    local collapsed = self._sysCollapsed

    local ROWH = FT.py(FT.SP.ROW)
    -- Only draw (and register click regions for) content inside the visible band.
    local function vis(top) return top <= startY and top >= minY end

    local rowIx = 0
    for _, mod in ipairs(modules) do
        local modId    = tostring(mod.modId)
        local settings = mod.settings or {}
        local isCol    = collapsed[modId] == true

        y = y - FT.py(6)   -- gap before each module

        -- Collapsible module header: accent band + caret + name + count.
        local headerY = y
        if vis(headerY) then
            self.r:appRect(x - FT.px(4), headerY - FT.py(3), cw + FT.px(8), FT.py(16),
                { AC[1], AC[2], AC[3], 0.12 })
            self.r:appRect(x, headerY - FT.py(2), FT.px(3), FT.py(12), AC)
            self.r:appText(x + FT.px(9), headerY, FT.FONT.SMALL,
                (isCol and "[+] " or "[-] ") .. modId, RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
            self.r:appText(x + cw - FT.px(2), headerY, FT.FONT.TINY,
                "(" .. #settings .. ")", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
            table.insert(self._contentBtns, {
                x = x - FT.px(4), y = headerY - FT.py(4), w = cw + FT.px(8), h = FT.py(17),
                meta = { onClick = function() collapsed[modId] = not collapsed[modId] end },
            })
        end
        y = y - FT.py(18)

        if not isCol then
            for _, setting in ipairs(settings) do
                rowIx = rowIx + 1
                if vis(y) then
                    if rowIx % 2 == 0 then
                        self.r:appRect(x - FT.px(4), y - FT.py(3), cw + FT.px(8), ROWH,
                            { 1, 1, 1, 0.03 })
                    end
                    local label = setting.label or setting.id
                    local scope = setting.adminOnly and "admin" or "local"
                    local col   = setting.adminOnly and FT.C.WARNING or FT.C.TEXT_DIM
                    self:drawRow(y, tostring(label),
                        fmtValue(setting) .. "   [" .. scope .. "]", nil, col)
                end
                y = y - ROWH
            end
        end
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_sysSetHelp", AC)
end)
