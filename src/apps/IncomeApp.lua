-- =========================================================
-- FarmTablet v2 – Companion Mod Integration Apps
-- Registers drawers for companion mods:
--   • FT.APP.INCOME          → FS25_IncomeMod
--   • FT.APP.TAX             → FS25_TaxMod
--   • FT.APP.NPC_FAVOR       → FS25_NPCFavor
--   • FT.APP.SOIL_FERT       → FS25_SoilFertilizer
--   • FT.APP.WORKER_COSTS    → FS25_WorkerCosts
-- Market Dynamics and Random World Events live in their own app
-- files (MarketDynamicsApp.lua, RandomWorldEventsApp.lua), sourced
-- after this file in main.lua.
-- Each drawer guards itself: if the companion mod's global
-- manager is nil the app shows a "mod not installed" banner
-- rather than erroring. The apps are only visible in the
-- sidebar when autoDetect() has confirmed the mod is loaded.
-- =========================================================

-- ── The companion mods' words ─────────────────────────────
-- What the companion mods' getters return, in English (their own settings ids): IncomeMod's pay mode
-- (Settings:getPayModeName), TaxMod's rate id (settings.taxRate), WorkerCosts' wage level and cost mode
-- (Settings:getWageLevelName / getCostModeName) and its roster's level and status (getRosterSnapshot).
-- Each known word reaches the tablet's key here; a word this table does not know keeps the map's pass.
local COMPANION_WORD = {
    ["Hourly"]          = function() return FT.l10n("ft_companion_hourly", "Hourly") end,
    ["Daily"]           = function() return FT.l10n("ft_companion_daily", "Daily") end,
    ["Per Hectare"]     = function() return FT.l10n("ft_companion_per_hectare", "Per Hectare") end,
    ["Low"]             = function() return FT.l10n("ft_companion_low", "Low") end,
    ["Medium"]          = function() return FT.l10n("ft_companion_medium", "Medium") end,
    ["High"]            = function() return FT.l10n("ft_companion_high", "High") end,
    ["low"]             = function() return FT.l10n("ft_companion_low", "Low") end,
    ["medium"]          = function() return FT.l10n("ft_companion_medium", "Medium") end,
    ["high"]            = function() return FT.l10n("ft_companion_high", "High") end,
    ["Novice"]          = function() return FT.l10n("ft_companion_novice", "Novice") end,
    ["Experienced"]     = function() return FT.l10n("ft_companion_experienced", "Experienced") end,
    ["Master"]          = function() return FT.l10n("ft_companion_master", "Master") end,
    ["Legendary"]       = function() return FT.l10n("ft_companion_legendary", "Legendary") end,
    ["working"]         = function() return FT.l10n("ft_companion_working", "working") end,
    ["idle"]            = function() return FT.l10n("ft_companion_idle", "idle") end,
    ["working, pinned"] = function() return FT.l10n("ft_companion_working_pinned", "working, pinned") end,
    ["idle, pinned"]    = function() return FT.l10n("ft_companion_idle_pinned", "idle, pinned") end,
}

--- A companion mod's word in the reader's language, resolved where it is read (drawn with the literal flag).
local function companionWord(word)
    local f = COMPANION_WORD[tostring(word)]
    if f ~= nil then return f() end
    return FT.l10nAuto(word)
end

