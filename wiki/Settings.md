# Settings

Everything you can configure lives in the **Settings** app inside the tablet. There is no config file to edit by hand. Open the tablet, tap Settings, and change what you like. Each change saves instantly.

This page lists every setting, what it does, and its default.

---

## Where settings are stored

All of your settings are written to a small file in your savegame folder:

```
<savegame>/FS25_FarmTablet.xml
```

Your savegame itself is never touched. Delete that file, or run `TabletResetSettings`, to start fresh. A custom home background, if you set one, lives in `<savegame>/FTBackground/` next to it.

---

## Display and layout

| Setting | Default | What it does |
|---------|---------|--------------|
| Tablet position | Centre | Where the tablet sits on screen. Set it by dragging in Edit Mode. |
| Tablet scale | 100% | Overall size, from 50% to 200%. Set in Edit Mode. |
| Width multiplier | 100% | Stretch the width on its own, 50% to 200%. Set in Edit Mode. |
| Background colour | Deep Space | The screen colour theme. Other options: Ocean Blue, Forest Green, Midnight Purple, Slate Grey. |
| Home background | Default | Your own PNG behind the home and lock screens, from the FTBackground folder. |

See [[Customising the Tablet]] for how to use Edit Mode and set a custom background.

---

## Opening and behaviour

| Setting | Default | What it does |
|---------|---------|--------------|
| Open key | T | The key that opens and closes the tablet. Any letter, function key, and most others are valid. |
| Startup app | Dashboard | The app shown first every time you open the tablet. |
| Lock screen | On | Show the slide to unlock screen at the start of a session. Turn off to open straight to the home screen. |
| Notifications | On | The welcome message in the corner when a save loads. |

To change the open key from the console, use `TabletKeybind`. To change the startup app, use `TabletSetStartupApp`. See [[Console Commands]].

---

## Sound

The tablet has a master sound toggle plus three separate sound toggles, so you can keep the sounds you like and silence the ones you do not.

| Setting | Default | What it does |
|---------|---------|--------------|
| Sound effects | On | Master toggle for all tablet sounds. Off here silences everything. |
| App select sound | On | The click when you open an app. |
| Help panel sound | On | The page sound when the in app help opens or closes. |
| Open and close sound | On | The sound when the tablet itself opens or closes. |
| Vibration feedback | On | A subtle press feedback when you tap things. |

---

## Advanced

| Setting | Default | What it does |
|---------|---------|--------------|
| Debug mode | Off | Writes verbose diagnostic lines to `log.txt`, tagged with the tablet prefix. Turn this on if you are reporting a bug. |
| Reset all to defaults | n/a | Sets every setting back to factory defaults, including position, scale, and keybind. This cannot be undone. |

---

## Resetting

Two ways to reset:

- **Just position and size:** Settings, then **Reset Position and Scale**. Everything else is kept.
- **Everything:** Settings, then **Reset All To Defaults**, or run `TabletResetSettings` in the console. This puts the open key, startup app, sounds, position, scale, and background all back to their defaults.

Use the full reset if the tablet ever ends up off screen, oversized, or behaving oddly. It is the quickest way back to a known good state.
