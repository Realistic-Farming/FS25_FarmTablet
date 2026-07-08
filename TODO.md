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
