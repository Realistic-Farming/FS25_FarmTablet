# GLOBAL VARIABLE LEAK AUDIT - FS25_UsedPlus

**Generated:** 2026-08-18T18:10:27.456Z
**Total Lua files scanned:** 66
**Potential leaks found:** 230

## Severity Breakdown

- **HIGH:** 0 (immediate fix recommended)
- **MEDIUM:** 0 (review needed)
- **LOW:** 230 (low priority)

---

## LOW SEVERITY LEAKS

### `src/FarmTabletUI.lua`

**Line 1265:** `mono = (app and app.navLabel) or "?" })`

```lua
    local tiY = barY + (appbarH - titleIconSz)/2
    table.insert(self._iconQueue, { appId = self.system.currentApp, x = tiX, y = tiY, size = titleIconSz,
                                    mono = (app and app.navLabel) or "?" })
    -- App name as a dim right-aligned breadcrumb (apps draw their own bright header)
    r:text(sx + sw - FT.px(12), barY + appbarH/2 - FT.py(5),
```

**Issue:** Variable `mono` is assigned without `local` keyword.
**Fix:** Add `local mono` before first use, or add `local` to this line.

---

**Line 1354:** `appId = AppRegistry.resolve(appId)`

```lua
function FarmTabletUI:switchApp(appId)
    if AppRegistry and AppRegistry.resolve then
        appId = AppRegistry.resolve(appId)
    elseif appId == FT.APP.TIME_CONTROLS then
        appId = FT.APP.FARM_ADMIN
```

**Issue:** Variable `appId` is assigned without `local` keyword.
**Fix:** Add `local appId` before first use, or add `local` to this line.

---

**Line 1356:** `appId = FT.APP.FARM_ADMIN`

```lua
        appId = AppRegistry.resolve(appId)
    elseif appId == FT.APP.TIME_CONTROLS then
        appId = FT.APP.FARM_ADMIN
    elseif appId == FT.APP.DIGGING or appId == FT.APP.BUCKET then
        appId = FT.APP.EXCAVATOR
```

**Issue:** Variable `appId` is assigned without `local` keyword.
**Fix:** Add `local appId` before first use, or add `local` to this line.

---

**Line 1358:** `appId = FT.APP.EXCAVATOR`

```lua
        appId = FT.APP.FARM_ADMIN
    elseif appId == FT.APP.DIGGING or appId == FT.APP.BUCKET then
        appId = FT.APP.EXCAVATOR
    end
    if not self.system.registry:has(appId) then return false end
```

**Issue:** Variable `appId` is assigned without `local` keyword.
**Fix:** Add `local appId` before first use, or add `local` to this line.

---

**Line 1606:** `provider = provider or {name="Realistic Farming Mobile", id="`

```lua

function FarmTabletUI:_selectSignalProvider(provider)
    provider = provider or {name="Realistic Farming Mobile", id="default"}
    self._signalProvider = provider.name or "Realistic Farming Mobile"
    self._signalProviderId = provider.id or "default"
```

**Issue:** Variable `provider` is assigned without `local` keyword.
**Fix:** Add `local provider` before first use, or add `local` to this line.

---

**Line 1622:** `providerId = tostring(providerId or self._signalProviderId or "`

```lua

function FarmTabletUI:_getSignalProviderDailyFee(providerId)
    providerId = tostring(providerId or self._signalProviderId or "realistic_farming")
    for _, provider in ipairs(self._signalProviders or {}) do
        if tostring(provider.id or "") == providerId then
```

**Issue:** Variable `providerId` is assigned without `local` keyword.
**Fix:** Add `local providerId` before first use, or add `local` to this line.

---

**Line 1708:** `providerId = tostring(providerId or "")`

```lua

function FarmTabletUI:_normalizeSignalProviderId(providerId, providerName)
    providerId = tostring(providerId or "")
    providerName = tostring(providerName or "")

```

**Issue:** Variable `providerId` is assigned without `local` keyword.
**Fix:** Add `local providerId` before first use, or add `local` to this line.

---

**Line 1709:** `providerName = tostring(providerName or "")`

```lua
function FarmTabletUI:_normalizeSignalProviderId(providerId, providerName)
    providerId = tostring(providerId or "")
    providerName = tostring(providerName or "")

    -- Migration alter Anbieter aus Test-/Altversionen auf die neue saubere Marke.
```

**Issue:** Variable `providerName` is assigned without `local` keyword.
**Fix:** Add `local providerName` before first use, or add `local` to this line.

---

**Line 1723:** `providerId = tostring(providerId or "")`

```lua

function FarmTabletUI:_findSignalProviderById(providerId)
    providerId = tostring(providerId or "")
    for _, provider in ipairs(self._signalProviders or {}) do
        if tostring(provider.id or "") == providerId then
```

**Issue:** Variable `providerId` is assigned without `local` keyword.
**Fix:** Add `local providerId` before first use, or add `local` to this line.

---

**Line 1733:** `freq = string.lower(tostring(freq or "off"))`

```lua

function FarmTabletUI:_normalizeSignalOutageFrequency(freq)
    freq = string.lower(tostring(freq or "off"))
    if freq == "rare" or freq == "selten" then return "rare" end
    if freq == "normal" then return "normal" end
```

**Issue:** Variable `freq` is assigned without `local` keyword.
**Fix:** Add `local freq` before first use, or add `local` to this line.

---

**Line 1741:** `freq = self:_normalizeSignalOutageFrequency(freq or self.`

```lua

function FarmTabletUI:_getSignalOutageFrequencyLabel(freq)
    freq = self:_normalizeSignalOutageFrequency(freq or self._signalOutageFrequency)
    if freq == "rare" then return ftUiText("ft_common_rare", "Rare") end
    if freq == "normal" then return ftUiText("ft_common_normal", "Normal") end
```

**Issue:** Variable `freq` is assigned without `local` keyword.
**Fix:** Add `local freq` before first use, or add `local` to this line.

---

**Line 1764:** `startMin = tonumber(startMin) or 0`

```lua

function FarmTabletUI:_minutesSince(startMin, currentMin)
    startMin = tonumber(startMin) or 0
    currentMin = tonumber(currentMin) or 0
    if currentMin < startMin then
```

**Issue:** Variable `startMin` is assigned without `local` keyword.
**Fix:** Add `local startMin` before first use, or add `local` to this line.

---

**Line 1765:** `currentMin = tonumber(currentMin) or 0`

```lua
function FarmTabletUI:_minutesSince(startMin, currentMin)
    startMin = tonumber(startMin) or 0
    currentMin = tonumber(currentMin) or 0
    if currentMin < startMin then
        currentMin = currentMin + 1440
```

**Issue:** Variable `currentMin` is assigned without `local` keyword.
**Fix:** Add `local currentMin` before first use, or add `local` to this line.

---

**Line 1767:** `currentMin = currentMin + 1440`

```lua
    currentMin = tonumber(currentMin) or 0
    if currentMin < startMin then
        currentMin = currentMin + 1440
    end
    return currentMin - startMin
```

**Issue:** Variable `currentMin` is assigned without `local` keyword.
**Fix:** Add `local currentMin` before first use, or add `local` to this line.

---

**Line 1773:** `cfg = cfg or self:_getSignalOutageConfig()`

```lua

function FarmTabletUI:_scheduleNextSignalOutageCheck(currentMinute, cfg)
    cfg = cfg or self:_getSignalOutageConfig()
    if cfg.enabled ~= true then
        self._signalNextCheckMin = nil
```

**Issue:** Variable `cfg` is assigned without `local` keyword.
**Fix:** Add `local cfg` before first use, or add `local` to this line.

---

**Line 1971:** `freq = string.lower(tostring(freq or "off"))`

```lua

function FarmTabletUI:_normalizeTabletRepairFrequency(freq)
    freq = string.lower(tostring(freq or "off"))
    if freq == "rare" or freq == "selten" then return "rare" end
    if freq == "normal" then return "normal" end
```

**Issue:** Variable `freq` is assigned without `local` keyword.
**Fix:** Add `local freq` before first use, or add `local` to this line.

---

**Line 1979:** `freq = self:_normalizeTabletRepairFrequency(freq or self.`

```lua

function FarmTabletUI:_getTabletRepairFrequencyLabel(freq)
    freq = self:_normalizeTabletRepairFrequency(freq or self._tabletRepairFrequency)
    if freq == "rare" then return ftUiText("ft_common_rare", "Rare") end
    if freq == "normal" then return ftUiText("ft_common_normal", "Normal") end
```

**Issue:** Variable `freq` is assigned without `local` keyword.
**Fix:** Add `local freq` before first use, or add `local` to this line.

---

**Line 2034:** `msg = tostring(msg or "")`

```lua

function FarmTabletUI:_notifyTabletRepair(msg)
    msg = tostring(msg or "")
    local title = ftUiText("ft_repair_service_title", "Tablet-Service")
    self._signalToast = { title = title, msg = msg, time = 6200 }
```

**Issue:** Variable `msg` is assigned without `local` keyword.
**Fix:** Add `local msg` before first use, or add `local` to this line.

---

**Line 2326:** `title = tostring(title or "Realistic Farming Mobile")`

```lua

function FarmTabletUI:_notifySignal(title, msg)
    title = tostring(title or "Realistic Farming Mobile")
    msg = tostring(msg or "")
    local key = title .. msg
```

**Issue:** Variable `title` is assigned without `local` keyword.
**Fix:** Add `local title` before first use, or add `local` to this line.

---

**Line 2327:** `msg = tostring(msg or "")`

```lua
function FarmTabletUI:_notifySignal(title, msg)
    title = tostring(title or "Realistic Farming Mobile")
    msg = tostring(msg or "")
    local key = title .. msg
    if self._signalLastNotify == key then return end
```

**Issue:** Variable `msg` is assigned without `local` keyword.
**Fix:** Add `local msg` before first use, or add `local` to this line.

---

**Line 2985:** `meta = { onClick = function()`

```lua
    local btn = {
        x = iX, y = iY, w = iSz, h = iSz,
        meta = { onClick = function()
            self[sk] = true
            self:switchApp(appId)
```

**Issue:** Variable `meta` is assigned without `local` keyword.
**Fix:** Add `local meta` before first use, or add `local` to this line.

---

### `src/FarmTabletUIEditMode.lua`

**Line 284:** `newTabletX = math.max(0, math.min(1 - w, newTabletX))`

```lua
    local w = FT.LAYOUT.tabletW or 0
    local h = FT.LAYOUT.tabletH or 0
    newTabletX = math.max(0, math.min(1 - w, newTabletX))
    newTabletY = math.max(0, math.min(1 - h, newTabletY))

```

**Issue:** Variable `newTabletX` is assigned without `local` keyword.
**Fix:** Add `local newTabletX` before first use, or add `local` to this line.

---

**Line 285:** `newTabletY = math.max(0, math.min(1 - h, newTabletY))`

```lua
    local h = FT.LAYOUT.tabletH or 0
    newTabletX = math.max(0, math.min(1 - w, newTabletX))
    newTabletY = math.max(0, math.min(1 - h, newTabletY))

    -- Store centre for settings
```

