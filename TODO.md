# TODO: FS25_FarmTablet

> Ecosystem role: **Hub** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline, kept current.
> Convention: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked. Newest at the top of each section.

## From the ecosystem audit (Arissani)
- [ ] Focus state (Point 1): goHome / openTablet / unlock should pass nil, not the previous appId. Three one-line fixes in FarmTabletUI.lua.
- [x] Confirmed: MarketDynamicsApp and RandomWorldEventsApp are real apps, not stubs (autoDetect registers them when handles present).

## Bugs
- [ ] Focus state passes previous appId instead of nil on goHome/openTablet/unlock (Point 1).

## Features / enhancements
- [x] Irrigation Suite app (FT #100): a read-only SCS operating picture (coverage overlay + system status), built to Wizard's UI brief and merged; real frame-cache for the coverage overlay (03a6198).
- [x] Rotation Planner app (FT #99): reads SoilFertilizer's #739 rotation data surface (lastCrop3 + bonus countdown), prefers the SF-blessed candidate pool.
- [x] Soil tablet field-card redesign (FT #101): the Soil app field cards reworked per Tyson's approval.
- [x] App text scales with the tablet + a font-size setting (#96); Weather app help copy dejargoned (#91).
- [x] App icons for irrigation_suite / rotation_planner / system_settings (gen_icons emblems + baked DDS).
- [x] FieldSentry admin gate is now fail-closed, not fail-open (security).
- [ ] Financial Cockpit page (FT-6): read-only financial HEALTH heart + instruments + self-recorded monthly history via its own StateLedger module. Brief staged; buildable on the Time Guard handle. Not started.
- [ ] DataProvider renderer object pool (Point 2, not blocking).
- [ ] Pocket Profile / Worker Profiles app (deferred; depends on WorkerCosts).

## Cross-mod integration
- [ ] Reads all companion handles: soilFertilityManager + fieldSentry, cropStressManager, incomeManager, taxManager, workerCostsManager, npcFavorSystem, MarketDynamics, randomWorldEvents (+ external UsedPlus, RoleplayPhone, Akita).
- [x] Publishes `g_currentMission.farmTablet` (focus) and `g_currentMission.ftInvoiceManager` (invoices, read by RoleplayPhone).

## Docs / localization
- [ ] Keep all 26 languages in step for any new app label or string.
- [ ] Update README/version on each release.

## Blocked / waiting on
- [!] Pocket Profile app (waits on: FS25_WorkerCosts built + stable, and the sprite art pipeline decision).
