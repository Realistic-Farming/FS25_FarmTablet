# Farm Tablet documentation

Player documentation now lives in the **[Farm Tablet Wiki](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki)**. That is the single source of truth, kept in step with the current build. This folder keeps only the developer and API reference, which the wiki does not duplicate.

---

## For players, go to the wiki

| I want to | Page |
|-----------|------|
| Install or update the mod | [Installation](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Installation) |
| Learn the controls | [Getting Started](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Getting-Started) |
| See what every app does | [The Apps](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/The-Apps) |
| Move, resize, or reskin the tablet | [Customising the Tablet](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Customising-the-Tablet) |
| Change a setting or the open key | [Settings](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Settings) |
| Use the developer console | [Console Commands](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Console-Commands) |
| Companion mod apps | [Mod Integration Apps](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Mod-Integration-Apps) |
| Play on a server | [Multiplayer](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Multiplayer) |
| Fix a problem | [Troubleshooting and FAQ](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/wiki/Troubleshooting-and-FAQ) |

---

## For developers, stay here

These live in this folder because they are reference material, not player guides.

| Document | What is inside |
|----------|----------------|
| [developer/architecture.md](developer/architecture.md) | Module map, init sequence, rendering pipeline, multiplayer |
| [developer/writing-an-app.md](developer/writing-an-app.md) | Step by step guide to building a new app |
| [developer/settings-system.md](developer/settings-system.md) | The settings classes, XML types, adding new settings |
| [developer/data-provider.md](developer/data-provider.md) | Cache system, methods, return shapes, TTL |
| [developer/renderer.md](developer/renderer.md) | Layer model, scoping rules, methods, colour palette |
| [developer/eventbus.md](developer/eventbus.md) | Events, the on/off/emit API, companion patterns |
| [api/](api/) | Public API for every class and method |

> Note: the developer docs describe internal structure and can lag behind the code between refactors. When in doubt, the source in `src/` is authoritative.
