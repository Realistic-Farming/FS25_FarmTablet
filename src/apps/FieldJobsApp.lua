-- =========================================================
-- FarmTablet v2 – Field Jobs App
-- Start/stop field work sessions and review job history.
-- =========================================================


local function FJText(key, fallback)
    if FT_UI_TEXT ~= nil then return FT_UI_TEXT(key, fallback) end
    if g_i18n and key and g_i18n:hasText(key) then return g_i18n:getText(key) end
    return fallback or tostring(key or "")
end

--- A localized string that carries placeholders, interpolated AFTER the lookup.
--- A bare FJText lookup returns the template with its %s and %d intact, so a
--- caller that forgets to format draws a raw template at the player.
---
--- The pcall is not defensive padding. These templates are translated into 26
--- locale files by hand, and a translator who drops a %s, adds one, or swaps %d
--- for %s produces a string.format error inside a draw call, which is a crash in
--- the middle of a frame rather than a wrong word. When a locale's arity does not
--- match what the caller supplied, this falls back to the English template and
--- formats that instead, so the worst case is one line in English.
local function FJFormat(key, fallbackFmt, ...)
    local template = FJText(key, fallbackFmt)
    local ok, out = pcall(string.format, template, ...)
    if ok then return out end
    local okFallback, fallbackOut = pcall(string.format, fallbackFmt, ...)
    if okFallback then return fallbackOut end
    return fallbackFmt
end

--- A localized MULTI-LINE string.
---
--- drawHelpPage splits a body on real newline characters and does not wrap
--- (FarmTabletUI.lua:3151). The engine never expands an escape in a locale
--- value, and the LOAD path is the half that proves it: I18N:loadEntriesFromXML
--- at I18N.lua:99 performs exactly ONE transformation on a loaded string,
--- string.gsub(text, CR-LF, LF), which is line-ending normalisation and nothing
--- else. I18N:getText at :175-187 is then a bare table lookup. So a "\n" written in a translation file arrives here as the two
--- characters backslash and n, not as a line break. Nothing else in these 26
--- files uses one, so this is the first.
---
--- Rather than mint one key per LINE, which would have turned four help bodies
--- into thirteen keys across 26 files, a body is one key whose translation uses
--- "\n" between lines and this converts them. A translator sees one coherent
--- paragraph, and the English fallbacks below can keep real newlines because the
--- conversion is a no-op on them.
local function FJLines(key, fallbackFmt, ...)
    local out = FJFormat(key, fallbackFmt, ...)
    return (out:gsub("\\n", "\n"))
end

-- ── Module state ──────────────────────────────────────────

local _activeJob   = nil   -- { fieldId, fieldName, vehicleName, taskType, startTime, startDay }
local _jobHistory  = {}    -- array of completed job records
local _view        = "home"  -- "home" | "start" | "history"

-- App-bar Back: return to the app's home view from a sub-view first.
FarmTabletUI:registerBackHandler("field_jobs", function()
    if _view ~= "home" then
        _view = "home"
        return true
    end
    return false
end)

-- Fields & vehicles cached at view open to avoid per-frame queries
local _cachedFields   = nil
local _cachedVehicles = nil
local _fieldScroll    = 0
local _histScroll     = 0

-- Selection state for the "start job" view
local _selFieldIdx   = 1
local _selVehicleIdx = 1
local _selTaskIdx    = 1

local TASK_TYPES = {
    "Plowing / Cultivating",
    "Sowing / Planting",
    "Fertilizing",
    "Spraying",
    "Harvesting",
    "Mowing / Cutting",
    "Baling",
    "Rolling",
    "Stone Picking",
    "General Work",
}

-- ── Persistence ───────────────────────────────────────────

local function _savePath()
    if g_currentMission
    and g_currentMission.missionInfo
    and g_currentMission.missionInfo.savegameDirectory then
        return g_currentMission.missionInfo.savegameDirectory
               .. "/farm_tablet_field_jobs.xml"
    end
    return nil
end

