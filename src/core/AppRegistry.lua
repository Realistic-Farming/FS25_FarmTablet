-- =========================================================
-- FarmTablet v2 – AppRegistry
-- Central registry for all installed apps
-- =========================================================
---@class AppRegistry
AppRegistry = {}
local AppRegistry_mt = Class(AppRegistry)

-- App category display groups
AppRegistry.GROUPS = {
    { id = "core",      label = "CORE",     icon = "CORE" },
    { id = "farm",      label = "FARM",     icon = "FARM" },
    { id = "finance",   label = "FINANCE",  icon = "FIN" },
    { id = "mods",      label = "MODS",     icon = "MODS" },
}

-- Built-in app definitions (always present)
AppRegistry.BUILTIN_APPS = {
    {
        id = FT.APP.DASHBOARD,  group = "core",
        name = "ft_ui_app_dashboard",  navLabel = "DASH",
        icon = "dashboard",         order = 1,
        developer = "FarmTablet",   version = "Built-in",
        description = "Farm overview: balance, fields, vehicles, world state",
    },
    {
        id = FT.APP.APP_STORE,  group = "core",
        name = "ft_ui_app_store",      navLabel = "APPS",
        icon = "store",             order = 2,
        developer = "FarmTablet",   version = "Built-in",
        description = "Browse and manage installed apps",
    },
    {
        id = FT.APP.SETTINGS,   group = "core",
        name = "ft_ui_app_settings",   navLabel = "SET",
        icon = "settings",          order = 3,
        developer = "FarmTablet",   version = "Built-in",
        description = "Tablet configuration",
    },
    {
        id = FT.APP.WEATHER,    group = "farm",
        name = "ft_ui_app_weather",    navLabel = "WTH",
        icon = "weather",           order = 10,
        developer = "FarmTablet",   version = "Built-in",
        description = "Current conditions and forecast",
    },
    {
        id = FT.APP.FIELDS,     group = "farm",
        name = "ft_ui_app_field_status", navLabel = "FLD",
        icon = "fields",            order = 11,
        developer = "FarmTablet",   version = "Built-in",
        description = "All owned fields with crop and growth state",
    },
    {
        id = FT.APP.ANIMALS,    group = "farm",
        name = "ft_ui_app_animals",    navLabel = "ANI",
        icon = "animals",           order = 12,
        developer = "FarmTablet",   version = "Built-in",
        description = "Animal pens — food, water, cleanliness",
    },
    {
        id = FT.APP.WORKSHOP,   group = "farm",
        name = "ft_ui_app_workshop",   navLabel = "WRK",
        icon = "workshop",          order = 13,
        developer = "FarmTablet",   version = "Built-in",
        description = "Nearby vehicle diagnostics",
    },
    {
        id = FT.APP.EXCAVATOR,  group = "farm",
        name = "ft_ui_app_excavator",  navLabel = "EXC",
        icon = "digging",           order = 14,
        developer = "FarmTablet",   version = "Built-in",
        description = "Terrain depth readout and bucket load counter",
    },
    {
        id = FT.APP.STORAGE,    group = "farm",
        name = "ft_ui_app_storage",    navLabel = "STR",
        icon = "storage",           order = 16,
        developer = "FarmTablet",   version = "Built-in",
        description = "Silo inventory and current sell prices",
    },
    {
        id = FT.APP.TIME_CONTROLS, group = "farm",
        name = "ft_ui_app_time_controls", navLabel = "TIME",
        icon = "time",              order = 17,
        developer = "FarmTablet",   version = "Built-in",
        description = "Set time scale and skip to a time of day",
    },
    {
        id = FT.APP.HOTSPOT_MGR, group = "farm",
        name = "ft_ui_app_hotspot_manager", navLabel = "PINS",
        icon = "hotspot",           order = 18,
        developer = "FarmTablet",   version = "Built-in",
        description = "View and remove map hotspots",
    },
    {
        id = FT.APP.NOTES,      group = "farm",
        name = "ft_ui_app_notes",      navLabel = "NOTE",
        icon = "notes",             order = 19,
        developer = "FarmTablet",   version = "Built-in",
        description = "Checkbox-style farm todo list",
    },
    {
        id = FT.APP.FARM_ADMIN, group = "farm",
        name = "ft_ui_app_farm_admin", navLabel = "ADM",
        icon = "admin",             order = 20,
        developer = "FarmTablet",   version = "Built-in",
        description = "Admin controls: money, time, vehicle repair/fuel",
    },
    {
        id = FT.APP.FIELD_JOBS, group = "farm",
        name = "ft_ui_app_field_jobs", navLabel = "JOBS",
        icon = "jobs",              order = 21,
        developer = "FarmTablet",   version = "Built-in",
        description = "Log field work sessions — field, vehicle, task, duration",
    },
    {
        id = FT.APP.CONTRACTS,  group = "farm",
        name = "ft_ui_app_contracts",  navLabel = "CON",
        icon = "contracts",         order = 22,
        developer = "FarmTablet",   version = "Built-in",
        description = "Active contracts — completion, reward, time remaining",
    },
    {
        id = FT.APP.FLEET,      group = "farm",
        name = "ft_ui_app_fleet_manager", navLabel = "FLEET",
        icon = "fleet",             order = 23,
        developer = "FarmTablet",   version = "Built-in",
        description = "All owned vehicles — fuel, wear, operating hours",
    },
    {
        id = FT.APP.PRODUCTION, group = "farm",
        name = "ft_ui_app_production_buildings", navLabel = "PROD",
        icon = "production",        order = 24,
        developer = "FarmTablet",   version = "Built-in",
        description = "Production building chains — inputs, outputs, active status",
    },
    {
        id = FT.APP.FARM_STATS, group = "farm",
        name = "ft_ui_app_farm_stats", navLabel = "STAT",
        icon = "stats",             order = 25,
        developer = "FarmTablet",   version = "Built-in",
        description = "Comprehensive farm statistics snapshot",
    },
    -- NOTE: Companion-mod apps (Income, Tax, NPC Favor, Crop Stress, Soil Fertilizer)
    -- are NOT pre-registered here. They are added dynamically by autoDetect() once the
    -- mission is loaded and the companion mod's global manager is confirmed present.
    -- This prevents "mod not installed" placeholders from cluttering the sidebar.
    {
        id = FT.APP.UPDATES,    group = "core",
        name = "ft_ui_app_updates",    navLabel = "UPD",
        icon = "updates",           order = 100,
        developer = "FarmTablet",   version = "Built-in",
        description = "Changelog and update history",
    },
}

