-- =========================================================
-- FarmTablet v2 - MarketDynamicsApp
-- Read-only integration app for FS25_MarketDynamics.
-- Reads the cross-mod handle that mod publishes in Mission00.load:
--   g_currentMission.MarketDynamics      (bridge field)
--   getfenv(0)["g_MarketDynamics"]       (same instance, engine global)
-- Soft lookup only: when the mod is missing the app renders an
-- install hint instead of erroring. Display only - no writes.
--
-- Data shapes (verified against FS25_MarketDynamics source):
--   mgr.isActive                          boolean
--   mgr.settings.pricesEnabled            boolean
--   mgr.settings.eventsEnabled            boolean
--   mgr.settings.eventFrequency           number (0.4 rare / 1.0 normal / 2.0 frequent)
--   mgr.marketEngine.volatilityScale      number (0.5 low .. 2.0 extreme)
--   mgr.marketEngine.prices[fillTypeIdx]  { base, current, ... }  per-litre prices
--   mgr.worldEvents:getActiveEvents()     { { id, name, intensity 0-1, endsAt gameMs } }
-- =========================================================

-- In-game clock in ms, same formula as MDM's MDMUtil.getGameTime(),
-- so remaining-time math matches the endsAt values the mod stores.
local function mdmGameTimeMs()
    local env = g_currentMission and g_currentMission.environment
    if not env then return 0 end
    return ((env.currentDay or 1) - 1) * 86400000 + (env.dayTime or 0)
end

-- Fill type display title, or nil when the index no longer exists
-- (stale entries left by removed third-party fill type mods).
local function mdmFillTypeTitle(idx)
    if not g_fillTypeManager then return nil end
    local ft = g_fillTypeManager:getFillTypeByIndex(idx)
    if not ft then return nil end
    return ft.title or ft.name or ("Type " .. tostring(idx))
end

FarmTabletUI:registerDrawer(FT.APP.MARKET_DYNAMICS, function(self)
    local AC = FT.appColor(FT.APP.MARKET_DYNAMICS)

    if self:drawHelpPage("_mktHelp", FT.APP.MARKET_DYNAMICS, "Market Dynamics", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays FS25_MarketDynamics status:\n" ..
                  "active world events, market price modifiers,\n" ..
                  "and event frequency settings." },
        { title = "WORLD EVENTS",
          body  = "Events like droughts, trade disruptions, and\n" ..
                  "pest outbreaks temporarily shift crop prices.\n" ..
                  "Active events and their intensity are listed here." },
        { title = "SETTINGS",
          body  = "Price modifiers and event frequency can be\n" ..
                  "adjusted in the Market Dynamics mod settings." },
    }) then return end

    local startY = self:drawAppHeader("Market Dynamics", "Integration")
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y   = startY + scrollY
    local mgr = (g_currentMission and g_currentMission.MarketDynamics)
             or getfenv(0)["g_MarketDynamics"]

    if not mgr then
        self.r:appText(x, y - FT.py(12), FT.FONT.BODY,
            "Market Dynamics is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, y - FT.py(30), FT.FONT.SMALL,
            "Install FS25_MarketDynamics to use this app.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_mktHelp", AC)
        return
    end

    local settings      = mgr.settings
    local isActive      = mgr.isActive or false
    local pricesEnabled = settings and settings.pricesEnabled or false
    local eventsEnabled = settings and settings.eventsEnabled or false
    local freqVal       = (settings and settings.eventFrequency) or 1.0
    local freqLabel
    if freqVal <= 0.5 then freqLabel = "Rare"
    elseif freqVal <= 1.2 then freqLabel = "Normal"
    else freqLabel = "Frequent" end

    y = self:drawSection(y, "STATUS")
    y = self:drawRow(y, "Active", isActive and "Yes" or "No", nil,
        isActive and FT.C.POSITIVE or FT.C.NEGATIVE)
    y = self:drawRow(y, "Price Modifiers", pricesEnabled and "On" or "Off", nil,
        pricesEnabled and FT.C.POSITIVE or FT.C.TEXT_DIM)
    y = self:drawRow(y, "World Events", eventsEnabled and "On" or "Off", nil,
        eventsEnabled and FT.C.POSITIVE or FT.C.TEXT_DIM)
    y = self:drawRow(y, "Event Frequency", freqLabel)
    if mgr.marketEngine and mgr.marketEngine.volatilityScale then
        y = self:drawRow(y, "Volatility",
            string.format("%.1fx", mgr.marketEngine.volatilityScale))
    end

    -- Active world events. Synced to MP clients via MDMMarketSyncEvent,
    -- so this list is valid on any peer.
    local activeEvents = {}
    if mgr.worldEvents and mgr.worldEvents.getActiveEvents then
        activeEvents = mgr.worldEvents:getActiveEvents() or {}
    end
    table.sort(activeEvents, function(a, b) return (a.endsAt or 0) < (b.endsAt or 0) end)

    y = y - FT.py(4)
    y = self:drawSection(y, "ACTIVE EVENTS  (" .. #activeEvents .. ")")

    if #activeEvents == 0 then
        self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
            "No active market events.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(18)
    else
        local now = mdmGameTimeMs()
        for _, evt in ipairs(activeEvents) do
            local intPct = math.floor((evt.intensity or 0) * 100 + 0.5)
            local remMin = math.max(0, math.ceil(((evt.endsAt or now) - now) / 60000))
            y = self:drawRow(y, evt.name or evt.id,
                string.format("%d%%  |  %dm", intPct, remMin), nil, FT.C.WARNING)
        end
    end

    -- Market movers: biggest current deviation from the vanilla base price.
    -- MDM stores per-litre prices; the tablet shows per 1,000 L like StorageApp.
    local movers = {}
    if mgr.marketEngine and mgr.marketEngine.prices then
        for idx, entry in pairs(mgr.marketEngine.prices) do
            if entry and entry.base and entry.base > 0 and entry.current then
                local pct = (entry.current - entry.base) / entry.base * 100
                if math.abs(pct) >= 0.05 then
                    local title = mdmFillTypeTitle(idx)
                    if title then
                        table.insert(movers, { name = title, price = entry.current, pct = pct })
                    end
                end
            end
        end
    end
    table.sort(movers, function(a, b) return math.abs(a.pct) > math.abs(b.pct) end)

    y = y - FT.py(4)
    y = self:drawSection(y, "MARKET MOVERS  (per 1,000 L)")

    if #movers == 0 then
        self.r:appText(x, y - FT.py(8), FT.FONT.SMALL,
            "No sell price data found", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        y = y - FT.py(18)
    else
        for i = 1, math.min(8, #movers) do
            local m = movers[i]
            local moneyStr = self.system.data:formatMoney(math.floor(m.price * 1000 + 0.5))
            y = self:drawRow(y, m.name,
                string.format("%s  %+.1f%%", moneyStr, m.pct), nil,
                m.pct >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE)
        end
    end

    -- Extra bottom pad so the last mover and the info icon do not clip.
    self:setContentHeight(startY - y + scrollY + FT.py(28))
    self:drawInfoIcon("_mktHelp", AC)
    self:drawScrollBar()
end)