local function _saveJobs()
    local path = _savePath()
    if not path then return end

    local xml = XMLFile.create("FTJobs", path, "farmTabletJobs")
    if not xml then return end

    -- Save active job
    if _activeJob then
        xml:setBool("farmTabletJobs#hasActive", true)
        xml:setInt   ("farmTabletJobs.active#fieldId",    _activeJob.fieldId   or 0)
        xml:setString("farmTabletJobs.active#fieldName",  _activeJob.fieldName  or "")
        xml:setString("farmTabletJobs.active#vehicleName",_activeJob.vehicleName or "")
        xml:setString("farmTabletJobs.active#taskType",   _activeJob.taskType   or "")
        xml:setInt   ("farmTabletJobs.active#startTime",  _activeJob.startTime  or 0)
        xml:setInt   ("farmTabletJobs.active#startDay",   _activeJob.startDay   or 0)
    else
        xml:setBool("farmTabletJobs#hasActive", false)
    end

    -- Save history (keep last 30)
    local limit = math.min(#_jobHistory, 30)
    xml:setInt("farmTabletJobs#count", limit)
    for i = 1, limit do
        local j   = _jobHistory[i]
        local key = string.format("farmTabletJobs.job(%d)", i - 1)
        xml:setInt   (key .. "#fieldId",      j.fieldId      or 0)
        xml:setString(key .. "#fieldName",    j.fieldName    or "")
        xml:setString(key .. "#vehicleName",  j.vehicleName  or "")
        xml:setString(key .. "#taskType",     j.taskType     or "")
        xml:setInt   (key .. "#startTime",    j.startTime    or 0)
        xml:setInt   (key .. "#startDay",     j.startDay     or 0)
        xml:setInt   (key .. "#endTime",      j.endTime      or 0)
        xml:setInt   (key .. "#endDay",       j.endDay       or 0)
        xml:setInt   (key .. "#durationMins", j.durationMins or 0)
    end

    xml:save()
    xml:delete()
end

local function _loadJobs()
    local path = _savePath()
    if not path then return end

    local xml = XMLFile.load("FTJobs", path)
    if not xml then return end

    -- Active job
    local hasActive = xml:getBool("farmTabletJobs#hasActive", false)
    if hasActive then
        _activeJob = {
            fieldId     = xml:getInt   ("farmTabletJobs.active#fieldId",     0),
            fieldName   = xml:getString("farmTabletJobs.active#fieldName",   ""),
            vehicleName = xml:getString("farmTabletJobs.active#vehicleName", ""),
            taskType    = xml:getString("farmTabletJobs.active#taskType",    ""),
            startTime   = xml:getInt   ("farmTabletJobs.active#startTime",   0),
            startDay    = xml:getInt   ("farmTabletJobs.active#startDay",    0),
        }
    end

    -- History
    local count = xml:getInt("farmTabletJobs#count", 0)
    for i = 1, count do
        local key = string.format("farmTabletJobs.job(%d)", i - 1)
        table.insert(_jobHistory, {
            fieldId     = xml:getInt   (key .. "#fieldId",      0),
            fieldName   = xml:getString(key .. "#fieldName",    ""),
            vehicleName = xml:getString(key .. "#vehicleName",  ""),
            taskType    = xml:getString(key .. "#taskType",     ""),
            startTime   = xml:getInt   (key .. "#startTime",    0),
            startDay    = xml:getInt   (key .. "#startDay",     0),
            endTime     = xml:getInt   (key .. "#endTime",      0),
            endDay      = xml:getInt   (key .. "#endDay",       0),
            durationMins= xml:getInt   (key .. "#durationMins", 0),
        })
    end

    xml:delete()
end

-- Load saved data once at startup
_loadJobs()

-- ── Helpers ───────────────────────────────────────────────

local function _gameMinutes()
    if g_currentMission and g_currentMission.environment then
        local env = g_currentMission.environment
        local dayTime = env.dayTime or 0   -- ms within day
        local day     = env.currentDay or 1
        return day * 1440 + math.floor(dayTime / 60000)
    end
    return 0
end

local function _gameDay()
    if g_currentMission and g_currentMission.environment then
        return g_currentMission.environment.currentDay or 1
    end
    return 1
end

local function _gameTimeStr(totalMins)
    local mins = totalMins % 1440
    local h = math.floor(mins / 60)
    local m = mins % 60
    return string.format("%02d:%02d", h, m)
end

local function _durationStr(mins)
    if mins < 60 then
        return mins .. "m"
    else
        local h = math.floor(mins / 60)
        local m = mins % 60
        if m == 0 then
            return h .. "h"
        end
        return h .. "h " .. m .. "m"
    end
end

local function _truncate(s, n)
    if FT.utf8Len(s) > n then return FT.utf8Sub(s, n - 2) .. ".." end
    return s
end

local function _getFarmVehicles(farmId)
    local out = {}
    local vehicles = g_currentMission
        and g_currentMission.vehicleSystem
        and g_currentMission.vehicleSystem.vehicles
    if not vehicles then return out end
    for _, v in pairs(vehicles) do
        if v.spec_motorized and v.getOwnerFarmId and v:getOwnerFarmId() == farmId then
            local name = (v.getFullName and v:getFullName())
                      or v.configFileName or "Unknown"
            -- Strip long paths
            name = name:match("([^/\\]+)$") or name
            table.insert(out, name)
        end
    end
    table.sort(out)
    -- Deduplicate
    local seen = {}
    local deduped = {}
    for _, n in ipairs(out) do
        if not seen[n] then
            seen[n] = true
            table.insert(deduped, n)
        end
    end
    return deduped
end

local function _startJob(fieldName, fieldId, vehicleName, taskType)
    _activeJob = {
        fieldId     = fieldId,
        fieldName   = fieldName,
        vehicleName = vehicleName,
        taskType    = taskType,
        startTime   = _gameMinutes(),
        startDay    = _gameDay(),
    }
    _saveJobs()
end

local function _finishJob()
    if not _activeJob then return end
    local nowMins = _gameMinutes()
    local dur = nowMins - _activeJob.startTime
    if dur < 0 then dur = 0 end

    local record = {
        fieldId      = _activeJob.fieldId,
        fieldName    = _activeJob.fieldName,
        vehicleName  = _activeJob.vehicleName,
        taskType     = _activeJob.taskType,
        startTime    = _activeJob.startTime,
        startDay     = _activeJob.startDay,
        endTime      = nowMins,
        endDay       = _gameDay(),
        durationMins = dur,
    }
    table.insert(_jobHistory, 1, record)
    if #_jobHistory > 30 then
        _jobHistory[31] = nil
    end
    _activeJob = nil
    _saveJobs()
end

-- ── App Drawer ────────────────────────────────────────────

local AC = FT.APP_COLOR["field_jobs"] or {0.30, 0.75, 1.00, 1.00}

FarmTabletUI:registerDrawer("field_jobs", function(self)
    AC = FT.appColor("field_jobs")

    -- ── Help page ───────────────────────────────────────
    -- Help names the REAL controls and says which screen each one is on, and
    -- every button name is resolved through the key that owns it rather than
    -- retyped. A second English copy of a label drifts the first time the label
    -- changes, and then help confidently points at a control that is not there.
    if self:drawHelpPage("_fieldJobsHelp", "field_jobs", "Field Jobs", AC, {
        { title = FJText("ft_fieldjobs_help_start_title", "STARTING A JOB"),
          body  = FJLines("ft_fieldjobs_help_start_body",
                    "Home screen: tap %s.\n"..
                    "New Job screen: pick field, vehicle and task,\n"..
                    "then tap %s to begin timing.",
                    FJText("ft_fieldjobs_start_job", "Start job"), FJText("ft_fieldjobs_confirm_start", "START JOB TIMER")), literalTitle = true, literalBody = true },
        { title = FJText("ft_fieldjobs_help_finish_title", "FINISHING A JOB"),
          body  = FJLines("ft_fieldjobs_help_finish_body",
                    "Home screen: tap %s when the work is done.\n"..
                    "While a job runs, %s stays disabled until you\n"..
                    "finish the current one.",
                    FJText("ft_fieldjobs_finish_job", "FINISH JOB"), FJText("ft_fieldjobs_start_job", "Start job")), literalTitle = true, literalBody = true },
        { title = FJText("ft_common_history", "History"),
          body  = FJLines("ft_fieldjobs_help_history_body",
                    "The %s button appears on the Home screen once\n"..
                    "your first job is finished. Up to 30 jobs are kept\n"..
                    "per savegame, newest first.",
                    FJText("ft_common_history", "History")), literalTitle = true, literalBody = true },
        { title = FJText("ft_fieldjobs_help_nav_title", "GETTING BACK"),
          body  = FJLines("ft_fieldjobs_help_nav_body",
                    "This help closes with its own Back button.\n"..
                    "From New Job or History, Back returns to Field\n"..
                    "Jobs Home, app bar or on-screen alike.\n"..
                    "From Home, Back leaves Field Jobs."), literalTitle = true, literalBody = true },
    }) then return end

    -- ── Route to sub-views ──────────────────────────────
    if _view == "start" then
        _drawStartView(self)
    elseif _view == "history" then
        _drawHistoryView(self)
    else
        _drawHomeView(self)
    end

    self:drawInfoIcon("_fieldJobsHelp", AC)
end)

-- ─────────────────────────────────────────────────────────
-- HOME VIEW
-- ─────────────────────────────────────────────────────────

function _drawHomeView(self)
    local subtitle = _activeJob and "1 active job" or "no active job"
    local startY = self:drawAppHeader("Field Jobs", subtitle)
    local x, contentY, cw, _ = self:contentInner()
    -- Purpose line (#141): players read "Start job" / "Confirm" as dispatching a
    -- worker. Say plainly, on the screen, that this app only times and logs jobs.
    self.r:appText(x, startY - FT.py(3), FT.FONT.TINY,
        FJText("ft_fieldjobs_purpose", "Times and logs your jobs. It doesn't send a worker."),
        RenderText.ALIGN_LEFT, FT.C.MUTED, true)
    local y = startY - FT.py(18)

    -- ── Active job card ────────────────────────────────
    if _activeJob then
        local aj = _activeJob
        local cardH = FT.py(70)

        -- Card background
        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4), cw + FT.px(8), cardH,
            {AC[1], AC[2], AC[3], 0.10})
        -- Accent left bar
        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4), FT.px(3), cardH,
            {AC[1], AC[2], AC[3], 0.85})

        -- "ACTIVE" badge
        self.r:badge(x + FT.px(8), y - FT.py(2), "ACTIVE", {AC[1]*0.6, AC[2]*0.6, AC[3]*0.6, 0.9})

        -- Task type (big label)
        self.r:appText(x + FT.px(8), y - FT.py(18),
            FT.FONT.BODY, _truncate(aj.taskType, 26),
            RenderText.ALIGN_LEFT, {AC[1], AC[2], AC[3], 1.00})

        -- Field
        self.r:appText(x + FT.px(8), y - FT.py(32),
            FT.FONT.SMALL, "Field: " .. _truncate(aj.fieldName, 22),
            RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)

        -- Vehicle
        self.r:appText(x + FT.px(8), y - FT.py(44),
            FT.FONT.SMALL, "Vehicle: " .. _truncate(aj.vehicleName, 22),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        -- Duration so far
        local elapsed = _gameMinutes() - aj.startTime
        if elapsed < 0 then elapsed = 0 end
        self.r:appText(x + FT.px(8), y - FT.py(56),
            FT.FONT.TINY,
            "Started Day " .. aj.startDay .. " at " .. _gameTimeStr(aj.startTime) ..
            "  ·  Elapsed: " .. _durationStr(elapsed),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        y = y - cardH - FT.py(8)

        -- FINISH button
        local bw = FT.px(100)
        local bh = FT.py(22)
        local finBtn = self.r:button(x, y, bw, bh,
            FJText("ft_fieldjobs_finish_job", "FINISH JOB"),
            FT.C.BTN_DANGER,
            { onClick = function()
                _finishJob()
                _view = "home"
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, finBtn)

        -- START NEW (disabled look while active)
        local sBtn = self.r:button(x + bw + FT.px(8), y, bw, bh, FT.l10nAuto("START NEW"),
            {0.18, 0.20, 0.26, 0.50},
            { onClick = function() end }, true)  -- no-op while active
        table.insert(self._contentBtns, sBtn)
        self.r:appText(x + bw + FT.px(8) + bw/2, y - FT.py(14),
            FT.FONT.TINY, "finish current first",
            RenderText.ALIGN_CENTER, FT.C.MUTED)

        y = y - bh - FT.py(14)

    else
        -- No active job — compact card with clean spacing
        local cardH = FT.py(44)
        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4), cw + FT.px(8), cardH,
            {AC[1], AC[2], AC[3], 0.08})
        self.r:appRect(x - FT.px(4), y - cardH + FT.py(4), FT.px(3), cardH,
            {AC[1], AC[2], AC[3], 0.75})
        self.r:appText(x + FT.px(10), y - FT.py(8),
            FT.FONT.SMALL, FJText("ft_fieldjobs_no_job", "No job running."),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM, true)

        local bw = FT.px(108)
        local bh = FT.py(22)
        local sBtn = self.r:button(x + FT.px(10), y - FT.py(32), bw, bh, FJText("ft_fieldjobs_start_job", "Start job"),
            FT.C.BTN_PRIMARY,
            { onClick = function()
                -- Refresh caches when entering start view
                local data   = self.system.data
                local farmId = data:getPlayerFarmId()
                _cachedFields   = data:getOwnedFields(farmId)
                _cachedVehicles = _getFarmVehicles(farmId)
                if #_cachedVehicles == 0 then
                    table.insert(_cachedVehicles, "No vehicle")
                end
                _selFieldIdx   = 1
                _selVehicleIdx = 1
                _selTaskIdx    = 1
                _view = "start"
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, sBtn)
        y = y - cardH - FT.py(14)
    end

    -- ── Divider + History preview ──────────────────────
    y = self:drawRule(y, 0.35)
    y = y - FT.py(4)

    -- History header row
    self.r:appText(x, y,
        FT.FONT.SMALL, FJText("ft_fieldjobs_recent_jobs", "Recent jobs"),
        RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT, true)

    if #_jobHistory > 0 then
        local hbw = FT.px(60)
        local hbh = FT.py(16)
        local histBtn = self.r:button(x + cw - hbw, y - FT.py(2), hbw, hbh, FJText("ft_common_history", "History"),
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _histScroll = 0
                _view = "history"
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, histBtn)
    end

    y = y - FT.py(20)

    if #_jobHistory == 0 then
        self.r:appText(x, y, FT.FONT.SMALL,
            FJText("ft_fieldjobs_no_completed", "No completed jobs yet."),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
    else
        -- Show last 4 entries as a mini-list
        local rowH  = FT.py(19)
        local minY  = contentY + FT.py(4)
        local limit = math.min(4, #_jobHistory)
        for i = 1, limit do
            if y < minY then break end
            local j = _jobHistory[i]
            if i % 2 == 0 then
                self.r:appRect(x - FT.px(4), y - FT.py(4),
                    cw + FT.px(8), rowH, {0.09, 0.11, 0.16, 0.50})
            end
            -- Task badge dot
            self.r:appRect(x + FT.px(2), y + FT.py(4),
                FT.px(5), FT.py(5), {AC[1], AC[2], AC[3], 0.70})
            self.r:appText(x + FT.px(12), y,
                FT.FONT.SMALL, _truncate(j.taskType, 16),
                RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)
            self.r:appText(x + cw * 0.44, y,
                FT.FONT.SMALL, _truncate(j.fieldName, 12),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            self.r:appText(x + cw * 0.72, y,
                FT.FONT.SMALL, _truncate(j.vehicleName, 12),
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            self.r:appText(x + cw, y,
                FT.FONT.TINY, _durationStr(j.durationMins),
                RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
            y = y - rowH
        end

        if #_jobHistory > 4 then
            self.r:appText(x + cw / 2, minY,
                FT.FONT.TINY,
                FJFormat("ft_fieldjobs_history_more", "+%d more, tap %s",
                    #_jobHistory - 4, FJText("ft_common_history", "History")),
                RenderText.ALIGN_CENTER, FT.C.MUTED, true)
        end
    end
end

-- ─────────────────────────────────────────────────────────
-- START JOB VIEW
-- ─────────────────────────────────────────────────────────

function _drawStartView(self)
    local startY = self:drawAppHeader("Field Jobs", "New Job")
    local x, contentY, cw, _ = self:contentInner()
    local y = startY - FT.py(4)

    -- BACK button
    local backBw = FT.px(52)
    local backBh = FT.py(18)
    local backBtn = self.r:button(x + cw - backBw, y, backBw, backBh, FT.l10nAuto("< BACK"),
        FT.C.BTN_NEUTRAL,
        { onClick = function()
            _view = "home"
            self:switchApp("field_jobs")
        end }, true)
    table.insert(self._contentBtns, backBtn)

    -- Purpose line (#141), on the START view. Home already carries this one, but
    -- the farmer makes the decision HERE, looking at a control that says START,
    -- and the approved restore put the explanation at the choice.
    --
    -- IT SITS ON THE BACK BUTTON'S OWN ROW, to its left, and that is deliberate
    -- rather than tidy. This view ends in a confirmation that only draws while
    -- y > contentY + FT.py(28), so every unit of height added above it eats that
    -- margin, and a purpose line that pushed the only confirmation off screen
    -- would be a worse bug than the one being fixed. Drawn on a row that already
    -- exists it costs ZERO vertical space, so the gate is arithmetically
    -- untouched. Same key as Home, so there is one sentence to translate and the
    -- two screens cannot drift apart.
    --
    -- Width is the one thing a source read cannot settle: this shares a row with
    -- a fixed-width button, so a long translation may need the smaller glyph or
    -- a different slot. That is Wizard's layout call, not a reason to withhold
    -- the explanation.
    self.r:appText(x, y + backBh / 2 - FT.py(3), FT.FONT.TINY,
        FJText("ft_fieldjobs_purpose", "Times and logs your jobs. It doesn't send a worker."),
        RenderText.ALIGN_LEFT, FT.C.MUTED, true)

    y = y - FT.py(24)

    local fields   = _cachedFields   or {}
    local vehicles = _cachedVehicles or {"No vehicle"}

    -- Clamp indices
    if _selFieldIdx   < 1 then _selFieldIdx   = 1 end
    if _selFieldIdx   > math.max(1,#fields)   then _selFieldIdx   = math.max(1,#fields)   end
    if _selVehicleIdx < 1 then _selVehicleIdx = 1 end
    if _selVehicleIdx > math.max(1,#vehicles) then _selVehicleIdx = math.max(1,#vehicles) end
    if _selTaskIdx    < 1 then _selTaskIdx    = 1 end
    if _selTaskIdx    > #TASK_TYPES           then _selTaskIdx    = #TASK_TYPES           end

    -- ── Section: Field ───────────────────────────────
    self.r:sectionHeader(x, y, cw, "FIELD")
    y = y - FT.py(20)

    if #fields == 0 then
        self.r:appText(x, y, FT.FONT.SMALL, "You don't own any fields.",
            RenderText.ALIGN_LEFT, FT.C.MUTED)
        y = y - FT.py(18)
    else
        local arrowW = FT.px(22)
        local arrowH = FT.py(20)
        local selW   = cw - arrowW * 2 - FT.px(4)
        local field  = fields[_selFieldIdx]
        local label
        if field ~= nil then
            label = FJFormat("ft_fieldjobs_field_label", "Field %s, %s",
                tostring(field.id or "?"), _truncate(field.cropName or "Empty", 18))
        else
            -- Was a bare em dash, which tells a player nothing and reads as a
            -- rendering fault rather than as "there is no field here".
            --
            -- WHEN THIS BRANCH ACTUALLY FIRES, because it is easy to mistake for
            -- the empty-farm case and I did: a farm with NO fields is caught above
            -- by `#fields == 0` and shows "You don't own any fields." This is the
            -- other thing entirely, #fields > 0 but fields[_selFieldIdx] resolving
            -- to nil, which is a data gap rather than a farm state. Note that
            -- canStart is (#fields > 0), so the confirm button is ENABLED here.
            -- So the string must stay a neutral signal and must NOT advise buying
            -- land: the player already owns some.
            label = FJText("ft_fieldjobs_no_field", "No field")
        end

        -- Left arrow
        local lBtn = self.r:button(x, y, arrowW, arrowH, "<", FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selFieldIdx = _selFieldIdx - 1
                if _selFieldIdx < 1 then _selFieldIdx = #fields end
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, lBtn)

        -- Field display
        self.r:appRect(x + arrowW + FT.px(2), y, selW - FT.px(4), arrowH, {0.09,0.11,0.15,0.80})
        self.r:appText(x + arrowW + selW/2, y + arrowH/2 - FT.py(3),
            FT.FONT.SMALL, label, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)

        -- Right arrow
        local rBtn = self.r:button(x + arrowW + selW + FT.px(4), y, arrowW, arrowH, ">",
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selFieldIdx = _selFieldIdx + 1
                if _selFieldIdx > #fields then _selFieldIdx = 1 end
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, rBtn)

        y = y - arrowH - FT.py(6)

        -- Field detail line
        if field then
            local detail = "Area: " .. string.format("%.1f", field.area or 0) .. " ha"
                         .. "   State: " .. (field.stateName or "Unknown")
            self.r:appText(x, y, FT.FONT.TINY, detail,
                RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)
            y = y - FT.py(14)
        end
    end

    y = y - FT.py(4)

    -- ── Section: Vehicle ────────────────────────────
    self.r:sectionHeader(x, y, cw, "VEHICLE")
    y = y - FT.py(20)

    do
        local arrowW = FT.px(22)
        local arrowH = FT.py(20)
        local selW   = cw - arrowW * 2 - FT.px(4)
        local vname  = vehicles[_selVehicleIdx] or "No vehicle"

        local lBtn = self.r:button(x, y, arrowW, arrowH, "<", FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selVehicleIdx = _selVehicleIdx - 1
                if _selVehicleIdx < 1 then _selVehicleIdx = #vehicles end
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, lBtn)

        self.r:appRect(x + arrowW + FT.px(2), y, selW - FT.px(4), arrowH, {0.09,0.11,0.15,0.80})
        self.r:appText(x + arrowW + selW/2, y + arrowH/2 - FT.py(3),
            FT.FONT.SMALL, _truncate(vname, 30), RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)

        local rBtn = self.r:button(x + arrowW + selW + FT.px(4), y, arrowW, arrowH, ">",
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selVehicleIdx = _selVehicleIdx + 1
                if _selVehicleIdx > #vehicles then _selVehicleIdx = 1 end
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, rBtn)

        y = y - arrowH - FT.py(10)
    end

    -- ── Section: Task Type ───────────────────────────
    self.r:sectionHeader(x, y, cw, "TASK")
    y = y - FT.py(20)

    do
        local arrowW = FT.px(22)
        local arrowH = FT.py(20)
        local selW   = cw - arrowW * 2 - FT.px(4)
        local task   = TASK_TYPES[_selTaskIdx] or "General Work"

        local lBtn = self.r:button(x, y, arrowW, arrowH, "<", FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selTaskIdx = _selTaskIdx - 1
                if _selTaskIdx < 1 then _selTaskIdx = #TASK_TYPES end
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, lBtn)

        self.r:appRect(x + arrowW + FT.px(2), y, selW - FT.px(4), arrowH,
            {AC[1]*0.15, AC[2]*0.15, AC[3]*0.15, 0.90})
        self.r:appText(x + arrowW + selW/2, y + arrowH/2 - FT.py(3),
            FT.FONT.SMALL, task, RenderText.ALIGN_CENTER, {AC[1], AC[2], AC[3], 1.00})

        local rBtn = self.r:button(x + arrowW + selW + FT.px(4), y, arrowW, arrowH, ">",
            FT.C.BTN_NEUTRAL,
            { onClick = function()
                _selTaskIdx = _selTaskIdx + 1
                if _selTaskIdx > #TASK_TYPES then _selTaskIdx = 1 end
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, rBtn)

        y = y - arrowH - FT.py(10)
    end

    -- ── CONFIRM button ────────────────────────────────
    if y > contentY + FT.py(28) then
        y = self:drawRule(y, 0.35)
        y = y - FT.py(6)

        local canStart = (#fields > 0)
        local bw = FT.px(130)
        local bh = FT.py(24)
        local color = canStart and FT.C.BTN_PRIMARY or {0.18, 0.20, 0.26, 0.50}

        local confirmBtn = self.r:button(x + (cw - bw) / 2, y, bw, bh,
            FJText("ft_fieldjobs_confirm_start", "START JOB TIMER"),
            color,
            { onClick = function()
                if not canStart then return end
                local field = fields[_selFieldIdx]
                local fname = field and ("Field " .. (field.id or "?")) or "Unknown"
                local fid   = field and (field.id or 0) or 0
                local vname = (_cachedVehicles or {})[_selVehicleIdx] or "Unknown"
                local task  = TASK_TYPES[_selTaskIdx] or "General Work"
                _startJob(fname, fid, vname, task)
                _view = "home"
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, confirmBtn)
    end
end

-- ─────────────────────────────────────────────────────────
-- HISTORY VIEW
-- ─────────────────────────────────────────────────────────

function _drawHistoryView(self)
    local subtitle = #_jobHistory .. " job" .. (#_jobHistory ~= 1 and "s" or "")
    local startY = self:drawAppHeader("Field Jobs", "History · " .. subtitle)
    local x, contentY, cw, _ = self:contentInner()
    local y = startY - FT.py(4)

    -- BACK + CLEAR buttons
    local backBw = FT.px(52)
    local backBh = FT.py(18)
    local backBtn = self.r:button(x + cw - backBw, y, backBw, backBh, FT.l10nAuto("< BACK"),
        FT.C.BTN_NEUTRAL,
        { onClick = function()
            _view = "home"
            self:switchApp("field_jobs")
        end }, true)
    table.insert(self._contentBtns, backBtn)

    if #_jobHistory > 0 then
        local clrBtn = self.r:button(x, y, backBw, backBh, FT.l10nAuto("CLEAR"),
            FT.C.BTN_DANGER,
            { onClick = function()
                _jobHistory = {}
                _saveJobs()
                self:switchApp("field_jobs")
            end }, true)
        table.insert(self._contentBtns, clrBtn)
    end

    y = y - FT.py(24)

    if #_jobHistory == 0 then
        self.r:appText(x, y, FT.FONT.BODY, FJText("ft_fieldjobs_no_completed", "No completed jobs yet."),
            RenderText.ALIGN_LEFT, FT.C.MUTED, true)
        return
    end

    -- Column headers
    self.r:appText(x,              y, FT.FONT.TINY, "TASK",    RenderText.ALIGN_LEFT,  FT.C.TEXT_DIM)
    self.r:appText(x + cw * 0.32,  y, FT.FONT.TINY, "FIELD",   RenderText.ALIGN_LEFT,  FT.C.TEXT_DIM)
    self.r:appText(x + cw * 0.56,  y, FT.FONT.TINY, "VEHICLE", RenderText.ALIGN_LEFT,  FT.C.TEXT_DIM)
    self.r:appText(x + cw * 0.82,  y, FT.FONT.TINY, "DAY",     RenderText.ALIGN_LEFT,  FT.C.TEXT_DIM)
    self.r:appText(x + cw,         y, FT.FONT.TINY, "DUR",     RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
    y = y - FT.py(16)

    local rowH  = FT.py(20)
    local minY  = contentY + FT.py(6)
    local scrollY = self:getContentScrollY()
    y = y + scrollY

    for i, j in ipairs(_jobHistory) do
        if y < minY then break end

        -- Alternating row bg
        if i % 2 == 0 then
            self.r:appRect(x - FT.px(4), y - FT.py(4),
                cw + FT.px(8), rowH, {0.09, 0.11, 0.16, 0.50})
        end

        -- Accent dot
        self.r:appRect(x + FT.px(1), y + FT.py(4), FT.px(4), FT.py(4),
            {AC[1], AC[2], AC[3], 0.65})

        self.r:appText(x + FT.px(10), y,
            FT.FONT.SMALL, _truncate(j.taskType, 14),
            RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)

        self.r:appText(x + cw * 0.32, y,
            FT.FONT.SMALL, _truncate(j.fieldName, 10),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        self.r:appText(x + cw * 0.56, y,
            FT.FONT.SMALL, _truncate(j.vehicleName, 10),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        self.r:appText(x + cw * 0.82, y,
            FT.FONT.TINY, "Day " .. (j.startDay or "?"),
            RenderText.ALIGN_LEFT, FT.C.TEXT_DIM)

        self.r:appText(x + cw, y,
            FT.FONT.SMALL, _durationStr(j.durationMins),
            RenderText.ALIGN_RIGHT, FT.C.TEXT_ACCENT)

        y = y - rowH
    end

    -- Enable scroll wheel and scroll bar for long history lists
    self:setContentHeight(startY - y + scrollY)
    self:drawScrollBar()
end