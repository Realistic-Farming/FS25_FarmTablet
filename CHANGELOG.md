# Changelog

All notable changes to FS25_FarmTablet will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Changelog tracking for this mod begins **2026-08-23** under the suite-wide ruling
(see the ecosystem ledger, entry for Arissani and Wizard). Prior history lives in
the repo's git history and README.

---

## [Unreleased]

### Fixed
- **The NPC Favor app shows your farm's own favours from the host, or says it cannot yet (RSF-F357, the tablet drawer).** With an NPC Favor host that has saved neighbours, the Favors block is the host's copied page for your farm (your accepted work, the open offers, the completed count), refreshed while the app is shown and released when you leave it or close the tablet; a page that has not arrived, or is older than two refresh intervals, says so instead of showing zero, and a remaining time the host does not know reads as unknown rather than 0h. The Relationships block reads the host's public roster: a neighbour who is waiting or a hired worker is listed by name with no score. An older NPC Favor keeps the previous display. Nothing to configure.

### Added
- Changelog file established (suite ruling 2026-08-22).
- Control Center action: `FT_TOGGLE_TABLET` toggles the FarmTablet from the suite Control Center (requires SettingsHub).

### Fixed
- RSF-F245: the Irrigation Suite forecast no longer raises a "drying" alert for a field that SeasonalCropStress reports with no moisture reading. A missing reading is no longer counted as 0 percent; the dry and wet moisture alerts wait for a real reading, while the stress alert and "watering now" still show.

## [2.6.0.6] - 2026-08-23

- First entry under changelog tracking.
