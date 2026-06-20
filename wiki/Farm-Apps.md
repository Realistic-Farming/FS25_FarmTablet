# Farm Apps

These are the day to day tools. They are always on the home screen, no mods required. Every one of them reads your game data and shows it back cleanly, and a few of them can act on your farm where it makes sense.

Jump to an app:
[Weather](#weather) ·
[Field Manager](#field-manager) ·
[Animals](#animals) ·
[Workshop](#workshop) ·
[Digging](#digging) ·
[Bucket Tracker](#bucket-tracker) ·
[Storage](#storage) ·
[Time Controls](#time-controls) ·
[Hotspot Manager](#hotspot-manager) ·
[Notes](#notes) ·
[Farm Admin](#farm-admin) ·
[Field Jobs](#field-jobs) ·
[Contracts](#contracts) ·
[Fleet Manager](#fleet-manager) ·
[Production Buildings](#production-buildings) ·
[Farm Stats](#farm-stats)

---

## Weather

**App id:** `weather`

Full weather, including a multi day forecast, so you can plan spraying and harvest without pausing.

- **Condition hero card** at the top shows the current weather with a colour coded icon and a large label.
- **Temperature** in Celsius with a feel label: Freezing, Cold, Cool, Mild, Warm, or Hot.
- **Cloud cover** as a percentage of sky.
- **Wind** speed in km/h with a compass direction (N, NE, E, SE, S, SW, W, NW).
- **Precipitation** intensity shown as a fill bar.
- **Forecast** for Day +1 through Day +5, each with its condition and high temperature.

Condition colours: blue is rain, purple is storm, grey is fog or overcast, gold is clear and sunny.

The forecast needs the game to have forecast data ready. On some maps, or very early in a brand new save, it can be briefly missing.

---

## Field Manager

**App id:** `field_status`

Every field you own with its crop and growth state, in one scrollable list.

**Summary badges** across the top: how many fields are READY to harvest, how many are GROWING, and how many are EMPTY.

**Columns:**

| Column | Meaning |
|--------|---------|
| # | Field id number |
| CROP | Crop type, or Empty |
| HA | Field area in hectares |
| STATE | Current condition, shown as a coloured dot |

**State dot colours:**

- Green: ready to harvest.
- Blue: growing normally.
- Yellow: needs attention, like fertilising, ploughing, or rolling.
- Grey: fallow or empty.

If you own more fields than fit on screen, scroll the mouse wheel over the list.

---

## Animals

**App id:** `animals`

Every animal pen you own with care status, so you never have to walk pen to pen again.

Each pen card shows the animal type, the current count against capacity, and three bars:

- **FOOD:** how full the food trough is.
- **WATER:** how full the water trough is.
- **STRAW / CLEAN:** straw level for pigs and cows, cleanliness for the pen.

**Bar colours, all three:** green at 60% or above, yellow at 25% or above, red below 25%.

All three bars feed into productivity. Keep them green for the best milk, eggs, wool, and manure. Refill before anything hits red. Empty pens are shown dimmed.

---

## Workshop

**App id:** `workshop`

Diagnostics for vehicles near you, with a one click repair. It only shows vehicles within about 35 metres, so distant machines do not clutter the list.

- The nearby list shows each vehicle, its distance, and its wear, colour coded.
- Tap **SELECT** to pin a vehicle and open its diagnostics: full name, fuel level with a bar, wear with a bar, and operating hours.
- A **REPAIR** button appears when you have a workshop placeable on your farm and the selected vehicle has more than 2% wear. One click restores it to new.

In multiplayer the repair is sent to the host as a network event on a dedicated server, or applied locally on a listen server. See [[Multiplayer]].

---

## Digging

**App id:** `digging`

Real time terrain information for excavation and landscaping work. It refreshes on its own every 500 milliseconds while open.

- **Position:** your world coordinates. X is east to west, Y is elevation, Z is north to south.
- **Vehicle:** when you are driving, its name, speed, and attached implements.
- **Ground Level:** the terrain height in metres at your position.
- **Above Ground:** how far above or below the terrain you are. A negative value means you have dug below the original surface, which is handy for hitting an exact depth.

---

## Bucket Tracker

**App id:** `bucket_tracker`

Counts fill and dump cycles for loaders, excavators, and material handlers. It turns itself on the moment you start working a bucket or loader, no setup needed.

- **Summary cards:** LOADS is the dump cycles this session, WEIGHT is the total moved in tonnes, ITEMS is the number of entries in history.
- **Active vehicle** shows the machine being tracked, its current fill, and material, updated live.
- **Load history** lists the most recent dumps with material and estimated weight. Older entries scroll off the bottom.
- **RESET** clears the history and sets the session totals back to zero.

Weight is estimated from typical material densities, so treat it as a close approximation rather than a certified weigh bridge.

---

## Storage

**App id:** `storage`

Silo inventory and live sell prices, so you can decide where and when to sell without driving around checking boards.

- **Inventory:** every crop currently stored across the silos you own.
- **Best sell prices:** the best available price per stored crop right now.
- **Price comparison:** for a crop, every selling station and its current price, so you can see who is paying the most.

A silo here means any placeable with bulk storage that you own. Buy more storage and it shows up automatically.

---

## Time Controls

**App id:** `time_controls`

Set how fast time passes and skip ahead to a time of day, without leaving the game world.

- **Time scale:** pause, or 1x, 3x, 10x, 60x, 120x.
- **Skip to:** jump the clock to a preset time, 6 AM, 12 PM, 6 PM, or midnight. If that time has already passed today, it advances to tomorrow.

Handy for waiting out a job, skipping a night, or speeding through growth without sitting and watching.

---

## Hotspot Manager

**App id:** `hotspot_manager`

A simple manager for the map pins and hotspots that build up over a playthrough.

- Shows all active map hotspots and pins.
- **CLEAR ALL** removes them in one go. Press it once and it turns red to confirm, press again to clear. That two step is on purpose so you do not wipe your pins by accident.

---

## Notes

**App id:** `notes`

A plain checkbox style todo list for your farm. Nothing fancy, just somewhere to jot what needs doing so you do not forget it between sessions.

- Add a task and it sits in the list.
- **DONE** marks a task complete.
- Your notes are saved with the game, so the list is there next time you load.

---

## Farm Admin

**App id:** `farm_admin`

Quality of life and admin controls in one place. This app can change your game state, so in multiplayer it is host and listen server only, and the controls affect everyone.

- **Money:** add funds, +$1K, +$10K, +$100K, +$1M.
- **Time scale:** set how fast time passes, same options as Time Controls.
- **Skip to:** jump the clock to a preset time of day.
- **Vehicles:** REPAIR ALL resets wear on every vehicle you own, FILL FUEL tops up fuel and AdBlue to max.

If you want a strict career, just do not use it. It is there for when you want it. See [[Multiplayer]] for who can use it on a server.

---

## Field Jobs

**App id:** `field_jobs`

A work log for your field sessions. Start a job when you begin, finish it when you are done, and the tablet keeps a record.

- Tap **START JOB**, pick the field, your vehicle, and the task (ploughing, sowing, fertilising, spraying, harvesting, mowing, baling, rolling, stone picking, or general work). An active job badge then shows on the Home screen.
- Tap **FINISH** on the Home screen when you are done. The duration is worked out in game time.
- **History** keeps up to 30 completed jobs per save, each with the field, vehicle, task, day started, and duration.

Good for roleplay, for tracking how long real work takes, or just for the satisfaction of a logbook.

---

## Contracts

**App id:** `contracts`

Your active field contracts with live completion, reward, and time left, so you do not have to keep opening the pause menu.

- Shows every contract your farm has accepted, with completion updating automatically.
- **Time remaining** is in game time, not real time. A contract turning amber is expiring soon, under two game hours.
- A contract marked **DONE** is finished but unpaid. Visit the NPC on the map to dismiss it and collect the reward.

Nothing showing? Accept contracts from NPCs on the map or the contracts board in the pause menu. Only accepted contracts appear here.

---

## Fleet Manager

**App id:** `fleet_manager`

Every motorised vehicle your farm owns, in one list, sorted by fuel so the emptiest machines float to the top.

- Each row shows the vehicle with a **fuel bar** as a percentage of tank capacity.
- It also surfaces wear and operating hours so you can spot which machines need attention.

Where Workshop is about the vehicles near you right now, Fleet Manager is the whole farm at once. Use it to plan refuelling and maintenance before things run dry mid job.

---

## Production Buildings

**App id:** `production_buildings`

Your production buildings and their chains, so you can see what is running and what has stalled without driving to each one.

- **Building list:** every production building your farm owns.
- **Active or stalled:** active means at least one chain is enabled and producing, stalled means it is idle, usually out of an input.
- **Inputs and outputs:** the fill types each building consumes and produces.

Nothing here? Production buildings must be owned by your farm to appear.

---

## Farm Stats

**App id:** `farm_stats`

One big snapshot of your whole operation. If the Dashboard is the quick glance, Farm Stats is the full report.

- **Finances:** balance, outstanding loan, and net worth (balance minus loan, your true position).
- **Session P&L:** income and expenses since this session started, with the net.
- **Farm totals:** field count, total area in hectares, vehicles, animal pens, and production buildings.
- **World:** the in game day, season if a Seasons mod is active, and the time.

A good screen to check at the start and end of a play session to see how far you have come.
