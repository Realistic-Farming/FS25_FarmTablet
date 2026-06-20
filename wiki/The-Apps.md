# The Apps

Farm Tablet is built around apps. Each one does a single job well, and you open them from the home screen, the same way you tap apps on a phone. This page is the master list. For the full detail on any app, follow the link to its category page.

There are three kinds of app:

- **Core apps** run the tablet itself. Always present.
- **Farm apps** cover everything about running your farm. Always present.
- **Mod integration apps** appear on their own when a companion mod is in your save.

That is **20 apps built in** and **up to 12 more** that show up automatically, so as many as 32 app icons on the home screen.

---

## Core apps

The four apps that make the tablet a tablet. Full detail on [[Core Apps]].

| App | App id | What it does |
|-----|--------|--------------|
| Dashboard | `dashboard` | Your farm at a glance: balance, income, fields, vehicles, time, weather |
| App Store | `app_store` | Every installed app grouped by category, with one click open |
| Settings | `settings` | All tablet settings in one panel |
| Updates | `updates` | The full changelog, newest first |

---

## Farm apps

The day to day tools. Full detail on [[Farm Apps]].

| App | App id | What it does |
|-----|--------|--------------|
| Weather | `weather` | Current conditions and a five day forecast |
| Field Manager | `field_status` | Every field you own with crop and growth state |
| Animals | `animals` | Every pen with food, water, and cleanliness bars |
| Workshop | `workshop` | Nearby vehicle diagnostics with one click repair |
| Digging | `digging` | Live position, terrain height, and dig depth |
| Bucket Tracker | `bucket_tracker` | Counts loader dump cycles and weight moved |
| Storage | `storage` | Silo inventory and the best sell price per crop |
| Time Controls | `time_controls` | Set the time scale and skip to a time of day |
| Hotspot Manager | `hotspot_manager` | View and clear map pins |
| Notes | `notes` | A simple farm todo list |
| Farm Admin | `farm_admin` | Money, time, and vehicle controls (host only) |
| Field Jobs | `field_jobs` | Log your field work sessions |
| Contracts | `contracts` | Active contracts with completion and reward |
| Fleet Manager | `fleet_manager` | Every owned vehicle sorted by fuel |
| Production Buildings | `production_buildings` | Your production chains, inputs and outputs |
| Farm Stats | `farm_stats` | A full farm statistics snapshot |

---

## Mod integration apps

These appear on the home screen only when the matching mod is loaded. No setup, no load order. Full detail on [[Mod Integration Apps]].

| App | App id | Needs this mod |
|-----|--------|----------------|
| Income Mod | `income_mod` | FS25_IncomeMod |
| Tax Mod | `tax_mod` | FS25_TaxMod |
| NPC Favor | `npc_favor` | FS25_NPCFavor |
| Crop Stress | `crop_stress` | FS25_SeasonalCropStress |
| Soil Fertilizer | `soil_fertilizer` | FS25_SoilFertilizer |
| Field Sentry | `field_sentry` | FS25_SoilFertilizer (with the Field Sentry bridge) |
| Market Dynamics | `market_dynamics` | FS25_MarketDynamics |
| Worker Costs | `worker_costs` | FS25_WorkerCosts |
| Personnel | `personnel` | FS25_WorkerCosts |
| Random World Events | `random_world_events` | FS25_RandomWorldEvents |
| UsedPlus | `used_plus` | FS25_UsedPlus |
| Invoices | `roleplay_phone` | Built in, with extra features if FS25_RoleplayPhone is loaded |

---

## How companion apps appear

When a save finishes loading, the tablet checks for each companion mod by looking for the object that mod registers in the game. If it finds it, the app is added to the home screen. If it does not, the app is simply left out, no empty placeholder.

If you add a companion mod halfway through a playthrough, restart the game session and the app will be there next time you open the tablet. More on this in [[Mod Integration Apps]].
