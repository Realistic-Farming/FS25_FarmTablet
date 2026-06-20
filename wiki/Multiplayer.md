# Multiplayer

Farm Tablet works in multiplayer. The short version: every player runs their own tablet, it shows your farm's data, and the few actions that change the game are checked by the host. There is nothing extra to install or configure for a server.

---

## How it works

The tablet is a client side tool. Each player who has the mod opens their own tablet with their own key, at their own position and scale. Your settings are yours, they do not affect anyone else's tablet.

What the tablet shows is read from the running game, so it reflects your farm and the shared world. Opening the tablet, switching apps, and reading data never touches the save or other players.

---

## Dedicated servers

On a dedicated server the tablet is safely skipped. It is a client side interface, so it does not load or run on the server itself and adds no overhead there. Players connecting to the server still get their tablet on their own machine as normal.

---

## Actions that change the game

Most apps only read data. A few can act, and those are handled carefully so a client cannot change things they should not.

**Farm Admin** is host and listen server only. The money, time, repair, and fuel controls affect everyone in the session, so they are not available to a normal client on a dedicated server. If you are hosting, they work for you.

**Field Sentry** toggles (sleep and meadow) are admin only and validated by the host. Clients can see each field's state, but only an admin can change it. The host has the final say.

**Workshop repair** is sent to the host as a network event on a dedicated server, so the repair happens server side and syncs back. On a listen server, where the host is also playing, it is applied locally.

**Personnel** keeps its roster on the host. When you hire, fire, or assign a worker, your action is sent to the host and applied there, then reflected back to everyone.

---

## Companion mod apps in multiplayer

Companion apps appear the same way they do in single player. When the save loads, the tablet checks for each companion mod and adds its app if the mod is present. As long as the mod is loaded for the session, every player with Farm Tablet sees the app.

Where a companion app changes that mod's settings (for example the Enable and Disable buttons), the companion mod's own multiplayer rules apply. Many of my mods restrict settings changes to an admin, so if a button does nothing for you, you are probably not an admin in that session.

---

## If something looks out of sync

The tablet reads live game data, so it should match what the game shows. If a value looks stale, close and reopen the tablet to force a fresh read. If an app that should be there is missing, see the detection notes in [[Mod Integration Apps]] and the [[Troubleshooting and FAQ]] page.
