-- =========================================================
-- FarmTablet - Financial Cockpit (FT-6 v1)
-- =========================================================
-- Read-only whole-farm financial page. Health heart (worst-vital-wins),
-- live instruments, monthly history via own StateLedger module, and a
-- projection forecast. Moves no money. Never re-implements owning apps.
--
-- Gate: none. The page always registers because cash / leverage / runway read
-- base-game balance and loan. Time Guard is the month clock that records
-- history; without it the history vitals say so instead of promising samples.
-- Balance/loan: FT_DataProvider. Economic mods: pcall, neutral when absent.
-- =========================================================

FinancialCockpit = FinancialCockpit or {}

local LEDGER_MODULE = "FarmTablet_FinancialCockpit"
local ACCRUAL_ID    = "FarmTablet_FinancialCockpit_monthSample"
local MONTHLY_KEEP  = 36
local REFRESH_MS    = 1000

-- Balance-pass tunable bands (function is fixed; numbers can move later).
local THRESH = {
    cashGreen       = 50000,
    cashAmber       = 0,
    leverageGreen   = 0.25,
    leverageAmber   = 0.50,
    runwayGreen     = 3.0,
    runwayAmber     = 1.0,
    marginGreen     = 0.15,
    marginAmber     = 0.0,
    directionEps    = 1000,
    trajectoryEps   = 1000,
}

local BAND_RANK = { red = 3, amber = 2, green = 1 }

local _view       = "home"   -- home | vital | history | forecast | flows
local _vitalFocus = nil
local _bound      = false
local _cache      = { t = -1e9, snap = nil }

-- Own history (StateLedger-backed when present).
local _hist = {
    monthly = {},  -- array of { year, monthIndex, closingBalance, loan, perSourceFlowTotals }
    yearly  = {},  -- array of { year, yearEndBalance, yearEndLoan, perSourceFlowSums }
}

-- ── Tiny helpers ──────────────────────────────────────────

local function _T(key, fallback)
    return FT.l10n(key, fallback)
end

-- IncomeMod's pay mode name is English ("Hourly" / "Daily", Settings:getPayModeName); the tablet's words for them are
-- the Income app's keys. Any other name is IncomeMod's own text and keeps the renderer's pass.
local PAY_MODE_WORD = {
    Hourly = function() return _T("ft_companion_hourly", "Hourly") end,
    Daily  = function() return _T("ft_companion_daily", "Daily") end,
}
local function _payModeText(mode)
    local w = PAY_MODE_WORD[tostring(mode)]
    if w then return w(), true end
    return tostring(mode), false
end

