--!load: src/core/Constants.lua, src/utils/Renderer.lua, src/FarmTabletUI.lua, src/FarmTabletManager.lua, src/apps/IncomeApp.lua
-- RSF-F357 section 9b, the tablet's NPC drawer: one more reader of the owner's
-- shared work page, never a claimed zero, never a raw favour read on the
-- repaired host.
--
-- THE ENTRY-POINT BAR. The drawer is reached the way FarmTabletUI:draw reaches
-- it: through the registry IncomeApp.lua fills at load with the real
-- FarmTabletUI:registerDrawer (FarmTabletUI._appDrawers[FT.APP.NPC_FAVOR]), and
-- the release hook is the one IncomeApp.lua appended to the real
-- FarmTabletUI.update at load. The tablet UI object is a recorder over the real
-- FarmTabletUI methods (its element painters are replaced by recorders; the
-- drawer's own logic is untouched). The host is the WORLD: a stand-in of the
-- repaired host's adapter surface (getPersonalWorkView, requestPersonalWorkView,
-- watchPersonalWork, getNeighbourRosterView), whose contract is pinned by
-- NPCFavor's own spec; nothing here hand-fills what the drawer computes.
--
-- Groups: R registry; H the work page (unavailable, pending, current,
-- last-confirmed, watch and release, raw model never read, old host); N the
-- roster view; X no host.

local function group(name, fn)
    local ok, err = pcall(fn)
    if not ok then T.ok(name .. " [group crashed]", false, tostring(err)) end
end

