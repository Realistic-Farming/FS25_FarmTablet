# Console Commands

Everything the tablet does from a menu, you can also do from the developer console. Handy for testing, for fixing a tablet that has wandered off screen, or just for speed.

Open the console with the **grave or tilde key** (`` ` `` or `~`), type `tablet`, and press Enter to see the full list in game.

Console commands run on your **local client only**. They do nothing on a dedicated server and are not shared with other players.

---

## The commands

| Command | What it does |
|---------|--------------|
| `tablet` | Lists every tablet command in the console output. |
| `TabletOpen` | Opens the tablet if it is closed. |
| `TabletClose` | Closes the tablet if it is open. |
| `TabletToggle` | Opens it if closed, closes it if open. Same as pressing the open key. |
| `TabletEnable` | Enables the mod if you have disabled it. |
| `TabletDisable` | Disables the mod. The open key stops working until you enable it again. Saved. |
| `TabletKeybind [key]` | Changes the open key. Takes effect at once. |
| `TabletApp [app_id]` | Switches to an app by id. Opens the tablet if it is closed. |
| `TabletSetStartupApp [app_id]` | Sets which app opens first. Saved. |
| `TabletSetNotifications true\|false` | Turns the welcome message on or off. |
| `TabletShowSettings` | Prints all current settings. Useful for bug reports. |
| `TabletResetSettings` | Resets everything to factory defaults. Cannot be undone. |

---

## Changing the open key

```
TabletKeybind F5
TabletKeybind B
TabletKeybind TAB
```

Keys are not case sensitive, so `f5` and `F5` both work. Valid values include any letter A to Z, F1 to F12, TAB, SPACE, ENTER, BACKSPACE, DELETE, HOME, END, PAGEUP, PAGEDOWN, INSERT, ESC, the arrow keys, and the numpad keys NUM0 to NUM9 plus NUMMULT, NUMADD, NUMSUB, NUMDEC, and NUMDIV.

If you type something invalid, the key falls back to T.

---

## Jumping straight to an app

```
TabletApp weather
TabletApp field_status
TabletApp storage
```

Use the app id, not the display name. Here is every id. Companion app ids only work when their mod is loaded.

**Core**

| Id | App |
|----|-----|
| `dashboard` | Dashboard |
| `app_store` | App Store |
| `settings` | Settings |
| `updates` | Updates |

**Farm**

| Id | App |
|----|-----|
| `weather` | Weather |
| `field_status` | Field Manager |
| `animals` | Animals |
| `workshop` | Workshop |
| `digging` | Digging |
| `bucket_tracker` | Bucket Tracker |
| `storage` | Storage |
| `time_controls` | Time Controls |
| `hotspot_manager` | Hotspot Manager |
| `notes` | Notes |
| `farm_admin` | Farm Admin |
| `field_jobs` | Field Jobs |
| `contracts` | Contracts |
| `fleet_manager` | Fleet Manager |
| `production_buildings` | Production Buildings |
| `farm_stats` | Farm Stats |

**Mod integrations** (need the companion mod loaded)

| Id | App |
|----|-----|
| `income_mod` | Income Mod |
| `tax_mod` | Tax Mod |
| `npc_favor` | NPC Favor |
| `crop_stress` | Crop Stress |
| `soil_fertilizer` | Soil Fertilizer |
| `field_sentry` | Field Sentry |
| `market_dynamics` | Market Dynamics |
| `worker_costs` | Worker Costs |
| `personnel` | Personnel |
| `random_world_events` | Random World Events |
| `used_plus` | UsedPlus |
| `roleplay_phone` | Invoices |

---

## Tips

**Fix a tablet you cannot see.** If the tablet is off screen or too large to reach Settings, run:

```
TabletResetSettings
```

That puts position and scale back to default along with everything else.

**Reading the log.** Turn on Debug Mode in [[Settings]] and watch `log.txt`. Tablet activity is written with the tablet prefix, which makes it easy to filter when you are chasing a problem or filing a report.
