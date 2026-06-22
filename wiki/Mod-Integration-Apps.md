# Mod Integration Apps

These apps are not on the home screen by default. They appear on their own when the tablet detects the matching mod in your save. There is nothing to configure and load order does not matter.

Most of these companion mods are part of my own suite, so the integrations are first party and stay in step with each mod.

Jump to an app:
[Income Mod](#income-mod) ·
[Tax Mod](#tax-mod) ·
[NPC Favor](#npc-favor) ·
[Crop Stress](#crop-stress) ·
[Soil Fertilizer](#soil-fertilizer) ·
[Field Sentry](#field-sentry) ·
[Market Dynamics](#market-dynamics) ·
[Worker Costs](#worker-costs) ·
[Personnel](#personnel) ·
[Random World Events](#random-world-events) ·
[UsedPlus](#usedplus) ·
[Invoices](#invoices)

---

## How detection works

When a save finishes loading, the tablet runs an auto detect pass. For each companion mod it looks for the object that mod registers on the running game, for example the income manager or the soil fertility manager. If that object is there, the app is added to the home screen. If it is not, the app is skipped, with no "mod not installed" placeholder.

If you add a companion mod partway through a playthrough, restart the game session so the detect pass runs again. The app will be there next time you open the tablet.

Every integration reads the companion mod's data. A few also write back to it (the Enable and Disable buttons, for example). When they write, they write straight to that mod's own settings, so if the mod has its own save timing the change lands when that mod next saves.

---

## Income Mod

**App id:** `income_mod` · **Needs:** FS25_IncomeMod

Status and controls for periodic income payments.

- **Status:** whether the mod is on or off.
- **Payment mode:** when income is paid, hourly, daily, or weekly.
- **Amount:** the money added per payment cycle.
- **ENABLE / DISABLE:** turn the mod on or off without uninstalling it. The change takes effect at once and is saved.

---

## Tax Mod

**App id:** `tax_mod` · **Needs:** FS25_TaxMod

Status and a quick toggle for the tax system.

- **Status:** on or off.
- **Tax rate:** the rate tier charged per cycle.
- **Return %:** how much of the tax you pay comes back as a rebate.
- **Total paid:** cumulative tax across the current session.
- **ENABLE / DISABLE:** toggle the mod without uninstalling it.

---

## NPC Favor

**App id:** `npc_favor` · **Needs:** FS25_NPCFavor

Your standing with the local community and your active favours.

- **Town Reputation:** overall standing from 0 to 100, with a colour coded bar and a label, Respected, Neutral, or Poor.
- **Active favors:** how many you have in progress, plus completed totals and money earned.
- **Active favors detail:** the NPC, the task, completion percent, and hours remaining.
- **Relationships:** every active NPC sorted by score, each with a status (Friend, Neutral, or Cold), a bar, and their role in brackets.

To build a relationship, complete favours for that NPC and their score climbs.

---

## Crop Stress

**App id:** `crop_stress` · **Needs:** FS25_SeasonalCropStress

Per field soil moisture and drought stress.

- **Status banner:** whether Seasonal Crop Stress is enabled, and its difficulty.
- **Field list:** each field with its crop, moisture percent, and a colour coded bar.
- **Stress indicator:** if a field has more than 5% accumulated drought stress, it shows a red `!XX%`.

Moisture bar colours: green at 40% or above, yellow at 25% or above, red below 25%. A red stress flag means that field needs irrigation soon to avoid yield loss.

---

## Soil Fertilizer

**App id:** `soil_fertilizer` · **Needs:** FS25_SoilFertilizer

Per field nutrient tracking with a detail view.

- **Status banner:** active or disabled.
- **Field list:** each owned field with its crop. Rows marked `[FERT!]` in yellow need fertilising.
- **Select a field:** tap SELECT to open its detail panel.

The detail panel shows Nitrogen, Phosphorus, and Potassium with a status, pH, organic matter, the last crop, and days since the last harvest.

- **Nutrient colours:** green is Good, yellow is Fair, red is Poor.
- **pH:** the healthy range is 6.0 to 7.5. Outside that, nutrient uptake drops even when the raw numbers look fine.
- **Organic matter:** higher is better, it improves water retention and long term fertility.

---

## Field Sentry

**App id:** `field_sentry` · **Needs:** FS25_SoilFertilizer with the Field Sentry bridge

Field Sentry decides which fields the soil simulation actually runs, and this app lets you see and control that per field. It appears only on a Soil Fertilizer build new enough to publish the bridge.

- **Status:** ACTIVE means the field is simulated normally. Other states mean it is asleep or handled differently, each shown in its own colour.
- **Sleep toggle:** force a field to sleep, or wake it. Your choice persists.
- **Meadow toggle:** mark a field as permanent grassland. It still simulates, but as meadow.

In multiplayer the toggles are admin only and validated by the host. Clients see the state but only an admin can change it. See [[Multiplayer]].

---

## Market Dynamics

**App id:** `market_dynamics` · **Needs:** FS25_MarketDynamics

Status for the dynamic market system.

- **Status:** the mod's current state.
- **World events:** events like droughts and trade disruptions that move prices, shown while active.
- **Settings:** price modifiers and event frequency that the mod is running with.

---

## Worker Costs

**App id:** `worker_costs` · **Needs:** FS25_WorkerCosts

Status and the wage picture for hired workers.

- **Status:** the mod's current state.
- **Wage level:** the per hour wage rate for hired workers.
- **Cost mode:** how wages are calculated.
- **Month costs:** total wages accumulated this month.
- **Pro Staff roster:** your hired workers with their level.

For full hire and fire management, use the Personnel app below, which shares the same mod.

---

## Personnel

**App id:** `personnel` · **Needs:** FS25_WorkerCosts

A full HR command centre for the Pro Staff side of Worker Costs. Where Worker Costs shows the numbers, Personnel lets you manage the people.

- **Roster tab:** every worker with level, lifetime hours, jobs done, and status.
- **Hire tab:** a rotating recruitment pool, each candidate with their own stats so you can pick who to bring on.
- **Payroll tab:** the wage structure and a running cost estimate.

In multiplayer the roster lives on the host. Your hire and fire actions are sent to the host and applied there.

---

## Random World Events

**App id:** `random_world_events` · **Needs:** FS25_RandomWorldEvents

Status for the random events system.

- **Status:** the mod's current state.
- **Active event:** when an event is running (fire, flood, drought, and so on) it is shown here.
- **Frequency and intensity:** the dials the mod is using, frequency for how often events fire, intensity for how strong they are.

---

## UsedPlus

**App id:** `used_plus` · **Needs:** FS25_UsedPlus

Your active sale listings and finance deals from UsedPlus.

- **Active sale listings:** vehicles you have listed for sale through a UsedPlus dealer.
- **Progress bar:** filled shows time elapsed on a listing. An offer can arrive at any point.
- **Finance deals:** active loans and leases arranged through UsedPlus.
- **Credit score:** your farm's UsedPlus credit rating.

---

## Invoices

**App id:** `roleplay_phone` · **Needs:** built in, with extras if FS25_RoleplayPhone is loaded

The one companion app that is always present, because it runs on a built in invoice manager. If you have FS25_RoleplayPhone v0.4.0 or newer, it links up for extra features.

- **Invoice tracker:** money you owe others (outgoing) and money owed to you (incoming).
- **Summary bar:** total receivable in green and total payable, across the top.
- **New invoice:** tap **+ NEW** to open the creation form, set an amount and an optional due date (none, 7, 14, 30, 60, or 90 days).
- **Roleplay Phone integration:** with the phone mod installed, invoices tie into it for a fuller roleplay loop.

---

## When an app does not appear

1. Make sure the companion mod is enabled for this save in the mod manager.
2. Reload the save. The tablet checks for mods when the mission finishes loading.
3. Turn on Debug Mode in [[Settings]] and check `log.txt`. Detection results are logged, so you can see whether the tablet found the mod.

The detection looks for a specific object each mod publishes. If a companion mod changes that in a future version, the app might stop appearing until I update the bridge. If that happens, open an [issue](https://github.com/Realistic-Farming/FS25_FarmTablet/issues) and tell me which mod and version.