--- The tablet UI as the drawer sees it: the real FarmTabletUI behind a recorder.
local function tablet()
    local ui = setmetatable({ isOpen = true, system = { currentApp = FT.APP.NPC_FAVOR }, rows = {}, texts = {}, sections = {} }, { __index = FarmTabletUI })
    -- Every drawn text goes through FT.l10nAuto, as the real renderer's appText and row do
    -- (Renderer.lua:77, :131), so a mapped literal is recorded in the reader's language.
    local function auto(s) return FT.l10nAuto(tostring(s)) end
    ui.r = { appText = function(_, x, y, font, text) ui.texts[#ui.texts + 1] = auto(text) end, appRect = function() end }
    function ui:drawHelpPage() return false end
    function ui:drawAppHeader() return 500 end
    function ui:contentInner() return 0, 0, 200, 0 end
    function ui:getContentScrollY() return 0 end
    function ui:drawRule(y) return y - 4 end
    function ui:drawSection(y, label) self.sections[#self.sections + 1] = tostring(label) return y - 10 end
    function ui:drawRow(y, label, value) self.rows[#self.rows + 1] = auto(label) .. "=" .. auto(value) return y - 10 end
    function ui:drawBar(y) return y - 6 end
    function ui:setContentHeight() end
    function ui:drawInfoIcon() end
    function ui:drawScrollBar() end
    return ui
end
local function draw(ui)
    ui.rows, ui.texts, ui.sections = {}, {}, {}
    FarmTabletUI._appDrawers[FT.APP.NPC_FAVOR](ui)
    return ui
end
local function has(list, needle)
    for _, s in ipairs(list) do if s == needle then return true end end
    return false
end
local function hasPrefix(list, prefix)
    for _, s in ipairs(list) do if s:sub(1, #prefix) == prefix then return true end end
    return false
end
--- The repaired host's adapter surface, with a raw favour model beside it that
--- the drawer must never read while the adapters are present.
local function host(opts)
    opts = opts or {}
    local h = { watchers = 0, requests = 0, view = opts.view, roster = opts.roster, townReputation = 55,
        favorSystem = { activeFavors = { { npcName = "Raw One", description = "Raw job", progress = 10, timeRemaining = 3600000 }, { npcName = "Raw Two", description = "Raw job", progress = 70, timeRemaining = 0 } },
                        stats = { totalFavorsCompleted = 99, totalMoneyEarned = 12345 } },
        activeNPCs = { { name = "Raw One", role = "farmer", relationship = 88, isActive = true } } }
    if opts.repaired ~= false then
        h.getPersonalWorkView = function(self) return self.view end
        h.requestPersonalWorkView = function(self) self.requests = self.requests + 1 return true end
        h.watchPersonalWork = function(self, on) self.watchers = self.watchers + (on and 1 or -1) end
    end
    if opts.roster ~= nil then h.getNeighbourRosterView = function(self) return self.roster end end
    g_NPCSystem = nil
    g_currentMission.npcFavorSystem = h
    return h
end
--- One frame of the real FarmTabletUI.update: the release hook IncomeApp.lua
--- prepended runs first; the frame's own engine work beyond it is past the mock,
--- so only the hook's effect is read here.
local function update(ui) pcall(FarmTabletUI.update, ui, 16) end

local CURRENT = { state = "CURRENT", totalKnown = true, total = 4, completedKnown = true, completedCount = 4, rows = {
    { status = "pending", npcName = "Ben", description = "Water animals", progress = 0, timeKnown = true, timeRemainingMs = 3600000 },
    { status = "active", npcName = "Greta", description = "Fix fence", progress = 50, timeKnown = true, timeRemainingMs = 7200000 },
    { status = "pending", npcName = "Cara", description = "Deliver seeds", progress = 0, timeKnown = true, timeRemainingMs = 3600000 },
    { status = "in_progress", npcName = "Anna", description = "Watch property", progress = 20, timeKnown = false, timeRemainingMs = 0 },
} }

group("R registry", function()
    T.eq("R1 [reached] the NPC drawer is in the registry IncomeApp.lua filled at load", type(FarmTabletUI._appDrawers[FT.APP.NPC_FAVOR]), "function")
    T.eq("R2 the app id is the constant the springboard uses", FT.APP.NPC_FAVOR, "npc_favor")
end)

group("X no host", function()
    g_NPCSystem = nil
    g_currentMission.npcFavorSystem = nil
    local ui = draw(tablet())
    T.ok("X1 with no host the drawer says so and draws no favour or roster rows", has(ui.texts, "NPC Favor mod not detected.") and #ui.rows == 0)
end)

group("H the work page", function()
    local h = host({ view = { state = "UNAVAILABLE", rows = {} } })
    local ui = draw(tablet())
    T.eq("H1 the first draw registers this reader once and asks for the page once (opening the screen)", h.watchers .. "/" .. h.requests, "1/1")
    T.ok("H2 an unavailable page reads unavailable, never a zero, and the raw model is not read", has(ui.rows, "Work=unavailable") and has(ui.rows, "Total Earned=unavailable") and not hasPrefix(ui.rows, "Active Favors=") and not has(ui.rows, "Completed=99"))
    draw(ui)
    T.eq("H3 a second frame registers nothing again and issues no second request", h.watchers .. "/" .. h.requests, "1/1")
    h.view = { state = "PENDING", rows = {} }
    draw(ui)
    T.ok("H4 a page still out reads unavailable, not an empty list", has(ui.rows, "Work=unavailable") and not hasPrefix(ui.rows, "Active Favors="))
    h.view = CURRENT
    draw(ui)
    T.ok("H5 a current page: this farm's accepted work counted, the offers counted, the owner's completed count", has(ui.rows, "Active Favors=2") and has(ui.rows, "Open Offers=2") and has(ui.rows, "Completed=4") and has(ui.sections, "ACTIVE"))
    T.ok("H5b an accepted row shows the host's remaining time when known", has(ui.rows, "Greta  Fix fence=50%  2h left"))
    T.ok("H5c an accepted row with no known time says so on its own line, never zero hours", has(ui.rows, "Anna  Watch property=20%") and has(ui.rows, "time unknown=") and not hasPrefix(ui.rows, "Anna  Watch property=20%  0h"))
    T.ok("H5d the raw model is never read on the repaired host: the earnings row reads unavailable, never the raw figure", not has(ui.rows, "Completed=99") and has(ui.rows, "Total Earned=unavailable") and not has(ui.rows, "Total Earned=$12345"))
    h.view = { state = "LAST_CONFIRMED", totalKnown = true, total = 4, completedKnown = true, completedCount = 4, rows = CURRENT.rows }
    draw(ui)
    T.ok("H6 a last-confirmed page carries the note as its own line, the count untouched", has(ui.rows, "Active Favors=2") and has(ui.rows, "(last confirmed)="))
    h.view = { state = "CURRENT", totalKnown = true, total = 0, completedKnown = false, rows = {} }
    draw(ui)
    T.ok("H7 an absent completed summary reads unavailable, never zero", has(ui.rows, "Completed=unavailable") and has(ui.rows, "Active Favors=0"))
    -- Leaving the app releases the page; coming back registers again and refreshes.
    ui.system.currentApp = "dashboard"
    update(ui)
    T.eq("H8 leaving the app: the update hook lets go of the page", h.watchers, 0)
    ui.system.currentApp = FT.APP.NPC_FAVOR
    draw(ui)
    T.eq("H9 back on the app: registered again and refreshed once", h.watchers .. "/" .. h.requests, "1/2")
    ui.isOpen = false
    update(ui)
    T.eq("H10 closing the tablet lets go of the page", h.watchers, 0)
    ui.isOpen = true
    draw(ui)
    T.eq("H10b [reached] drawn again while open: watching", h.watchers, 1)
    local mgr = setmetatable({ settings = { enabled = false }, ui = ui }, { __index = FarmTabletManager })
    pcall(FarmTabletManager.update, mgr, 16)
    T.eq("H10c the tablet disabled in its settings: the manager's update lets go ahead of its own return", h.watchers, 0)
    -- An older host without the adapters keeps the compatibility read.
    local old = host({ repaired = false })
    local ui2 = draw(tablet())
    T.ok("H11 an old host: the established compatibility read, and no adapter is touched", has(ui2.rows, "Active Favors=2") and has(ui2.rows, "Completed=99") and hasPrefix(ui2.rows, "Total Earned=") and old.watchers == 0)
end)

group("L the reader's language", function()
    -- The engine has the six new keys in the reader's language: every new literal
    -- lands translated, none of them as English.
    local realHas, realGet = g_i18n.hasText, g_i18n.getText
    local NEW = { ft_auto_work = "Arbeit", ft_auto_open_offers = "Offene Angebote", ft_auto_neighbours_not_available_yet = "Nachbarn noch nicht verfügbar.",
        ft_auto_last_confirmed = "(zuletzt bestätigt)", ft_auto_time_unknown = "Zeit unbekannt", ft_auto_waiting = "wartet", ft_auto_worker_2 = "Arbeiter",
        ft_auto_unavailable = "nicht verfügbar", ft_auto_total_earned = "Gesamtverdienst" }
    g_i18n.hasText = function(_, key) return NEW[key] ~= nil end
    g_i18n.getText = function(_, key) return NEW[key] or key end
    local h = host({ view = { state = "LAST_CONFIRMED", totalKnown = true, total = 4, completedKnown = true, completedCount = 4, rows = CURRENT.rows },
        roster = { schema = 1, personLoadState = "WAITING", snapshotState = "UNAVAILABLE", rows = {} } })
    local ui = draw(tablet())
    T.ok("L1 the page's new literals draw in the reader's language", has(ui.rows, "(zuletzt bestätigt)=") and has(ui.rows, "Offene Angebote=2") and has(ui.rows, "Zeit unbekannt=") and has(ui.rows, "Gesamtverdienst=nicht verfügbar"))
    T.ok("L1b and none of them as English", not has(ui.rows, "(last confirmed)=") and not has(ui.rows, "Open Offers=2") and not has(ui.rows, "time unknown="))
    T.ok("L2 the roster's not-ready line draws in the reader's language", has(ui.texts, "Nachbarn noch nicht verfügbar."))
    h.view = { state = "UNAVAILABLE", rows = {} }
    h.roster = { schema = 1, personLoadState = "READY", snapshotState = "CURRENT", rows = { { kind = "WAITING", name = "Cara", personId = 3 }, { kind = "PRESENCE", name = "Worker 1" } } }
    draw(ui)
    T.ok("L3 the tags draw in the reader's language as their own texts", has(ui.rows, "Arbeit=nicht verfügbar") and has(ui.texts, "wartet") and has(ui.texts, "Arbeiter") and not has(ui.texts, "waiting"))
    g_i18n.hasText, g_i18n.getText = realHas, realGet
end)

group("N the roster view", function()
    local h = host({ view = { state = "UNAVAILABLE", rows = {} }, roster = { schema = 1, personLoadState = "READY", snapshotState = "CURRENT", rows = {
        { kind = "LIVE", name = "Ben", trust = 30, personId = 2 },
        { kind = "LIVE", name = "Anna", roleLabel = "farmer", trust = 80, personId = 1 },
        { kind = "WAITING", name = "Cara", personId = 3, reasonKey = "npc_person_waiting_count" },
        { kind = "PRESENCE", name = "Worker 1" },
    } } })
    local ui = draw(tablet())
    T.ok("N1 live people by trust with their role and a number", has(ui.sections, "RELATIONSHIPS  (2)") and has(ui.texts, "Anna  [farmer]") and has(ui.texts, "80 Friend") and has(ui.texts, "Ben  [?]") and has(ui.texts, "30 Cold"))   -- the renderer's count-label pass collapses the score's spacing
    local annaAt, benAt = 0, 0
    for i, s in ipairs(ui.texts) do if s == "Anna  [farmer]" then annaAt = i elseif s == "Ben  [?]" then benAt = i end end
    T.ok("N1b sorted by trust, highest first", annaAt > 0 and benAt > annaAt)
    T.ok("N2 a waiting person and an observed worker are named with no number, the tag its own text", has(ui.texts, "Cara") and has(ui.texts, "waiting") and has(ui.texts, "Worker 1") and has(ui.texts, "worker") and not has(ui.texts, "0  Cold") and not has(ui.texts, "Cara  [waiting]"))
    T.ok("N3 the raw live list is not read while the roster view exists", not has(ui.texts, "Raw One  [farmer]"))
    h.roster = { schema = 1, personLoadState = "WAITING", snapshotState = "UNAVAILABLE", rows = {} }
    draw(ui)
    T.ok("N4 a roster not ready says so", has(ui.texts, "Neighbours not available yet.") and has(ui.sections, "RELATIONSHIPS  (0)"))
    host({ repaired = false })
    local ui2 = draw(tablet())
    T.ok("N5 an old host: the compatibility list from its live people", has(ui2.sections, "RELATIONSHIPS  (1)") and has(ui2.texts, "Raw One  [farmer]") and has(ui2.texts, "88 Friend"))
end)
