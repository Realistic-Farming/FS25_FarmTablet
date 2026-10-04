-- =========================================================
-- FarmTablet v2 - SystemSettingsApp
-- EDITABLE view of every setting registered with the ecosystem
-- Settings Hub (FS25_SettingsHub), grouped by mod. Reads the cross-mod
-- handle that mod publishes at mission load:
--   g_currentMission.settingsHub   (bridge field)
--   getfenv(0)["g_settingsHub"]    (same instance, engine global)
-- Soft lookup only: when SettingsHub is absent the app renders an install
-- hint. Editing rides the shipped write path:
--   hub:getValue(modId, key)                     -- live read
--   hub:setValue(modId, key, value)              -- validate + route + persist
-- SettingsHub routes by scope: local settings apply here, admin settings go
-- to the server (which re-checks master rights and broadcasts). Data shape
-- verified against FS25_SettingsHub getModules():
--   { { modId, settings = { { id, type, value, default, adminOnly,
--       min, max, step, values, label }, ... } }, ... }
--
-- Each mod is a collapsible section: tap its header to fold/unfold its
-- settings (state kept per session in self._sysCollapsed). The body
-- scrolls (setContentHeight + drawScrollBar) and culls off-screen rows.
--
-- Admin (server-shared) rows are editable only for the host / a master user
-- (hub:isLocalAdmin()); for everyone else they render locked and greyed. That
-- gate is presentation only; the server is the sole authority on apply.
-- =========================================================

local function fmtValue(setting, live)
    local v = live
    if v == nil then v = setting.value end
    if v == nil then v = setting.default end
    if type(v) == "boolean" then
        return v and "On" or "Off"
    end
    if setting.type == "float" and type(v) == "number" then
        return string.format("%.2f", v)
    end
    return tostring(v)
end

local function clampNum(v, mn, mx)
    if mn ~= nil and v < mn then v = mn end
    if mx ~= nil and v > mx then v = mx end
    return v
end

local function roundToStep(v, step)
    if step == nil or step == 0 then return v end
    return math.floor(v / step + 0.5) * step
end