-- ── INCOME MOD ────────────────────────────────────────────
FarmTabletUI:registerDrawer(FT.APP.INCOME, function(self)
    local AC = FT.appColor(FT.APP.INCOME)

    if self:drawHelpPage("_incomeHelp", FT.APP.INCOME, "Income Mod", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = FT.l10n("ft_income_help_what_body", "Displays the current status of FS25_IncomeMod.\n" ..
                  "The mod adds configurable periodic income payments\n" ..
                  "to supplement your farm earnings."), literalBody = true },
        { title = "PAYMENT MODE",
          body  = FT.l10n("ft_income_help_mode_body", "Controls when income is paid out:\n" ..
                  "Hourly = every in-game hour.\n" ..
                  "Daily = once per in-game day.\n" ..
                  "Weekly = once per in-game week."), literalBody = true },
        { title = "AMOUNT",
          body  = FT.l10n("ft_income_help_amount_body", "The money added to your balance per payment cycle.\n" ..
                  "Configure this in the Income Mod settings."), literalBody = true },
        { title = "ENABLE / DISABLE",
          body  = FT.l10n("ft_companion_help_toggle_body", "Toggles the mod on or off without uninstalling it.\n" ..
                  "Changes take effect immediately."), literalBody = true },
    }) then return end

    local startY = self:drawAppHeader("Income Mod", "Integration")
    local x, contentY, cw, _ = self:contentInner()
    local y = startY
    local inst = g_currentMission and g_currentMission.incomeManager

    if not inst then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Income Mod is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_IncomeMod to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_incomeHelp", AC)
        return
    end

    local enabled = inst.settings and inst.settings.enabled or false
    local mode    = (inst.settings and inst.settings.getPayModeName and inst.settings:getPayModeName()) or "Unknown"
    local amount  = (inst.settings and inst.settings.getPaymentAmount and inst.settings:getPaymentAmount()) or 0

    y = self:drawSection(y, "STATUS")
    y = self:drawRow(y, "Status", enabled and "Enabled" or "Disabled", nil,
        enabled and FT.C.POSITIVE or FT.C.NEGATIVE)
    y = self:drawRow(y, "Payment Mode", companionWord(mode), nil, nil, nil, true)
    y = self:drawRow(y, "Amount",
        (g_i18n and g_i18n:formatMoney(amount, 0, true, true)) or tostring(amount))

    y = y - FT.py(8)
    y = self:drawRule(y, 0.3)

    local minY = contentY + FT.py(8)
    if y > minY + FT.py(26) then
        self:drawButtonPair(minY + FT.py(2),
            FT.l10nAuto("ENABLE"),  enabled and FT.C.BTN_PRIMARY or FT.C.BTN_NEUTRAL,
            { onClick = function()
                if not g_currentMission:getIsServer() then return end
                if inst.settings then inst.settings.enabled = true end
                if inst.settings and inst.settings.save then inst.settings:save() end
                self:switchApp(FT.APP.INCOME)
            end },
            FT.l10nAuto("DISABLE"), enabled and FT.C.BTN_NEUTRAL or FT.C.BTN_DANGER,
            { onClick = function()
                if not g_currentMission:getIsServer() then return end
                if inst.settings then inst.settings.enabled = false end
                if inst.settings and inst.settings.save then inst.settings:save() end
                self:switchApp(FT.APP.INCOME)
            end }, true, true)
    end

    self:drawInfoIcon("_incomeHelp", AC)
end)


-- ── TAX MOD ───────────────────────────────────────────────
FarmTabletUI:registerDrawer(FT.APP.TAX, function(self)
    local AC = FT.appColor(FT.APP.TAX)

    if self:drawHelpPage("_taxHelp", FT.APP.TAX, "Tax Mod", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = FT.l10n("ft_tax_help_what_body", "Displays the status of FS25_TaxMod.\n" ..
                  "The mod deducts periodic tax from your balance\n" ..
                  "and returns a configurable percentage as a rebate."), literalBody = true },
        { title = "TAX RATE",
          body  = FT.l10n("ft_tax_help_rate_body", "How much tax is charged per cycle.\n" ..
                  "Low / Medium / High tiers are set in the mod settings.\n" ..
                  "Shown here so you can plan your cash flow."), literalBody = true },
        { title = "RETURN %",
          body  = FT.l10n("ft_tax_help_return_body", "Percentage of tax paid that is returned as a rebate.\n" ..
                  "A 20% return means you effectively pay 80% of the\n" ..
                  "stated tax rate."), literalBody = true },
        { title = "TOTAL PAID",
          body  = FT.l10n("ft_tax_help_total_body", "Cumulative tax paid across the current session.\n" ..
                  "Shown in orange as it represents an ongoing cost."), literalBody = true },
        { title = "ENABLE / DISABLE",
          body  = FT.l10n("ft_companion_help_toggle_body", "Toggles the mod on or off without uninstalling it.\n" ..
                  "Changes take effect immediately."), literalBody = true },
    }) then return end

    local data   = self.system.data
    local startY = self:drawAppHeader("Tax Mod", "Integration")
    local x, contentY, cw, _ = self:contentInner()
    local y    = startY
    local inst = g_currentMission and g_currentMission.taxManager

    if not inst then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Tax Mod is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_TaxMod to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_taxHelp", AC)
        return
    end

    local enabled = inst.settings and inst.settings.enabled or false
    local rate    = (inst.settings and inst.settings.taxRate) or "medium"
    local retPct  = (inst.settings and inst.settings.returnPercentage) or 20
    local total   = inst.stats and inst.stats.totalTaxesPaid

    y = self:drawSection(y, "STATUS")
    y = self:drawRow(y, "Status", enabled and "Enabled" or "Disabled", nil,
        enabled and FT.C.POSITIVE or FT.C.NEGATIVE)
    y = self:drawRow(y, "Tax Rate",   companionWord(rate), nil, nil, nil, true)
    y = self:drawRow(y, "Return %",   tostring(retPct) .. "%")
    if total then
        y = self:drawRow(y, "Total Paid", data:formatMoney(total), nil, FT.C.WARNING, nil, true)
    end

    y = y - FT.py(8)
    y = self:drawRule(y, 0.3)

    local minY = contentY + FT.py(8)
    if y > minY + FT.py(26) then
        self:drawButtonPair(minY + FT.py(2),
            FT.l10nAuto("ENABLE"),  enabled and FT.C.BTN_PRIMARY or FT.C.BTN_NEUTRAL,
            { onClick = function()
                if not g_currentMission:getIsServer() then return end
                if inst.settings then inst.settings.enabled = true end
                if inst.saveSettings then inst:saveSettings() end
                self:switchApp(FT.APP.TAX)
            end },
            FT.l10nAuto("DISABLE"), enabled and FT.C.BTN_NEUTRAL or FT.C.BTN_DANGER,
            { onClick = function()
                if not g_currentMission:getIsServer() then return end
                if inst.settings then inst.settings.enabled = false end
                if inst.saveSettings then inst:saveSettings() end
                self:switchApp(FT.APP.TAX)
            end }, true, true)
    end

    self:drawInfoIcon("_taxHelp", AC)
