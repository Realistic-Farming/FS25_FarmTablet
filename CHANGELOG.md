# Changelog

All notable changes to FS25_FarmTablet will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Changelog tracking for this mod begins **2026-08-23** under the suite-wide ruling
(see the ecosystem ledger, entry for Arissani and Wizard). Prior history lives in
the repo's git history and README.

---

## [Unreleased]

## [2.7.0.0] - 2026-10-12

> **This is not a final release.** It gives everyone, testers and players, new or returning, everything we have built so far, so nobody has to wait on an old version any longer. The Realistic Farming suite is far from done: we are still building and expanding every mod, and completing it could take months, possibly a year. Expect changes and rough edges along the way, and please report anything that looks wrong.

### Added
- **A Tablet Charging Station** placeable.
- **Editable System Settings app:** change suite settings from the tablet through Settings Hub. Enum settings show their chosen value, and a group opens on the first tap.
- **Emergency loan in the Financial Cockpit** (with Income Mod).
- **Irrigation Suite** shows rain-key state and hours of water, and replaces the old Crop Stress app (the App Store's Seasonal Crop Stress row points to it, and old saves are redirected). In multiplayer it shows only your own farm's irrigation.
- **Dairy app:** herd and tank breed records for your farm. **Organic app:** a compost display and a livestock section, with barns shown by name.
- **Soil app:** with Soil & Fertilizer's experimental AUTO target on, field cards show the crop window, the soil reading where you stand, the last AUTO pass and any pause (including a field with no growing crop).
- Owned-field lists are grouped by the helper's GPS outline. Control Center actions for the tablet.

### Fixed
- **The whole tablet speaks your language:** the home and lock screens, app names, App Store, Dashboard, Settings and every app (Field Status, FieldSentry, Rotation Planner, Animal Husbandry, Contracts, Fleet Manager, Farm Stats, Production, Storage, Workshop, Weather, Hotspots, Notes, Excavator, Farm Admin, Personnel, Organic, Soil, Updates, Invoices, Income, Tax, Worker Costs, NPC Favor, Pro Staff, the Financial Cockpit, the Irrigation Suite and the Akita apps) are translated into every language the game ships.
- Garbled letters and symbols in Danish, English, Indonesian, Italian, Dutch and Turkish are fixed. German and Russian players read the tablet's own translations instead of words rewritten inside other words. Long names no longer end in a broken letter, and text already in your language is drawn as it is (clocks read "06:30").
- Farm Admin's money buttons show your own currency, and Farm Admin works on dedicated servers. The force-repair fee is charged on the server, and the weather dial says when a change is refused instead of doing nothing.
- Market Movers no longer scales a per-head livestock price by 1,000. The Akita apps agree with their own data, and the helps only name what the companion mods really have.
- The tablet stays visible when Master HUD hides the suite HUDs. The Contracts tab survives missions with a broken field wrapper, the Field Jobs timer and controls are explained where you press Start, and the irrigation forecast never reads a missing moisture as 0.
- The tablet shows the installed build's own version, the excavator icon is back, settings save on dedicated servers, and the help pages' Back control sits clear of the first section.

### Fixed
- **The Dairy app's title is translated in every language (MAINTENANCE row 95).** It read the English "Dairy" in all 25 other languages; each now names dairy farming in its own words, for example Milchvieh, Élevage laitier and 酪農.
- **The NPC Favor app shows your farm's own favours from the host, or says it cannot yet (RSF-F357, the tablet drawer).** With an NPC Favor host that has saved neighbours, the Favors block is the host's copied page for your farm (your accepted work, the open offers, the completed count), refreshed while the app is shown and released when you leave it or close the tablet; a page that has not arrived, or is older than two refresh intervals, says so instead of showing zero, and a remaining time the host does not know reads as unknown rather than 0h. The Relationships block reads the host's public roster: a neighbour who is waiting or a hired worker is listed by name with no score. An older NPC Favor keeps the previous display. Nothing to configure.

### Added
- Changelog file established (suite ruling 2026-08-22).
- Control Center action: `FT_TOGGLE_TABLET` toggles the FarmTablet from the suite Control Center (requires SettingsHub).

### Fixed
- RSF-F245: the Irrigation Suite forecast no longer raises a "drying" alert for a field that SeasonalCropStress reports with no moisture reading. A missing reading is no longer counted as 0 percent; the dry and wet moisture alerts wait for a real reading, while the stress alert and "watering now" still show.

## [2.6.0.6] - 2026-08-23

- First entry under changelog tracking.
