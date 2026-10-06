# Roadmap: FS25_FarmTablet

> Ecosystem role: **Hub** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline.
> Forward-looking only. Shipped history lives in CHANGELOG.md and the releases.

## How to use this file
- Populate the milestones below from the audit baseline once it lands.
- Each item should be small enough to map to a `TODO.md` entry.
- Keep it honest: near-term is committed, mid-term is intended, long-term is aspirational.

## Current baseline
- Version at baseline: v2.5.3.0 (development); Rotation Planner + Irrigation Suite apps shipped this cycle.
- Audit reference: ecosystem-dev-tracking systems/farm-tablet-* Point 1-3 (2026-06-29)
- Baseline date: 2026-06-29 (updated 2026-07-25)

## Near-term (next release cycle)
- [x] Organic app compost display (OM-201, 2026-08-18): the COMPOST section of the Organic app now shows live compost batch state from SoilFertilizer's CompostManager (`g_currentMission.compostManager:getBatchRows`): batch id, days remaining or READY + output litres, and the organic-safe tag. Read-only; starting/collecting stays on the SF console commands. Replaces the "waiting on compost production API" stub.
- [x] TabletForceRepair works on a dedicated server (2026-08-18): the client previously hit "Money can only be deducted on the server" and could never force-complete a display repair on a dedi. The fee is now charged server-authoritatively through a new FarmTabletForceRepairEvent (client requests, server deducts, broadcast confirm completes the local repair), and the single-player path is unchanged. Remains a temporary command, removed when the repair station ships.
- [~] TEMPORARY `TabletForceRepair` console command: force-completes a display repair for a fixed 3000 fee until the real repair station ships, then it is removed.
- [ ] Focus state fix (Point 1): make goHome / openTablet / unlock pass nil instead of the previous appId (three one-line changes in FarmTabletUI.lua).
- [x] Keep the ecosystem-map current: MarketDynamicsApp and RandomWorldEventsApp are NOT stubs (source files exist; autoDetect registers them when the handles are present).
- [x] 2026-07-26 bug sweep: FT-001 (camera rotation restore), FT-002 (nil guard on g_currentMission), FT-003/FT-004/FT-005 fixed and merged to main.

