# Installation

Farm Tablet installs like any other FS25 mod. You drop one zip in your mods folder and enable it. There is nothing to extract and nothing to edit.

---

## Install in about ten seconds

1. **Download** `FS25_FarmTablet.zip` from the [Releases page](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/releases).
2. **Drop the zip** (do not unzip it) into your mods folder:
   - Windows: `Documents\My Games\FarmingSimulator2025\mods\`
   - Mac: `~/Library/Application Support/FarmingSimulator2025/mods/`
3. **Enable Farm Tablet** on the mod selection screen when you start or load a save.
4. **Load the save and press T.** The tablet opens.

That is the whole process. The first time you open it you get a quick lock screen, slide to unlock, and you are in.

---

## Updating

Updating is just as simple. Replace the old zip with the new one in your mods folder.

Your settings are stored in the savegame, not in the zip, so nothing is lost when you update. Your position, scale, background, startup app, and keybind all carry over.

If you want to see what changed in a release, open the tablet and tap the **Updates** app. It shows the full changelog, newest first. You can also read it on the [Releases page](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/releases).

---

## Where my settings are saved

Everything you change in the tablet is written to a small file inside your savegame folder:

```
<savegame>/FS25_FarmTablet.xml
```

Your savegame itself is never touched. If you ever want a clean slate, delete that file or run `TabletResetSettings` in the console. See [[Settings]] for the full list of what gets saved.

A custom home background, if you set one, lives in a separate folder next to your save:

```
<savegame>/FTBackground/
```

---

## Uninstalling

Remove `FS25_FarmTablet.zip` from your mods folder and disable it on the mod screen. Your savegame loads fine without it. The settings file is harmless to leave behind, but you can delete it if you like.

---

## Requirements and compatibility

- **Game:** Farming Simulator 25.
- **Multiplayer:** fully supported. The tablet is client side, so each player has their own view. See [[Multiplayer]].
- **Dedicated server:** safe. The tablet skips itself on the server with no overhead.
- **Other mods:** no known conflicts. The tablet reads game data and does not modify your farm.

If you do hit a conflict, please open an [issue](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/issues) and tell me which mod, I will take a look.