function AppRegistry.new()
    local self = setmetatable({}, AppRegistry_mt)
    self._apps = {}  -- keyed by id
    self._order = {} -- sorted list of ids

    -- Register built-ins
    for _, def in ipairs(AppRegistry.BUILTIN_APPS) do
        self:register(def)
    end

    return self
end

function AppRegistry:register(def)
    if self._apps[def.id] then return end -- already registered
    def.enabled = (def.enabled ~= false)
    self._apps[def.id] = def

    -- Insert into ordered list
    table.insert(self._order, def.id)
    table.sort(self._order, function(a, b)
        local oa = self._apps[a] and self._apps[a].order or 50
        local ob = self._apps[b] and self._apps[b].order or 50
        return oa < ob
    end)

    FT_EventBus:emit(FT_EventBus.EVENTS.APP_REGISTERED, def.id)
end

function AppRegistry:get(id)
    return self._apps[id]
end

function AppRegistry:getAll()
    local out = {}
    for _, id in ipairs(self._order) do
        local app = self._apps[id]
        if app and app.enabled then
            table.insert(out, app)
        end
    end
    return out
end

function AppRegistry:has(id)
    return self._apps[id] ~= nil
end

-- Legacy Digging / Bucket Tracker ids redirect to Excavator so saved
-- startupApp / favourite lists keep working after the merge.
function AppRegistry.resolve(id)
    if id == FT.APP.DIGGING or id == FT.APP.BUCKET then
        return FT.APP.EXCAVATOR
    end
    return id
