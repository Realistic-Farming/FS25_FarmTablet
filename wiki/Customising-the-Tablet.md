# Customising the Tablet

The tablet is meant to sit exactly where you want it, at the size you want, looking the way you like. You can move it, resize it, recolour the screen, and even put your own image behind the home screen. Everything here is saved with your game, so you set it once and forget it.

---

## Edit Mode: move and resize

Edit Mode is how you reposition and resize the tablet on your screen.

**To start:** open the tablet, go to **Settings**, and tap **ENTER EDIT MODE**. The tablet switches into a draggable state.

**While in Edit Mode:**

| Do this | To |
|---------|----|
| Drag the body | Move the whole tablet anywhere on screen |
| Drag a corner | Scale the whole tablet, from 50% up to 200% |
| Drag a side edge | Stretch the width on its own, also 50% to 200% |

**To finish:** right-click, or press **Esc**. Your position and size are saved straight away.

If the tablet ever ends up off screen or too big to use, you do not need Edit Mode to fix it. Go to **Settings** and use **Reset Position and Scale**, or run `TabletResetSettings` in the console. The tablet still draws even when it is partly off screen, so you can always reach Settings.

---

## Background colour

You can change the colour of the tablet screen itself. In **Settings**, find **Background Color** and cycle through the built in themes:

- Deep Space (the default)
- Ocean Blue
- Forest Green
- Midnight Purple
- Slate Grey

This is the flat colour behind your apps. It is separate from the home screen image below, so you can mix and match.

---

## Your own home screen image

If you want the home and lock screens to show your own picture, you can.

1. Find your savegame folder, the same place the settings file lives.
2. Open the **FTBackground** folder inside it (create it if it is not there yet).
3. Drop a **PNG** image into that folder.
4. Open the tablet, go to **Settings**, find **Home Background**, and pick your image from the list.

Choose **DEFAULT** in that same setting to go back to the built in wallpaper at any time. This image sits behind the springboard and the lock screen, so it is the first thing you see when the tablet opens.

---

## Arrange the Dashboard

The Dashboard is not fixed either. Open it and tap the small **EDIT** button in the top right. From there you choose which widgets show and in what order: balance, loan, income, expenses, net profit and loss, fields, vehicles, contracts, season, day, time, and weather.

Turn off anything you never look at and the screen stays clean and quick to read. Your layout is saved with the game.

---

## Pick what opens first

By default the tablet opens to the Dashboard. If you always check the same screen, set it as your startup app in **Settings** under **Startup App**, or run `TabletSetStartupApp` in the console. Every open then lands you straight where you want to be.

---

## None of this touches your save

All of these choices live in the tablet's own settings file inside your savegame folder, not in your actual save data. Resetting them, or removing the mod, never affects your farm. See [[Settings]] for exactly what is stored and where.