**Issue:** Variable `newTabletY` is assigned without `local` keyword.
**Fix:** Add `local newTabletY` before first use, or add `local` to this line.

---

### `src/InvoiceManager.lua`

**Line 124:** `receivable = receivable + inv.amount`

```lua
                owed = owed + inv.amount
            else
                receivable = receivable + inv.amount
            end
        end
```

**Issue:** Variable `receivable` is assigned without `local` keyword.
**Fix:** Add `local receivable` before first use, or add `local` to this line.

---

### `src/apps/AkitaTabletIntegrationsApp.lua`

**Line 93:** `onClick = function()`

```lua
    local btn = self.r:button(x, y - FT.py(8), FT.px(170), FT.py(22),
        ftAkitaText("ft_aac_care_now", "Care Now"), AC, {
            onClick = function()
                local c = g_currentMission and g_currentMission.animalAutoCareCore or nil
                if c and type(c.performDailyPflegeForFarm) == "function" then
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 314:** `onClick = function()`

```lua
    local btn = self.r:button(x, y - FT.py(8), FT.px(160), FT.py(22),
        ftAkitaText("ft_rd_check_repo", "Check Repo"), AC, {
            onClick = function()
                local dealer = ftRDGetDealer()
                local f = dealer ~= nil and dealer.financeManager or nil
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/AppStoreApp.lua`

**Line 34:** `body = "Lists every app registered with the Farm Tablet,\`

```lua
    if self:drawHelpPage("_appStoreHelp", FT.APP.APP_STORE, "App Store", AC, {
        { title = "WHAT IS THE APP STORE",
          body  = "Lists every app registered with the Farm Tablet,\n" ..
                  "grouped into Built-in, Farming, and\n" ..
                  "Mod Integration categories." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 38:** `body = "Click OPEN on any app row to switch to it directl`

```lua
                  "Mod Integration categories." },
        { title = "OPEN BUTTON",
          body  = "Click OPEN on any app row to switch to it directly.\n" ..
                  "This is a shortcut — you can also click the icon in\n" ..
                  "the left sidebar at any time." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 42:** `body = "All known companion mod integrations are listed h`

```lua
                  "the left sidebar at any time." },
        { title = "MOD INTEGRATIONS",
          body  = "All known companion mod integrations are listed here.\n" ..
                  "Active mods show in full colour with an OPEN button.\n" ..
                  "Dimmed rows are supported but not currently installed.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 48:** `body = "Built-in apps show 'Built-in' as their version.\n`

```lua
                  "matching mod is loaded in your savegame." },
        { title = "VERSION / DEVELOPER",
          body  = "Built-in apps show 'Built-in' as their version.\n" ..
                  "Third-party companion apps show their own version\n" ..
                  "number and developer name." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/ContractsApp.lua`

**Line 86:** `body = "Shows all field contracts your farm has accepted\`

```lua
    if self:drawHelpPage("_contractsHelp", FT.APP.CONTRACTS, "Contracts", AC, {
        { title = "ACTIVE CONTRACTS",
          body  = "Shows all field contracts your farm has accepted\n" ..
                  "and is currently working on.\n" ..
                  "Completion updates automatically." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 90:** `body = "Time shown is in-game time, not real-world time.\`

```lua
                  "Completion updates automatically." },
        { title = "TIME REMAINING",
          body  = "Time shown is in-game time, not real-world time.\n" ..
                  "Contracts in amber are expiring soon (< 2 game hours).\n" ..
                  "Tap T to close the tablet and get back to work!" },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 94:** `body = "Contracts marked DONE are complete but unpaid.\n"`

```lua
                  "Tap T to close the tablet and get back to work!" },
        { title = "DONE — COLLECT REWARD",
          body  = "Contracts marked DONE are complete but unpaid.\n" ..
                  "Visit the NPC on the map to dismiss and collect\n" ..
                  "your reward." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 98:** `body = "Accept contracts from NPCs on the map or via the\`

```lua
                  "your reward." },
        { title = "NO CONTRACTS SHOWING",
          body  = "Accept contracts from NPCs on the map or via the\n" ..
                  "Contracts board in the pause menu. Only accepted\n" ..
                  "contracts appear here — available ones do not." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/DashboardApp.lua`

**Line 13:** `_dashView = "home"`

```lua
FarmTabletUI:registerBackHandler(FT.APP.DASHBOARD, function()
    if _dashView ~= "home" then
        _dashView = "home"
        return true
    end
```

**Issue:** Variable `_dashView` is assigned without `local` keyword.
**Fix:** Add `local _dashView` before first use, or add `local` to this line.

---

**Line 75:** `body = "Your farm's total available money.\n" ..`

```lua
    if self:drawHelpPage("_dashHelp", FT.APP.DASHBOARD, "Dashboard", AC, {
        { title = "CURRENT BALANCE",
          body  = "Your farm's total available money.\n" ..
                  "Green = positive, Red = overdrawn.\n" ..
                  "Loan amount shown alongside balance if active." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 79:** `body = "Tracked from the current session (since load).\n"`

```lua
                  "Loan amount shown alongside balance if active." },
        { title = "INCOME / EXPENSES / NET P/L",
          body  = "Tracked from the current session (since load).\n" ..
                  "Income: money earned. Expenses: money spent.\n" ..
                  "Net P/L: income minus expenses." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 83:** `body = "Fields: land you own with a crop growing.\n" ..`

```lua
                  "Net P/L: income minus expenses." },
        { title = "ACTIVE FIELDS / VEHICLES",
          body  = "Fields: land you own with a crop growing.\n" ..
                  "Vehicles: motorised vehicles owned by your farm." },
        { title = "ACTIVE CONTRACTS",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 86:** `body = "Count of accepted contracts currently in progress`

```lua
                  "Vehicles: motorised vehicles owned by your farm." },
        { title = "ACTIVE CONTRACTS",
          body  = "Count of accepted contracts currently in progress.\n" ..
                  "Open the Contracts app for details and deadlines." },
        { title = "SEASON / DAY / TIME / WEATHER",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 89:** `body = "Season requires the Seasons mod — blank in base g`

```lua
                  "Open the Contracts app for details and deadlines." },
        { title = "SEASON / DAY / TIME / WEATHER",
          body  = "Season requires the Seasons mod — blank in base game.\n" ..
                  "Day and time show the in-game clock (24h)." },
        { title = "CUSTOMISING WIDGETS",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 92:** `body = "Tap the small EDIT button (top-right of the dashb`

```lua
                  "Day and time show the in-game clock (24h)." },
        { title = "CUSTOMISING WIDGETS",
          body  = "Tap the small EDIT button (top-right of the dashboard)\n" ..
                  "to show or hide individual data rows.\n" ..
                  "Changes are saved automatically." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 146:** `onClick = function()`

```lua
        x + w - editBW, y - FT.py(1), editBW, editBH,
        "EDIT", {0.18, 0.20, 0.26, 0.65}, {
        onClick = function()
            _dashView = "customize"
            self:switchApp(FT.APP.DASHBOARD)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 147:** `_dashView = "customize"`

```lua
        "EDIT", {0.18, 0.20, 0.26, 0.65}, {
        onClick = function()
            _dashView = "customize"
            self:switchApp(FT.APP.DASHBOARD)
        end
```

**Issue:** Variable `_dashView` is assigned without `local` keyword.
**Fix:** Add `local _dashView` before first use, or add `local` to this line.

---

**Line 280:** `onClick = function()`

```lua
    local doneBtn = self.r:button(x + cw - doneBW, y, doneBW, doneBH,
        "DONE", FT.C.BTN_PRIMARY, {
        onClick = function()
            _dashView = "home"
            self:switchApp(FT.APP.DASHBOARD)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 281:** `_dashView = "home"`

```lua
        "DONE", FT.C.BTN_PRIMARY, {
        onClick = function()
            _dashView = "home"
            self:switchApp(FT.APP.DASHBOARD)
        end
```

**Issue:** Variable `_dashView` is assigned without `local` keyword.
**Fix:** Add `local _dashView` before first use, or add `local` to this line.

---

**Line 326:** `onClick = function()`

```lua
        local togBtn = self.r:button(x + cw - togW, y - FT.py(1), togW, togH,
            togLabel, togColor, {
            onClick = function()
                toggleWidget(settings, defId)
                self:switchApp(FT.APP.DASHBOARD)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/ExcavatorApp.lua`

**Line 56:** `body = "Shows your current world position, vehicle name a`

```lua
    if self:drawHelpPage("_excavatorHelp", FT.APP.EXCAVATOR, "Excavator", AC, {
        { title = "TERRAIN READOUT",
          body  = "Shows your current world position, vehicle name and\n" ..
                  "speed, ground height, and how far above or below the\n" ..
                  "terrain surface you are. Values refresh while this\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 61:** `body = "Load counting runs in the background whenever you`

```lua
                  "page is open." },
        { title = "BUCKET COUNTING",
          body  = "Load counting runs in the background whenever you\n" ..
                  "drive a wheel loader, excavator, or material handler.\n" ..
                  "It keeps going if you leave this page or close the\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 66:** `body = "LOADS = dump cycles recorded this session.\n" ..`

```lua
                  "tablet. No setup required." },
        { title = "SUMMARY CARDS",
          body  = "LOADS = dump cycles recorded this session.\n" ..
                  "WEIGHT = total material moved in tonnes.\n" ..
                  "ITEMS = number of history entries kept." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 70:** `body = "Lists recent dump cycles with material name and\n`

```lua
                  "ITEMS = number of history entries kept." },
        { title = "LOAD HISTORY",
          body  = "Lists recent dump cycles with material name and\n" ..
                  "estimated weight. Older rows scroll off the list." },
        { title = "RESET",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 73:** `body = "Clears load history and session totals. Use at th`

```lua
                  "estimated weight. Older rows scroll off the list." },
        { title = "RESET",
          body  = "Clears load history and session totals. Use at the\n" ..
                  "start of a new job to track productivity separately." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 209:** `onClick = function()`

```lua
    if y > minY + FT.py(4) then
        self:drawButton(minY + FT.py(2), "RESET", FT.C.BTN_DANGER, {
            onClick = function()
                self.system:resetBucket()
                self:switchApp(FT.APP.EXCAVATOR)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/FarmAdminApp.lua`

**Line 156:** `body = "Adds funds to your farm account.\n" ..`

```lua
    if self:drawHelpPage("_adminHelp", FT.APP.FARM_ADMIN, "Farm Admin", AC, {
        { title = "MONEY",
          body  = "Adds funds to your farm account.\n" ..
                  "Amounts: +$1K · +$10K · +$100K · +$1M" },
        { title = "TIME SCALE",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 159:** `body = "Sets how fast game time passes.\n" ..`

```lua
                  "Amounts: +$1K · +$10K · +$100K · +$1M" },
        { title = "TIME SCALE",
          body  = "Sets how fast game time passes.\n" ..
                  "PAUSE freezes time. Active speed highlighted.\n" ..
                  "Absorbed the old Time Controls hub tile." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 163:** `body = "Jumps the clock to a preset time of day.\n" ..`

```lua
                  "Absorbed the old Time Controls hub tile." },
        { title = "SKIP TO",
          body  = "Jumps the clock to a preset time of day.\n" ..
                  "Advances to tomorrow if time has passed today." },
        { title = "VEHICLES",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 166:** `body = "REPAIR ALL - resets damage on all your vehicles.\`

```lua
                  "Advances to tomorrow if time has passed today." },
        { title = "VEHICLES",
          body  = "REPAIR ALL - resets damage on all your vehicles.\n" ..
                  "FILL FUEL  - fills fuel (and AdBlue) to max\n" ..
                  "             on all your motorized vehicles." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 170:** `body = "Host / listen-server only today. Admin access fro`

```lua
                  "             on all your motorized vehicles." },
        { title = "MULTIPLAYER",
          body  = "Host / listen-server only today. Admin access from\n" ..
                  "pure clients is a separate tracked issue." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/FarmStatsApp.lua`

**Line 12:** `body = "Balance: your current available money.\n" ..`

```lua
    if self:drawHelpPage("_statsHelp", FT.APP.FARM_STATS, "Farm Stats", AC, {
        { title = "FINANCES",
          body  = "Balance: your current available money.\n" ..
                  "Loan: outstanding loan amount (0 if debt-free).\n" ..
                  "Net Worth: balance minus loan — your true financial position." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 16:** `body = "Income and expenses tracked since this session st`

```lua
                  "Net Worth: balance minus loan — your true financial position." },
        { title = "SESSION P&L",
          body  = "Income and expenses tracked since this session started\n" ..
                  "(since the last time the savegame was loaded).\n" ..
                  "Net P/L = income minus expenses for the session." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 20:** `body = "Fields: count of fields your farm owns (with crop`

```lua
                  "Net P/L = income minus expenses for the session." },
        { title = "FARM TOTALS",
          body  = "Fields: count of fields your farm owns (with crop or empty).\n" ..
                  "Area: total farmland owned in hectares.\n" ..
                  "Vehicles: motorized vehicles owned by your farm.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 26:** `body = "Current in-game day, season (if Seasons mod is ac`

```lua
                  "Production: production buildings you own." },
        { title = "WORLD",
          body  = "Current in-game day, season (if Seasons mod is active),\n" ..
                  "and time of day." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/FieldJobsApp.lua`

**Line 22:** `_view = "home"`

```lua
FarmTabletUI:registerBackHandler("field_jobs", function()
    if _view ~= "home" then
        _view = "home"
        return true
    end
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 262:** `AC = FT.appColor("field_jobs")`

```lua

FarmTabletUI:registerDrawer("field_jobs", function(self)
    AC = FT.appColor("field_jobs")

    -- ── Help page ───────────────────────────────────────
```

**Issue:** Variable `AC` is assigned without `local` keyword.
**Fix:** Add `local AC` before first use, or add `local` to this line.

---

**Line 267:** `body = "Tap START JOB, pick a field, your vehicle, and th`

```lua
    if self:drawHelpPage("_fieldJobsHelp", "field_jobs", "Field Jobs", AC, {
        { title = "STARTING A JOB",
          body  = "Tap START JOB, pick a field, your vehicle, and the\n"..
                  "type of work. Hit Confirm to begin timing.\n"..
                  "The active job badge shows on the Home screen." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 271:** `body = "Tap FINISH on the Home screen when you are done.\`

```lua
                  "The active job badge shows on the Home screen." },
        { title = "FINISHING A JOB",
          body  = "Tap FINISH on the Home screen when you are done.\n"..
                  "Duration is calculated in in-game time and the\n"..
                  "record is saved to the History list." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 275:** `body = "Up to 30 completed jobs are stored per savegame.\`

```lua
                  "record is saved to the History list." },
        { title = FJText("ft_common_history", "History"),
          body  = "Up to 30 completed jobs are stored per savegame.\n"..
                  "Each entry shows field, vehicle, task, day started,\n"..
                  "and how long the job took." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 279:** `body = "Only motorized vehicles owned by your farm appear`

```lua
                  "and how long the job took." },
        { title = "VEHICLE LIST",
          body  = "Only motorized vehicles owned by your farm appear.\n"..
                  "If a vehicle is missing, check it is assigned to\n"..
                  "your farm in the vehicle settings." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 354:** `_view = "home"`

```lua
            { onClick = function()
                _finishJob()
                _view = "home"
                self:switchApp("field_jobs")
            end })
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 389:** `_cachedFields = data:getOwnedFields(farmId)`

```lua
                local data   = self.system.data
                local farmId = data:getPlayerFarmId()
                _cachedFields   = data:getOwnedFields(farmId)
                _cachedVehicles = _getFarmVehicles(farmId)
                if #_cachedVehicles == 0 then
```

**Issue:** Variable `_cachedFields` is assigned without `local` keyword.
**Fix:** Add `local _cachedFields` before first use, or add `local` to this line.

---

**Line 390:** `_cachedVehicles = _getFarmVehicles(farmId)`

```lua
                local farmId = data:getPlayerFarmId()
                _cachedFields   = data:getOwnedFields(farmId)
                _cachedVehicles = _getFarmVehicles(farmId)
                if #_cachedVehicles == 0 then
                    table.insert(_cachedVehicles, "No vehicle")
```

**Issue:** Variable `_cachedVehicles` is assigned without `local` keyword.
**Fix:** Add `local _cachedVehicles` before first use, or add `local` to this line.

---

**Line 419:** `_histScroll = 0`

```lua
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _histScroll = 0
                _view = "history"
                self:switchApp("field_jobs")
```

**Issue:** Variable `_histScroll` is assigned without `local` keyword.
**Fix:** Add `local _histScroll` before first use, or add `local` to this line.

---

**Line 420:** `_view = "history"`

```lua
            { onClick = function()
                _histScroll = 0
                _view = "history"
                self:switchApp("field_jobs")
            end })
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 485:** `_view = "home"`

```lua
        FT.C.BTN_NEUTRAL,
        { onClick = function()
            _view = "home"
            self:switchApp("field_jobs")
        end })
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 521:** `_selFieldIdx = _selFieldIdx - 1`

```lua
        local lBtn = self.r:button(x, y, arrowW, arrowH, "<", FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selFieldIdx = _selFieldIdx - 1
                if _selFieldIdx < 1 then _selFieldIdx = #fields end
                self:switchApp("field_jobs")
```

**Issue:** Variable `_selFieldIdx` is assigned without `local` keyword.
**Fix:** Add `local _selFieldIdx` before first use, or add `local` to this line.

---

**Line 536:** `_selFieldIdx = _selFieldIdx + 1`

```lua
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selFieldIdx = _selFieldIdx + 1
                if _selFieldIdx > #fields then _selFieldIdx = 1 end
                self:switchApp("field_jobs")
```

**Issue:** Variable `_selFieldIdx` is assigned without `local` keyword.
**Fix:** Add `local _selFieldIdx` before first use, or add `local` to this line.

---

**Line 568:** `_selVehicleIdx = _selVehicleIdx - 1`

```lua
        local lBtn = self.r:button(x, y, arrowW, arrowH, "<", FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selVehicleIdx = _selVehicleIdx - 1
                if _selVehicleIdx < 1 then _selVehicleIdx = #vehicles end
                self:switchApp("field_jobs")
```

**Issue:** Variable `_selVehicleIdx` is assigned without `local` keyword.
**Fix:** Add `local _selVehicleIdx` before first use, or add `local` to this line.

---

**Line 581:** `_selVehicleIdx = _selVehicleIdx + 1`

```lua
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selVehicleIdx = _selVehicleIdx + 1
                if _selVehicleIdx > #vehicles then _selVehicleIdx = 1 end
                self:switchApp("field_jobs")
```

**Issue:** Variable `_selVehicleIdx` is assigned without `local` keyword.
**Fix:** Add `local _selVehicleIdx` before first use, or add `local` to this line.

---

**Line 602:** `_selTaskIdx = _selTaskIdx - 1`

```lua
        local lBtn = self.r:button(x, y, arrowW, arrowH, "<", FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selTaskIdx = _selTaskIdx - 1
                if _selTaskIdx < 1 then _selTaskIdx = #TASK_TYPES end
                self:switchApp("field_jobs")
```

**Issue:** Variable `_selTaskIdx` is assigned without `local` keyword.
**Fix:** Add `local _selTaskIdx` before first use, or add `local` to this line.

---

**Line 616:** `_selTaskIdx = _selTaskIdx + 1`

```lua
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selTaskIdx = _selTaskIdx + 1
                if _selTaskIdx > #TASK_TYPES then _selTaskIdx = 1 end
                self:switchApp("field_jobs")
```

**Issue:** Variable `_selTaskIdx` is assigned without `local` keyword.
**Fix:** Add `local _selTaskIdx` before first use, or add `local` to this line.

---

**Line 669:** `_view = "home"`

```lua
        FT.C.BTN_NEUTRAL,
        { onClick = function()
            _view = "home"
            self:switchApp("field_jobs")
        end })
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 678:** `_jobHistory = {}`

```lua
            FT.C.BTN_DANGER,
            { onClick = function()
                _jobHistory = {}
                _saveJobs()
                self:switchApp("field_jobs")
```

**Issue:** Variable `_jobHistory` is assigned without `local` keyword.
**Fix:** Add `local _jobHistory` before first use, or add `local` to this line.

---

### `src/apps/FinancialCockpitApp.lua`

**Line 418:** `serialize = function()`

```lua
        pcall(function()
            ledger:registerModule(LEDGER_MODULE, {
                serialize = function()
                    return _serializeHistory()
                end,
```

**Issue:** Variable `serialize` is assigned without `local` keyword.
**Fix:** Add `local serialize` before first use, or add `local` to this line.

---

**Line 421:** `deserialize = function(data)`

```lua
                    return _serializeHistory()
                end,
                deserialize = function(data)
                    _deserializeHistory(data)
                end,
```

**Issue:** Variable `deserialize` is assigned without `local` keyword.
**Fix:** Add `local deserialize` before first use, or add `local` to this line.

---

**Line 436:** `onSettle = function(ctx)`

```lua
                firstPeriodPolicy = "skip",
                priority = 900,
                onSettle = function(ctx)
                    _sampleClosedMonth(ctx)
                end,
```

**Issue:** Variable `onSettle` is assigned without `local` keyword.
**Fix:** Add `local onSettle` before first use, or add `local` to this line.

---

**Line 865:** `_vitalFocus = snap.heartVitalId`

```lua

    _pocketBtn(self, x, y - h, w, h, "", {0, 0, 0, 0}, function()
        _vitalFocus = snap.heartVitalId
        _view = "vital"
        self:switchApp(FT.APP.FINANCIAL_COCKPIT)
```

**Issue:** Variable `_vitalFocus` is assigned without `local` keyword.
**Fix:** Add `local _vitalFocus` before first use, or add `local` to this line.

---

**Line 866:** `_view = "vital"`

```lua
    _pocketBtn(self, x, y - h, w, h, "", {0, 0, 0, 0}, function()
        _vitalFocus = snap.heartVitalId
        _view = "vital"
        self:switchApp(FT.APP.FINANCIAL_COCKPIT)
    end)
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 927:** `_view = "forecast"`

```lua
    _pocketBtn(self, x + cw - fcBtnW, y - FT.py(2), fcBtnW, FT.py(16),
        _T("ft_fc_open", "OPEN"), FT.C.BTN_NEUTRAL, function()
            _view = "forecast"
            self:switchApp(FT.APP.FINANCIAL_COCKPIT)
        end)
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 952:** `_view = "history"`

```lua
    _pocketBtn(self, x + cw - hBtnW, y - FT.py(2), hBtnW, FT.py(16),
        _T("ft_fc_open", "OPEN"), FT.C.BTN_NEUTRAL, function()
            _view = "history"
            self:switchApp(FT.APP.FINANCIAL_COCKPIT)
        end)
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 989:** `_view = "flows"`

```lua
    _pocketBtn(self, x + cw - fBtnW, y - FT.py(2), fBtnW, FT.py(16),
        _T("ft_fc_open", "OPEN"), FT.C.BTN_NEUTRAL, function()
            _view = "flows"
            self:switchApp(FT.APP.FINANCIAL_COCKPIT)
        end)
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 1200:** `_view = "home"`

```lua
FarmTabletUI:registerBackHandler(FT.APP.FINANCIAL_COCKPIT, function()
    if _view ~= "home" then
        _view = "home"
        _vitalFocus = nil
        return true
```

**Issue:** Variable `_view` is assigned without `local` keyword.
**Fix:** Add `local _view` before first use, or add `local` to this line.

---

**Line 1201:** `_vitalFocus = nil`

```lua
    if _view ~= "home" then
        _view = "home"
        _vitalFocus = nil
        return true
    end
```

**Issue:** Variable `_vitalFocus` is assigned without `local` keyword.
**Fix:** Add `local _vitalFocus` before first use, or add `local` to this line.

---

### `src/apps/FleetManagerApp.lua`

**Line 18:** `body = "Shows every motorized vehicle your farm owns.\n" `

```lua
    if self:drawHelpPage("_fleetHelp", FT.APP.FLEET, ftFleetText("ft_ui_app_fleet_manager", "Fleet Manager"), AC, {
        { title = "VEHICLE LIST",
          body  = "Shows every motorized vehicle your farm owns.\n" ..
                  "Sorted by fuel level — emptiest machines appear first\n" ..
                  "so you can spot what needs refuelling at a glance." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 22:** `body = "Current fuel as a percentage of tank capacity.\n"`

```lua
                  "so you can spot what needs refuelling at a glance." },
        { title = "FUEL BAR",
          body  = "Current fuel as a percentage of tank capacity.\n" ..
                  "Litres remaining and total capacity shown beside the bar.\n" ..
                  "Green >= 50%  |  Yellow >= 20%  |  Red < 20%." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 26:** `body = "Component wear percentage (0% = new, 100% = worn `

```lua
                  "Green >= 50%  |  Yellow >= 20%  |  Red < 20%." },
        { title = "WEAR BAR",
          body  = "Component wear percentage (0% = new, 100% = worn out).\n" ..
                  "High wear reduces efficiency — repair before reaching 80%.\n" ..
                  "Green <= 30%  |  Yellow <= 65%  |  Red > 65%." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 30:** `body = "Operating hours: total engine time in whole hours`

```lua
                  "Green <= 30%  |  Yellow <= 65%  |  Red > 65%." },
        { title = "HOURS / STATUS",
          body  = "Operating hours: total engine time in whole hours.\n" ..
                  "AI badge appears when the vehicle is driven by a hired worker.\n" ..
                  "No badge = parked or player-controlled." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/HotspotManagerApp.lua`

**Line 136:** `body = "Shows all active map hotspots / pins.\n" ..`

```lua
    if self:drawHelpPage("_hotspotHelp", FT.APP.HOTSPOT_MGR, "Hotspot Manager", AC, {
        { title = "WHAT IS THIS?",
          body  = "Shows all active map hotspots / pins.\n" ..
                  "Tick the checkbox beside a pin, then REMOVE SELECTED.\n" ..
                  "ADD PIN HERE drops a custom pin at your feet.\n\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 143:** `body = "Press CLEAR ALL once — it turns red and asks\n" .`

```lua
                  "after a map re-sync." },
        { title = "CLEAR ALL",
          body  = "Press CLEAR ALL once — it turns red and asks\n" ..
                  "for confirmation. Press it again within 4 seconds\n" ..
                  "to remove every hotspot from the map." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 187:** `onClick = function()`

```lua

    local btnAdd = self.r:button(x, y - BTN_H, btnW, BTN_H, "ADD PIN HERE", FT.C.BTN_PRIMARY, {
        onClick = function()
            local ok, err = hs_addPinAtPlayer()
            _statusMsg = ok and "Pin added at your position." or (err or "Add failed")
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 189:** `_statusMsg = ok and "Pin added at your position." or (err or "A`

```lua
        onClick = function()
            local ok, err = hs_addPinAtPlayer()
            _statusMsg = ok and "Pin added at your position." or (err or "Add failed")
            _statusTimer = 180
        end
```

**Issue:** Variable `_statusMsg` is assigned without `local` keyword.
**Fix:** Add `local _statusMsg` before first use, or add `local` to this line.

---

**Line 190:** `_statusTimer = 180`

```lua
            local ok, err = hs_addPinAtPlayer()
            _statusMsg = ok and "Pin added at your position." or (err or "Add failed")
            _statusTimer = 180
        end
    })
```

**Issue:** Variable `_statusTimer` is assigned without `local` keyword.
**Fix:** Add `local _statusTimer` before first use, or add `local` to this line.

---

**Line 199:** `onClick = function()`

```lua
    local rmColor = selectedCount > 0 and FT.C.BTN_DANGER or FT.C.BTN_NEUTRAL
    local btnRmSel = self.r:button(x + btnW + gapX, y - BTN_H, btnW, BTN_H, rmLabel, rmColor, {
        onClick = function()
            if selectedCount == 0 then
                _statusMsg = "Tick pins to remove first."
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 201:** `_statusMsg = "Tick pins to remove first."`

```lua
        onClick = function()
            if selectedCount == 0 then
                _statusMsg = "Tick pins to remove first."
                _statusTimer = 120
                return
```

**Issue:** Variable `_statusMsg` is assigned without `local` keyword.
**Fix:** Add `local _statusMsg` before first use, or add `local` to this line.

---

**Line 202:** `_statusTimer = 120`

```lua
            if selectedCount == 0 then
                _statusMsg = "Tick pins to remove first."
                _statusTimer = 120
                return
            end
```

**Issue:** Variable `_statusTimer` is assigned without `local` keyword.
**Fix:** Add `local _statusTimer` before first use, or add `local` to this line.

---

**Line 227:** `onClick = function()`

```lua
        local btnClear = self.r:button(x + (btnW + gapX) * 2, y - BTN_H, btnW, BTN_H,
            clearLabel, clearColor, {
            onClick = function()
                if _confirmClear then
                    local toRemove = {}
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 285:** `onClick = function()`

```lua
            local btnChk = self.r:button(x, y - rowH + FT.py(2), checkW, rowH - FT.py(2),
                mark, boxCol, {
                onClick = function()
                    if _selected[capturedKey] then
                        _selected[capturedKey] = nil
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/IncomeApp.lua`

**Line 25:** `body = "Displays the current status of FS25_IncomeMod.\n"`

```lua
    if self:drawHelpPage("_incomeHelp", FT.APP.INCOME, "Income Mod", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays the current status of FS25_IncomeMod.\n" ..
                  "The mod adds configurable periodic income payments\n" ..
                  "to supplement your farm earnings." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 29:** `body = "Controls when income is paid out:\n" ..`

```lua
                  "to supplement your farm earnings." },
        { title = "PAYMENT MODE",
          body  = "Controls when income is paid out:\n" ..
                  "Hourly = every in-game hour.\n" ..
                  "Daily = once per in-game day.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 34:** `body = "The money added to your balance per payment cycle`

```lua
                  "Weekly = once per in-game week." },
        { title = "AMOUNT",
          body  = "The money added to your balance per payment cycle.\n" ..
                  "Configure this in the Income Mod settings." },
        { title = "ENABLE / DISABLE",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 37:** `body = "Toggles the mod on or off without uninstalling it`

```lua
                  "Configure this in the Income Mod settings." },
        { title = "ENABLE / DISABLE",
          body  = "Toggles the mod on or off without uninstalling it.\n" ..
                  "Changes take effect immediately." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 98:** `body = "Displays the status of FS25_TaxMod.\n" ..`

```lua
    if self:drawHelpPage("_taxHelp", FT.APP.TAX, "Tax Mod", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays the status of FS25_TaxMod.\n" ..
                  "The mod deducts periodic tax from your balance\n" ..
                  "and returns a configurable percentage as a rebate." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 102:** `body = "How much tax is charged per cycle.\n" ..`

```lua
                  "and returns a configurable percentage as a rebate." },
        { title = "TAX RATE",
          body  = "How much tax is charged per cycle.\n" ..
                  "Low / Medium / High tiers are set in the mod settings.\n" ..
                  "Shown here so you can plan your cash flow." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 106:** `body = "Percentage of tax paid that is returned as a reba`

```lua
                  "Shown here so you can plan your cash flow." },
        { title = "RETURN %",
          body  = "Percentage of tax paid that is returned as a rebate.\n" ..
                  "A 20% return means you effectively pay 80% of the\n" ..
                  "stated tax rate." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 110:** `body = "Cumulative tax paid across the current session.\n`

```lua
                  "stated tax rate." },
        { title = "TOTAL PAID",
          body  = "Cumulative tax paid across the current session.\n" ..
                  "Shown in orange as it represents an ongoing cost." },
        { title = "ENABLE / DISABLE",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 113:** `body = "Toggles the mod on or off without uninstalling it`

```lua
                  "Shown in orange as it represents an ongoing cost." },
        { title = "ENABLE / DISABLE",
          body  = "Toggles the mod on or off without uninstalling it.\n" ..
                  "Changes take effect immediately." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 178:** `body = "Overall standing with the local community (0-100)`

```lua
    if self:drawHelpPage("_npcHelp", FT.APP.NPC_FAVOR, "NPC Favor", AC, {
        { title = "TOWN REPUTATION",
          body  = "Overall standing with the local community (0-100).\n" ..
                  "Respected >= 70  |  Neutral >= 40  |  Poor < 40.\n" ..
                  "Higher reputation unlocks better favor rewards." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 182:** `body = "Number of favors currently in progress.\n" ..`

```lua
                  "Higher reputation unlocks better favor rewards." },
        { title = "ACTIVE FAVORS",
          body  = "Number of favors currently in progress.\n" ..
                  "Each favor shows NPC name, description, completion\n" ..
                  "percentage, and hours remaining." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 186:** `body = "Lists every active NPC with their relationship sc`

```lua
                  "percentage, and hours remaining." },
        { title = "RELATIONSHIPS",
          body  = "Lists every active NPC with their relationship score\n" ..
                  "and a colour-coded bar.\n" ..
                  "Friend >= 70  |  Neutral >= 40  |  Cold < 40.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 192:** `body = "Complete favors for an NPC to increase their\n" .`

```lua
                  "square brackets next to their name." },
        { title = "BUILDING RELATIONSHIPS",
          body  = "Complete favors for an NPC to increase their\n" ..
                  "relationship score. Higher scores unlock exclusive\n" ..
                  "advice, discounts, and early warnings." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 307:** `body = "Integrates with FS25_SeasonalCropStress to displa`

```lua
    if self:drawHelpPage("_cropStressHelp", FT.APP.CROP_STRESS, "Crop Stress", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Integrates with FS25_SeasonalCropStress to display\n" ..
                  "soil moisture and drought stress per field.\n" ..
                  "Install that mod and open its own Help section for\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 312:** `body = "Shows whether Seasonal Crop Stress is enabled and`

```lua
                  "full irrigation guidance." },
        { title = "STATUS BANNER",
          body  = "Shows whether Seasonal Crop Stress is enabled and\n" ..
                  "the current difficulty setting." },
        { title = "FIELD LIST",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 315:** `body = "Each row shows field ID, crop type, moisture %,\n`

```lua
                  "the current difficulty setting." },
        { title = "FIELD LIST",
          body  = "Each row shows field ID, crop type, moisture %,\n" ..
                  "and a colour-coded bar.\n" ..
                  "Green >= 40%  |  Yellow >= 25%  |  Red < 25%." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 319:** `body = "If a field has more than 5% accumulated drought\n`

```lua
                  "Green >= 40%  |  Yellow >= 25%  |  Red < 25%." },
        { title = "STRESS INDICATOR",
          body  = "If a field has more than 5% accumulated drought\n" ..
                  "stress, the value row ends with  !XX%  in red.\n" ..
                  "Irrigate those fields immediately to stop yield loss." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 323:** `body = "Visual fill bar below each row.\n" ..`

```lua
                  "Irrigate those fields immediately to stop yield loss." },
        { title = "MOISTURE BAR",
          body  = "Visual fill bar below each row.\n" ..
                  "Longer bar = more moisture in the soil.\n" ..
                  "An empty bar means the field is critically dry." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 464:** `body = "Displays FS25_WorkerCosts status:\n" ..`

```lua
    if self:drawHelpPage("_wrkHelp", FT.APP.WORKER_COSTS, "Worker Costs", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays FS25_WorkerCosts status:\n" ..
                  "current wage level, cost mode, active\n" ..
                  "workers, and month-to-date costs.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 469:** `body = "Sets the per-hour wage rate for hired workers.\n"`

```lua
                  "Scroll down for the Pro-Staff roster." },
        { title = "WAGE LEVEL",
          body  = "Sets the per-hour wage rate for hired workers.\n" ..
                  "Low / Medium / High tiers are configured in\n" ..
                  "the Worker Costs mod settings." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 473:** `body = "Controls how wages are calculated:\n" ..`

```lua
                  "the Worker Costs mod settings." },
        { title = "COST MODE",
          body  = "Controls how wages are calculated:\n" ..
                  "Hourly = charged every in-game hour.\n" ..
                  "Monthly = accumulated and charged at month end." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/IrrigationSuiteApp.lua`

**Line 237:** `body = "Farm-wide irrigation picture from Seasonal Crop S`

```lua
    if self:drawHelpPage("_irrigationSuiteHelp", FT.APP.IRRIGATION_SUITE, "Irrigation Suite", AC, {
        { title = "WHAT THIS IS",
          body  = "Farm-wide irrigation picture from Seasonal Crop Stress:\n" ..
                  "which systems run, what they cover, moisture split,\n" ..
                  "a short trend, and usage plus soil risk when Soil Fertilizer\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 242:** `body = "Active systems, schedules, coverage outline, and `

```lua
                  "is present. Read-only mirror. No second moisture model." },
        { title = "OPERATIONS",
          body  = "Active systems, schedules, coverage outline, and per-field\n" ..
                  "irrigation-versus-rain split from live SCS reads." },
        { title = "FORECAST",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 245:** `body = "Current moisture and drought stress plus a clearl`

```lua
                  "irrigation-versus-rain split from live SCS reads." },
        { title = "FORECAST",
          body  = "Current moisture and drought stress plus a clearly labeled\n" ..
                  "trend. Not a simulated future. Farm-wide advisory when SCS\n" ..
                  "publishes one." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 249:** `body = "What SCS is charging per active hour when costs a`

```lua
                  "publishes one." },
        { title = "USAGE AND RISK",
          body  = "What SCS is charging per active hour when costs are on.\n" ..
                  "Compaction / OM / disease from Soil Fertilizer when present.\n" ..
                  "Unscouted disease reads Unscouted, never a false all-clear." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 283:** `onClick = function()`

```lua
        local captured = m
        local btn = self.r:button(bx, tabY, btnW, btnH, MODE_LABEL[m], col, {
            onClick = function()
                self.system.irrigationSuiteMode = captured
                self._contentScrollY = 0
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/MarketDynamicsApp.lua`

**Line 42:** `body = "Displays FS25_MarketDynamics status:\n" ..`

```lua
    if self:drawHelpPage("_mktHelp", FT.APP.MARKET_DYNAMICS, "Market Dynamics", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays FS25_MarketDynamics status:\n" ..
                  "active world events, market price modifiers,\n" ..
                  "and event frequency settings." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 46:** `body = "Events like droughts, trade disruptions, and\n" .`

```lua
                  "and event frequency settings." },
        { title = "WORLD EVENTS",
          body  = "Events like droughts, trade disruptions, and\n" ..
                  "pest outbreaks temporarily shift crop prices.\n" ..
                  "Active events and their intensity are listed here." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 50:** `body = "Price modifiers and event frequency can be\n" ..`

```lua
                  "Active events and their intensity are listed here." },
        { title = "SETTINGS",
          body  = "Price modifiers and event frequency can be\n" ..
                  "adjusted in the Market Dynamics mod settings." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/NotesApp.lua`

**Line 166:** `onClick = function()`

```lua
    local btnPrev = self.r:button(x, y - BTN_H, arrowW, BTN_H, "<",
        FT.C.BTN_NEUTRAL, {
        onClick = function()
            _templateIdx = ((_templateIdx - 2) % #TEMPLATES) + 1
        end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 167:** `_templateIdx = ((_templateIdx - 2) % #TEMPLATES) + 1`

```lua
        FT.C.BTN_NEUTRAL, {
        onClick = function()
            _templateIdx = ((_templateIdx - 2) % #TEMPLATES) + 1
        end
    })
```

**Issue:** Variable `_templateIdx` is assigned without `local` keyword.
**Fix:** Add `local _templateIdx` before first use, or add `local` to this line.

---

**Line 182:** `onClick = function()`

```lua
    local btnNext = self.r:button(x + arrowW + FT.px(3) + labelW + FT.px(3),
        y - BTN_H, arrowW, BTN_H, ">", FT.C.BTN_NEUTRAL, {
        onClick = function()
            _templateIdx = (_templateIdx % #TEMPLATES) + 1
        end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 183:** `_templateIdx = (_templateIdx % #TEMPLATES) + 1`

```lua
        y - BTN_H, arrowW, BTN_H, ">", FT.C.BTN_NEUTRAL, {
        onClick = function()
            _templateIdx = (_templateIdx % #TEMPLATES) + 1
        end
    })
```

**Issue:** Variable `_templateIdx` is assigned without `local` keyword.
**Fix:** Add `local _templateIdx` before first use, or add `local` to this line.

---

**Line 206:** `onClick = function()`

```lua
        local btnFPrev = self.r:button(x, y - BTN_H, arrowW, BTN_H, "<",
            FT.C.BTN_NEUTRAL, {
            onClick = function()
                _fieldIdx = (_fieldIdx - 1 + total) % total
            end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 207:** `_fieldIdx = (_fieldIdx - 1 + total) % total`

```lua
            FT.C.BTN_NEUTRAL, {
            onClick = function()
                _fieldIdx = (_fieldIdx - 1 + total) % total
            end
        })
```

**Issue:** Variable `_fieldIdx` is assigned without `local` keyword.
**Fix:** Add `local _fieldIdx` before first use, or add `local` to this line.

---

**Line 220:** `onClick = function()`

```lua
        local btnFNext = self.r:button(x + arrowW + FT.px(3) + labelW + FT.px(3),
            y - BTN_H, arrowW, BTN_H, ">", FT.C.BTN_NEUTRAL, {
            onClick = function()
                _fieldIdx = (_fieldIdx + 1) % total
            end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 221:** `_fieldIdx = (_fieldIdx + 1) % total`

```lua
            y - BTN_H, arrowW, BTN_H, ">", FT.C.BTN_NEUTRAL, {
            onClick = function()
                _fieldIdx = (_fieldIdx + 1) % total
            end
        })
```

**Issue:** Variable `_fieldIdx` is assigned without `local` keyword.
**Fix:** Add `local _fieldIdx` before first use, or add `local` to this line.

---

**Line 231:** `onClick = function()`

```lua
    local btnAdd = self.r:button(x, y - BTN_H, cw, BTN_H,
        N("ft_notes_add", "+ Add task"), FT.C.BTN_PRIMARY, {
        onClick = function()
            local todoText = templateText(_templateIdx)
            local fields = notes_getOwnedFieldNums()
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 287:** `onClick = function()`

```lua
                todo.done and N("ft_common_undo", "Undo") or N("ft_common_done", "Done"),
                todo.done and FT.C.BTN_NEUTRAL or FT.C.BTN_PRIMARY, {
                onClick = function()
                    if _todos[capturedIdx] then
                        _todos[capturedIdx].done = not _todos[capturedIdx].done
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 300:** `onClick = function()`

```lua
                x + statusW + FT.px(3) + textW + FT.px(3) + actionW + FT.px(3),
                y - BTN_H, removeW, BTN_H, "✕", FT.C.BTN_DANGER, {
                onClick = function()
                    table.remove(_todos, capturedIdx)
                    notes_save()
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 317:** `onClick = function()`

```lua
            string.format(N("ft_notes_clear_completed_fmt", "Clear %d completed"), done),
            FT.C.BTN_DANGER, {
            onClick = function()
                local remaining = {}
                for _, t in ipairs(_todos) do
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/OrganicApp.lua`

**Line 82:** `body = "Organic certification and practice advice for you`

```lua
    if self:drawHelpPage("_organicHelp", FT.APP.ORGANIC, "Organic", AC, {
        { title = "WHAT THIS IS",
          body  = "Organic certification and practice advice for your\n" ..
                  "fields. Reads Soil Fertilizer. Owns no organic state." },
        { title = "CERTIFICATION",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 85:** `body = "Per-field state: Conventional, In transition, or\`

```lua
                  "fields. Reads Soil Fertilizer. Owns no organic state." },
        { title = "CERTIFICATION",
          body  = "Per-field state: Conventional, In transition, or\n" ..
                  "Certified, plus the transition countdown. OPT IN /\n" ..
                  "OPT OUT asks Soil Fertilizer (admin-gated there)." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 89:** `body = "Cover-crop and rotation tips framed for organic,\`

```lua
                  "OPT OUT asks Soil Fertilizer (admin-gated there)." },
        { title = "PRACTICES",
          body  = "Cover-crop and rotation tips framed for organic,\n" ..
                  "from the same soil data as the Soil Fertilizer app." },
        { title = "COMING LATER",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 92:** `body = "Compost, livestock feed, and market premium secti`

```lua
                  "from the same soil data as the Soil Fertilizer app." },
        { title = "COMING LATER",
          body  = "Compost, livestock feed, and market premium sections\n" ..
                  "stay stubs until those sims expose read APIs." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 179:** `onClick = function()`

```lua
            local selBtn = self.r:button(x + cw - btnW, y - FT.py(2), btnW, btnH,
                isSel and "VIEW" or "SELECT", isSel and AC or FT.C.BTN_NEUTRAL, {
                    onClick = function()
                        self.system.organicSelectedField = field.id
                    end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 203:** `onClick = function()`

```lua
            local bIn = self.r:button(x, y - FT.py(20), half, FT.py(20), "OPT IN",
                FT.C.BTN_PRIMARY, {
                    onClick = function()
                        pcall(function() organic:requestOptIn(selected) end)
                    end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 216:** `onClick = function()`

```lua
            local bOut = self.r:button(x + half + gap, y - FT.py(20), half, FT.py(20),
                "OPT OUT", FT.C.BTN_DANGER, {
                    onClick = function()
                        pcall(function() organic:requestOptOut(selected) end)
                    end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/PersonnelApp.lua`

**Line 355:** `body = "A personnel command center for FS25_WorkerCosts.\`

```lua
    if self:drawHelpPage("_psHelp", FT.APP.PERSONNEL, "Personnel", AC, {
        { title = "WHAT THIS APP DOES",
          body  = "A personnel command center for FS25_WorkerCosts.\n" ..
                  "Manage your Pro-Staff roster: review, hire,\n" ..
                  "fire, and pin workers to vehicles." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 359:** `body = "Every worker with level, lifetime hours, jobs,\n"`

```lua
                  "fire, and pin workers to vehicles." },
        { title = "ROSTER TAB",
          body  = "Every worker with level, lifetime hours, jobs,\n" ..
                  "and fatigue. Sort and filter the list. PIN a\n" ..
                  "worker to the vehicle you're driving, or FIRE\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 364:** `body = "A rotating recruitment pool. Each candidate has\n`

```lua
                  "them (tap twice — severance applies)." },
        { title = "HIRE TAB",
          body  = "A rotating recruitment pool. Each candidate has\n" ..
                  "a level and a one-off signing cost. HIRE to add\n" ..
                  "them; REROLL to draw fresh candidates." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 368:** `body = "Wage structure, the running cost estimate, and\n"`

```lua
                  "them; REROLL to draw fresh candidates." },
        { title = "PAYROLL TAB",
          body  = "Wage structure, the running cost estimate, and\n" ..
                  "the Pro-Staff impact — how levels (cheaper) and\n" ..
                  "fatigue (pricier) net out across the crew." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 372:** `body = "The roster lives on the host. Your actions are\n"`

```lua
                  "fatigue (pricier) net out across the crew." },
        { title = "MULTIPLAYER",
          body  = "The roster lives on the host. Your actions are\n" ..
                  "sent to the host and the result syncs back to\n" ..
                  "everyone automatically." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/ProStaffApp.lua`

**Line 51:** `body = "Your farm's Pro-Staff Co-Op membership level,\n" `

```lua
    if self:drawHelpPage("_prostaffHelp", FT.APP.PROSTAFF, "Pro-Staff Co-Op", AC, {
        { title = "WHAT THIS IS",
          body  = "Your farm's Pro-Staff Co-Op membership level,\n" ..
                  "next investment cost, and active modifiers.\n" ..
                  "This is not the Personnel / Worker Costs roster." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 55:** `body = "BUY NEXT LEVEL spends the listed cost on the host`

```lua
                  "This is not the Personnel / Worker Costs roster." },
        { title = "INVEST",
          body  = "BUY NEXT LEVEL spends the listed cost on the host\n" ..
                  "via ProStaff's own buyLevel path. Pure clients need\n" ..
                  "the host / NetworkSync to complete the purchase." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 59:** `body = "Only non-neutral effects at your current level ar`

```lua
                  "the host / NetworkSync to complete the purchase." },
        { title = "MODIFIERS",
          body  = "Only non-neutral effects at your current level are\n" ..
                  "listed (wages, fatigue, fertilizer, dairy, flags)." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 113:** `onClick = function()`

```lua
        local btn = self.r:button(x, y - FT.py(22), cw, FT.py(22),
            "BUY NEXT LEVEL", FT.C.BTN_PRIMARY, {
                onClick = function()
                    pcall(function() mgr:buyLevel() end)
                end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/ProductionBuildingsApp.lua`

**Line 19:** `body = "Shows every production building your farm owns.\n`

```lua
    if self:drawHelpPage("_prodHelp", FT.APP.PRODUCTION, "Production", AC, {
        { title = "BUILDING LIST",
          body  = "Shows every production building your farm owns.\n" ..
                  "Each entry shows the building name and how many of its\n" ..
                  "production lines are currently active." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 23:** `body = "Active: at least one production chain is enabled `

```lua
                  "production lines are currently active." },
        { title = "ACTIVE / STALLED",
          body  = "Active: at least one production chain is enabled and\n" ..
                  "the building has the inputs it needs.\n" ..
                  "Stalled: no productions are enabled (check the building\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 28:** `body = "Lists the fill types the building consumes and pr`

```lua
                  "management menu to turn them on)." },
        { title = "INPUTS / OUTPUTS",
          body  = "Lists the fill types the building consumes and produces.\n" ..
                  "Check your Storage app to ensure inputs are stocked.\n" ..
                  "Outputs pile up if the unloading station is full — check\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 33:** `body = "Production buildings must be owned by your farm.\`

```lua
                  "your silo capacity." },
        { title = "NO BUILDINGS SHOWN",
          body  = "Production buildings must be owned by your farm.\n" ..
                  "Purchase a cheese factory, bakery, or other production\n" ..
                  "placeable from the shop to see it here." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/RandomWorldEventsApp.lua`

**Line 44:** `body = "Displays FS25_RandomWorldEvents status:\n" ..`

```lua
    if self:drawHelpPage("_rweHelp", FT.APP.RANDOM_EVENTS, "Random World Events", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Displays FS25_RandomWorldEvents status:\n" ..
                  "the currently active event, frequency,\n" ..
                  "intensity, and event counter." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 48:** `body = "When an event is running (fire, flood, drought,\n`

```lua
                  "intensity, and event counter." },
        { title = "ACTIVE EVENT",
          body  = "When an event is running (fire, flood, drought,\n" ..
                  "etc.) it appears here with its name. Events end\n" ..
                  "after a fixed duration." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/RoleplayPhoneApp.lua`

**Line 124:** `onClick = function()`

```lua

    local btnL = self.r:button(ctrlX, y, arrowW, rowH, "◄", FT.C.BTN_NEUTRAL, {
        onClick = function()
            onChange(-1)
            self:switchApp(appId)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 141:** `onClick = function()`

```lua

    local btnR = self.r:button(ctrlX + ctrlW - arrowW, y, arrowW, rowH, "►", FT.C.BTN_NEUTRAL, {
        onClick = function()
            onChange(1)
            self:switchApp(appId)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 195:** `onClick = function()`

```lua
        local stepVal = step
        local btn = self.r:button(bx, y, stepW - FT.px(2), rowH, labels[i], FT.C.BTN_NEUTRAL, {
            onClick = function()
                self._invoiceForm.amount = math.max(0, self._invoiceForm.amount + stepVal)
                self:switchApp(appId)
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 218:** `y = drawCycler(self, y, "PARTY", partyVal, function(di`

```lua
    local partyVal  = partyList[form.partyIdx] or "—"
    if partyVal == "Custom" then partyVal = "Custom (set via console)" end
    y = drawCycler(self, y, "PARTY", partyVal, function(dir)
        form.partyIdx = ((form.partyIdx - 1 + dir + #partyList) % #partyList) + 1
    end)
```

**Issue:** Variable `y` is assigned without `local` keyword.
**Fix:** Add `local y` before first use, or add `local` to this line.

---

**Line 225:** `y = drawCycler(self, y, "DESCRIPTION", descVal, functi`

```lua
    local descVal = DESC_PRESETS[form.descIdx] or "—"
    if descVal == "Custom" then descVal = "Custom (set via console)" end
    y = drawCycler(self, y, "DESCRIPTION", descVal, function(dir)
        form.descIdx = ((form.descIdx - 1 + dir + #DESC_PRESETS) % #DESC_PRESETS) + 1
    end)
```

**Issue:** Variable `y` is assigned without `local` keyword.
**Fix:** Add `local y` before first use, or add `local` to this line.

---

**Line 234:** `y = drawCycler(self, y, "DUE DATE", dueOpt.label, func`

```lua

    local dueOpt = DUE_OPTIONS[form.dueIdx] or DUE_OPTIONS[1]
    y = drawCycler(self, y, "DUE DATE", dueOpt.label, function(dir)
        form.dueIdx = ((form.dueIdx - 1 + dir + #DUE_OPTIONS) % #DUE_OPTIONS) + 1
    end)
```

**Issue:** Variable `y` is assigned without `local` keyword.
**Fix:** Add `local y` before first use, or add `local` to this line.

---

**Line 246:** `onClick = function()`

```lua

    local btnCancel = self.r:button(x, y, halfW, btnH, "CANCEL", FT.C.BTN_NEUTRAL, {
        onClick = function()
            self._invoiceFormOpen = false
            self._invoiceForm     = nil
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 257:** `onClick = function()`

```lua
    local createColor = canCreate and FT.C.BTN_PRIMARY or FT.C.BTN_NEUTRAL
    local btnCreate = self.r:button(x + halfW + FT.px(8), y, halfW, btnH, "CREATE", createColor, {
        onClick = function()
            if not canCreate then return end
            local invoiceMgr = g_currentMission and g_currentMission.ftInvoiceManager
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 532:** `onClick = function()`

```lua
                    local btnPay = self.r:button(x, btnY, btnW, btnH, "PAY",
                        FT.C.BTN_PRIMARY, {
                            onClick = function()
                                local mgr = g_currentMission and g_currentMission.ftInvoiceManager
                                if mgr then mgr:updateStatus(invId, FT_InvoiceManager.STATUS.PAID); mgr:save() end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 540:** `onClick = function()`

```lua
                    local btnCancel = self.r:button(x + btnW + gap, btnY, btnW, btnH, "CANCEL",
                        FT.C.BTN_DANGER, {
                            onClick = function()
                                local mgr = g_currentMission and g_currentMission.ftInvoiceManager
                                if mgr then mgr:deleteInvoice(invId); mgr:save() end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 555:** `onClick = function()`

```lua
                    local btnDel = self.r:button(x + w - delW, btnY, delW, btnH, "DELETE",
                        FT.C.BTN_NEUTRAL, {
                            onClick = function()
                                local mgr = g_currentMission and g_currentMission.ftInvoiceManager
                                if mgr then mgr:deleteInvoice(invId); mgr:save() end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/RotationPlannerApp.lua`

**Line 88:** `body = "Farm-wide crop rotation standing and a what-if co`

```lua
    if self:drawHelpPage("_rotationPlannerHelp", FT.APP.ROTATION_PLANNER, "Rotation Planner", AC, {
        { title = "WHAT THIS IS",
          body  = "Farm-wide crop rotation standing and a what-if compare\n" ..
                  "for the next crop on any field. Numbers come from Soil\n" ..
                  "Fertilizer's own rotation scoring, not a second model." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 92:** `body = "Each owned field shows recent crops and whether t`

```lua
                  "Fertilizer's own rotation scoring, not a second model." },
        { title = "WHERE DO I STAND",
          body  = "Each owned field shows recent crops and whether the\n" ..
                  "ground is Bonus-primed, OK, or Fatigue. Kinds, not grades." },
        { title = "WHAT IF",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 95:** `body = "Select a field, then read the same curated candid`

```lua
                  "ground is Bonus-primed, OK, or Fatigue. Kinds, not grades." },
        { title = "WHAT IF",
          body  = "Select a field, then read the same curated candidates\n" ..
                  "the soil field-detail dialog uses (same crop, a legume,\n" ..
                  "a neutral cereal) with the sim's own consequence words." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 99:** `body = "Until the soil data surface publishes a third sea`

```lua
                  "a neutral cereal) with the sim's own consequence words." },
        { title = "HONEST DEGRADE",
          body  = "Until the soil data surface publishes a third season and\n" ..
                  "bonus countdown, this app shows two seasons and no timer.\n" ..
                  "A field with no history reads Unknown, never invented." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 192:** `onClick = function()`

```lua
            local by = y - FT.py(2)
            local btn = self.r:button(bx, by, btnW, btnH, isSel and "VIEW" or "SELECT", AC, {
                onClick = function()
                    self.system.rotationPlannerSelectedField = field.id
                end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/SoilFertilizerApp.lua`

**Line 30:** `body = "FieldSentry decides which fields the soil simulat`

```lua
    if self:drawHelpPage("_sentryHelp", FT.APP.FIELD_SENTRY, "Field Sentry", AC, {
        { title = "WHAT THIS IS",
          body  = "FieldSentry decides which fields the soil simulation runs\n" ..
                  "on. Sleeping fields are skipped to save performance and to\n" ..
                  "leave NPC-contracted or decorative land alone." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 34:** `body = "ACTIVE = simulated normally.\n" ..`

```lua
                  "leave NPC-contracted or decorative land alone." },
        { title = "STATUS",
          body  = "ACTIVE = simulated normally.\n" ..
                  "MANUAL = you put it to sleep.\n" ..
                  "NPC    = asleep under an AI/NPC contract.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 39:** `body = "Force a field to sleep (or wake it). Your choice `

```lua
                  "DECO   = decorative / fake field (auto-detected)." },
        { title = "SLEEP TOGGLE",
          body  = "Force a field to sleep (or wake it). Your choice persists\n" ..
                  "and is independent of contract/decorative states." },
        { title = "MEADOW TOGGLE",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 42:** `body = "Mark a field as permanent grassland. It still sim`

```lua
                  "and is independent of contract/decorative states." },
        { title = "MEADOW TOGGLE",
          body  = "Mark a field as permanent grassland. It still simulates,\n" ..
                  "just on meadow rules. Independent of the sleep state." },
        { title = "MULTIPLAYER",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 45:** `body = "Toggles are admin-only and validated by the host.`

```lua
                  "just on meadow rules. Independent of the sleep state." },
        { title = "MULTIPLAYER",
          body  = "Toggles are admin-only and validated by the host. Clients\n" ..
                  "without admin see the list read-only." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 146:** `onClick = function()`

```lua
            local sleepBtn = self.r:button(sleepX, y - FT.py(2), btnW, btnH,
                isManual and "WAKE" or "SLEEP", sleepCol, isAdmin and {
                    onClick = function()
                        if FS.toggleSleep then FS.toggleSleep(field.id, not isManual) end
                    end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

**Line 156:** `onClick = function()`

```lua
            local meadowBtn = self.r:button(meadowX, y - FT.py(2), btnW, btnH,
                "MEADOW", meadowCol, isAdmin and {
                    onClick = function()
                        if FS.toggleMeadow then FS.toggleMeadow(field.id, not isMeadow) end
                    end
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/apps/SoilNutrientApp.lua`

**Line 300:** `body = "One card per owned field: N / P / K / pH / OM /\n`

```lua
    if self:drawHelpPage("_soilHelp", FT.APP.SOIL_FERT, "Soil Fertilizer", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "One card per owned field: N / P / K / pH / OM /\n" ..
                  "Weed / Pest / Disease as current vs expected bars,\n" ..
                  "plus a TREATMENT plan with rates when a nutrient\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 305:** `body = "Cards are sorted by SoilFertilizer urgency so the`

```lua
                  "or pressure needs work." },
        { title = "URGENCY ORDER",
          body  = "Cards are sorted by SoilFertilizer urgency so the\n" ..
                  "fields that need attention first rise to the top.\n" ..
                  "Left tick: green OK · yellow WATCH · red URGENT." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 309:** `body = "Prescriptions mirror the Shift+T Soil Treatment\n`

```lua
                  "Left tick: green OK · yellow WATCH · red URGENT." },
        { title = "TREATMENT",
          body  = "Prescriptions mirror the Shift+T Soil Treatment\n" ..
                  "dialog (product rates + protection actions).\n" ..
                  "Disease stays Unscouted until you scout the field." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 313:** `body = "Green = on target  |  Yellow = fair  |  Red = poo`

```lua
                  "Disease stays Unscouted until you scout the field." },
        { title = "NUTRIENT COLOURS",
          body  = "Green = on target  |  Yellow = fair  |  Red = poor.\n" ..
                  "Bars show current / expected (ppm for N/P/K)." },
        { title = "pH + ORGANIC MATTER",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 316:** `body = "Optimal pH is 6.5 (band ~6.0–7.5).\n" ..`

```lua
                  "Bars show current / expected (ppm for N/P/K)." },
        { title = "pH + ORGANIC MATTER",
          body  = "Optimal pH is 6.5 (band ~6.0–7.5).\n" ..
                  "OM is a 0–10 soil scale (not a percent).\n" ..
                  "Healthy band sits around 3.5–5.0." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/StorageApp.lua`

**Line 69:** `body = "Lists all crops currently stored across your owne`

```lua
    if self:drawHelpPage("_storageHelp", FT.APP.STORAGE, "Storage", AC, {
        { title = "INVENTORY",
          body  = "Lists all crops currently stored across your owned silos.\n" ..
                  "Amounts shown in litres, sorted largest-first.\n" ..
                  "Data refreshes every 3 seconds." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 73:** `body = "Shows the best available sell price per stored cr`

```lua
                  "Data refreshes every 3 seconds." },
        { title = "BEST SELL PRICES",
          body  = "Shows the best available sell price per stored crop\n" ..
                  "across all active selling stations on the map.\n" ..
                  "Peak price is tracked and saved per savegame.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 79:** `body = "Lists every selling station and its current price`

```lua
                  "Prices are per 1,000 litres. Refreshes every 5 seconds." },
        { title = "PRICE COMPARISON",
          body  = "Lists every selling station and its current price for\n" ..
                  "each crop you have in storage.\n" ..
                  "Stations are sorted best-price first.\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 84:** `body = "Any placeable with bulk storage you own:\n" ..`

```lua
                  "Only shown when 2+ stations buy that crop." },
        { title = "WHAT COUNTS AS A SILO?",
          body  = "Any placeable with bulk storage you own:\n" ..
                  "grain silos, bunker silos, silage pits, manure stores,\n" ..
                  "and liquid manure tanks." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/SystemSettingsApp.lua`

**Line 33:** `body = "Every setting the Realistic Farming mods have\n" `

```lua
    if self:drawHelpPage("_sysSetHelp", FT.APP.SYSTEM_SETTINGS, "System Settings", AC, {
        { title = "WHAT THIS APP SHOWS",
          body  = "Every setting the Realistic Farming mods have\n" ..
                  "registered with the Settings Hub, grouped by mod,\n" ..
                  "with its current value." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 37:** `body = "Tap a mod's header to fold or unfold its settings`

```lua
                  "with its current value." },
        { title = "COLLAPSE / EXPAND",
          body  = "Tap a mod's header to fold or unfold its settings.\n" ..
                  "The list scrolls when it runs past the screen." },
        { title = "ADMIN VS LOCAL",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 40:** `body = "Admin settings are shared by the server and apply`

```lua
                  "The list scrolls when it runs past the screen." },
        { title = "ADMIN VS LOCAL",
          body  = "Admin settings are shared by the server and apply\n" ..
                  "to everyone in multiplayer. Local settings are your\n" ..
                  "own and stay on this machine." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 44:** `body = "This overview is read-only for now. Change values`

```lua
                  "own and stay on this machine." },
        { title = "EDITING",
          body  = "This overview is read-only for now. Change values\n" ..
                  "from each mod's own settings for the moment.\n" ..
                  "Making this page editable is proposed and waiting\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/UsedPlusApp.lua`

**Line 13:** `body = "Vehicles you have listed for sale through a UsedP`

```lua
    if self:drawHelpPage("_usedPlusHelp", FT.APP.USED_PLUS, "UsedPlus", AC, {
        { title = "ACTIVE SALE LISTINGS",
          body  = "Vehicles you have listed for sale through a UsedPlus\n" ..
                  "agent. Shows vehicle name, asking price range, agent\n" ..
                  "tier, and how far through the listing period you are." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 17:** `body = "Filled = time elapsed. An offer can arrive any ti`

```lua
                  "tier, and how far through the listing period you are." },
        { title = "PROGRESS BAR",
          body  = "Filled = time elapsed. An offer can arrive any time\n" ..
                  "between 25% and 75% of the listing window.\n" ..
                  "Orange bar = offer is waiting for your decision." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 21:** `body = "Active loans and leases arranged through UsedPlus`

```lua
                  "Orange bar = offer is waiting for your decision." },
        { title = "FINANCE DEALS",
          body  = "Active loans and leases arranged through UsedPlus.\n" ..
                  "Shows item name, monthly payment, and remaining\n" ..
                  "balance. Manage deals in the UsedPlus finance menu." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 25:** `body = "Your farm's UsedPlus credit rating.\n" ..`

```lua
                  "balance. Manage deals in the UsedPlus finance menu." },
        { title = "CREDIT SCORE",
          body  = "Your farm's UsedPlus credit rating.\n" ..
                  "Higher score = better loan terms and lower interest." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/WeatherApp.lua`

**Line 42:** `body = "Shows the current weather at the top with a colou`

```lua
    if self:drawHelpPage("_weatherHelp", FT.APP.WEATHER, "Weather", AC, {
        { title = "CURRENT CONDITION",
          body  = "Shows the current weather at the top with a colour-coded\n" ..
                  "left edge: blue = rain, orange = storm, grey = overcast,\n" ..
                  "white = clear, dark = fog." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 46:** `body = "With FS25_WeatherGuard installed this app reads t`

```lua
                  "white = clear, dark = fog." },
        { title = "WEATHERGUARD",
          body  = "With FS25_WeatherGuard installed this app reads the shared\n" ..
                  "weather truth and a real engine forecast, not a guess." },
        { title = "WORLD WEATHER DIAL",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 49:** `body = "Real / Arid / Normal / Wet set the shared world c`

```lua
                  "weather truth and a real engine forecast, not a guess." },
        { title = "WORLD WEATHER DIAL",
          body  = "Real / Arid / Normal / Wet set the shared world climate.\n" ..
                  "Admin-only in multiplayer. Matches Soil Fertilizer." },
        { title = "TEMPERATURE",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 52:** `body = "Air temperature in Celsius with a feel label: Fre`

```lua
                  "Admin-only in multiplayer. Matches Soil Fertilizer." },
        { title = "TEMPERATURE",
          body  = "Air temperature in Celsius with a feel label: Freezing (<0)\n" ..
                  "Cold (<8)  Cool (<16)  Mild (<24)  Warm (<32)  Hot (32+)." },
        { title = "OTHER READINGS",
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 55:** `body = "Cloud cover: 0-19% Clear, 20-39% Partly, 40-69% M`

```lua
                  "Cold (<8)  Cool (<16)  Mild (<24)  Warm (<32)  Hot (32+)." },
        { title = "OTHER READINGS",
          body  = "Cloud cover: 0-19% Clear, 20-39% Partly, 40-69% Mostly,\n" ..
                  "70%+ Overcast. Wind: km/h plus compass direction.\n" ..
                  "Precipitation: rain or storm intensity as a fill bar." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 59:** `body = "With WeatherGuard: real outlook, rain shown as in`

```lua
                  "Precipitation: rain or storm intensity as a fill bar." },
        { title = "FORECAST",
          body  = "With WeatherGuard: real outlook, rain shown as intensity.\n" ..
                  "Without it: a projected estimate showing rain chance." },
    }) then return end
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

### `src/apps/WorkshopApp.lua`

**Line 29:** `body = "Any vehicle within 35 metres appears automaticall`

```lua
    if self:drawHelpPage("_workshopHelp", FT.APP.WORKSHOP, "Workshop", AC, {
        { title = "NEARBY VEHICLES",
          body  = "Any vehicle within 35 metres appears automatically.\n" ..
                  "Walk closer to a machine to see it in the list.\n" ..
                  "Up to 6 vehicles are shown at a time." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 33:** `body = "Click SELECT on a vehicle to pin its diagnostics `

```lua
                  "Up to 6 vehicles are shown at a time." },
        { title = "SELECT / UNPIN",
          body  = "Click SELECT on a vehicle to pin its diagnostics in\n" ..
                  "the panel below. Pinned vehicles stay visible even\n" ..
                  "when you walk away. Click UNPIN to release it." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 37:** `body = "Shows current fuel level, litres remaining, and t`

```lua
                  "when you walk away. Click UNPIN to release it." },
        { title = "FUEL BAR",
          body  = "Shows current fuel level, litres remaining, and tank\n" ..
                  "capacity (e.g. 78%  (390L / 500L)).\n" ..
                  "Green >= 50%  |  Yellow >= 20%  |  Red < 20%." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 41:** `body = "Component wear as a percentage (0% = new, 100% = `

```lua
                  "Green >= 50%  |  Yellow >= 20%  |  Red < 20%." },
        { title = "WEAR BAR",
          body  = "Component wear as a percentage (0% = new, 100% = worn).\n" ..
                  "Green <= 30%  |  Yellow <= 65%  |  Red > 65%.\n" ..
                  "High wear reduces vehicle efficiency and can cause\n" ..
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 46:** `body = "Only shown when a workshop placeable is on your f`

```lua
                  "breakdowns — repair before reaching 80%." },
        { title = "REPAIR BUTTON",
          body  = "Only shown when a workshop placeable is on your farm\n" ..
                  "and the selected vehicle has more than 2% wear.\n" ..
                  "Click to instantly restore the vehicle to new condition." },
```

**Issue:** Variable `body` is assigned without `local` keyword.
**Fix:** Add `local body` before first use, or add `local` to this line.

---

**Line 197:** `onClick = function()`

```lua
        y = y - FT.py(8)
        local _, repairBtn = self:drawButton(y, "REPAIR VEHICLE", FT.C.BTN_PRIMARY, {
                onClick = function()
                    local ws = workshops[1]
                    local repaired = false
```

**Issue:** Variable `onClick` is assigned without `local` keyword.
**Fix:** Add `local onClick` before first use, or add `local` to this line.

---

### `src/integrations/FTMasterHUDBridge.lua`

**Line 40:** `isFullscreen = function()`

```lua
            -- other companion HUD stands down. Optional on MasterHUD's side, so an
            -- older MasterHUD simply ignores it and behaves exactly as before.
            isFullscreen = function()
                return ui.isOpen == true
            end,
```

**Issue:** Variable `isFullscreen` is assigned without `local` keyword.
**Fix:** Add `local isFullscreen` before first use, or add `local` to this line.

---

### `src/settings/Settings.lua`

**Line 31:** `saveImmediately = saveImmediately ~= false`

```lua

function Settings:resetToDefaults(saveImmediately)
    saveImmediately = saveImmediately ~= false

    self.enabled                 = true
```

**Issue:** Variable `saveImmediately` is assigned without `local` keyword.
**Fix:** Add `local saveImmediately` before first use, or add `local` to this line.

---

### `src/settings/SettingsUI.lua`

**Line 195:** `callback = function()`

```lua
            inputAction = InputAction.MENU_EXTRA_1, -- X button
            text = g_i18n:getText("ft_ui_reset") or "Reset Settings",
            callback = function()
                if g_FarmTablet and g_FarmTablet.settings then
                    g_FarmTablet.settings:resetToDefaults()
```

**Issue:** Variable `callback` is assigned without `local` keyword.
**Fix:** Add `local callback` before first use, or add `local` to this line.

---

### `src/ui/Icons.lua`

**Line 90:** `scale = scale or 1.0`

```lua
--- Returns true if the fallback tile was used (caller should draw a monogram).
function FT_Icons.renderIcon(appId, x, y, size, scale, alpha)
    scale = scale or 1.0
    alpha = alpha or 1.0
    local ov, isFallback = FT_Icons.getAppOverlay(appId)
```

**Issue:** Variable `scale` is assigned without `local` keyword.
**Fix:** Add `local scale` before first use, or add `local` to this line.

---

**Line 91:** `alpha = alpha or 1.0`

```lua
function FT_Icons.renderIcon(appId, x, y, size, scale, alpha)
    scale = scale or 1.0
    alpha = alpha or 1.0
    local ov, isFallback = FT_Icons.getAppOverlay(appId)
    if ov == nil then return isFallback end
```

**Issue:** Variable `alpha` is assigned without `local` keyword.
**Fix:** Add `local alpha` before first use, or add `local` to this line.

---

### `src/ui/LockScreen.lua`

**Line 95:** `dateStr = tostring(FT.l10nAuto(seasonStr)) .. "  -  Tag " ..`

```lua
        local ok, dateStr = pcall(string.format, fmt, FT.l10nAuto(seasonStr), tonumber(world.day) or 1)
        if not ok then
            dateStr = tostring(FT.l10nAuto(seasonStr)) .. "  -  Tag " .. tostring(world.day or 1)
        end
        r:appText(cx, clockY - FT.py(26), FT.FONT.SMALL, dateStr, RenderText.ALIGN_CENTER, {0.85,0.88,0.92,0.9})
```

**Issue:** Variable `dateStr` is assigned without `local` keyword.
**Fix:** Add `local dateStr` before first use, or add `local` to this line.

---

### `src/utils/DataProvider.lua`

**Line 126:** `isOnline = isOnline ~= false`

```lua

function FT_DataProvider:setNetworkOnline(isOnline)
    isOnline = isOnline ~= false
    if self._networkOnline ~= isOnline then
        if isOnline == false then
```

**Issue:** Variable `isOnline` is assigned without `local` keyword.
**Fix:** Add `local isOnline` before first use, or add `local` to this line.

---

**Line 826:** `radiusM = radiusM or 20`

```lua

function FT_DataProvider:getNearbyVehicles(radiusM)
    radiusM = radiusM or 20

    local px, py, pz
```

**Issue:** Variable `radiusM` is assigned without `local` keyword.
**Fix:** Add `local radiusM` before first use, or add `local` to this line.

---

### `src/utils/Renderer.lua`

**Line 204:** `str = tostring(str or "")`

```lua
--- Truncate a string to maxLen characters with an ellipsis.
function FT_Renderer.truncate(str, maxLen)
    str = tostring(str or "")
    maxLen = tonumber(maxLen) or 20
    if #str <= maxLen then return str end
```

**Issue:** Variable `str` is assigned without `local` keyword.
**Fix:** Add `local str` before first use, or add `local` to this line.

---

**Line 205:** `maxLen = tonumber(maxLen) or 20`

```lua
function FT_Renderer.truncate(str, maxLen)
    str = tostring(str or "")
    maxLen = tonumber(maxLen) or 20
    if #str <= maxLen then return str end
    return str:sub(1, math.max(1, maxLen - 1)) .. "…"
```

**Issue:** Variable `maxLen` is assigned without `local` keyword.
**Fix:** Add `local maxLen` before first use, or add `local` to this line.

---

## Summary & Recommendations

### Pattern Analysis

**Most common leaked variable names:**

- `body`: 121 occurrences
- `onClick`: 35 occurrences
- `_view`: 10 occurrences
- `freq`: 4 occurrences
- `_dashView`: 3 occurrences
- `y`: 3 occurrences
- `appId`: 3 occurrences
- `providerId`: 3 occurrences
- `_selFieldIdx`: 2 occurrences
- `_selVehicleIdx`: 2 occurrences
- `_selTaskIdx`: 2 occurrences
- `_vitalFocus`: 2 occurrences
- `_statusMsg`: 2 occurrences
- `_statusTimer`: 2 occurrences
- `_templateIdx`: 2 occurrences

### General Recommendations

1. **Add `local` keyword** to all variable declarations
2. **For loop counters**: Use `for i = 1, n do` (implicit local) or `local i; for i = ...`
3. **For calculations**: Declare temps as `local score = 0` at function start
4. **Review HIGH severity** items first - these are most likely to cause bugs
5. **Test thoroughly** after fixes - global leaks can have subtle effects

### Impact of Global Leaks

Global variables in Lua can cause:
- **Cross-contamination**: Variable values leak between function calls
- **Multiplayer bugs**: Server/client state corruption
- **Hard-to-debug issues**: Values mysteriously changing
- **Performance**: Global table lookups are slower than locals

### Known Safe Patterns (Excluded from Report)

- Class definitions: `MyClass = {}` at top level
- Intentional globals: `g_myGlobal = ...`
- Self/spec references: `self.field = ...`, `spec.field = ...`
- Table field assignments: `myTable.field = ...`
- Local variable modifications: `score = score + 10` (if `local score` was declared earlier)
- Table initializations: Lines ending with `,` or `},`

