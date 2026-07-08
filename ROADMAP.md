# Roadmap: FS25_FarmTablet

> Ecosystem role: **Hub** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline.
> Forward-looking only. Shipped history lives in CHANGELOG.md and the releases.

## How to use this file
- Populate the milestones below from the audit baseline once it lands.
- Each item should be small enough to map to a `TODO.md` entry.
- Keep it honest: near-term is committed, mid-term is intended, long-term is aspirational.

## Current baseline
- Version at baseline: v2.5.1.0
- Audit reference: ecosystem-dev-tracking systems/farm-tablet-* Point 1-3 (2026-06-29)
- Baseline date: 2026-06-29

## Near-term (next release cycle)
- [ ] Focus state fix (Point 1): make goHome / openTablet / unlock pass nil instead of the previous appId (three one-line changes in FarmTabletUI.lua).
- [ ] Keep the ecosystem-map current: MarketDynamicsApp and RandomWorldEventsApp are NOT stubs (source files exist; autoDetect registers them when the handles are present).

## Mid-term (this season)
- [ ] DataProvider renderer object pool (Point 2): replace the per-refresh allocate/destroy with a pool. Perf, not blocking.
- [ ] Polish the companion apps as their mods complete their bedrock migrations.

## Long-term / aspirational
- [ ] Worker Profiles / Pocket Profile app: a portrait grid over the WorkerCosts companion API with a full per-worker profile. Depends on WorkerCosts being built and stable.

## Cross-mod / ecosystem dependencies
- [ ] Reads every companion handle; each app's readiness tracks that mod's own progress.
- [ ] Pocket Profile app (blocks on: FS25_WorkerCosts stable + the sprite/art pipeline decision).

## Deferred / parked
- Pocket Profile: filed post-rollout, evaluate after WorkerCosts is stable.