end)


-- ── NPC FAVOR ─────────────────────────────────────────────
-- RSF-F357 section 9b: the tablet is one more reader of the owner's shared work
-- page. With the repaired host (its adapters present) the work and count block
-- is that copied page for this farm: the tablet registers interest while the
-- NPC app is shown (the host's one adapter polls for every reader) and lets go
-- the moment the app is left or the tablet closes, so no poll outlives the
-- screen. A page that has not arrived, or is older than two refresh intervals,
-- says so instead of claiming a zero. Nothing here touches the host's favour
-- model; the page and the roster view are copies. An older host keeps the
-- established compatibility read below.
-- The role ids NPCFavor ships as a person's role (NPCSystem's farmer / shopkeeper / worker / farmhand, and
-- agronomist for the consultant; the roster view's roleLabel carries the same id). An id selects the tablet's
-- key where it is read (RSF-F357 section 7: names and ids are not lookup keys, the UI uses localized keys); an id
-- this table does not know is drawn as the host supplies it.
local NPC_ROLE_WORD = {
    farmer     = function() return FT.l10n("ft_npc_role_farmer", "farmer") end,
    shopkeeper = function() return FT.l10n("ft_npc_role_shopkeeper", "shopkeeper") end,
    worker     = function() return FT.l10n("ft_npc_role_worker", "worker") end,
    farmhand   = function() return FT.l10n("ft_npc_role_farmhand", "farmhand") end,
    agronomist = function() return FT.l10n("ft_npc_role_agronomist", "agronomist") end,
}

local function npcRoleWord(role)
    local f = NPC_ROLE_WORD[tostring(role)]
    if f ~= nil then return f() end
    return tostring(role)
end

local function npcHostRepaired(npcSys)
    return type(npcSys) == "table"
        and type(npcSys.getPersonalWorkView) == "function"
        and type(npcSys.requestPersonalWorkView) == "function"
        and type(npcSys.watchPersonalWork) == "function"
end

local function npcWorkWatch(self, npcSys, on)
    if on then
        if self._npcWorkWatching then return end
        self._npcWorkWatching = true
        self._npcWorkHost = npcSys
        pcall(npcSys.watchPersonalWork, npcSys, true)
        -- Refresh on opening the screen; the adapter refuses a second outstanding request itself.
        pcall(npcSys.requestPersonalWorkView, npcSys, "")
    elseif self._npcWorkWatching then
        self._npcWorkWatching = false
        local host = self._npcWorkHost
        self._npcWorkHost = nil
        if type(host) == "table" and type(host.watchPersonalWork) == "function" then
            pcall(host.watchPersonalWork, host, false)
        end
    end
end

--- The release: a watch outlives neither the app nor the tablet nor the tablet's
--- enabled setting. Let go when the app is not the one shown, the tablet is
--- closed, or the tablet is disabled.
function FarmTabletUI:npcWorkReleaseIfHidden(disabled)
    if not self._npcWorkWatching then return end
    if disabled or not self.isOpen or self.system == nil or self.system.currentApp ~= FT.APP.NPC_FAVOR then
        npcWorkWatch(self, nil, false)
    end
end

-- Prepended, so the release runs ahead of the frame's own work and never
-- depends on it (the engine's Utils.prependedFunction, Utils.lua:387).
FarmTabletUI.update = Utils.prependedFunction(FarmTabletUI.update, function(self, dt)
    self:npcWorkReleaseIfHidden(false)
end)
-- The manager returns before ui:update while the tablet is disabled
-- (FarmTabletManager.lua, the settings.enabled return), so the disabled case
-- is released here, ahead of that return.
FarmTabletManager.update = Utils.prependedFunction(FarmTabletManager.update, function(self, dt)
    if self.ui ~= nil and self.settings ~= nil and not self.settings.enabled and self.ui.npcWorkReleaseIfHidden ~= nil then
        self.ui:npcWorkReleaseIfHidden(true)
    end
end)

local function drawNpcWork(self, npcSys, y, minY)
    npcWorkWatch(self, npcSys, true)
    local ok, view = pcall(npcSys.getPersonalWorkView, npcSys)
    if not ok or type(view) ~= "table" or (view.state ~= "CURRENT" and view.state ~= "LAST_CONFIRMED") then
        y = self:drawRow(y, "Work", "unavailable", nil, FT.C.TEXT_DIM)
        y = self:drawRow(y, "Total Earned", "unavailable", nil, FT.C.TEXT_DIM)
        return y
    end
    local active, offers, rows = 0, 0, {}
    for _, r in ipairs(view.rows or {}) do
        if r.status == "active" or r.status == "in_progress" then
            active = active + 1
            rows[#rows + 1] = r
        elseif r.status == "pending" then
            offers = offers + 1
        end
    end
    -- Every literal here is its own mapped text (FT.AUTO_L10N, the ft_auto_* keys):
    -- the last-confirmed note is a line of its own, never appended to a value.
    y = self:drawRow(y, "Active Favors", tostring(active), nil, nil, nil, true)
    if view.state == "LAST_CONFIRMED" then
        y = self:drawRow(y, "(last confirmed)", "", FT.C.TEXT_DIM, nil, nil, true)
    end
    y = self:drawRow(y, "Open Offers", tostring(offers), nil, nil, nil, true)
    if view.completedKnown then
        y = self:drawRow(y, "Completed", tostring(view.completedCount or 0))
    else
        y = self:drawRow(y, "Completed", "unavailable", nil, FT.C.TEXT_DIM)
    end
    -- The host supplies no earnings summary: unavailable, never a raw figure.
    y = self:drawRow(y, "Total Earned", "unavailable", nil, FT.C.TEXT_DIM)
    if #rows > 0 then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.2)
        y = self:drawSection(y, "ACTIVE")
        for i = 1, math.min(3, #rows) do
            local f = rows[i]
            if y > minY + FT.py(16) then
                local progress = math.floor(f.progress or 0)
                local pctColor = progress >= 66 and FT.C.POSITIVE
                              or progress >= 33 and FT.C.WARNING or FT.C.TEXT_DIM
                local left = FT_Renderer.truncate(
                    (f.npcName or "?") .. "  " .. (f.description or f.type or ""), 28)
                if f.timeKnown then
                    y = self:drawRow(y, left, FT.l10nFormat("ft_npc_progress_left_fmt", "%d%%  %dh left", progress, math.floor((f.timeRemainingMs or 0) / 3600000)), nil, pctColor, nil, true)
                else
                    -- The unknown time is its own mapped literal beside the progress.
                    y = self:drawRow(y, left, string.format("%d%%", progress), nil, pctColor, nil, true)
                    y = self:drawRow(y, "time unknown", "", FT.C.TEXT_DIM, nil, nil, true)
                end
            end
        end
    end
    return y
end

FarmTabletUI:registerDrawer(FT.APP.NPC_FAVOR, function(self)
    local AC = FT.appColor(FT.APP.NPC_FAVOR)

    if self:drawHelpPage("_npcHelp", FT.APP.NPC_FAVOR, "NPC Favor", AC, {
        { title = "TOWN REPUTATION",
          body  = FT.l10n("ft_npc_help_rep_body", "Overall standing with the local community (0-100).\n" ..
                  "Respected >= 70  |  Neutral >= 40  |  Poor < 40.\n" ..
                  "Higher reputation unlocks better favor rewards."), literalBody = true },
        { title = "ACTIVE FAVORS",
          body  = FT.l10n("ft_npc_help_active_body", "Number of favors currently in progress.\n" ..
                  "Each favor shows NPC name, description, completion\n" ..
                  "percentage, and hours remaining."), literalBody = true },
        { title = "RELATIONSHIPS",
          body  = FT.l10n("ft_npc_help_relationships_body", "Lists every active NPC with their relationship score\n" ..
                  "and a colour-coded bar.\n" ..
                  "Friend >= 70  |  Neutral >= 40  |  Cold < 40.\n" ..
                  "Their role (Agronomist, Mechanic, etc.) is shown in\n" ..
                  "square brackets next to their name."), literalBody = true },
        { title = "BUILDING RELATIONSHIPS",
          body  = FT.l10n("ft_npc_help_building_body", "Complete favors for an NPC to increase their\n" ..
                  "relationship score. Higher scores unlock exclusive\n" ..
                  "advice, discounts, and early warnings."), literalBody = true },
    }) then return end

    local startY = self:drawAppHeader("NPC Favor", "", nil, true)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y    = startY + scrollY
    local minY = contentY + FT.py(8)

    local npcSys = g_NPCSystem or (g_currentMission and g_currentMission.npcFavorSystem)

    if not npcSys then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "NPC Favor mod not detected.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_NPCFavor to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_npcHelp", AC)
        return
    end

    local npcs     = npcSys.activeNPCs or {}
    local favorSys = npcSys.favorSystem
    local townRep  = npcSys.townReputation or 0
    local accent   = AC

    local repColor = townRep >= 70 and FT.C.POSITIVE or townRep >= 40 and FT.C.WARNING or FT.C.NEGATIVE
    local repLabel = townRep >= 70 and FT.l10n("ft_auto_respected", "Respected")
                  or townRep >= 40 and FT.l10n("ft_auto_neutral", "Neutral") or FT.l10n("ft_auto_poor", "Poor")

    self.r:appRect(x - FT.px(4), y - FT.py(22), cw + FT.px(8), FT.py(20),
        {repColor[1]*0.12, repColor[2]*0.12, repColor[3]*0.12, 0.95})
    self.r:appText(x, y - FT.py(18), FT.FONT.BODY,
        FT.l10nFormat("ft_npc_town_rep_fmt", "Town Reputation: %s", repLabel), RenderText.ALIGN_LEFT, repColor, true)
    self.r:appText(x + cw, y - FT.py(18), FT.FONT.SMALL,
        tostring(math.floor(townRep)) .. " / 100", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM, true)
    y = y - FT.py(26)
    y = y + FT.py(FT.SP.ROW) - FT.py(8)
    y = self:drawBar(y, townRep, 100, repColor)
    y = y - FT.py(8)

    if npcHostRepaired(npcSys) then
        y = self:drawRule(y, 0.3)
        y = self:drawSection(y, "FAVORS")
        y = drawNpcWork(self, npcSys, y, minY)
    elseif favorSys then
        local active = favorSys.activeFavors or {}
        local stats  = favorSys.stats or {}
        y = self:drawRule(y, 0.3)
        y = self:drawSection(y, "FAVORS")
        y = self:drawRow(y, "Active Favors", tostring(#active), nil, nil, nil, true)
        y = self:drawRow(y, "Completed",     tostring(stats.totalFavorsCompleted or 0))
        y = self:drawRow(y, "Total Earned",
            (g_i18n and g_i18n:formatMoney(stats.totalMoneyEarned or 0, 0, true, true))
            or ("$" .. tostring(stats.totalMoneyEarned or 0)), nil, FT.C.POSITIVE)

        if #active > 0 then
            y = y - FT.py(4)
            y = self:drawRule(y, 0.2)
            y = self:drawSection(y, "ACTIVE")
            for i = 1, math.min(3, #active) do
                local f = active[i]
                if f and y > minY + FT.py(16) then
                    local hoursLeft = math.floor((f.timeRemaining or 0) / 3600000)
                    local pctColor  = f.progress >= 66 and FT.C.POSITIVE
                                   or f.progress >= 33 and FT.C.WARNING or FT.C.TEXT_DIM
                    local left = FT_Renderer.truncate(
                        (f.npcName or "?") .. "  " .. (f.description or f.type or ""), 28)
                    y = self:drawRow(y, left,
                        FT.l10nFormat("ft_npc_progress_left_fmt", "%d%%  %dh left", math.floor(f.progress or 0), hoursLeft),
                        nil, pctColor, nil, true)
                end
            end
        end
    end

    y = y - FT.py(4)
    y = self:drawRule(y, 0.3)

    -- RSF-F357 section 9a: the public roster view when the host publishes it.
    -- Trust and a bar only for a live person; a waiting person or an observed
    -- worker is listed by name with no number (never a zero). An older host
    -- keeps the compatibility read of its live list.
    local roster = nil
    if type(npcSys.getNeighbourRosterView) == "function" then
        local okR, v = pcall(npcSys.getNeighbourRosterView, npcSys)
        if okR and type(v) == "table" and type(v.rows) == "table" then roster = v end
    end
    if roster ~= nil then
        local live, others = {}, {}
        for _, r in ipairs(roster.rows) do
            if r.kind == "LIVE" and type(r.trust) == "number" then live[#live + 1] = r else others[#others + 1] = r end
        end
        table.sort(live, function(a, b) return a.trust > b.trust end)
        y = self:drawSection(y, FT.l10nFormat("ft_npc_relationships_fmt", "RELATIONSHIPS  (%d)", #live), true)
        if roster.personLoadState ~= "READY" or roster.snapshotState == "UNAVAILABLE" then
            self.r:appText(x, y - FT.py(10), FT.FONT.SMALL,
                "Neighbours not available yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        elseif #live == 0 and #others == 0 then
            self.r:appText(x, y - FT.py(10), FT.FONT.SMALL,
                "No NPCs spawned yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        else
            for _, r in ipairs(live) do
                if y <= minY + FT.py(16) then break end
                local rel      = math.floor(math.min(math.max(r.trust, 0), 100))
                local relColor = rel >= 70 and FT.C.POSITIVE or rel >= 40 and FT.C.WARNING or FT.C.NEGATIVE
                local relLabel = rel >= 70 and FT.l10n("ft_auto_friend", "Friend")
                              or rel >= 40 and FT.l10n("ft_auto_neutral", "Neutral") or FT.l10n("ft_npc_rel_cold", "Cold")
                local nm       = tostring(r.name or "Unknown")
                if FT.utf8Len(nm) > 16 then nm = FT.utf8Sub(nm, 14) .. ">" end
                self.r:appText(x, y, FT.FONT.SMALL,
                    nm .. "  [" .. npcRoleWord(r.roleLabel or "?") .. "]", RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL, true)
                -- One space: the text players have seen (the old draw pass collapsed the code's two).
                self.r:appText(x + cw, y, FT.FONT.SMALL,
                    rel .. " " .. relLabel, RenderText.ALIGN_RIGHT, relColor, true)
                y = y - FT.py(14)
                y = self:drawBar(y, rel, 100, relColor)
                y = y - FT.py(4)
            end
            for _, r in ipairs(others) do
                if y <= minY + FT.py(16) then break end
                local nm = tostring(r.name or "Unknown")
                if FT.utf8Len(nm) > 16 then nm = FT.utf8Sub(nm, 14) .. ">" end
                -- The name on the left, the tag as its own mapped literal on the right
                -- (where a live person's score sits), never composed into one string.
                local tag = (r.kind == "PRESENCE") and "worker" or "waiting"
                self.r:appText(x, y, FT.FONT.SMALL, nm, RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
                self.r:appText(x + cw, y, FT.FONT.SMALL, tag, RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
                y = y - FT.py(14)
            end
        end
    elseif #npcs == 0 then
        y = self:drawSection(y, FT.l10nFormat("ft_npc_relationships_fmt", "RELATIONSHIPS  (%d)", #npcs), true)
        self.r:appText(x, y - FT.py(10), FT.FONT.SMALL,
            "No NPCs spawned yet.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
    else
        y = self:drawSection(y, FT.l10nFormat("ft_npc_relationships_fmt", "RELATIONSHIPS  (%d)", #npcs), true)
        local sorted = {}
        for _, npc in ipairs(npcs) do
            if npc and npc.isActive ~= false then table.insert(sorted, npc) end
        end
        table.sort(sorted, function(a, b) return (a.relationship or 0) > (b.relationship or 0) end)

        for _, npc in ipairs(sorted) do
            if y <= minY + FT.py(16) then break end
            local rel      = math.floor(math.min(math.max(npc.relationship or 0, 0), 100))
            local relColor = rel >= 70 and FT.C.POSITIVE or rel >= 40 and FT.C.WARNING or FT.C.NEGATIVE
            local relLabel = rel >= 70 and FT.l10n("ft_auto_friend", "Friend")
                          or rel >= 40 and FT.l10n("ft_auto_neutral", "Neutral") or FT.l10n("ft_npc_rel_cold", "Cold")
            local nm       = tostring(npc.name or "Unknown")
            if FT.utf8Len(nm) > 16 then nm = FT.utf8Sub(nm, 14) .. ">" end
            self.r:appText(x, y, FT.FONT.SMALL,
                nm .. "  [" .. npcRoleWord(npc.role or "?") .. "]", RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL, true)
            -- One space: the text players have seen (the old draw pass collapsed the code's two).
            self.r:appText(x + cw, y, FT.FONT.SMALL,
                rel .. " " .. relLabel, RenderText.ALIGN_RIGHT, relColor, true)
            y = y - FT.py(14)
            y = self:drawBar(y, rel, 100, relColor)
            y = y - FT.py(4)
        end
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_npcHelp", AC)
    self:drawScrollBar()
end)




-- ── SOIL FERTILIZER ───────────────────────────────────────
-- Drawer lives in SoilNutrientApp.lua (FT #101 field-card redesign).


-- ── WORKER COSTS ──────────────────────────────────────────
FarmTabletUI:registerDrawer(FT.APP.WORKER_COSTS, function(self)
    local AC = FT.appColor(FT.APP.WORKER_COSTS)

    if self:drawHelpPage("_wrkHelp", FT.APP.WORKER_COSTS, "Worker Costs", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = FT.l10n("ft_wrk_help_what_body", "Displays FS25_WorkerCosts status:\n" ..
                  "current wage level, cost mode, active\n" ..
                  "workers, and month-to-date costs.\n" ..
                  "Scroll down for the Pro-Staff roster."), literalBody = true },
        { title = "WAGE LEVEL",
          body  = FT.l10n("ft_wrk_help_wage_body", "Sets the per-hour wage rate for hired workers.\n" ..
                  "Low / Medium / High tiers are configured in\n" ..
                  "the Worker Costs mod settings."), literalBody = true },
        { title = "COST MODE",
          body  = FT.l10n("ft_wrk_help_mode_body", "Controls how wages are calculated:\n" ..
                  "Hourly = charged every in-game hour.\n" ..
                  "Monthly = accumulated and charged at month end."), literalBody = true },
        { title = "MONTH COSTS",
          body  = FT.l10n("ft_wrk_help_month_body", "Total wages accumulated this month.\n" ..
                  "Resets after the monthly salary is paid."), literalBody = true },
        { title = "PRO-STAFF ROSTER",
          body  = FT.l10n("ft_wrk_help_roster_body", "Your hired workers with their level\n" ..
                  "(Novice / Experienced / Master), lifetime hours,\n" ..
                  "jobs completed, and current fatigue bar.\n" ..
                  "This view is read-only - hire, fire, and assign\n" ..
                  "workers from the in-game roster panel (ALT+H)\n" ..
                  "or the WorkerCosts console commands."), literalBody = true },
    }) then return end

    local startY = self:drawAppHeader("Worker Costs", "Integration")
    local x, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y    = startY + scrollY
    local mgr  = g_currentMission and g_currentMission.workerCostsManager

    if not mgr then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Worker Costs is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_WorkerCosts to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_wrkHelp", AC)
        return
    end

    local settings   = mgr.settings
    local workerSys  = mgr.workerSystem
    local enabled    = settings and settings.enabled or false
    local wageLevel  = (settings and settings.getWageLevelName and settings:getWageLevelName()) or "Unknown"
    local costMode   = (settings and settings.getCostModeName and settings:getCostModeName()) or "Unknown"

    y = self:drawSection(y, "STATUS")
    y = self:drawRow(y, "Status",     enabled and "Enabled" or "Disabled", nil,
        enabled and FT.C.POSITIVE or FT.C.NEGATIVE)
    y = self:drawRow(y, "Wage Level", companionWord(wageLevel), nil, nil, nil, true)
    y = self:drawRow(y, "Cost Mode",  companionWord(costMode), nil, nil, nil, true)

    -- Active workers
    local activeWorkers = {}
    if workerSys and workerSys.getActiveWorkers then
        activeWorkers = workerSys:getActiveWorkers()
    end
    y = self:drawRow(y, "Active Workers", tostring(#activeWorkers),
        nil, #activeWorkers > 0 and FT.C.WARNING or FT.C.TEXT_DIM, nil, true)

    -- Month-to-date costs
    local monthTotal = 0
    if workerSys and workerSys.monthlyCosts then
        for _, amt in pairs(workerSys.monthlyCosts) do
            monthTotal = monthTotal + (amt or 0)
        end
    end

    y = y - FT.py(4)
    y = self:drawSection(y, "THIS MONTH")
    local fmtCost = (g_i18n and g_i18n:formatMoney(monthTotal, 0, true, true)) or tostring(monthTotal)
    y = self:drawRow(y, "Wages Accrued", fmtCost, nil,
        monthTotal > 0 and FT.C.WARNING or FT.C.TEXT_DIM, nil, true)

    -- ── PRO-STAFF ROSTER ──────────────────────────────────
    -- Read the roster through the WorkerCosts cross-repo contract. Guard the call:
    -- an older WorkerCosts without getRosterSnapshot() simply omits this section.
    local snap = (mgr.getRosterSnapshot ~= nil) and mgr:getRosterSnapshot() or nil
    if snap then
        y = y - FT.py(6)
        y = self:drawRule(y, 0.3)
        y = self:drawSection(y, FT.l10nFormat("ft_wrk_prostaff_fmt", "PRO-STAFF  (%d)", tonumber(snap.count) or 0), true)

        if not snap.authoritative then
            -- Multiplayer client: the roster lives on the host and isn't synced yet.
            self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
                FT.l10n("ft_wrk_roster_host", "Roster is host-managed - syncs to clients soon."),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
            y = y - FT.py(16)
        elseif snap.count == 0 then
            self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
                "No workers yet. Hire from the roster panel (ALT+H).",
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(16)
        else
            y = self:drawRow(y, "Working Now", tostring(snap.working), nil,
                snap.working > 0 and FT.C.POSITIVE or FT.C.TEXT_DIM)
            y = self:drawRow(y, "Levels", FT.l10nFormat("ft_wrk_levels_fmt", "%dN / %dE / %dM",
                snap.levels.novice, snap.levels.experienced, snap.levels.master), nil, nil, nil, true)
            y = y - FT.py(2)

            -- Draw every worker. The renderer clips rows that fall outside the
            -- content area (flushContent's clipY/clipH) and setContentHeight()
            -- below measures the FULL list, so the scrollbar + wheel can reach
            -- all of them. #81: an early `break` here stopped both the draw and
            -- the height accounting, which zeroed _contentScrollMax and locked
            -- the roster to the ~5 rows that happened to fit on screen.
            for _, w in ipairs(snap.workers) do
                local fatPct   = math.floor((w.fatigue or 0) * 100)
                local stColor  = w.working and FT.C.POSITIVE or FT.C.TEXT_DIM
                local nm       = tostring(w.name or "Worker")
                if FT.utf8Len(nm) > 18 then nm = FT.utf8Sub(nm, 16) .. ">" end

                self.r:appText(x, y, FT.FONT.SMALL,
                    nm .. "  [" .. companionWord(w.levelName or "Novice") .. "]",
                    RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL, true)
                self.r:appText(x + cw, y, FT.FONT.SMALL, companionWord(w.status or "idle"),
                    RenderText.ALIGN_RIGHT, stColor, true)
                y = y - FT.py(13)

                self.r:appText(x, y, FT.FONT.TINY,
                    FT.l10nFormat("ft_wrk_worker_stats_fmt", "%.1fh  -  %d jobs  -  fatigue %d%%",
                        w.totalHours or 0, w.totalJobs or 0, fatPct),
                    RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
                y = y - FT.py(11)

                local fatColor = fatPct >= 70 and FT.C.NEGATIVE
                              or fatPct >= 40 and FT.C.WARNING or FT.C.POSITIVE
                y = self:drawBar(y, fatPct, 100, fatColor)
                y = y - FT.py(6)
            end
        end
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_wrkHelp", AC)
    self:drawScrollBar()
end)
