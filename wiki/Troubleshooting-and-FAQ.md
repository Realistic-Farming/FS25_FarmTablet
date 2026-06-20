# Troubleshooting and FAQ

Common questions and quick fixes. If your problem is not here, turn on Debug Mode in [[Settings]], reproduce the issue, and open an [issue](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/issues) with what `log.txt` shows. The more detail the better.

---

## Opening and controls

**The tablet does not open when I press T.**
First, make sure the mod is enabled on the mod screen and that you reloaded the save after installing. Then try `TabletEnable` in the console in case it was disabled. If T clashes with another mod, change the key with `TabletKeybind` or in [[Settings]].

**How do I change the open key?**
Settings, then the open key option, or run `TabletKeybind F5` (or any key) in the console. It takes effect at once.

**Can I skip the lock screen?**
Yes. Turn off the lock screen in [[Settings]] and the tablet opens straight to the home screen.

**How do I get back to the home screen from inside an app?**
Tap the **HOME** button in the top bar of the app. To close the tablet entirely, press your open key again or Esc.

**How do I move between home screen pages?**
Roll the mouse wheel over the grid, or click one of the page dots above the dock.

---

## The tablet looks wrong

**The tablet is off screen or far too big.**
Open Settings and use **Reset Position and Scale**, or run `TabletResetSettings` in the console. The tablet still draws when it is partly off screen, so you can always reach Settings to fix it.

**How do I move or resize it?**
Settings, then **Enter Edit Mode**. Drag the body to move, drag a corner to resize, drag a side edge to change width. Right-click or press Esc to save and exit. Full detail on [[Customising the Tablet]].

**Can I use my own background image?**
Yes. Drop a PNG into the `FTBackground` folder in your savegame folder, then pick it in Settings under Home Background. See [[Customising the Tablet]].

---

## Apps

**A companion mod app is not showing.**
The companion mod has to be enabled for this save. Add it, then reload the save so the tablet runs its detection pass again. If it still does not appear, turn on Debug Mode and check `log.txt`, the detection result for each mod is logged. More in [[Mod Integration Apps]].

**Workshop shows no vehicles.**
Workshop only lists vehicles within about 35 metres of you. Walk up to a vehicle and it appears. This is on purpose so distant machines do not clutter the list. For every vehicle on the farm regardless of distance, use Fleet Manager instead.

**The forecast in Weather is empty.**
The forecast needs the game to have forecast data ready. On some maps, or very early in a brand new save, it can be briefly missing. It fills in shortly.

**Why are some apps in the App Store dimmed?**
Those are companion apps you do not have the mod for. The dimmed row shows you what you would unlock by adding that mod. Load it and the app turns on by itself.

---

## Multiplayer

**Does it work in multiplayer?**
Yes. Every player runs their own tablet with their own settings. See [[Multiplayer]].

**A button in a companion app does nothing for me.**
Many of my mods only let an admin change settings. If a toggle does nothing on a server, you are likely not an admin in that session. Farm Admin and the Field Sentry toggles are host or admin only by design.

**Does it run on a dedicated server?**
The tablet is client side, so it skips the server itself and runs on each player's machine. No server setup needed.

---

## Saves and safety

**Will this hurt my save?**
No. The tablet reads your game data and does not modify your farm. Its settings are kept in a separate file in your savegame folder, so removing the mod leaves your save intact.

**Where are my settings saved?**
In `<savegame>/FS25_FarmTablet.xml`. A custom background, if set, is in `<savegame>/FTBackground/`. Delete the XML or run `TabletResetSettings` to start fresh.

**I updated the mod, did I lose my settings?**
No. Settings live in the savegame, not the zip. Replace the old zip with the new one and everything carries over.

---

## General

**Does it support my language?**
Farm Tablet ships in 26 languages and follows your game language automatically.

**Is it heavy on performance?**
No. The tablet only does work while it is open, and data reads are cached so they do not run every frame.

**How do I see what changed in an update?**
Open the **Updates** app for the full changelog, newest first. It is also on the [Releases page](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/releases).

**How do I report a bug or suggest an app?**
Open an [issue](https://github.com/TheCodingDad-TisonK/FS25_FarmTablet/issues). Bug reports and ideas are welcome, this is a community shaped project and feedback drives what gets built next.