## Mid-term (this season)
- [ ] Financial Cockpit page (FT-6): read-only financial health page with a self-recorded monthly history module. Brief staged, buildable on the Time Guard handle; opt-in follow-ons per companion (FuelCosts spend, DairyCore income, RWE money attribution, ProStaff/WorkerCosts co-op figure).
- [ ] DataProvider renderer object pool (Point 2): replace the per-refresh allocate/destroy with a pool. Perf, not blocking.
- [~] Polish the companion apps as their mods complete their bedrock migrations. Progress: Irrigation Suite (SCS), Rotation Planner (SF #739), and the Soil field-card redesign landed this cycle.

## Long-term / aspirational
- [ ] Worker Profiles / Pocket Profile app: a portrait grid over the WorkerCosts companion API with a full per-worker profile. Depends on WorkerCosts being built and stable.

## Cross-mod / ecosystem dependencies
- [ ] Reads every companion handle; each app's readiness tracks that mod's own progress.
- [ ] Pocket Profile app (blocks on: FS25_WorkerCosts stable + the sprite/art pipeline decision).

## Deferred / parked
- Pocket Profile: filed post-rollout, evaluate after WorkerCosts is stable.


## 2026-08-31 (Fred): weather dial refusal made visible (issue #140)
- [x] The World Weather chips no longer swallow the WeatherGuard result. A refused or errored change now draws a notice above the dial instead of silently doing nothing (admin-only wording for non-admins, WeatherGuard-refused wording otherwise). In-game verification pending.

## 2026-10-03 (Fred): SF-73 W1c, the Soil app shows Soil Fertilizer's AUTO target (#209)
- [x] FarmTablet's optional depth for SF-73 section 7. When Soil Fertilizer answers (its Experimental Systems on), each owned field's card in the Soil app shows the crop window as a field report, the soil reading where the player stands with its cell size, the field's last confirmed AUTO target pass for its current crop with planned and applied litres, and a pause one of the farm's own machines is in now, in Soil's own words. Beside a confirmed dose the treatment plan reads "TREATMENT PLAN (estimate)". Read only and guarded: a locked or older Soil draws the card as before. 35 keys in all 26 locales, 32 of them Soil's own text and translations. In-game verification pending (TESTING row 408).

## 2026-10-03 (Fred): SF-73, the Soil app shows a field's last no-crop pause
- [x] The Soil app also reads Soil Fertilizer's last-pause read (getLastTargetPauseForField, Soil #1090), feature-detected, so a stubble field after a refused AUTO pass reads "Last pause: no growing crop" with the manual hint, as the PDA card does, instead of "Last pass: none on this crop". The PDA card's rules hold: only while the field reports the crop the pause was noted under, only when newer than the last pass (a tie goes to the pass), the newest over a merged field's farmlands, never a pause naming denied access. A Soil without the read draws as before. Two keys in all 26 locales, Soil's own text. In-game verification pending.

## 2026-10-04 (Fred): the Organic app names its barns, and Market Movers prices animals per head (Wizard, #213 and #217)

- [x] Organic app (#213, merged at 262b62f3): a barn card shows the barn's name, by the same ladder the Dairy app uses (the row's own name, then the placeable's, then the existing barn label with a short id cut by characters), never its 32-character internal id. On a pure client the name resolves only when DairyCore's barn id is the client's own placeable id; otherwise the short id shows, as on the Dairy card.
- [x] Market Movers (#217, merged at 38bd868e): an animal's per-head price is no longer multiplied by 1,000; a row counts as per head when the animal system knows its fill type, and a save without an animal system takes the old path.
- The "(per 1,000 L)" heading still sits above animal rows: rewording it needs three translated strings, a follow-up Wizard names in #217. The in-game checks are TESTING rows 425 and 426. Docs by Fred's catch-up, on Tyson's word of 2026-10-04.

## 2026-10-05 (Fred via Desk): Help pages show their Back control (Wizard, #215)

- [x] Help pages (#215, merged at 33937f2): the Back control is drawn on the fixed header layer, just above the accent divider at the right, so the body clip no longer hides it. Before, it sat under the clip: a culled sliver with no label that still answered clicks. New renderer call `headerButton`, the header-layer twin of `button`; bar `tools/test/help-back-visible-check.mjs`.
- The control sits above the divider rather than beside the "Help" subtitle as first asked, because the renderer has no text measurement (declared in #215). The in-game check is TESTING row 439. Docs by Fred's catch-up, on Tyson's word of 2026-10-05.

## 2026-10-05 (Fred via Desk): the App Store keeps a Seasonal Crop Stress row, and the retired Crop Stress id opens Irrigation Suite (Wizard, #214 and #216)

- [x] App Store (#214, merged at 90ced81): MOD INTEGRATIONS keeps a "Seasonal Crop Stress" row whose OPEN goes to Irrigation Suite, so a player looking for that mod still finds it. This partly reverses the App Store listing removal of #159 under the 2026-09-08 ruling; merged on Tyson's word. Bar `tools/test/appstore-integration-row-check.mjs`.
- [x] Retired id (#216, merged at 7f91b71): `crop_stress` is back in `FT.APP` as a legacy id beside `DIGGING` and `BUCKET`, and `AppRegistry.resolve` sends it to Irrigation Suite, so a saved startup app, favourite or rail tile holding it opens Irrigation Suite instead of nothing. Bar `tools/test/app-resolve-check.mjs`.
- The in-game checks are TESTING rows 441 and 442. Docs by Fred's catch-up, on Tyson's word of 2026-10-05.

## 2026-10-06 (Fred): System Settings shows an enum's chosen value, and a group opens on the first tap (Wizard, #219)

- [x] System Settings (#219, merged at a5199367): an enum setting's live value is painted as the declared option nearest to it, which is the value the player chose, and an enum whose options are all ratios with at least one fraction is painted as the percent it means, so a chosen 0.80 reads 80% and never a long decimal such as 0.800000011920929. A list of plain numbers (0, 1, 2) still shows the number. Module groups start closed and the first tap opens one (the closed start decided by Tyson, 2026-10-05, via Desk); a group you open stays open for the session. Bar `tools/test/settings-enum-value-check.mjs`.
- The in-game check is TESTING row 460. SettingsHub #23 (MAINTENANCE 217) is the hub-side fix for enum values that cross the network as float32. Docs by Fred's catch-up, on Tyson's word of 2026-10-05.
