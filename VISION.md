# Vision: FS25_FarmTablet

> Ecosystem role: **Hub** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit (FarmTablet platform audit, ecosystem-map, notes).
> Last updated: 2026-07-08

## 1. One-line purpose
The ecosystem's tablet: an in-game companion app platform (iOS-style springboard, app registry, data layer, focus API) where every Realistic Farming mod surfaces its information to the player in one place.

## 2. Problem it solves
Each mod has its own HUD or menu, and there is no single place to see the whole farm. FarmTablet is the shared surface all companion mods publish an app into, so the player reads soil, income, tax, labour, markets, events and NPCs from one device.

## 3. Design pillars
- **Read-only on peers.** FarmTablet reads other mods; the rare write-back (for example FieldSentry sleep/meadow toggles) goes through that mod's own admin-gated client-to-server event, never a direct poke.
- **Graceful when a mod is absent.** Every app gates on the peer handle and shows an "update the mod" message rather than crashing.
- **Platform, not logic.** The platform owns rendering, data caching, app switching, focus broadcast and input; companion mods only write drawer functions.
- **Idempotent auto-detect.** App registration runs on mission load and on every tablet open; registering an already-present app is a no-op.

## 4. Role in the ecosystem
- Public handles: `g_currentMission.farmTablet` (the cross-mod FarmTabletFocus singleton) and `g_currentMission.ftInvoiceManager` (invoice data for RoleplayPhone). `g_FarmTablet` is per-mod scoped and not cross-mod.
- Reads from (consumes): every companion via its published handle: `soilFertilityManager` + `fieldSentry`, `cropStressManager`, `incomeManager`, `taxManager`, `workerCostsManager`, `npcFavorSystem`, `MarketDynamics` (capital M), `randomWorldEvents`, plus external mods (UsedPlus, RoleplayPhone, Akita AnimalVet). Each via `g_currentMission.<handle>` with a `getfenv(0)` fallback, always pcall-guarded.
- Read by (consumers): RoleplayPhone reads `ftInvoiceManager`.
- Core-API registration status: N/A by design. FarmTablet is a display and interaction surface, not a core-API bedrock client. It publishes its own handles and reads peers; it is not a StateLedger/NetworkSync/MasterHUD consumer in the migration sense (it does keep its own save files: settings/invoices/notes/storage/field-jobs).

## 5. Explicit non-goals
- Does not own or write peer state. Any write goes through the owning mod's admin-gated event.
- Not a core-API bedrock mod. It is the platform the companions surface into.
- Does not contain a companion's business logic; each app is thin over that mod's read API.

## 6. Success criteria
- Every companion mod that has something to show has a working, non-crashing app, present or absent.
- Cross-mod focus state broadcasts correctly so apps and mods can react to what the player is viewing.
- Adding a new readable mod is app-side only when that mod publishes its handle.

## 7. Open questions for the audit
- Focus state: the system is binary (isVisible + appId) rather than three-state; goHome/openTablet/unlock pass the previous appId instead of nil. Confirm the three one-line fixes in FarmTabletUI.lua.
- DataProvider has no renderer object pool (allocate/destroy each refresh, TTL 2000ms / content 4000ms). Known tradeoff; confirm whether to pool.