-- The value one widget press produces. dir = +1 (next / increment) or -1.
-- Reads a live-value snapshot so a stale draw-time closure never writes an old
-- number back over a value that changed since the row was painted.
local function nextValue(t, v, dir, mn, mx, step, values)
    if t == "bool" then
        return not (v == true)
    elseif t == "enum" then
        values = values or {}
        if #values == 0 then return v end
        local idx = 1
        for i, o in ipairs(values) do if o == v then idx = i break end end
        idx = ((idx - 1 + dir) % #values) + 1
        return values[idx]
    elseif t == "int" then
        step = step or 1
        local nv = (tonumber(v) or 0) + dir * step
        nv = math.floor(nv + (nv >= 0 and 0.5 or -0.5))
        return clampNum(nv, mn, mx)
    elseif t == "float" then
        step = step or 0.1
        local nv = roundToStep((tonumber(v) or 0) + dir * step, step)
        return clampNum(nv, mn, mx)
    end
    return v
end

FarmTabletUI:registerDrawer(FT.APP.SYSTEM_SETTINGS, function(self)
    local AC = FT.appColor(FT.APP.SYSTEM_SETTINGS)

    if self:drawHelpPage("_sysSetHelp", FT.APP.SYSTEM_SETTINGS, "System Settings", AC, {
        { title = "WHAT THIS APP DOES",
          body  = "Change any setting the Realistic Farming mods have\n" ..
                  "registered with the Settings Hub, grouped by mod.\n" ..
                  "Changes save and apply straight away." },
        { title = "HOW TO CHANGE A VALUE",
          body  = "On / Off switches toggle. Lists cycle with the arrows.\n" ..
                  "Numbers step with the minus and plus buttons.\n" ..
                  "Tap a mod's header to fold or unfold its settings." },
        { title = "ADMIN VS LOCAL",
          body  = "Admin settings are shared by the server and apply to\n" ..
                  "everyone in multiplayer, so only the host or an admin\n" ..
                  "can change them. They show locked for other players.\n" ..
                  "Local settings are your own and stay on this machine." },
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

    local isAdmin = false
    if hub.isLocalAdmin then
        local ok, res = pcall(function() return hub:isLocalAdmin() end)
        isAdmin = ok and res == true
    end

    self._sysCollapsed = self._sysCollapsed or {}
    local collapsed = self._sysCollapsed

    local ROWH = FT.py(32)
    local pad  = FT.px(6)
    -- Only draw (and register click regions for) content inside the visible band.
    local function vis(top) return top <= startY and top >= minY end

    -- Right-aligned widget cluster + value for one setting row at cursor y.
    local function drawWidget(setting, modId, rowY)
        local sid    = setting.id
        local st     = setting.type
        local mn, mx = setting.min, setting.max
        local sp     = setting.step
        local vals   = setting.values
        local locked = setting.adminOnly and not isAdmin
        local live   = hub:getValue(modId, sid)
        if live == nil then live = setting.value end

        local rightEdge = x + cw - pad
        local valColor  = locked and FT.C.TEXT_DIM
                       or (setting.adminOnly and FT.C.WARNING or FT.C.BRAND)

        -- Non-editable admin row: value + a LOCKED chip, no controls.
        if locked then
            self.r:appText(rightEdge, rowY - FT.py(6), FT.FONT.SMALL,
                fmtValue(setting, live), RenderText.ALIGN_RIGHT, valColor)
            self.r:appText(rightEdge, rowY - FT.py(20), FT.FONT.TINY,
                "admin - locked", RenderText.ALIGN_RIGHT, FT.C.MUTED)
            return
        end

        local function commit(dir)
            local cur = hub:getValue(modId, sid)
            if cur == nil then cur = setting.default end
            local nv = nextValue(st, cur, dir, mn, mx, sp, vals)
            local ok = pcall(function() return hub:setValue(modId, sid, nv) end)
            if not ok and self.log then self:log("setValue failed for %s.%s", tostring(modId), tostring(sid)) end
            self:_rebuildScreen()
        end

        if st == "bool" then
            local on = (live == true)
            local bw = FT.px(60)
            local btn = self.r:button(rightEdge - bw, rowY - FT.py(22), bw, FT.py(20),
                FT.l10nAuto(on and "On" or "Off"), on and FT.C.POSITIVE or FT.C.MUTED,
                { onClick = function() commit(1) end }, true)
            table.insert(self._contentBtns, btn)
        else
            -- enum / int / float: [<]/[-]  value  [>]/[+]
            local aw   = FT.px(26)
            local gap  = FT.px(4)
            local incX = rightEdge - aw
            local decX = incX - gap - aw
            local decLbl = (st == "enum") and "<" or "-"
            local incLbl = (st == "enum") and ">" or "+"

            local bDec = self.r:button(decX, rowY - FT.py(22), aw, FT.py(20),
                decLbl, FT.C.BTN_NEUTRAL, { onClick = function() commit(-1) end }, true)
            local bInc = self.r:button(incX, rowY - FT.py(22), aw, FT.py(20),
                incLbl, FT.C.BTN_NEUTRAL, { onClick = function() commit(1) end }, true)
            table.insert(self._contentBtns, bDec)
            table.insert(self._contentBtns, bInc)

            self.r:appText(decX - gap, rowY - FT.py(6), FT.FONT.SMALL,
                fmtValue(setting, live), RenderText.ALIGN_RIGHT, valColor)
        end
    end

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
                "(" .. #settings .. ")", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM, true)
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
                    local labelCol = (setting.adminOnly and not isAdmin) and FT.C.TEXT_DIM
                                  or FT.C.TEXT_NORMAL
                    self.r:appText(x + FT.px(2), y - FT.py(6), FT.FONT.BODY,
                        tostring(label), RenderText.ALIGN_LEFT, labelCol)
                    if setting.adminOnly then
                        self.r:appText(x + FT.px(2), y - FT.py(20), FT.FONT.TINY,
                            "server-shared", RenderText.ALIGN_LEFT, FT.C.WARNING)
                    end
                    drawWidget(setting, modId, y)
                end
                y = y - ROWH
            end
        end
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
    self:drawInfoIcon("_sysSetHelp", AC)
end)
