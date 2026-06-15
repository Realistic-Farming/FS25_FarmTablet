-- =========================================================
-- FarmTablet v2 – PersonnelApp  ("Pro-Staff" personnel management)
-- =========================================================
-- The dedicated HR command center for FS25_WorkerCosts (issue #78). Three views:
--   ROSTER   — sortable/filterable worker list with metrics, plus per-worker
--              Pin/Unpin and Fire controls.
--   HIRE     — recruitment pool with signing costs; hire or reroll candidates.
--   PAYROLL  — financial review: base wage, estimate, month-to-date, and the
--              Pro-Staff modifier impact (the net effect of levels + fatigue).
--
-- All reads go through WorkerCosts' cross-repo snapshot (mgr:getRosterSnapshot);
-- all mutations go through its command API (hire/fire/assign), which is multiplayer
-- aware — a client's button press routes to the host and the result syncs back.
-- This drawer never touches WorkerCosts internals.
--
-- Scroll model: the header + tab bar are fixed. Body content scrolls. Items are
-- drawn ONLY when fully inside the body window so off-screen buttons never register
-- phantom clicks; y still advances through every item so setContentHeight reports
-- the true total and the list can scroll to its end.
-- =========================================================

-- ── Local helpers ─────────────────────────────────────────

-- The vehicle the player is currently operating (for Pin-to-vehicle).
local function getCurrentVehicle()
    if g_localPlayer and g_localPlayer.getIsInVehicle and g_localPlayer:getIsInVehicle() then
        local v = g_localPlayer.getCurrentVehicle and g_localPlayer:getCurrentVehicle()
        if v then return v end
    end
    return (g_currentMission and g_currentMission.controlledVehicle) or nil
end

local function levelColor(level)
    if level == 3 then return FT.C.TEXT_ACCENT
    elseif level == 2 then return FT.C.POSITIVE end
    return FT.C.TEXT_NORMAL
end

local function fatigueColor(pct)
    if pct >= 70 then return FT.C.NEGATIVE
    elseif pct >= 40 then return FT.C.WARNING end
    return FT.C.POSITIVE
end

local function money(n)
    return (g_i18n and g_i18n:formatMoney(n or 0, 0, true, true)) or ("$" .. tostring(n or 0))
end

local function signed(n)
    n = math.floor(n or 0)
    return (n <= 0 and "-" or "+") .. money(math.abs(n))
end

-- Register a custom-placed button for click handling this frame.
local function addBtn(self, bx, by, bw, bh, label, color, onClick)
    local btn = self.r:button(bx, by, bw, bh, label, color, { onClick = onClick })
    table.insert(self._contentBtns, btn)
    return btn
end

local function mgrRef()
    return g_currentMission and g_currentMission.workerCostsManager
end

-- ── Sort / filter cycles ──────────────────────────────────
local SORT_ORDER   = { "level", "name", "hours", "status" }
local SORT_LABEL   = { level = "Level", name = "Name", hours = "Hours", status = "Status" }
local FILTER_ORDER = { "all", "working", "idle" }
local FILTER_LABEL = { all = "All", working = "Working", idle = "Idle" }

local function nextInCycle(order, cur)
    for i, v in ipairs(order) do
        if v == cur then return order[(i % #order) + 1] end
    end
    return order[1]
end

local function sortedFilteredWorkers(snap, sortKey, filterKey)
    local out = {}
    for _, w in ipairs(snap.workers or {}) do
        local keep = (filterKey == "all")
            or (filterKey == "working" and w.working)
            or (filterKey == "idle" and not w.working)
        if keep then out[#out + 1] = w end
    end

    table.sort(out, function(a, b)
        if sortKey == "name" then
            return (a.name or "") < (b.name or "")
        elseif sortKey == "hours" then
            return (a.totalHours or 0) > (b.totalHours or 0)
        elseif sortKey == "status" then
            if a.working ~= b.working then return a.working end
            return (a.name or "") < (b.name or "")
        else -- level
            if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
            return (a.name or "") < (b.name or "")
        end
    end)
    return out
end

-- ── View: ROSTER ──────────────────────────────────────────
local function drawRoster(self, snap, bodyTop, AC)
    local x, contentY, cw = self:contentInner()
    local minY    = contentY + FT.py(8)
    local scrollY = self:getContentScrollY()
    local y       = bodyTop + scrollY
    local ROWH    = FT.py(FT.SP.ROW)

    local function visTop(top) return top <= bodyTop and top >= minY end          -- single-line item
    local function visBlock(top, h) return top <= bodyTop and (top - h) >= minY end -- multi-line block

    -- Summary
    if visTop(y) then
        self:drawRow(y, "Workers", string.format("%d  (%d working)", snap.count or 0, snap.working or 0),
            nil, (snap.working or 0) > 0 and FT.C.POSITIVE or FT.C.TEXT_DIM)
    end
    y = y - ROWH
    if visTop(y) then
        local lv = snap.levels or {}
        self:drawRow(y, "Levels", string.format("%dN / %dE / %dM",
            lv.novice or 0, lv.experienced or 0, lv.master or 0))
    end
    y = y - ROWH

    -- Sort / filter controls
    local ctlH = FT.py(16)
    local ctlW = (cw - FT.px(8)) / 2
    y = y - FT.py(2)
    if visBlock(y, ctlH) then
        addBtn(self, x, y - ctlH, ctlW, ctlH,
            "SORT: " .. (SORT_LABEL[self._psSort] or "Level"), FT.C.BTN_NEUTRAL,
            function() self._psSort = nextInCycle(SORT_ORDER, self._psSort) end)
        addBtn(self, x + ctlW + FT.px(8), y - ctlH, ctlW, ctlH,
            "FILTER: " .. (FILTER_LABEL[self._psFilter] or "All"), FT.C.BTN_NEUTRAL,
            function() self._psFilter = nextInCycle(FILTER_ORDER, self._psFilter) end)
    end
    y = y - ctlH - FT.py(8)

    if (snap.count or 0) == 0 then
        if visTop(y) then
            self.r:appText(x, y, FT.FONT.SMALL,
                "No workers yet. Open the HIRE tab to recruit.",
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        end
        y = y - FT.py(16)
        self:setContentHeight(bodyTop - y + scrollY)
        return
    end

    local workers = sortedFilteredWorkers(snap, self._psSort, self._psFilter)
    local blockH  = FT.py(48)
    local smallW  = FT.px(52)
    local smallH  = FT.py(15)

    for _, w in ipairs(workers) do
        if visBlock(y, blockH) then
            -- Line 1: name [level] ............ [PIN/UNPIN] [FIRE]
            local nm = tostring(w.name or "Worker")
            if #nm > 16 then nm = nm:sub(1, 14) .. ">" end
            self.r:appText(x, y, FT.FONT.SMALL, nm, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
            self.r:appText(x + FT.px(96), y, FT.FONT.TINY, "[" .. (w.levelName or "Novice") .. "]",
                RenderText.ALIGN_LEFT, levelColor(w.level))

            local fireX = x + cw - smallW
            local pinX  = fireX - smallW - FT.px(6)
            local uuid  = w.uuid
            local wName = w.name
            local wSev  = w.severance

            -- Pin / Unpin
            if w.pinned then
                addBtn(self, pinX, y - FT.py(2), smallW, smallH, "UNPIN", FT.C.BTN_NEUTRAL, function()
                    local mgr = mgrRef()
                    if mgr then mgr:unassignWorker(uuid) end
                    self._psMsg = "Unpinned " .. (wName or "worker")
                end)
            else
                addBtn(self, pinX, y - FT.py(2), smallW, smallH, "PIN", FT.C.BTN_PRIMARY, function()
                    local mgr = mgrRef()
                    local veh = getCurrentVehicle()
                    if not veh then
                        self._psMsg = "Enter a vehicle first, then PIN"
                        return
                    end
                    local uid = (veh.getUniqueId and veh:getUniqueId()) or nil
                    if not uid or uid == "" then
                        self._psMsg = "Vehicle has no stable id — save once, then PIN"
                        return
                    end
                    if mgr then mgr:assignWorker(uuid, uid) end
                    local vn = (veh.getFullName and veh:getFullName()) or "vehicle"
                    self._psMsg = string.format("Pinned %s to %s", wName or "worker", vn)
                end)
            end

            -- Fire (two-tap confirm)
            local confirming = (self._psConfirmFire == uuid)
            addBtn(self, fireX, y - FT.py(2), smallW, smallH,
                confirming and "SURE?" or "FIRE", FT.C.BTN_DANGER, function()
                local mgr = mgrRef()
                if confirming then
                    if mgr then mgr:fireWorker(uuid) end
                    self._psMsg = string.format("Fired %s (severance %s)", wName or "worker", money(wSev))
                    self._psConfirmFire = nil
                else
                    self._psConfirmFire = uuid
                    self._psMsg = "Tap FIRE again to confirm — severance " .. money(wSev)
                end
            end)

            -- Line 2: metrics + effective rate
            local fatPct = math.floor((w.fatigue or 0) * 100)
            self.r:appText(x, y - FT.py(15), FT.FONT.TINY,
                string.format("%.1fh  -  %d jobs  -  fatigue %d%%", w.totalHours or 0, w.totalJobs or 0, fatPct),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            self.r:appText(x + cw, y - FT.py(15), FT.FONT.TINY,
                money(math.floor(w.effRate or 0)) .. (snap.finance and snap.finance.isHourly and "/h" or "/ha"),
                RenderText.ALIGN_RIGHT, FT.C.TEXT_NORMAL)

            -- Line 3: fatigue bar
            self.r:progressBar(x, y - FT.py(30), cw, fatPct, 100, fatigueColor(fatPct))
        end
        y = y - blockH
    end

    self:setContentHeight(bodyTop - y + scrollY)
end

-- ── View: HIRE ────────────────────────────────────────────
local function drawHire(self, snap, bodyTop, AC)
    local x, contentY, cw = self:contentInner()
    local minY    = contentY + FT.py(8)
    local scrollY = self:getContentScrollY()
    local y       = bodyTop + scrollY

    local function visTop(top) return top <= bodyTop and top >= minY end
    local function visBlock(top, h) return top <= bodyTop and (top - h) >= minY end

    if visTop(y) then
        self.r:appText(x, y, FT.FONT.SMALL, "Recruitment pool", RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
        local rW = FT.px(70)
        addBtn(self, x + cw - rW, y - FT.py(2), rW, FT.py(16), "REROLL", FT.C.BTN_NEUTRAL, function()
            local mgr = mgrRef()
            if mgr then mgr:refreshRecruits() end
            self._psMsg = "Recruitment pool rerolled"
        end)
    end
    y = y - FT.py(22)

    local recruits = snap.recruits or {}
    if #recruits == 0 then
        if visTop(y) then
            self.r:appText(x, y, FT.FONT.SMALL, "No candidates available.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        end
        y = y - FT.py(16)
        self:setContentHeight(bodyTop - y + scrollY)
        return
    end

    local blockH = FT.py(34)
    local hireW  = FT.px(60)
    local hireH  = FT.py(16)
    for _, r in ipairs(recruits) do
        if visBlock(y, blockH) then
            self.r:appText(x, y, FT.FONT.SMALL, tostring(r.name or "Recruit"),
                RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)
            self.r:appText(x + FT.px(96), y, FT.FONT.TINY, "[" .. (r.levelName or "Novice") .. "]",
                RenderText.ALIGN_LEFT, levelColor(r.level))

            local slot     = r.slot
            local rName    = r.name
            local rCost    = r.hireCost
            addBtn(self, x + cw - hireW, y - FT.py(2), hireW, hireH, "HIRE", FT.C.BTN_PRIMARY, function()
                local mgr = mgrRef()
                if mgr then mgr:hireWorker(slot) end
                self._psMsg = string.format("Hired %s (signing %s)", rName or "recruit", money(rCost))
            end)

            self.r:appText(x, y - FT.py(15), FT.FONT.TINY,
                "Signing cost  " .. money(r.hireCost), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        end
        y = y - blockH
    end

    self:setContentHeight(bodyTop - y + scrollY)
end

-- ── View: PAYROLL ─────────────────────────────────────────
local function drawPayroll(self, snap, bodyTop, AC)
    local x, contentY, cw = self:contentInner()
    local minY    = contentY + FT.py(8)
    local scrollY = self:getContentScrollY()
    local y       = bodyTop + scrollY
    local fin     = snap.finance or {}
    local rateUnit = fin.isHourly and "/h" or "/ha"

    -- These leading sections are short and always near the top; the per-worker
    -- list below is what actually scrolls. drawSection/drawRow are text-only here
    -- (no buttons), so light top-overdraw while scrolling is harmless.
    y = self:drawSection(y, "WAGE STRUCTURE")
    y = self:drawRow(y, "Cost Mode",  fin.costModeName or "-")
    y = self:drawRow(y, "Wage Level", fin.wageLevelName or "-")
    y = self:drawRow(y, "Base Rate",  money(math.floor(fin.baseRate or 0)) .. rateUnit)

    y = y - FT.py(2)
    y = self:drawSection(y, "RUNNING COSTS")
    y = self:drawRow(y, "Est. Interval", money(fin.estIntervalCost or 0), nil,
        (fin.estIntervalCost or 0) > 0 and FT.C.WARNING or FT.C.TEXT_DIM)
    y = self:drawRow(y, "Month To Date", money(fin.monthAccrued or 0), nil,
        (fin.monthAccrued or 0) > 0 and FT.C.WARNING or FT.C.TEXT_DIM)

    -- Pro-Staff impact: net of all level discounts + fatigue surcharges across the
    -- roster. Negative => the crew's perks save money; positive => fatigue costs you.
    local delta = fin.proStaffDelta or 0
    local impactColor = delta < 0 and FT.C.POSITIVE or (delta > 0 and FT.C.NEGATIVE or FT.C.TEXT_DIM)
    y = y - FT.py(2)
    y = self:drawSection(y, "PRO-STAFF IMPACT")
    y = self:drawRow(y, delta <= 0 and "Net Savings" or "Net Surcharge",
        signed(delta) .. rateUnit, nil, impactColor)

    -- Per-worker effective rate breakdown (this part scrolls)
    y = y - FT.py(2)
    y = self:drawSection(y, "PER WORKER  (base " .. money(math.floor(fin.baseRate or 0)) .. rateUnit .. ")")

    local workers = sortedFilteredWorkers(snap, "level", "all")
    for _, w in ipairs(workers) do
        if y <= bodyTop and y >= minY then
            local d = w.proStaffDelta or 0
            local dCol = d < 0 and FT.C.POSITIVE or (d > 0 and FT.C.NEGATIVE or FT.C.TEXT_DIM)
            local nm = tostring(w.name or "Worker")
            if #nm > 14 then nm = nm:sub(1, 12) .. ">" end
            self.r:appText(x, y, FT.FONT.TINY, nm .. "  [" .. (w.levelName or "Novice") .. "]",
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + cw, y, FT.FONT.TINY,
                money(math.floor(w.effRate or 0)) .. rateUnit .. "  (" .. signed(d) .. ")",
                RenderText.ALIGN_RIGHT, dCol)
        end
        y = y - FT.py(13)
    end

    self:setContentHeight(bodyTop - y + scrollY)
end

-- ── Drawer entry point ────────────────────────────────────
FarmTabletUI:registerDrawer(FT.APP.PERSONNEL, function(self)
    local AC = FT.appColor(FT.APP.PERSONNEL)

    if self:drawHelpPage("_psHelp", FT.APP.PERSONNEL, "Personnel", AC, {
        { title = "WHAT THIS APP DOES",
          body  = "A personnel command center for FS25_WorkerCosts.\n" ..
                  "Manage your Pro-Staff roster: review, hire,\n" ..
                  "fire, and pin workers to vehicles." },
        { title = "ROSTER TAB",
          body  = "Every worker with level, lifetime hours, jobs,\n" ..
                  "and fatigue. Sort and filter the list. PIN a\n" ..
                  "worker to the vehicle you're driving, or FIRE\n" ..
                  "them (tap twice — severance applies)." },
        { title = "HIRE TAB",
          body  = "A rotating recruitment pool. Each candidate has\n" ..
                  "a level and a one-off signing cost. HIRE to add\n" ..
                  "them; REROLL to draw fresh candidates." },
        { title = "PAYROLL TAB",
          body  = "Wage structure, the running cost estimate, and\n" ..
                  "the Pro-Staff impact — how levels (cheaper) and\n" ..
                  "fatigue (pricier) net out across the crew." },
        { title = "MULTIPLAYER",
          body  = "The roster lives on the host. Your actions are\n" ..
                  "sent to the host and the result syncs back to\n" ..
                  "everyone automatically." },
    }) then return end

    -- View / control state defaults
    self._psView   = self._psView   or "roster"
    self._psSort   = self._psSort   or "level"
    self._psFilter = self._psFilter or "all"

    local startY = self:drawAppHeader("Personnel", "Pro-Staff")
    local x, contentY, cw = self:contentInner()
    local mgr = mgrRef()

    if not mgr then
        self.r:appText(x, startY - FT.py(12), FT.FONT.BODY,
            "Worker Costs is not installed.", RenderText.ALIGN_LEFT, FT.C.NEGATIVE)
        self.r:appText(x, startY - FT.py(30), FT.FONT.SMALL,
            "Install FS25_WorkerCosts to manage personnel.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_psHelp", AC)
        return
    end

    -- Tab bar (fixed; never scrolls)
    local tabH = FT.py(20)
    local tabY = startY - tabH
    local tbw  = (cw - FT.px(16)) / 3
    local tabs = { { id = "roster", label = "ROSTER" }, { id = "hire", label = "HIRE" }, { id = "payroll", label = "PAYROLL" } }
    for i, t in ipairs(tabs) do
        local active = (self._psView == t.id)
        local col = active and { AC[1], AC[2], AC[3], 0.95 } or FT.C.BTN_NEUTRAL
        local id = t.id
        addBtn(self, x + (i - 1) * (tbw + FT.px(8)), tabY, tbw, tabH, t.label, col, function()
            self._psView = id
            self._psConfirmFire = nil
            self._contentScrollY = 0
        end)
    end

    local bodyTop = tabY - FT.py(8)

    -- Transient status line (persists until the next action replaces it).
    if self._psMsg then
        self.r:appText(x, bodyTop, FT.FONT.TINY, self._psMsg, RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)
        bodyTop = bodyTop - FT.py(14)
    end

    local snap = (mgr.getRosterSnapshot ~= nil) and mgr:getRosterSnapshot() or nil
    if not snap then
        self.r:appText(x, bodyTop, FT.FONT.SMALL,
            "Roster data unavailable.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_psHelp", AC)
        return
    end

    if not snap.authoritative then
        -- MP client before the first host sync arrives.
        self.r:appText(x, bodyTop, FT.FONT.SMALL,
            "Syncing roster from host...", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self.r:appText(x, bodyTop - FT.py(16), FT.FONT.TINY,
            "The roster lives on the host and is loading.", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
        self:drawInfoIcon("_psHelp", AC)
        return
    end

    if self._psView == "hire" then
        drawHire(self, snap, bodyTop, AC)
    elseif self._psView == "payroll" then
        drawPayroll(self, snap, bodyTop, AC)
    else
        drawRoster(self, snap, bodyTop, AC)
    end

    self:drawInfoIcon("_psHelp", AC)
    self:drawScrollBar()
end)