local function _pcall(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function _money(data, n)
    n = tonumber(n) or 0
    if data and data.formatMoney then return data:formatMoney(n) end
    if g_i18n and g_i18n.formatMoney then return g_i18n:formatMoney(n, 0, true, true) end
    return string.format("$%.0f", n)
end

local function _timeGuard()
    return g_currentMission and g_currentMission.timeGuard or nil
end

local function _stateLedger()
    return g_currentMission and g_currentMission.stateLedger or nil
end

local function _isServer()
    return g_currentMission ~= nil and g_currentMission.getIsServer
        and g_currentMission:getIsServer()
end

-- Best-effort: dedicated peers have no host FarmTablet recorder.
-- Time Guard is the month clock that closes a row. Without it nothing ever
-- records, so say that plainly rather than promising samples that never come.
local function _historyMode()
    if _timeGuard() == nil then return "no_clock" end
    if _isServer() then return "available" end
    local m = g_currentMission
    if m ~= nil and (m.isDedicatedServer == true
        or (m.missionDynamicInfo and m.missionDynamicInfo.isDedicatedServer == true)) then
        return "dedicated"
    end
    return "host_only"
end

local function _nowMs()
    return (g_currentMission and g_currentMission.time) or 0
end

local function _finiteNumber(v)
    local n = tonumber(v)
    if n == nil or n ~= n then return nil end
    if n == math.huge or n == -math.huge then return nil end
    return n
end

local function _farmExcluded(id)
    return id == 0 or id == 14 or id == 15
end

local function _historyFarmId(row)
    if type(row) ~= "table" then return nil end
    return _finiteNumber(row.farmId)
end

-- Same live farm object only. Never invent farm 1.
local function _playerFarmIds()
    local mgr = g_farmManager
    if mgr == nil or type(mgr.getFarms) ~= "function" or type(mgr.getFarmById) ~= "function" then
        return nil
    end
    local farms = mgr:getFarms()
    if type(farms) ~= "table" then return nil end
    local ids = {}
    for _, farm in ipairs(farms) do
        if type(farm) == "table" then
            local id = _finiteNumber(farm.farmId)
            if id ~= nil and not _farmExcluded(id) and mgr:getFarmById(id) == farm then
                ids[#ids + 1] = id
            end
        end
    end
    return ids
end

-- Client wire cash/outstanding/offer are 0-coerced. Outstanding is trusted on the
-- server when finite (including explicit 0). Otherwise only principal+accruedInterest
-- when both are finite. A lone 0 outstanding on a client is not debt-free.
local function _trustedOutstanding(view)
    if type(view) ~= "table" then return nil end
    if _isServer() then
        local outstanding = _finiteNumber(view.outstanding)
        if outstanding ~= nil then return outstanding end
    end
    local principal = _finiteNumber(view.principal)
    local interest = _finiteNumber(view.accruedInterest)
    if principal ~= nil and interest ~= nil then
        return principal + interest
    end
    return nil
end


-- Debt is COMPLETE only for version 1, a real farm id, and readiness READY.
-- Nil version, nil farm, or an unknown readiness such as FUTURE_STATE stays incomplete.
local function _ownerDebtReady(view, farmId)
    if type(view) ~= "table" then return false end
    if tonumber(view.version) ~= 1 then return false end
    local viewFarm = _finiteNumber(view.farmId)
    if viewFarm == nil then return false end
    if farmId ~= nil and viewFarm ~= _finiteNumber(farmId) then return false end
    return view.readiness == "READY"
end


local function _costRows(list)
    local out = {}
    if type(list) ~= "table" then return out end
    for _, item in ipairs(list) do
        if type(item) == "table" then
            out[#out + 1] = {
                sourceId = type(item.sourceId) == "string" and item.sourceId or nil,
                amount = _finiteNumber(item.amount),
                basis = type(item.basis) == "string" and item.basis or nil,
                dueDay = _finiteNumber(item.dueDay),
                dueTimeMs = _finiteNumber(item.dueTimeMs),
            }
        end
    end
    return out
end

local function _missingCodes(list)
    local out = {}
    if type(list) ~= "table" then return out end
    for _, code in ipairs(list) do
        if type(code) == "string" then
            out[#out + 1] = code
        end
    end
    return out
end

local function _outlookFrom(view)
    if type(view) ~= "table" then
        return { status = "UNAVAILABLE", knownCosts = {}, estimatedCosts = {}, missing = {} }
    end
    local status = view.forecastStatus
    if status ~= "OK" and status ~= "PARTIAL" and status ~= "UNAVAILABLE" then
        status = "UNAVAILABLE"
    end
    local basis = view.workingCashBasis
    if basis ~= "HALF_PERIOD_GROSS" and basis ~= "FALLBACK_10000" then
        basis = nil
    end
    return {
        status = status,
        minimum = _finiteNumber(view.minimumBalance),
        shortfall = _finiteNumber(view.shortfall),
        gross = _finiteNumber(view.expectedGrossIncome),
        net = _finiteNumber(view.expectedNetIncome),
        workingCash = _finiteNumber(view.workingCashAmount),
        basis = basis,
        horizon = type(view.horizonEnd) == "table",
        knownCosts = _costRows(view.knownCosts),
        estimatedCosts = _costRows(view.estimatedCosts),
        missing = _missingCodes(view.missingInputs),
    }
end

local function _ownFarmMonthly(farmId)
    local id = _finiteNumber(farmId)
    if id == nil or _farmExcluded(id) then return {} end
    local out = {}
    for _, row in ipairs(_hist.monthly) do
        if _historyFarmId(row) == id then
            out[#out + 1] = row
        end
    end
    return out
end

local function _ownFarmYearly(farmId)
    local id = _finiteNumber(farmId)
    if id == nil or _farmExcluded(id) then return {} end
    local out = {}
    for _, row in ipairs(_hist.yearly) do
        if _historyFarmId(row) == id then
            out[#out + 1] = row
        end
    end
    return out
end

local function _rowNetWorth(row)
    if type(row) ~= "table" then return nil end
    local bal = _finiteNumber(row.closingBalance)
    if bal == nil then return nil end
    local basis = row.debtBasis
    local debt = nil
    if basis == "COMPLETE" then
        debt = _finiteNumber(row.totalDebt)
    elseif basis == "NATIVE_ONLY" then
        debt = _finiteNumber(row.loan)
        if debt == nil then debt = _finiteNumber(row.nativeLoan) end
    end
    if debt == nil then return nil end
    return bal - debt
end

local function _moneyKnown(data, n)
    if _finiteNumber(n) == nil then return nil end
    return _money(data, n)
end


local function _bandColor(band)
    if band == "green" then return FT.C.POSITIVE end
    if band == "amber" then return FT.C.WARNING end
    if band == "red" then return FT.C.NEGATIVE end
    if band == "partial" then return FT.C.TEXT_ACCENT end
    return FT.C.MUTED
end

local function _bandLabel(band)
    if band == "green" then return _T("ft_fc_band_green", "Healthy") end
    if band == "amber" then return _T("ft_fc_band_amber", "Watch") end
    if band == "red" then return _T("ft_fc_band_red", "Critical") end
    if band == "partial" then return _T("ft_fc_band_partial", "Partial / Estimated") end
    return _T("ft_fc_band_neutral", "Neutral")
end

-- ── Flow reads (neutral when absent; never invent) ────────

local function _readIncomeFlow()
    local mgr = g_currentMission and g_currentMission.incomeManager
    if mgr == nil then return nil end
    local settings = mgr.settings
    local amount = nil
    local mode = nil
    local nextInfo = nil
    local seasonMult = nil
    if settings ~= nil then
        if type(settings.getPaymentAmount) == "function" then
            amount = _pcall(function() return settings:getPaymentAmount() end)
        end
        if type(settings.getPayModeName) == "function" then
            mode = _pcall(function() return settings:getPayModeName() end)
        end
    end
    local sys = mgr.system or mgr
    if type(sys.getNextPaymentInfo) == "function" then
        nextInfo = _pcall(function() return sys:getNextPaymentInfo() end)
    elseif type(mgr.getNextPaymentInfo) == "function" then
        nextInfo = _pcall(function() return mgr:getNextPaymentInfo() end)
    end
    if type(sys.getSeasonalMultiplier) == "function" then
        seasonMult = _pcall(function() return sys:getSeasonalMultiplier() end)
    end
    return {
        present = true,
        amount = tonumber(amount),
        mode = mode,
        nextInfo = nextInfo,
        seasonMult = tonumber(seasonMult),
    }
end

local function _readTaxFlow()
    local mgr = g_currentMission and g_currentMission.taxManager
    if mgr == nil then return nil end
    local state = nil
    if type(mgr.serializeState) == "function" then
        state = _pcall(function() return mgr.serializeState() end)
    elseif type(FS25TaxMod) == "table" and type(FS25TaxMod.serializeState) == "function" then
        state = _pcall(function() return FS25TaxMod.serializeState() end)
    end
    local stats = state and state.stats or nil
    -- Consume ONLY live fields (brief). Drop dead totalTaxesReturned / taxesThisMonth / monthsReturned.
    local totalPaid = stats and tonumber(stats.totalTaxesPaid) or nil
    local annualAcc = stats and tonumber(stats.taxesAccumulatedAnnual) or nil
    return {
        present = true,
        totalTaxesPaid = totalPaid,
        taxesAccumulatedAnnual = annualAcc,
        lastTaxYear = stats and tonumber(stats.lastTaxYear) or nil,
    }
end

local function _readWageFlow()
    local mgr = g_currentMission and g_currentMission.workerCostsManager
    if mgr == nil or type(mgr.getRosterSnapshot) ~= "function" then return nil end
    local snap = _pcall(function() return mgr:getRosterSnapshot() end)
    if type(snap) ~= "table" then return nil end
    local fin = snap.finance or {}
    return {
        present = true,
        monthAccrued = tonumber(fin.monthAccrued),
        estIntervalCost = tonumber(fin.estIntervalCost),
    }
end

local function _readCoopSignal()
    local mgr = g_currentMission and g_currentMission.proStaffManager
    if mgr == nil or type(mgr.getLevel) ~= "function" then return nil end
    local farmId = 1
    if g_localPlayer then
        farmId = (g_localPlayer.getFarmId and g_localPlayer:getFarmId()) or g_localPlayer.farmId or 1
    end
    local level = _pcall(function() return mgr:getLevel(farmId) end)
    if level == nil then return nil end
    return { present = true, level = tonumber(level) or 0 }
end

local function _readDairySignal()
    local mgr = g_currentMission and g_currentMission.dairyCoreManager
    if mgr == nil or type(mgr.getBarnRows) ~= "function" then return nil end
    local rows = _pcall(function() return mgr:getBarnRows() end)
    if type(rows) ~= "table" then return nil end
    -- Signal only (health / spoilage / tier). Contract income is a maturity ask.
    local health, spoilage, tier = nil, nil, nil
    for _, row in ipairs(rows) do
        if type(row) == "table" then
            health = health or row.health or row.herdHealth
            spoilage = spoilage or row.spoilage
            tier = tier or row.qualityTier or row.tierName or row.tier
        end
    end
    return { present = true, barnCount = #rows, health = health, spoilage = spoilage, tier = tier }
end

local function _readMarketSignal()
    local mgr = (g_currentMission and g_currentMission.MarketDynamics)
        or getfenv(0)["g_MarketDynamics"]
    if mgr == nil then return nil end
    local events = nil
    if mgr.worldEvents and type(mgr.worldEvents.getActiveEvents) == "function" then
        events = _pcall(function() return mgr.worldEvents:getActiveEvents() end)
    end
    return {
        present = true,
        activeEvents = type(events) == "table" and #events or 0,
    }
end

local function _readRweSignal()
    -- Handle: g_currentMission.randomWorldEvents (see RandomWorldEventsApp).
    local mgr = g_currentMission and g_currentMission.randomWorldEvents
    if mgr == nil then return nil end
    local ev, intensity = nil, nil
    if type(mgr.getActiveEvent) == "function" then
        ev = _pcall(function() return mgr:getActiveEvent() end)
    elseif type(mgr.EVENT_STATE) == "table" then
        ev = mgr.EVENT_STATE.activeEvent
    end
    if type(mgr.getEventIntensity) == "function" then
        intensity = _pcall(function() return mgr:getEventIntensity() end)
    elseif type(mgr.events) == "table" then
        intensity = mgr.events.intensity
    end
    return { present = true, event = ev, intensity = intensity }
end

-- getActiveEvent() hands back a table ({ name, intensity, category, remainingMs }
-- from RandomWorldEvents, or the event definition from its category API), so the
-- signal row reads a display field and never tostring()s the table.
local function _rweEventLabel(ev)
    local raw
    if type(ev) == "table" then
        raw = ev.title or ev.name or ev.displayName or ev.id or ev.eventId
    else
        raw = ev
    end
    if raw == nil or raw == "" then return "?" end
    -- "field_mice_invasion" -> "Field mice invasion" (same rule as the RWE app).
    local label = tostring(raw):gsub("_", " ")
    return label:sub(1, 1):upper() .. label:sub(2)
end

local function _flowGaps(flows)
    -- Dollar-flow gaps that force PARTIAL on derived vitals / forecast.
    local gaps = {}
    if flows.income == nil then gaps[#gaps + 1] = "income" end
    if flows.tax == nil then gaps[#gaps + 1] = "tax" end
    if flows.wages == nil then gaps[#gaps + 1] = "wages" end
    -- Maturity-ask gaps (fuel / dairy contract / RWE money) always open in v1.
    gaps[#gaps + 1] = "fuel"
    gaps[#gaps + 1] = "dairy_income"
    gaps[#gaps + 1] = "rwe_money"
    return gaps
end

-- ── History (upsert + retention) ──────────────────────────

local function _sortMonthly()
    table.sort(_hist.monthly, function(a, b)
        if a.year ~= b.year then return a.year < b.year end
        return a.monthIndex < b.monthIndex
    end)
end

local function _upsertMonth(row)
    if type(row) ~= "table" then return end
    local y = tonumber(row.year)
    local m = tonumber(row.monthIndex)
    if y == nil or m == nil then return end
    row.year = y
    row.monthIndex = m
    row.closingBalance = _finiteNumber(row.closingBalance)
    row.loan = _finiteNumber(row.loan)
    row.farmId = _historyFarmId(row)
    row.perSourceFlowTotals = type(row.perSourceFlowTotals) == "table" and row.perSourceFlowTotals or {}

    local replaced = false
    local newFarm = _historyFarmId(row)
    for i, existing in ipairs(_hist.monthly) do
        -- Untagged legacy rows do not match a farm-tagged row.
        if existing.year == y and existing.monthIndex == m and _historyFarmId(existing) == newFarm then
            _hist.monthly[i] = row
            replaced = true
            break
        end
    end
    if not replaced then
        _hist.monthly[#_hist.monthly + 1] = row
    end
    _sortMonthly()
    FinancialCockpit._rollupIfNeeded()
end

function FinancialCockpit._rollupIfNeeded()
    while #_hist.monthly > MONTHLY_KEEP do
        local oldest = _hist.monthly[1]
        table.remove(_hist.monthly, 1)
        local year = oldest.year
        local yr = nil
        local fid = _historyFarmId(oldest)
        for _, yrow in ipairs(_hist.yearly) do
            if yrow.year == year and _historyFarmId(yrow) == fid then yr = yrow; break end
        end
        if yr == nil then
            yr = {
                year = year,
                farmId = oldest.farmId,
                debtBasis = oldest.debtBasis,
                yearEndBalance = oldest.closingBalance,
                yearEndLoan = oldest.loan,
                yearEndDebt = oldest.totalDebt,
                perSourceFlowSums = {},
            }
            _hist.yearly[#_hist.yearly + 1] = yr
        end
        yr.yearEndBalance = oldest.closingBalance
        yr.yearEndLoan = oldest.loan
        yr.yearEndDebt = oldest.totalDebt
        yr.debtBasis = oldest.debtBasis
        local sums = yr.perSourceFlowSums
        for k, v in pairs(oldest.perSourceFlowTotals or {}) do
            sums[k] = (tonumber(sums[k]) or 0) + (tonumber(v) or 0)
        end
    end
    table.sort(_hist.yearly, function(a, b) return a.year < b.year end)
end

local function _serializeHistory()
    return {
        version = 1,
        monthly = _hist.monthly,
        yearly = _hist.yearly,
    }
end

local function _deserializeHistory(data)
    _hist.monthly = {}
    _hist.yearly = {}
    if type(data) ~= "table" then return end
    if type(data.monthly) == "table" then
        for _, row in ipairs(data.monthly) do
            if type(row) == "table" then
                local y = _finiteNumber(row.year)
                local m = _finiteNumber(row.monthIndex)
                if y ~= nil and m ~= nil then
                    local farmId = _historyFarmId(row)
                    local basis = type(row.debtBasis) == "string" and row.debtBasis or nil
                    -- Old rows have no farm tag and no basis. Keep them unattributed.
                    if farmId == nil and basis == nil then
                        basis = "LEGACY_NATIVE_ONLY"
                    end
                    _hist.monthly[#_hist.monthly + 1] = {
                        year = y,
                        monthIndex = m,
                        farmId = farmId,
                        closingBalance = _finiteNumber(row.closingBalance),
                        loan = _finiteNumber(row.loan),
                        nativeLoan = _finiteNumber(row.nativeLoan),
                        emergencyDebt = _finiteNumber(row.emergencyDebt),
                        totalDebt = _finiteNumber(row.totalDebt),
                        debtBasis = basis,
                        flowBasis = type(row.flowBasis) == "string" and row.flowBasis or nil,
                        perSourceFlowTotals = type(row.perSourceFlowTotals) == "table" and row.perSourceFlowTotals or {},
                    }
                end
            end
        end
    end
    if type(data.yearly) == "table" then
        for _, row in ipairs(data.yearly) do
            if type(row) == "table" then
                local y = _finiteNumber(row.year)
                if y ~= nil then
                    local yFarm = _historyFarmId(row)
                    local yBasis = type(row.debtBasis) == "string" and row.debtBasis or nil
                    if yFarm == nil and yBasis == nil then
                        yBasis = "LEGACY_NATIVE_ONLY"
                    end
                    _hist.yearly[#_hist.yearly + 1] = {
                        year = y,
                        farmId = yFarm,
                        debtBasis = yBasis,
                        yearEndBalance = _finiteNumber(row.yearEndBalance),
                        yearEndLoan = _finiteNumber(row.yearEndLoan),
                        yearEndDebt = _finiteNumber(row.yearEndDebt),
                        perSourceFlowSums = type(row.perSourceFlowSums) == "table" and row.perSourceFlowSums or {},
                    }
                end
            end
        end
    end
    _sortMonthly()
    FinancialCockpit._rollupIfNeeded()
end

local function _sampleOneFarm(ctx, farmId, dataProvider, mgr)
    local providerBalance = nil
    if dataProvider and dataProvider.getBalance then
        providerBalance = _finiteNumber(_pcall(function() return dataProvider:getBalance(farmId) end))
    end
    local providerLoan = nil
    if dataProvider and dataProvider.getLoan then
        providerLoan = _finiteNumber(_pcall(function() return dataProvider:getLoan(farmId) end))
    end

    local year = _finiteNumber(ctx and ctx.year)
    local period = _finiteNumber(ctx and ctx.period)
    if year == nil or period == nil then return end
    local closedMonth = period - 1
    local closedYear = year
    if closedMonth < 1 then
        closedMonth = 12
        closedYear = year - 1
    end
    if closedYear == nil then return end

    local debtBasis = "INCOMPLETE"
    local nativeLoan, emergencyDebt, totalDebt = nil, nil, nil
    local balance = nil
    local view = nil
    if mgr ~= nil and type(mgr.getEmergencyLoanView) == "function" then
        view = _pcall(function() return mgr:getEmergencyLoanView(farmId) end)
        if not _ownerDebtReady(view, farmId) then
            view = nil
        end
        if view ~= nil then
            -- Keep the owner fraction. A missing cash figure is not the rounded cache.
            balance = _finiteNumber(view.cash)
        end
        local nLoan, outstanding = nil, nil
        if view ~= nil then
            nLoan = _finiteNumber(view.nativeLoan)
            outstanding = _trustedOutstanding(view)
        end
        if nLoan ~= nil and outstanding ~= nil then
            debtBasis = "COMPLETE"
            nativeLoan = nLoan
            emergencyDebt = outstanding
            totalDebt = nLoan + outstanding
        end
    elseif providerLoan ~= nil then
        debtBasis = "NATIVE_ONLY"
        balance = providerBalance
        nativeLoan = providerLoan
        totalDebt = providerLoan
    end

    -- Accrual pulses and the forecast are not this period's cash-flow totals.
    _upsertMonth({
        year = closedYear,
        monthIndex = closedMonth,
        farmId = farmId,
        closingBalance = balance,
        loan = nativeLoan,
        nativeLoan = nativeLoan,
        emergencyDebt = emergencyDebt,
        totalDebt = totalDebt,
        debtBasis = debtBasis,
        perSourceFlowTotals = {},
        flowBasis = "UNAVAILABLE",
    })
end

local function _sampleClosedMonth(ctx)
    if not _isServer() then return end
    local dataProvider = nil
    local ft = getfenv(0)["g_FarmTablet"]
    if ft and ft.system and ft.system.data then
        dataProvider = ft.system.data
    end
    local ids = _playerFarmIds()
    if ids == nil then return end
    local mgr = g_currentMission and g_currentMission.incomeManager or nil
    for _, farmId in ipairs(ids) do
        _sampleOneFarm(ctx, farmId, dataProvider, mgr)
    end
end

function FinancialCockpit.bind()
    if _bound then return true end
    local tg = _timeGuard()
    if tg == nil then return false end

    local ledger = _stateLedger()
    if ledger ~= nil and type(ledger.registerModule) == "function" then
        pcall(function()
            ledger:registerModule(LEDGER_MODULE, {
                serialize = function()
                    return _serializeHistory()
                end,
                deserialize = function(data)
                    _deserializeHistory(data)
                end,
            })
        end)
    end

    -- Prefer no-money month accrual (server-only, cursor-idempotent).
    if type(tg.registerAccrual) == "function" then
        pcall(function()
            tg:registerAccrual(ACCRUAL_ID, {
                cadence = "month",
                flowClass = "event",
                firstPeriodPolicy = "skip",
                priority = 900,
                onSettle = function(ctx)
                    _sampleClosedMonth(ctx)
                end,
            })
        end)
    elseif type(tg.subscribeTick) == "function" then
        pcall(function()
            tg:subscribeTick("month", ACCRUAL_ID, function(ctx)
                _sampleClosedMonth(ctx)
            end)
        end)
    end

    _bound = true
    return true
end

function FinancialCockpit.getHistory()
    return _hist
end

-- [RSF-F130] The emergency-loan owner view (guarded; neutral when absent). IncomeMod is
-- the sole provider; this reader never computes a competing balance or writes debt.
--   nil                -> owner absent  => explicit NATIVE_ONLY cockpit mode
--   { available=false }-> owner present but the view is unavailable/unready (combined
--                         debt-dependent vitals are UNAVAILABLE, never native-only healthy)
--   { available=true, outstanding=, nativeLoan=, readiness= }
local function _readEmergencyLoanView(farmId)
    local mgr = g_currentMission and g_currentMission.incomeManager
    if mgr == nil or type(mgr.getEmergencyLoanView) ~= "function" then
        return nil
    end
    local view = _pcall(function() return mgr:getEmergencyLoanView(farmId) end)
    if type(view) ~= "table" then return { rejected = true } end
    if tonumber(view.version) ~= 1 or _finiteNumber(view.farmId) == nil then
        return { rejected = true }
    end
    if farmId ~= nil and _finiteNumber(view.farmId) ~= _finiteNumber(farmId) then
        return { rejected = true }
    end
    -- cash, outstanding and offer are not copied. The client wire forces those to 0.
    return { view = view }
end

local function _netWorth(balance, loan)
    return (tonumber(balance) or 0) - (tonumber(loan) or 0)
end

local function _leverageRatio(balance, loan)
    balance = tonumber(balance) or 0
    loan = tonumber(loan) or 0
    local denom = balance + loan
    if denom <= 0 then
        if loan > 0 then return 1 end
        return 0
    end
    return loan / denom
end


local function _outlookPresentation(snap)
    local o = snap.outlook or { status = "UNAVAILABLE" }
    local sleep = _T("ft_fc_outlook_sleep",
        "Scheduled payments skipped while sleeping are not guaranteed receipts.")
    local unavailable = _T("ft_fc_outlook_unavailable", "Outlook unavailable")
    local partialText = _T("ft_fc_outlook_partial", "Partial outlook")
    if o.status ~= "OK" and o.status ~= "PARTIAL" then
        return unavailable, "neutral", unavailable
    end
    local partial = o.status == "PARTIAL"
    if o.shortfall ~= nil and o.shortfall > 0 then
        local shown = _moneyKnown(snap.data, o.shortfall)
        if shown == nil then
            if partial then return partialText, "partial", sleep end
            return unavailable, "neutral", sleep
        end
        return FT.l10nFormat("ft_fc_outlook_shortfall", "Shortage %s", shown),
            partial and "partial" or "red", sleep
    end
    if o.minimum ~= nil and o.minimum < 0 then
        local shown = _moneyKnown(snap.data, o.minimum)
        if shown == nil then
            if partial then return partialText, "partial", sleep end
            return unavailable, "neutral", sleep
        end
        return FT.l10nFormat("ft_fc_outlook_minimum", "Lowest cash %s", shown),
            partial and "partial" or "red", sleep
    end
    if partial then
        return partialText, "partial", sleep
    end
    if o.minimum == nil then
        return unavailable, "neutral", sleep
    end
    return _T("ft_fc_outlook_no_shortage", "No shortage predicted this period"), "neutral", sleep
end

local function _buildVitals(snap)
    local vitals = {}
    local balance = snap.balance
    local loan = snap.loan
    local nw = snap.netWorth
    local histMode = snap.historyMode
    local gaps = snap.flowGaps
    local hasFlowGap = #gaps > 0
    local monthly = _hist.monthly

    -- Cash position (live)
    local cashBand
    if balance >= THRESH.cashGreen then cashBand = "green"
    elseif balance >= THRESH.cashAmber then cashBand = "amber"
    else cashBand = "red" end
    vitals[#vitals + 1] = {
        id = "cash",
        label = _T("ft_fc_vital_cash", "Cash position"),
        band = cashBand,
        valueText = _money(snap.data, balance),
        detail = _T("ft_fc_vital_cash_detail", "Available farm balance."),
    }

    -- Leverage + whole-farm debt (RSF-F130: native bank loan + emergency outstanding).
    local levCash, levDebt = nil, nil
    if snap.debtBasis == "NATIVE_ONLY" then
        levCash, levDebt = snap.balance, snap.loan
    elseif snap.debtBasis == "COMPLETE" and snap.ownerCash ~= nil and snap.totalDebt ~= nil then
        levCash, levDebt = snap.ownerCash, snap.totalDebt
    end
    if levCash == nil then
        -- Owner present but cash or debt is missing. Not a native-only healthy reading.
        -- The two causes read differently to the player: an INCOMPLETE debt basis means the
        -- emergency-loan debt cannot be read, a nil cash figure means the owner's cash cannot.
        -- NOTE: ft_fc_leverage_cash is absent from all 26 locale files, so the cash branch still
        -- renders its English fallback until a translator adds it.
        local levDetail
        if snap.debtBasis == "INCOMPLETE" then
            levDetail = _T("ft_fc_vital_leverage_unavailable",
                "Emergency-loan debt is unavailable, so combined leverage can't be shown yet.")
        else
            levDetail = _T("ft_fc_leverage_cash",
                "Owner cash is unavailable, so leverage can't be shown.")
        end
        -- [RSF-F130 :33, :74] Name the three figures here too, and name them FIRST. The
        -- breakdown is what the brief requires the cockpit to display, and an unknown one
        -- reads Unavailable (:45, :74, :91) rather than 0 or a native-only healthy number.
        -- The reason follows the breakdown so the player still gets both. Order within the
        -- row is layout, which ":4 what is left to Wizard" leaves here.
        do
            local function owed(v)
                return _moneyKnown(snap.data, v) or _T("ft_fc_unavailable", "Unavailable")
            end
            levDetail = string.format("%s %s  .  %s %s  .  %s %s  .  %s",
                _T("ft_fc_debt_native", "Bank loan"), owed(snap.nativeLoan),
                _T("ft_fc_debt_emergency", "Emergency"), owed(snap.emergencyOutstanding),
                _T("ft_fc_debt_total", "Total debt"), owed(snap.totalDebt),
                levDetail)
        end
        vitals[#vitals + 1] = {
            id = "leverage",
            label = _T("ft_fc_vital_leverage", "Leverage"),
            band = "partial",
            valueText = _T("ft_fc_partial", "PARTIAL"),
            detail = levDetail,
        }
    else
        local totalDebt = levDebt
        local lev = _leverageRatio(levCash, totalDebt)
        local levBand
        if lev <= THRESH.leverageGreen then levBand = "green"
        elseif lev <= THRESH.leverageAmber then levBand = "amber"
        else levBand = "red" end
        local detail
        -- [RSF-F130 :33, :74] With a current matching owner view the cockpit displays
        -- Native bank loan, Emergency loan and Total debt SEPARATELY. Keyed on the view
        -- being READY (debtBasis COMPLETE, which _ownerDebtReady grants only for version 1,
        -- a real farm id and readiness READY), NOT on the emergency balance happening to be
        -- positive: a READY view with nothing outstanding still owes the player the
        -- breakdown, and collapsing to the combined line hides the three figures the brief
        -- requires. Each one goes through _moneyKnown, so an unknown input reads Unavailable
        -- (:45, :74, :91) rather than 0 or a native-only healthy reading. NATIVE_ONLY keeps
        -- the single line, because with the owner absent the cockpit stays native-only.
        if snap.debtBasis == "COMPLETE" then
            local function owed(v)
                return _moneyKnown(snap.data, v) or _T("ft_fc_unavailable", "Unavailable")
            end
            detail = string.format("%s %s  .  %s %s  .  %s %s",
                _T("ft_fc_debt_native", "Bank loan"), owed(snap.nativeLoan),
                _T("ft_fc_debt_emergency", "Emergency"), owed(snap.emergencyOutstanding),
                _T("ft_fc_debt_total", "Total debt"), owed(totalDebt))
        else
            detail = string.format("%s %s",
                _T("ft_fc_vital_leverage_detail", "Loan share of balance plus loan."),
                _money(snap.data, totalDebt))
        end
        vitals[#vitals + 1] = {
            id = "leverage",
            label = _T("ft_fc_vital_leverage", "Leverage"),
            band = levBand,
            valueText = string.format("%.0f%%", lev * 100),
            detail = detail,
        }
    end

    -- One-period owner outlook. Never a wage-interval runway and never 99 months.
    local oText, oBand, oDetail = _outlookPresentation(snap)
    vitals[#vitals + 1] = {
        id = "runway",
        label = _T("ft_fc_outlook", "One-period outlook"),
        band = oBand,
        valueText = oText,
        detail = oDetail,
    }

    -- History-derived vitals
    if histMode == "no_clock" then
        local noClock = _T("ft_fc_history_no_clock", "Needs Time Guard")
        local noClockDetail = _T("ft_fc_history_no_clock_detail",
            "Install Time Guard to record monthly history. Live vitals still stand.")
        for _, id in ipairs({ "direction", "margin", "trajectory" }) do
            vitals[#vitals + 1] = {
                id = id,
                label = _T("ft_fc_vital_" .. id, id),
                band = "neutral",
                valueText = noClock,
                detail = noClockDetail,
            }
        end
    elseif histMode == "dedicated" then
        local unavailable = _T("ft_fc_history_dedicated", "Unavailable on this server")
        for _, id in ipairs({ "direction", "margin", "trajectory" }) do
            vitals[#vitals + 1] = {
                id = id,
                label = _T("ft_fc_vital_" .. id, id),
                band = "neutral",
                valueText = unavailable,
                detail = unavailable,
            }
        end
    elseif histMode == "host_only" then
        local hostOnly = _T("ft_fc_history_host_only", "Host-only in v1")
        for _, idLabel in ipairs({
            { "direction", _T("ft_fc_vital_direction", "Profit direction") },
            { "margin", _T("ft_fc_vital_margin", "Margin") },
            { "trajectory", _T("ft_fc_vital_trajectory", "Net-worth trajectory") },
        }) do
            vitals[#vitals + 1] = {
                id = idLabel[1],
                label = idLabel[2],
                band = "neutral",
                valueText = hostOnly,
                detail = _T("ft_fc_history_host_only_detail", "Monthly history is recorded on the host. Live cash and leverage still stand."),
            }
        end
    else
        -- Own-farm tagged rows only. Legacy untagged rows are not this farm's book.
        local monthly = _ownFarmMonthly(snap.farmId)
        if #monthly == 0 then
            local missing = _T("ft_fc_history_own_unavailable", "History unavailable")
            local missingDetail = _T("ft_fc_history_own_detail", "No trusted history for this farm.")
            for _, idLabel in ipairs({
                { "direction", _T("ft_fc_vital_direction", "Profit direction") },
                { "margin", _T("ft_fc_vital_margin", "Margin") },
                { "trajectory", _T("ft_fc_vital_trajectory", "Net-worth trajectory") },
            }) do
                vitals[#vitals + 1] = {
                    id = idLabel[1],
                    label = idLabel[2],
                    band = "neutral",
                    valueText = missing,
                    detail = missingDetail,
                }
            end
        else
        -- Direction from last two comparable own-farm closes
        local prevNw, lastNw = nil, nil
        if #monthly >= 2 then
            local aRow, bRow = monthly[#monthly - 1], monthly[#monthly]
            if aRow.debtBasis ~= nil and aRow.debtBasis == bRow.debtBasis
                and aRow.debtBasis ~= "INCOMPLETE" then
                prevNw = _rowNetWorth(aRow)
                lastNw = _rowNetWorth(bRow)
            end
        end
        if #monthly < 2 then
            vitals[#vitals + 1] = {
                id = "direction",
                label = _T("ft_fc_vital_direction", "Profit direction"),
                band = "neutral",
                valueText = _T("ft_fc_no_history_yet", "No history yet"),
                detail = _T("ft_fc_vital_direction_wait", "Needs at least two monthly samples."),
            }
        else
            local d = nil
            if prevNw ~= nil and lastNw ~= nil then
                d = lastNw - prevNw
            end
            if d == nil then
                vitals[#vitals + 1] = {
                    id = "direction",
                    label = _T("ft_fc_vital_direction", "Profit direction"),
                    band = "neutral",
                    valueText = _T("ft_fc_history_basis", "Not compared. Debt records do not match."),
                    detail = _T("ft_fc_history_basis", "Not compared. Debt records do not match."),
                }
            else
            local dBand
            if d > THRESH.directionEps then dBand = "green"
            elseif d < -THRESH.directionEps then dBand = "red"
            else dBand = "amber" end
            vitals[#vitals + 1] = {
                id = "direction",
                label = _T("ft_fc_vital_direction", "Profit direction"),
                band = dBand,
                valueText = _money(snap.data, d),
                detail = _T("ft_fc_vital_direction_detail", "Change in net worth across the last two closed months."),
            }
            end
        end

        -- Margin
        if #monthly < 1 then
            vitals[#vitals + 1] = {
                id = "margin",
                label = _T("ft_fc_vital_margin", "Margin"),
                band = "neutral",
                valueText = _T("ft_fc_no_history_yet", "No history yet"),
                detail = _T("ft_fc_vital_margin_wait", "Needs a recorded month with flow totals."),
            }
        elseif hasFlowGap then
            vitals[#vitals + 1] = {
                id = "margin",
                label = _T("ft_fc_vital_margin", "Margin"),
                band = "partial",
                valueText = _T("ft_fc_partial", "PARTIAL"),
                detail = _T("ft_fc_vital_margin_partial", "Flow gaps remain; margin is estimated only."),
            }
        else
            vitals[#vitals + 1] = {
                id = "margin",
                label = _T("ft_fc_vital_margin", "Margin"),
                band = "partial",
                valueText = _T("ft_fc_partial", "PARTIAL"),
                detail = _T("ft_fc_vital_margin_partial", "Flow gaps remain; margin is estimated only."),
            }
        end

        -- Trajectory
        if #monthly < 2 then
            vitals[#vitals + 1] = {
                id = "trajectory",
                label = _T("ft_fc_vital_trajectory", "Net-worth trajectory"),
                band = "neutral",
                valueText = _T("ft_fc_no_history_yet", "No history yet"),
                detail = _T("ft_fc_vital_trajectory_wait", "Needs at least two monthly samples."),
            }
        else
            local last = monthly[#monthly]
            local first = last
            local count = 1
            local i = #monthly - 1
            while i >= 1 and count < 6 do
                local row = monthly[i]
                if last.debtBasis == nil or last.debtBasis == "INCOMPLETE" or row.debtBasis ~= last.debtBasis then
                    break
                end
                if _rowNetWorth(row) == nil or _rowNetWorth(last) == nil then break end
                first = row
                count = count + 1
                i = i - 1
            end
            local d = nil
            if count >= 2 then
                local fnw, lnw = _rowNetWorth(first), _rowNetWorth(last)
                if fnw ~= nil and lnw ~= nil then d = lnw - fnw end
            end
            if d == nil then
                vitals[#vitals + 1] = {
                    id = "trajectory",
                    label = _T("ft_fc_vital_trajectory", "Net-worth trajectory"),
                    band = "neutral",
                    valueText = _T("ft_fc_history_basis", "Not compared. Debt records do not match."),
                    detail = _T("ft_fc_history_basis", "Not compared. Debt records do not match."),
                }
            else
            local tBand
            if d > THRESH.trajectoryEps then tBand = "green"
            elseif d < -THRESH.trajectoryEps then tBand = "red"
            else tBand = "amber" end
            vitals[#vitals + 1] = {
                id = "trajectory",
                label = _T("ft_fc_vital_trajectory", "Net-worth trajectory"),
                band = tBand,
                valueText = _money(snap.data, d),
                detail = _T("ft_fc_vital_trajectory_detail", "Net worth change over the recent recorded window."),
            }
            end
        end
        end
    end

    return vitals
end

local function _worstVital(vitals)
    local worstBand, worstId = nil, nil
    local worstRank = 0
    for _, v in ipairs(vitals) do
        local rank = BAND_RANK[v.band]
        if rank ~= nil and rank > worstRank then
            worstRank = rank
            worstBand = v.band
            worstId = v.id
        end
    end
    return worstBand or "neutral", worstId
end

local function _addAmount(lines, data, label, amount, note)
    local shown = _moneyKnown(data, amount)
    if shown == nil then return end
    lines[#lines + 1] = { label = label, value = shown, note = note }
end

local function _buildForecast(snap)
    local o = snap.outlook or { status = "UNAVAILABLE" }
    local oText, oBand, oDetail = _outlookPresentation(snap)
    local lines = {}
    lines[#lines + 1] = {
        label = _T("ft_fc_outlook", "One-period outlook"),
        value = oText,
        note = oDetail,
    }
    if o.horizon then
        lines[#lines + 1] = {
            label = _T("ft_fc_horizon_period", "This period only"),
            value = _T("ft_fc_horizon_period", "This period only"),
        }
    end
    _addAmount(lines, snap.data, _T("ft_fc_outlook_minimum_label", "Lowest cash"), o.minimum, nil)
    if o.shortfall ~= nil and o.shortfall > 0 then
        _addAmount(lines, snap.data, _T("ft_fc_outlook_shortfall_label", "Shortage"), o.shortfall, nil)
    end
    _addAmount(lines, snap.data, _T("ft_fc_expected_gross", "Expected gross"), o.gross, nil)
    _addAmount(lines, snap.data, _T("ft_fc_expected_net", "Expected net"), o.net, nil)
    if o.workingCash ~= nil then
        local note = nil
        if o.basis == "HALF_PERIOD_GROSS" then
            note = _T("ft_fc_basis_half", "Half the period gross")
        elseif o.basis == "FALLBACK_10000" then
            note = _T("ft_fc_basis_fallback", "Fallback figure")
        end
        _addAmount(lines, snap.data, _T("ft_fc_working_cash", "Working cash"), o.workingCash, note)
    end

    if snap.income and snap.income.amount ~= nil then
        lines[#lines + 1] = {
            label = _T("ft_fc_forecast_next_pay", "Next income pulse"),
            value = _money(snap.data, snap.income.amount),
            -- IncomeMod's next-payment sentence is its own (English) text, drawn as IncomeMod gives it: the
            -- renderer's second pass split its time ("Hour 07:00" drew as "Hour 07: 00").
            note = snap.income.nextInfo or (snap.income.mode ~= nil and _payModeText(snap.income.mode)) or nil,
        }
    else
        lines[#lines + 1] = {
            label = _T("ft_fc_forecast_next_pay", "Next income pulse"),
            value = _T("ft_fc_not_tracked", "Not yet tracked"),
        }
    end

    local function basisWords(code)
        if code == "CURRENT_ACCRUAL" then return _T("ft_fc_cost_basis_current", "Current accrual") end
        if code == "HISTORY" then return _T("ft_fc_cost_basis_history", "History") end
        if code == "PAYROLL" then return _T("ft_fc_cost_basis_payroll", "Payroll") end
        if code == "TAX" then return _T("ft_fc_cost_basis_tax", "Tax") end
        if code == "LAST_PERIOD_OPERATING" then return _T("ft_fc_cost_basis_last", "Last period operating") end
        return code
    end
    local function sourceWords(id)
        if id == "tax" then return _T("ft_fc_cost_basis_tax", "Tax") end
        if id == "payroll" then return _T("ft_fc_cost_basis_payroll", "Payroll") end
        if id == "operating" then return _T("ft_fc_cost_source_operating", "Operating") end
        return id
    end
    local function dueClock(ms)
        if type(ms) ~= "number" or ms ~= ms or ms == math.huge or ms == -math.huge then
            return nil
        end
        if ms < 0 or ms >= 86400000 then return nil end
        local minutes = math.floor(ms / 60000)
        local hh = math.floor(minutes / 60)
        local mm = minutes % 60
        return string.format("%02d:%02d", hh, mm)
    end
    local function costNote(item)
        local parts = {}
        if type(item.sourceId) == "string" then
            parts[#parts + 1] = _T("ft_fc_cost_source", "Source") .. " " .. sourceWords(item.sourceId)
        end
        if type(item.basis) == "string" then
            parts[#parts + 1] = _T("ft_fc_cost_basis", "Basis") .. " " .. basisWords(item.basis)
        end
        if item.dueDay ~= nil then
            parts[#parts + 1] = _T("ft_fc_cost_due_day", "Due day") .. " " .. tostring(item.dueDay)
        end
        local clock = dueClock(item.dueTimeMs)
        if clock ~= nil then
            parts[#parts + 1] = _T("ft_fc_cost_due_time", "Due time") .. " " .. clock
        end
        if #parts == 0 then return nil end
        return table.concat(parts, ". ")
    end
    local function addListed(items, key, fallback)
        local label = _T(key, fallback)
        for _, item in ipairs(items or {}) do
            local shown = _moneyKnown(snap.data, item.amount)
            if shown == nil then
                shown = _T("ft_fc_unavailable", "Unavailable")
            end
            lines[#lines + 1] = { label = label, value = shown, note = costNote(item) }
        end
    end
    addListed(o.knownCosts, "ft_fc_known_bill", "Known bill")
    addListed(o.estimatedCosts, "ft_fc_estimate", "Estimate")
    local missText = {
        INVALID_CLOCK = { "ft_fc_miss_clock", "The clock cannot be read, so this period is not projected." },
        NO_BALANCE = { "ft_fc_miss_balance", "Farm balance could not be read." },
        PAYROLL_ABSENT = { "ft_fc_miss_payroll_absent", "Payroll is not available." },
        PAYROLL_UNAVAILABLE = { "ft_fc_miss_payroll_unavailable", "Payroll could not be read." },
        PAYROLL_PARTIAL = { "ft_fc_miss_payroll_partial", "Payroll is only partly known." },
        TAX_ABSENT = { "ft_fc_miss_tax_absent", "Tax is not available." },
        TAX_UNAVAILABLE = { "ft_fc_miss_tax_unavailable", "Tax could not be read." },
        TAX_PARTIAL = { "ft_fc_miss_tax_partial", "Tax is only partly known." },
        NO_OPERATING_HISTORY = { "ft_fc_miss_operating", "No operating history for this estimate." },
        SLEEP_SKIPS_REGULAR_PAYMENTS = { "ft_fc_miss_sleep", "Scheduled payments skipped while sleeping are not guaranteed receipts." },
        INCOME_DISABLED = { "ft_fc_miss_income_off", "Regular income is turned off." },
        INCOME_UNRELIABLE = { "ft_fc_miss_income_unreliable", "Regular income is not a reliable receipt." },
    }
    local firstReason = nil
    for _, code in ipairs(o.missing or {}) do
        local spec = missText[code]
        if spec ~= nil then
            local shown = _T(spec[1], spec[2])
            if firstReason == nil then firstReason = shown end
            -- Label only: label and value were the SAME sentence, printed twice on one row.
            lines[#lines + 1] = { label = shown }
        else
            lines[#lines + 1] = {
                label = _T("ft_fc_miss_unknown", "Missing coverage"),
                value = tostring(code),
            }
        end
    end

    if o.status == "OK" or o.status == "PARTIAL" then
        lines[#lines + 1] = {
            label = _T("ft_fc_outlook_sleep",
                "Scheduled payments skipped while sleeping are not guaranteed receipts."),
        }
    end

    return {
        reason = firstReason,
        partial = o.status == "PARTIAL",
        status = o.status or "UNAVAILABLE",
        headline = oText,
        band = oBand,
        lines = lines,
        monthEndProjected = nil,
    }
end


local function _strictFarmId(data)
    if data == nil or type(data.getPlayerFarmIdStrict) ~= "function" then
        return nil
    end
    local id = _finiteNumber(_pcall(function() return data:getPlayerFarmIdStrict() end))
    if id == nil or id <= 0 then return nil end
    return id
end

local function _gather(self)
    local data = self.system.data
    local farmId = _strictFarmId(data)
    local now = _nowMs()
    if _cache.snap ~= nil and _cache.farmId == farmId and (now - _cache.t) < REFRESH_MS then
        return _cache.snap
    end

    FinancialCockpit.bind()

    if farmId == nil then
        local snap = { data = data, farmId = nil, noFarm = true }
        _cache.t = now
        _cache.farmId = nil
        _cache.snap = snap
        return snap
    end

    local balance = tonumber(data:getBalance(farmId)) or 0
    local loan = tonumber(data:getLoan(farmId)) or 0  -- native bank loan (DataProvider stays native-only)

    -- [RSF-F130] Fold IncomeMod's emergency debt into the farm's WHOLE debt. Total debt =
    -- native loan + emergency outstanding; leverage/net worth use the total with the
    -- coherent owner cash snapshot. Owner absent => explicit native-only; owner present but
    -- view unavailable => combined debt-dependent vitals unavailable (not native-only healthy).
    local elv = _readEmergencyLoanView(farmId)
    local nativeLoan = loan
    local bankLoanKnown = true
    local emergencyOutstanding = nil
    local totalDebt = nativeLoan
    local debtBasis = "NATIVE_ONLY"
    local ownerCash = nil
    local outlook = { status = "UNAVAILABLE" }
    if elv ~= nil then
        bankLoanKnown = false
        nativeLoan = nil
        totalDebt = nil
        debtBasis = "INCOMPLETE"
        local view = (not elv.rejected) and elv.view or nil
        outlook = _outlookFrom(view)
        if type(view) == "table" then
            local nLoan, outstanding = nil, nil
            if _ownerDebtReady(view, farmId) then
                nLoan = _finiteNumber(view.nativeLoan)
                outstanding = _trustedOutstanding(view)
            end
            if nLoan ~= nil and outstanding ~= nil then
                debtBasis = "COMPLETE"
                nativeLoan = nLoan
                bankLoanKnown = true
                emergencyOutstanding = outstanding
                totalDebt = nLoan + outstanding
            end
            if _isServer() then
                ownerCash = _finiteNumber(view.cash)
            end
        end
    end
    local netWorth = nil
    if debtBasis == "NATIVE_ONLY" then
        netWorth = _netWorth(balance, loan)
    elseif ownerCash ~= nil and totalDebt ~= nil then
        netWorth = ownerCash - totalDebt
    end

    local tg = _timeGuard()
    local tgCtx = nil
    local tgSynced = false
    if tg ~= nil and type(tg.getContext) == "function" then
        tgCtx = _pcall(function() return tg:getContext() end)
        tgSynced = tgCtx ~= nil and tgCtx.synced == true
    end

    local income = _readIncomeFlow()
    local tax = _readTaxFlow()
    local wages = _readWageFlow()
    local flows = { income = income, tax = tax, wages = wages }
    local gaps = _flowGaps(flows)

    local snap = {
        data = data,
        farmId = farmId,
        farmName = data:getFarmName(farmId) or ("Farm " .. tostring(farmId)),
        balance = balance,
        loan = (bankLoanKnown and nativeLoan ~= nil) and nativeLoan or 0,
        bankLoanKnown = bankLoanKnown,
        nativeLoan = nativeLoan,
        emergencyOutstanding = emergencyOutstanding,
        totalDebt = totalDebt,
        debtBasis = debtBasis,
        ownerCash = ownerCash,
        outlook = outlook,
        netWorth = netWorth,
        timeGuard = tg,
        tgCtx = tgCtx,
        tgSynced = tgSynced,
        income = income,
        tax = tax,
        wages = wages,
        coop = _readCoopSignal(),
        dairy = _readDairySignal(),
        market = _readMarketSignal(),
        rwe = _readRweSignal(),
        flowGaps = gaps,
        historyMode = _historyMode(),
        ledgerPresent = _stateLedger() ~= nil,
        monthlyCount = #_ownFarmMonthly(farmId),
        yearlyCount = #_hist.yearly,
    }
    snap.vitals = _buildVitals(snap)
    snap.heartBand, snap.heartVitalId = _worstVital(snap.vitals)
    snap.forecast = _buildForecast(snap)

    _cache.t = now
    _cache.farmId = farmId
    _cache.snap = snap
    return snap
end

-- ── UI pieces ─────────────────────────────────────────────

local function _pocketBtn(self, x, y, w, h, label, color, onClick)
    local btn = self.r:button(x, y, w, h, label, color, { onClick = onClick }, true)
    table.insert(self._contentBtns, btn)
    return btn
end

local function _drawHeart(self, x, y, w, snap, AC)
    local band = snap.heartBand
    local col = _bandColor(band)
    local fsz   = (FT.LAYOUT and FT.LAYOUT.fontScale) or 1
    local capH  = FT.FONT.TINY * fsz
    local bandH = FT.FONT.TITLE * fsz
    local capY  = y - FT.py(5) - capH
    local bandY = capY - FT.py(3) - bandH
    local h     = (y - bandY) + FT.py(6)
    self.r:appRect(x, y - h, w, h, FT.C.BG_CARD)
    -- Heart color chip. px for width and py for height: both are n physical pixels on their
    -- own axis, so that pair is the square, and px twice is a squashed bar.
    local chip  = FT.px(22)
    local chipH = FT.py(22)
    self.r:appRect(x + FT.px(10), (bandY + capY + capH) * 0.5 - chipH * 0.5, chip, chipH, col)
    self.r:appText(x + FT.px(40), capY, FT.FONT.TINY,
        _T("ft_fc_health", "FARM HEALTH"), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
    self.r:appText(x + FT.px(40), bandY, FT.FONT.TITLE,
        _bandLabel(band), RenderText.ALIGN_LEFT, col, true)

    local worstLabel = ""
    if snap.heartVitalId then
        for _, v in ipairs(snap.vitals) do
            if v.id == snap.heartVitalId then
                worstLabel = v.label
                break
            end
        end
    end
    if worstLabel ~= "" then
        -- The vital's label is already the file's text (_T): drawn as it is (RSF-F166's flag).
        self.r:appText(x + w - FT.px(10), capY, FT.FONT.TINY,
            FT_Renderer.truncate(worstLabel, 18), RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM, true)
    end

    _pocketBtn(self, x, y - h, w, h, "", {0, 0, 0, 0}, function()
        _vitalFocus = snap.heartVitalId
        _view = "vital"
        self:switchApp(FT.APP.FINANCIAL_COCKPIT)
    end)
    return y - h - FT.py(6)
end

local function _drawHome(self, snap, AC)
    local startY = self:drawAppHeader(_T("ft_ui_app_financial_cockpit", "Financial Cockpit"), snap.farmName, true)
    local x, contentY, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    y = _drawHeart(self, x, y, cw, snap, AC)
    y = self:drawRule(y, 0.35)

    -- Live instruments
    y = self:drawSection(y, _T("ft_fc_section_instruments", "INSTRUMENTS"), true)
    local balC = snap.balance >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE
    y = self:drawRow(y, _T("ft_fc_balance", "Balance"), _money(snap.data, snap.balance), nil, balC, true, true)
    -- Native bank loan (RSF-F130: labelled distinctly from emergency debt).
    if snap.bankLoanKnown == false then
        y = self:drawRow(y, _T("ft_fc_loan", "Bank loan"),
            _T("ft_fc_unavailable", "Unavailable"), nil, FT.C.MUTED, true, true)
    elseif snap.loan > 0 then
        y = self:drawRow(y, _T("ft_fc_loan", "Bank loan"), _money(snap.data, snap.loan), nil, FT.C.WARNING, true, true)
    else
        y = self:drawRow(y, _T("ft_fc_loan", "Bank loan"), _money(snap.data, 0), nil, FT.C.TEXT_DIM, true, true)
    end
    -- Emergency loan + total debt (RSF-F130). Kept separate from the bank loan.
    if snap.debtBasis == "COMPLETE" and (snap.emergencyOutstanding or 0) > 0 then
        y = self:drawRow(y, _T("ft_fc_emergency_loan", "Emergency loan"),
            _money(snap.data, snap.emergencyOutstanding), nil, FT.C.WARNING, true, true)
        y = self:drawRow(y, _T("ft_fc_total_debt", "Total debt"),
            _money(snap.data, snap.totalDebt), nil, FT.C.WARNING, true, true)
    elseif snap.debtBasis == "INCOMPLETE" then
        y = self:drawRow(y, _T("ft_fc_emergency_loan", "Emergency loan"),
            _T("ft_fc_unavailable", "Unavailable"), nil, FT.C.MUTED, true, true)
        y = self:drawRow(y, _T("ft_fc_total_debt", "Total debt"),
            _T("ft_fc_unavailable", "Unavailable"), nil, FT.C.MUTED, true, true)
    end
    -- Net worth (total-debt based); unavailable when the combined debt is unknown.
    if snap.netWorth ~= nil then
        local nwC = snap.netWorth >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE
        y = self:drawRow(y, _T("ft_fc_net_worth", "Net worth"), _money(snap.data, snap.netWorth), nil, nwC, true, true)
    else
        y = self:drawRow(y, _T("ft_fc_net_worth", "Net worth"), _T("ft_fc_partial", "PARTIAL"), nil, FT.C.WARNING, true, true)
    end

    -- [RSF-F130] Open IncomeMod's own report to borrow or repay. The tablet never moves
    -- money: it yields (closes) and asks the owner to open its screen (the host report
    -- refuses to open while another GUI is active). Shown only when the owner is present.
    if snap.debtBasis ~= "NATIVE_ONLY" then
        local loanBtnW = FT.px(130)
        _pocketBtn(self, x + cw - loanBtnW, y - FT.py(2), loanBtnW, FT.py(16),
            _T("ft_fc_open_loan", "MANAGE LOAN"), FT.C.BTN_NEUTRAL, function()
                self:closeTablet()
                local mgr = g_currentMission and g_currentMission.incomeManager
                if mgr ~= nil and type(mgr.openEmergencyLoanReport) == "function" then
                    _pcall(function() mgr:openEmergencyLoanReport() end)
                end
            end)
        y = y - FT.py(20)
    end

    y = y - FT.py(4)
    y = self:drawRule(y, 0.25)

    -- Time Guard rhythm
    y = self:drawSection(y, _T("ft_fc_section_rhythm", "RHYTHM"), true)
    if snap.tgCtx == nil then
        y = self:drawRow(y, _T("ft_fc_clock", "Economic clock"), _T("ft_fc_unavailable", "Unavailable"), nil, FT.C.MUTED, true, true)
    elseif not snap.tgSynced then
        y = self:drawRow(y, _T("ft_fc_clock", "Economic clock"), _T("ft_fc_syncing", "Syncing"), nil, FT.C.WARNING, true, true)
    else
        y = self:drawRow(y, _T("ft_fc_period", "Period"),
            string.format("%s %d / %s %d",
                _T("ft_fc_month", "Month"), snap.tgCtx.period or 0,
                _T("ft_fc_year", "Year"), snap.tgCtx.year or 0),
            nil, FT.C.TEXT_NORMAL, true, true)
        y = self:drawRow(y, _T("ft_fc_days_per_period", "Days / period"),
            tostring(snap.tgCtx.daysPerPeriod or "-"), nil, FT.C.TEXT_DIM, true)
    end
    y = y - FT.py(4)
    y = self:drawRule(y, 0.25)

    -- Forecast teaser
    y = self:drawSection(y, _T("ft_fc_section_forecast", "FORECAST"), true)
    local fc = snap.forecast
    local fcColor = FT.C.MUTED
    if fc.band == "red" then fcColor = FT.C.NEGATIVE
    elseif fc.band == "partial" then fcColor = FT.C.WARNING
    elseif fc.band == "amber" then fcColor = FT.C.WARNING end
    y = self:drawRow(y, _T("ft_fc_outlook", "One-period outlook"),
        fc.headline or _T("ft_fc_outlook_unavailable", "Outlook unavailable"), nil, fcColor, true, true)
    -- OPEN on its own row so it cannot cover the forecast values above.
    local fcBtnW = FT.px(72)
    _pocketBtn(self, x + cw - fcBtnW, y - FT.py(2), fcBtnW, FT.py(16),
        _T("ft_fc_open", "OPEN"), FT.C.BTN_NEUTRAL, function()
            _view = "forecast"
            self:switchApp(FT.APP.FINANCIAL_COCKPIT)
        end)
    y = y - FT.py(22)
    y = self:drawRule(y, 0.25)

    -- History teaser
    y = self:drawSection(y, _T("ft_fc_section_history", "HISTORY"), true)
    if not snap.ledgerPresent and snap.historyMode == "available" then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_no_ledger", "No StateLedger (live vitals only)"), nil, FT.C.MUTED, true, true)
    elseif snap.historyMode == "dedicated" then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_dedicated", "Unavailable on this server"), nil, FT.C.MUTED, true, true)
    elseif snap.historyMode == "host_only" then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_host_only", "Host-only in v1"), nil, FT.C.MUTED, true, true)
    else
        if snap.monthlyCount == 0 then
            y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
                _T("ft_fc_history_own_unavailable", "History unavailable"), nil, FT.C.MUTED, true, true)
        else
            y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
                string.format("%d %s", snap.monthlyCount, _T("ft_fc_months", "months")),
                nil, FT.C.TEXT_NORMAL, true, true)
        end
    end
    local hBtnW = FT.px(72)
    _pocketBtn(self, x + cw - hBtnW, y - FT.py(2), hBtnW, FT.py(16),
        _T("ft_fc_open", "OPEN"), FT.C.BTN_NEUTRAL, function()
            _view = "history"
            self:switchApp(FT.APP.FINANCIAL_COCKPIT)
        end)
    y = y - FT.py(22)
    y = self:drawRule(y, 0.25)

    -- Flow / signal strip
    y = self:drawSection(y, _T("ft_fc_section_flows", "FLOWS AND SIGNALS"), true)
    local function flowRow(label, present, value, color)
        if not present then
            y = self:drawRow(y, label, _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
        else
            y = self:drawRow(y, label, value, nil, color or FT.C.TEXT_NORMAL, true, true)
        end
    end
    flowRow(_T("ft_fc_flow_income", "Income"), snap.income ~= nil,
        snap.income and _money(snap.data, snap.income.amount or 0) or "", FT.C.POSITIVE)
    flowRow(_T("ft_fc_flow_tax", "Tax paid (total)"), snap.tax ~= nil and snap.tax.totalTaxesPaid ~= nil,
        snap.tax and _money(snap.data, snap.tax.totalTaxesPaid) or "", FT.C.WARNING)
    flowRow(_T("ft_fc_flow_wages", "Wages (month)"), snap.wages ~= nil and snap.wages.monthAccrued ~= nil,
        snap.wages and _money(snap.data, snap.wages.monthAccrued) or "", FT.C.WARNING)
    flowRow(_T("ft_fc_flow_fuel", "Fuel spend"), false, "", nil)
    if snap.coop then
        y = self:drawRow(y, _T("ft_fc_signal_coop", "Co-Op level"),
            tostring(snap.coop.level), nil, FT.C.TEXT_ACCENT, true)
    else
        y = self:drawRow(y, _T("ft_fc_signal_coop", "Co-Op level"),
            _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    end
    if snap.dairy then
        y = self:drawRow(y, _T("ft_fc_signal_dairy", "Dairy barns"),
            tostring(snap.dairy.barnCount), nil, FT.C.TEXT_NORMAL, true)
    end

    local fBtnW = FT.px(72)
    _pocketBtn(self, x + cw - fBtnW, y - FT.py(2), fBtnW, FT.py(16),
        _T("ft_fc_open", "OPEN"), FT.C.BTN_NEUTRAL, function()
            _view = "flows"
            self:switchApp(FT.APP.FINANCIAL_COCKPIT)
        end)
    y = y - FT.py(20)

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
end

local function _drawVitalPocket(self, snap, AC)
    local startY = self:drawAppHeader(_T("ft_fc_pocket_vital", "Health vital"),
        _bandLabel(snap.heartBand), true, true)
    local x, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    y = self:drawSection(y, _T("ft_fc_section_vitals", "VITALS"), true)
    for _, v in ipairs(snap.vitals) do
        local focus = (_vitalFocus ~= nil and v.id == _vitalFocus)
        local label = focus and ("> " .. v.label) or v.label
        -- A vital's label, value and detail are already the file's text (_T) or a figure: drawn as they are.
        y = self:drawRow(y, label, v.valueText, nil, _bandColor(v.band), true, true)
        -- [RSF-F130 :4] A partial vital still owes the player a readable explanation, and
        -- "PARTIAL" alone is a status code. Its detail is drawn as well as the focused and
        -- heart-band ones. This changes no band and no heart colour: a partial still does
        -- not count as healthy for _heartBand.
        if focus or v.band == snap.heartBand or v.band == "partial" then
            self.r:appText(x + FT.px(8), y + FT.py(2), FT.FONT.TINY,
                v.detail or "", RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
            y = y - FT.py(14)
        end
    end
    y = y - FT.py(8)
    self.r:appText(x, y, FT.FONT.TINY,
        _T("ft_fc_worst_rule", "Heart color = worst vital that has data. Neutrals and partials do not count as healthy."),
        RenderText.ALIGN_LEFT, FT.C.MUTED, true)
    y = y - FT.py(20)

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
end

local function _drawHistoryPocket(self, snap, AC)
    local startY = self:drawAppHeader(_T("ft_fc_pocket_history", "Financial history"),
        _T("ft_fc_section_history", "HISTORY"), true, true)
    local x, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    if snap.historyMode == "no_clock" then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_no_clock", "Needs Time Guard"), nil, FT.C.MUTED, true, true)
        self.r:appText(x, y, FT.FONT.TINY,
            _T("ft_fc_history_no_clock_detail",
                "Install Time Guard to record monthly history. Live vitals still stand."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(18)
    elseif snap.historyMode == "dedicated" then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_dedicated", "Unavailable on this server"), nil, FT.C.MUTED, true, true)
    elseif snap.historyMode == "host_only" then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_host_only", "Host-only in v1"), nil, FT.C.MUTED, true, true)
        self.r:appText(x, y, FT.FONT.TINY,
            _T("ft_fc_history_host_only_detail", "Monthly history is recorded on the host. Live cash and leverage still stand."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(18)
    elseif not snap.ledgerPresent then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_no_ledger", "No StateLedger (live vitals only)"), nil, FT.C.MUTED, true, true)
    elseif #_ownFarmMonthly(snap.farmId) == 0 then
        y = self:drawRow(y, _T("ft_fc_history", "Monthly record"),
            _T("ft_fc_history_own_unavailable", "History unavailable"), nil, FT.C.MUTED, true, true)
        self.r:appText(x, y, FT.FONT.TINY,
            _T("ft_fc_history_own_detail", "No trusted history for this farm."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(18)
    else
        y = self:drawSection(y, _T("ft_fc_recent_months", "RECENT MONTHS"), true)
        local own = _ownFarmMonthly(snap.farmId)
        local startIdx = math.max(1, #own - 11)
        for i = #own, startIdx, -1 do
            local row = own[i]
            local nw = _rowNetWorth(row)
            local shown = _moneyKnown(snap.data, nw)
            if shown == nil then
                y = self:drawRow(y,
                    string.format("%d / %02d", row.year, row.monthIndex),
                    _T("ft_fc_unavailable", "Unavailable"),
                    nil, FT.C.MUTED, true, true)
            else
                y = self:drawRow(y,
                    string.format("%d / %02d", row.year, row.monthIndex),
                    shown,
                    nil, nw >= 0 and FT.C.POSITIVE or FT.C.NEGATIVE, true, true)
            end
        end
        if #_ownFarmYearly(snap.farmId) > 0 then
            y = y - FT.py(4)
            y = self:drawRule(y, 0.25)
            y = self:drawSection(y, _T("ft_fc_yearly_rollup", "YEARLY ROLLUP"), true)
            local years = _ownFarmYearly(snap.farmId)
            for i = #years, 1, -1 do
                local yr = years[i]
                local debt = _finiteNumber(yr.yearEndDebt)
                if debt == nil and yr.debtBasis == "NATIVE_ONLY" then
                    debt = _finiteNumber(yr.yearEndLoan)
                end
                local bal = _finiteNumber(yr.yearEndBalance)
                local nw = (bal ~= nil and debt ~= nil) and (bal - debt) or nil
                local shown = _moneyKnown(snap.data, nw)
                y = self:drawRow(y, tostring(yr.year),
                    shown or _T("ft_fc_unavailable", "Unavailable"),
                    nil, shown == nil and FT.C.MUTED or FT.C.TEXT_NORMAL, true, true)
            end
        end
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
end

local function _drawForecastPocket(self, snap, AC)
    local startY = self:drawAppHeader(_T("ft_fc_pocket_forecast", "Forecast"),
        _T("ft_fc_forecast_label", "Projection"), true, true)
    local x, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    local fc = snap.forecast
    if fc.partial then
        y = self:drawRow(y, _T("ft_fc_honesty", "Honesty"),
            _T("ft_fc_partial", "PARTIAL"), nil, FT.C.WARNING, true, true)
        -- RSF-F130 ":4": never leave a status word standing on its own. The cause comes from
        -- the outlook's own missing-input codes, drawn the same way as a forecast line's note.
        if fc.reason then
            self.r:appText(x + FT.px(8), y + FT.py(2), FT.FONT.TINY,
                tostring(fc.reason), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
            y = y - FT.py(12)
        end
    end
    for _, line in ipairs(fc.lines) do
        -- The forecast lines are the file's text (_T), money, or IncomeMod's own note: drawn as they are.
        y = self:drawRow(y, line.label, line.value, nil, FT.C.TEXT_NORMAL, true, true)
        if line.note then
            self.r:appText(x + FT.px(8), y + FT.py(2), FT.FONT.TINY,
                tostring(line.note), RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
            y = y - FT.py(12)
        end
    end
    if fc.monthEndProjected then
        y = y - FT.py(4)
        y = self:drawRule(y, 0.25)
        y = self:drawRow(y, _T("ft_fc_forecast_month_end", "Month-end outlook"),
            fc.monthEndProjected, nil, FT.C.WARNING, true)
        self.r:appText(x, y, FT.FONT.TINY,
            _T("ft_fc_forecast_disclaimer", "Projection only. Missing flows are not invented."),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        y = y - FT.py(16)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
end

local function _drawFlowsPocket(self, snap, AC)
    local startY = self:drawAppHeader(_T("ft_fc_pocket_flows", "Flows and signals"),
        _T("ft_fc_section_flows", "FLOWS AND SIGNALS"), true, true)
    local x, _, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y = startY + scrollY

    y = self:drawSection(y, _T("ft_fc_dollar_flows", "DOLLAR FLOWS"), true)
    if snap.income then
        y = self:drawRow(y, _T("ft_fc_flow_income", "Income"),
            _money(snap.data, snap.income.amount or 0), nil, FT.C.POSITIVE, true, true)
        if snap.income.mode then
            local modeText, tabletWord = _payModeText(snap.income.mode)
            y = self:drawRow(y, _T("ft_fc_flow_income_mode", "Pay mode"),
                modeText, nil, FT.C.TEXT_DIM, true, tabletWord)
        end
    else
        y = self:drawRow(y, _T("ft_fc_flow_income", "Income"),
            _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    end
    if snap.tax and snap.tax.totalTaxesPaid ~= nil then
        y = self:drawRow(y, _T("ft_fc_flow_tax", "Tax paid (total)"),
            _money(snap.data, snap.tax.totalTaxesPaid), nil, FT.C.WARNING, true, true)
    else
        y = self:drawRow(y, _T("ft_fc_flow_tax", "Tax paid (total)"),
            _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    end
    if snap.wages and snap.wages.monthAccrued ~= nil then
        y = self:drawRow(y, _T("ft_fc_flow_wages", "Wages (month)"),
            _money(snap.data, snap.wages.monthAccrued), nil, FT.C.WARNING, true, true)
    else
        y = self:drawRow(y, _T("ft_fc_flow_wages", "Wages (month)"),
            _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    end
    y = self:drawRow(y, _T("ft_fc_flow_fuel", "Fuel spend"),
        _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    y = self:drawRow(y, _T("ft_fc_flow_dairy_income", "Dairy contract income"),
        _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    y = self:drawRow(y, _T("ft_fc_flow_rwe", "World-event money"),
        _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)

    y = y - FT.py(4)
    y = self:drawRule(y, 0.25)
    y = self:drawSection(y, _T("ft_fc_signals", "SIGNALS"), true)
    if snap.coop then
        y = self:drawRow(y, _T("ft_fc_signal_coop", "Co-Op level"),
            tostring(snap.coop.level), nil, FT.C.TEXT_ACCENT, true)
        self.r:appText(x, y, FT.FONT.TINY,
            _T("ft_fc_signal_coop_note", "Level only. Quantified savings wait on ProStaff benefit getters."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)
        y = y - FT.py(14)
    else
        y = self:drawRow(y, _T("ft_fc_signal_coop", "Co-Op level"),
            _T("ft_fc_not_tracked", "Not yet tracked"), nil, FT.C.MUTED, true, true)
    end
    if snap.dairy then
        y = self:drawRow(y, _T("ft_fc_signal_dairy", "Dairy barns"),
            tostring(snap.dairy.barnCount), nil, FT.C.TEXT_NORMAL, true)
    end
    if snap.market then
        y = self:drawRow(y, _T("ft_fc_signal_market", "Market events"),
            tostring(snap.market.activeEvents), nil, FT.C.TEXT_NORMAL, true)
    end
    if snap.rwe and snap.rwe.event then
        y = self:drawRow(y, _T("ft_fc_signal_rwe", "World event"),
            _rweEventLabel(snap.rwe.event), nil, FT.C.TEXT_ACCENT, true)
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
end

-- ── Back handler + drawer ─────────────────────────────────

FarmTabletUI:registerBackHandler(FT.APP.FINANCIAL_COCKPIT, function()
    if _view ~= "home" then
        _view = "home"
        _vitalFocus = nil
        return true
    end
    return false
end)

FarmTabletUI:registerDrawer(FT.APP.FINANCIAL_COCKPIT, function(self)
    local AC = FT.appColor(FT.APP.FINANCIAL_COCKPIT)

    if self:drawHelpPage("_fcHelp", FT.APP.FINANCIAL_COCKPIT,
        _T("ft_ui_app_financial_cockpit", "Financial Cockpit"), AC, {
        { title = _T("ft_fc_help_health_title", "FARM HEALTH"),
          body  = _T("ft_fc_help_health_body",
              "One heart color from the worst vital that has data.\n" ..
              "Green / amber / red. Neutrals and partials never count as healthy.\n" ..
              "Tap the heart to open the vital that set the color."), literalTitle = true, literalBody = true },
        { title = _T("ft_fc_help_history_title", "HISTORY"),
          body  = _T("ft_fc_help_history_body",
              "This page records a compact monthly row itself.\n" ..
              "Needs Time Guard for the month clock. Host / single-player\n" ..
              "only in v1. Gaps stay gaps."), literalTitle = true, literalBody = true },
        { title = _T("ft_fc_help_forecast_title", "FORECAST"),
          body  = _T("ft_fc_help_forecast_body",
              "Labeled as a projection. PARTIAL when a flow is missing.\n" ..
              "Missing flows show not yet tracked, never a guess."), literalTitle = true, literalBody = true },
        { title = _T("ft_fc_help_readonly_title", "READ-ONLY"),
          body  = _T("ft_fc_help_readonly_body",
              "The cockpit never moves money and never re-implements\n" ..
              "Income, Tax, Wages, or other owning apps."), literalTitle = true, literalBody = true },
    }, true) then return end

    local snap = _gather(self)
    if snap.noFarm then
        local y = self:drawAppHeader(
            _T("ft_ui_app_financial_cockpit", "Financial Cockpit"),
            _T("ft_fc_no_farm", "No farm selected"))
        self:drawRow(y, _T("ft_fc_no_farm", "No farm selected"),
            _T("ft_fc_unavailable", "Unavailable"), nil, FT.C.MUTED)
        return
    end
    if _view == "vital" then
        _drawVitalPocket(self, snap, AC)
    elseif _view == "history" then
        _drawHistoryPocket(self, snap, AC)
    elseif _view == "forecast" then
        _drawForecastPocket(self, snap, AC)
    elseif _view == "flows" then
        _drawFlowsPocket(self, snap, AC)
    else
        _drawHome(self, snap, AC)
    end
    self:drawInfoIcon("_fcHelp", AC)
end)
