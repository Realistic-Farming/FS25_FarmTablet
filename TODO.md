# TODO: FS25_FarmTablet

> Ecosystem role: **Hub** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline, kept current.
> Convention: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked. Newest at the top of each section.

## Bugs
- [x] 2026-10-06: **The tablet shows a stale version (MAINTENANCE row 236).** FT.VERSION was a hand-kept copy of modDesc.xml's `<version>` and drifted (2.6.0.6 shown on 2.6.0.11). `src/core/Constants.lua` now takes the version the engine read from modDesc into its mod manager (`g_modManager:getModByName(FarmTabletModName).version`), and keeps the constant as the fallback. Bar `tools/test/version-label-check.mjs`, battery `tools/test/mutate_version_label.py`. In-game check pending (TESTING row 495).

- [x] 2026-08-31: **Weather dial refusal now visible (issue #140).** The World Weather chips called `WeatherGuard:requestWeatherMode` inside a bare `pcall` and discarded the result, so on a dedicated server a refused or errored change looked like "nothing happened" with no message. The chip handler now captures the return, clears any stale notice on success, and on failure draws a notice line above the dial: admin-only wording when the player is not a host or master user, WeatherGuard-refused wording otherwise. In-game verification pending.

- [x] 2026-07-30: `src/apps/ProStaffApp.lua:111` failed to COMPILE - `...` referenced from inside an anonymous function ("cannot use '...' outside of a vararg function"). Lua 5.1 does not let a nested closure see the enclosing function's vararg. The whole file was rejected, so the ProStaff app was dead in every session. `safeGet` now passes the varargs straight to `pcall` (no inner closure) and guards a missing method.
- [ ] **ROOT CAUSE, still open: `build.py` has NO Lua 5.1 syntax gate**, which is the only reason the above reached the game. SoilFertilizer catches this class of error before it can ship (its pre-commit hook runs `luaparse` pinned to 5.1 over every source file, plus a lint pass). Port that gate here: either a `tools/test/` harness of our own, or a syntax step in `build.py` that fails the build. A compile error in one app file takes the file down silently, so this is worth more than any individual fix.

## From the ecosystem audit (Arissani)
- [ ] Focus state (Point 1): goHome / openTablet / unlock should pass nil, not the previous appId. Three one-line fixes in FarmTabletUI.lua.
- [x] Confirmed: MarketDynamicsApp and RandomWorldEventsApp are real apps, not stubs (autoDetect registers them when handles present).

## Bugs
- [x] FT-006 TabletForceRepair on a dedicated server (2026-08-18): the client hit "Money can only be deducted on the server" and could not force-complete a display repair on a dedi. New `FarmTabletForceRepairEvent` (src/events/): the client sends the request, the server charges the 3000 fee via `farm:changeBalance` + `addMoneyChange`, then broadcasts a confirm that completes the requesting client's local repair (`_completeLocalForceRepair`). The single-player path in `forceCompleteRepair` is unchanged. Lua 5.1 syntax clean; built and uploaded to the RF Dev server (SHA256 byte-verified).
- [ ] Focus state passes previous appId instead of nil on goHome/openTablet/unlock (Point 1).
- [x] FT-001 `_exitEditMode()` restores camera rotation (fixed, merged to main).
- [x] FT-002 Nil guard on `g_currentMission` in `SettingsManager:getSettings()` (fixed, merged to main).
- [x] FT-003 / FT-004 / FT-005: additional FarmTablet bugs fixed in 2026-07-26 bug sweep, merged to main.

## Features / enhancements
- [x] System Settings shows an enum's chosen value (a ratio as its percent) and opens a group on the first tap; groups start closed (Wizard, #219, 2026-10-05). In-game check pending (TESTING row 460).
- [x] The retired Crop Stress app id opens Irrigation Suite instead of nothing (Wizard, #216, 2026-10-05). In-game check pending (TESTING row 442).
- [x] The App Store keeps a Seasonal Crop Stress row that opens Irrigation Suite (Wizard, #214, 2026-10-05). In-game check pending (TESTING row 441).
- [x] Help pages draw their Back control on the header layer, so the body clip no longer hides it (Wizard, #215, 2026-10-05). In-game check pending (TESTING row 439).
- [x] Market Movers no longer scales an animal's per-head price by 1,000 (Wizard, #217, 2026-10-04); the heading over animal rows stays loose until its strings are translated. In-game check pending (TESTING row 426).
- [x] The Organic app names each barn instead of printing its internal id (Wizard, #213, 2026-10-04). In-game check pending (TESTING row 425).
- [x] SF-73, the Soil app's last pause (2026-10-03): a stubble field after a refused AUTO pass reads "Last pause: no growing crop", as the PDA does, from Soil's guarded getLastTargetPauseForField under the PDA card's rules. Bar: `tools/test/soil-target-block-check.mjs` rows Q1 to Q13; battery `tools/test/mutate_w1c_soil_target.py` M21 to M28.
- [x] SF-73 W1c, the Soil app's AUTO target block (#209, 2026-10-03): the crop window as a field report, the local soil reading with its cell size, the field's last confirmed AUTO pass with its litres, and a current pause of one of the farm's own machines, all from Soil's guarded reads; the plan beside a confirmed dose reads as an estimate. Bar: `tools/test/soil-target-block-check.mjs` (entry-point row E, the real tablet load). In-game check: TESTING row 408.
- [x] Organic app compost display (OM-201, 2026-08-18): the COMPOST stub in `OrganicApp` now renders live batch rows from SF's `CompostManager` (`getBatchRows`), with READY/remaining days, output litres and the organic-safe tag. Requires the SF cross-mod handle (`mission.compostManager`, PR alongside). Read-only display.
- [~] TabletForceRepair console command (TEMPORARY): force-completes a display repair for a fixed 3000 fee so the player can use the tablet again. To be removed and replaced by the real repair station when it ships.
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
