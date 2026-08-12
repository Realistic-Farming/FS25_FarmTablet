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