end

function AppRegistry:setEnabled(id, state)
    if self._apps[id] then
        self._apps[id].enabled = state
    end
end

-- Auto-detect companion mods and register their apps.
-- Each check uses the EXACT global name set by that mod's main.lua.
-- NOTE: Cross-mod globals (getfenv(0)["name"]) are per-mod scoped in FS25.
-- Use g_currentMission.xxx properties for reliable cross-mod detection.
function AppRegistry:autoDetect()
    -- Settings Hub (ecosystem core-API): System Settings overview app.
    -- Bridge: mission.settingsHub set by FS25_SettingsHub in Mission00.load
    if g_currentMission and g_currentMission.settingsHub then
        if not self:has(FT.APP.SYSTEM_SETTINGS) then
            Logging.info("[FarmTablet] autoDetect: Settings Hub detected")
            self:register({
                id = FT.APP.SYSTEM_SETTINGS, group = "core",
                name = "ft_ui_app_system_settings", navLabel = "SYS",
                icon = "settings", order = 101,
                developer = "TisonK", version = "Integrated",
                description = "Overview of every ecosystem setting registered with the Settings Hub",
            })
        end
    end

    -- Financial Cockpit (FT-6): finance-group home page. Always available. The
    -- live vitals (cash, leverage, runway) read base-game balance and loan, so
    -- the page stands on its own. Time Guard adds the month clock that records
    -- history; its absence is stated in the app rather than hiding the page.
    if not self:has(FT.APP.FINANCIAL_COCKPIT) then
        Logging.info("[FarmTablet] autoDetect: Financial Cockpit")
        self:register({
            id = FT.APP.FINANCIAL_COCKPIT, group = "finance",
            name = "ft_ui_app_financial_cockpit", navLabel = "COCK",
            icon = "financial_cockpit", order = 5,
            developer = "Realistic Farming", version = "Integrated",
            description = "Whole-farm financial health, instruments, history and projection",
        })
    end
    if FinancialCockpit and type(FinancialCockpit.bind) == "function" then
        pcall(FinancialCockpit.bind)
    end

    -- Income Mod
    if g_currentMission and g_currentMission.incomeManager then
        if not self:has(FT.APP.INCOME) then
            Logging.info("[FarmTablet] autoDetect: Income Mod detected")
            self:register({
                id = FT.APP.INCOME, group = "mods",
                name = "ft_ui_app_income_mod", navLabel = "INC",
                icon = "income", order = 20,
                developer = "TisonK", version = "Integrated",
                description = "Income Mod controls and statistics",
            })
        end
    end

    -- Tax Mod
    -- Bridge: mission.taxManager set by TaxMod in Mission00.load
    if g_currentMission and g_currentMission.taxManager then
        if not self:has(FT.APP.TAX) then
            Logging.info("[FarmTablet] autoDetect: Tax Mod detected")
            self:register({
                id = FT.APP.TAX, group = "mods",
                name = "ft_ui_app_tax_mod", navLabel = "TAX",
                icon = "tax", order = 21,
                developer = "TisonK", version = "Integrated",
                description = "Tax Mod status and toggle",
            })
        end
    end

    -- NPC Favor
    -- Bridge: mission.npcFavorSystem set by NPCFavor in Mission00.load
    local hasNPC = (g_currentMission and g_currentMission.npcFavorSystem ~= nil)
    if hasNPC and not self:has(FT.APP.NPC_FAVOR) then
        Logging.info("[FarmTablet] autoDetect: NPC Favor detected")
        self:register({
            id = FT.APP.NPC_FAVOR, group = "mods",
            name = "ft_ui_app_npc_favor", navLabel = "NPC",
            icon = "npc", order = 22,
            developer = "TisonK", version = "Integrated",
            description = "NPC favor tracker",
        })
    end

    -- Seasonal Crop Stress
    -- Bridge: mission.cropStressManager set by SeasonalCropStress in Mission00.load
    local hasCropStress = (g_currentMission and g_currentMission.cropStressManager ~= nil)
    if hasCropStress and not self:has(FT.APP.CROP_STRESS) then
        Logging.info("[FarmTablet] autoDetect: Crop Stress detected")
        self:register({
            id = FT.APP.CROP_STRESS, group = "mods",
            name = "ft_ui_app_crop_stress", navLabel = "CRPS",
            icon = "crop_stress", order = 23,
            developer = "TisonK", version = "Integrated",
            description = "Seasonal crop stress monitor",
        })
    end

    -- Irrigation Suite (Wizard UI brief) - same SCS mission handle
    if hasCropStress and not self:has(FT.APP.IRRIGATION_SUITE) then
        Logging.info("[FarmTablet] autoDetect: Irrigation Suite (Seasonal Crop Stress)")
        self:register({
            id = FT.APP.IRRIGATION_SUITE, group = "mods",
            name = "ft_ui_app_irrigation_suite", navLabel = "IRRI",
            icon = "crop_stress", order = 23.5,
            developer = "WizardlyPayload", version = "Integrated",
            description = "Farm-wide irrigation operations, trend, and usage",
        })
    end

    -- Soil Fertilizer
    -- Bridge: mission.soilFertilityManager set by SoilFertilizer in Mission00.load
    local hasSoil = (g_currentMission and g_currentMission.soilFertilityManager ~= nil)
    if hasSoil and not self:has(FT.APP.SOIL_FERT) then
        Logging.info("[FarmTablet] autoDetect: Soil Fertilizer detected")
        self:register({
            id = FT.APP.SOIL_FERT, group = "mods",
            name = "ft_ui_app_soil_fertilizer", navLabel = "SOIL",
            icon = "soil", order = 24,
            developer = "TisonK", version = "Integrated",
            description = "Soil fertilizer status",
        })
    end

    -- FieldSentry — per-field soil-sim status + sleep/meadow toggles (#83).
    -- Detect via the cross-mod bridge S&F publishes on g_currentMission.fieldSentry
    -- (the plain FieldSentry_API global is per-mod scoped and invisible here). The
    -- app only appears on an S&F build new enough to ship that bridge.
    if hasSoil and g_currentMission.fieldSentry ~= nil and not self:has(FT.APP.FIELD_SENTRY) then
        Logging.info("[FarmTablet] autoDetect: FieldSentry detected")
        self:register({
            id = FT.APP.FIELD_SENTRY, group = "mods",
            name = "ft_ui_app_field_sentry", navLabel = "SENTRY",
            icon = "soil", order = 24.5,
            developer = "TisonK", version = "Integrated",
            description = "FieldSentry — per-field soil-sim status, sleep and meadow toggles",
        })
    end

    -- Crop Rotation Planner (Wizard UI brief #739) — SF mission handle only
    if hasSoil and not self:has(FT.APP.ROTATION_PLANNER) then
        Logging.info("[FarmTablet] autoDetect: Rotation Planner (Soil Fertilizer)")
        self:register({
            id = FT.APP.ROTATION_PLANNER, group = "mods",
            name = "ft_ui_app_rotation_planner", navLabel = "ROTATE",
            icon = "soil", order = 24.6,
            developer = "WizardlyPayload", version = "Integrated",
            description = "Farm-wide crop rotation standing and next-crop compare",
        })
    end

    -- Market Dynamics
    -- Bridge: mission.MarketDynamics set by MarketDynamics mod in Mission00.load
    if g_currentMission and g_currentMission.MarketDynamics then
        if not self:has(FT.APP.MARKET_DYNAMICS) then
            Logging.info("[FarmTablet] autoDetect: Market Dynamics detected")
            self:register({
                id = FT.APP.MARKET_DYNAMICS, group = "mods",
                name = "ft_ui_app_market_dynamics", navLabel = "MKT",
                icon = "market", order = 25,
                developer = "TisonK", version = "Integrated",
                description = "Market prices and dynamic events",
            })
        end
    end

    -- Worker Costs
    -- Bridge: mission.workerCostsManager set by WorkerCosts in Mission00.load
    if g_currentMission and g_currentMission.workerCostsManager then
        if not self:has(FT.APP.WORKER_COSTS) then
            Logging.info("[FarmTablet] autoDetect: Worker Costs detected")
            self:register({
                id = FT.APP.WORKER_COSTS, group = "mods",
                name = "ft_ui_app_worker_costs", navLabel = "WRK",
                icon = "worker", order = 26,
                developer = "TisonK", version = "Integrated",
                description = "Worker wages and cost breakdown",
            })
        end
        -- Personnel (Pro-Staff) — dedicated HR management app, same dependency.
        if not self:has(FT.APP.PERSONNEL) then
            Logging.info("[FarmTablet] autoDetect: Personnel (Pro-Staff) app enabled")
            self:register({
                id = FT.APP.PERSONNEL, group = "mods",
                name = "ft_ui_app_personnel", navLabel = "STAFF",
                icon = "personnel", order = 27,
                developer = "TisonK", version = "Integrated",
                description = "Pro-Staff personnel management — hire, fire, assign, payroll",
            })
        end
    end

    -- ProStaff Co-Op
    -- Bridge: mission.proStaffManager set by ProStaffCoOp in Mission00.load
    if g_currentMission and g_currentMission.proStaffManager then
        if not self:has(FT.APP.PROSTAFF) then
            Logging.info("[FarmTablet] autoDetect: ProStaff Co-Op detected")
            self:register({
                id = FT.APP.PROSTAFF, group = "mods",
                name = "ft_ui_app_prostaff", navLabel = "COOP",
                icon = "prostaff", order = 27.5,
                developer = "TisonK", version = "Integrated",
                description = "Co-Op progression -- level, benefits, and investment status",
            })
        end
    end

    -- Random World Events
    -- Bridge: mission.randomWorldEvents set by RandomWorldEvents in Mission00.load
    if g_currentMission and g_currentMission.randomWorldEvents then
        if not self:has(FT.APP.RANDOM_EVENTS) then
            Logging.info("[FarmTablet] autoDetect: Random World Events detected")
            self:register({
                id = FT.APP.RANDOM_EVENTS, group = "mods",
                name = "ft_ui_app_random_world_events", navLabel = "RWE",
                icon = "events", order = 27,
                developer = "TisonK", version = "Integrated",
                description = "Random world events tracker",
            })
        end
    end

    -- UsedPlus
    -- Bridge: g_vehicleSaleManager is set globally by UsedPlus main.lua
    -- Also check g_currentMission.usedPlusAPI (cross-mod bridge, also set by UsedPlus)
    local hasUsedPlus = (g_currentMission and g_currentMission.usedPlusAPI ~= nil)
    if hasUsedPlus and not self:has(FT.APP.USED_PLUS) then
        Logging.info("[FarmTablet] autoDetect: UsedPlus detected")
        self:register({
            id = FT.APP.USED_PLUS, group = "mods",
            name = "ft_ui_app_used_plus", navLabel = "USED",
            icon = "used_plus", order = 28,
            developer = "TisonK", version = "Integrated",
            description = "UsedPlus — active sale listings and finance deals",
        })
    end

    -- RoleplayPhone / Built-in Invoices
    -- Always registered — built-in FT_InvoiceManager provides fallback data even
    -- without FS25_RoleplayPhone. If the phone mod is present, RoleplayPhoneApp.lua
    -- detects it at draw time via getfenv(0)["RoleplayPhone_checkInstalled"].
    if not self:has(FT.APP.ROLEPLAY_PHONE) then
        Logging.info("[FarmTablet] autoDetect: Registering Invoices app (built-in + RoleplayPhone integration)")
        self:register({
            id = FT.APP.ROLEPLAY_PHONE, group = "mods",
            name = "ft_ui_app_roleplay_phone", navLabel = "INV",
            icon = "invoice", order = 29,
            developer = "TisonK", version = "Integrated",
            description = "Invoice tracker — built-in + RoleplayPhone integration",
        })
    end

    -- AnimalAutoCare
    if g_currentMission and g_currentMission.animalAutoCareCore and not self:has(FT.APP.ANIMAL_AUTO_CARE) then
        Logging.info("[FarmTablet] autoDetect: AnimalAutoCare detected")
        self:register({
            id = FT.APP.ANIMAL_AUTO_CARE, group = "mods",
            name = "ft_ui_app_animal_auto_care", navLabel = "AAC",
            icon = "animal_auto_care", order = 30,
            developer = "Akita83", version = "Integrated",
            description = "AnimalAutoCare status and safe care trigger",
            descriptionKey = "ft_desc_app_animal_auto_care",
        })
    end

    -- AnimalVetSystem
    if g_currentMission and (g_currentMission.animalVetSystem or g_currentMission.animalVet) and not self:has(FT.APP.ANIMAL_VET) then
        Logging.info("[FarmTablet] autoDetect: AnimalVetSystem detected")
        self:register({
            id = FT.APP.ANIMAL_VET, group = "mods",
            name = "ft_ui_app_animal_vet_system", navLabel = "VET",
            icon = "animal_vet_system", order = 31,
            developer = "Akita83", version = "Integrated",
            description = "AnimalVetSystem illness and treatment monitor",
            descriptionKey = "ft_desc_app_animal_vet_system",
        })
    end

    -- FactoryWeekSchedule
    if g_currentMission and g_currentMission.fws_weekSchedule and not self:has(FT.APP.FACTORY_WEEK) then
        Logging.info("[FarmTablet] autoDetect: FactoryWeekSchedule detected")
        self:register({
            id = FT.APP.FACTORY_WEEK, group = "mods",
            name = "ft_ui_app_factory_week_schedule", navLabel = "FWS",
            icon = "factory_week_schedule", order = 32,
            developer = "Akita83", version = "Integrated",
            description = "FactoryWeekSchedule overview with workers, events and fire state",
            descriptionKey = "ft_desc_app_factory_week_schedule",
        })
    end

    -- RealisticDealer
    local rd = (g_currentMission and (g_currentMission.realisticDealer or g_currentMission.RealisticDealer))
            or g_realisticDealer
            or (RealisticDealer and RealisticDealer.instance)
    if rd ~= nil and not self:has(FT.APP.REALISTIC_DEALER) then
        Logging.info("[FarmTablet] autoDetect: RealisticDealer detected")
        self:register({
            id = FT.APP.REALISTIC_DEALER, group = "mods",
            name = "ft_ui_app_realistic_dealer", navLabel = "DEAL",
            icon = "realistic_dealer", order = 33,
            developer = "Akita83", version = "Integrated",
            description = "RealisticDealer financing, installments and repossession status",
            descriptionKey = "ft_desc_app_realistic_dealer",
        })
    end

    -- DairyCore
    -- Bridge: mission.dairyCoreManager set by DairyCore in Mission00.load
    if g_currentMission and g_currentMission.dairyCoreManager then
        if not self:has(FT.APP.DAIRY_CORE) then
            Logging.info("[FarmTablet] autoDetect: DairyCore detected")
            self:register({
                id = FT.APP.DAIRY_CORE, group = "mods",
                name = "ft_ui_app_dairycore", navLabel = "DAIRY",
                icon = "dairy_core", order = 34,
                developer = "TisonK", version = "Integrated",
                description = "Dairy barn health, milk quality, spoilage and contracts",
            })
        end
    end

    Logging.info("[FarmTablet] autoDetect complete — %d apps registered", #self:getAll())
end
