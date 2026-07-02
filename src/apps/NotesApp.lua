-- =========================================================
-- FarmTablet v2 – Notes App
-- Checkbox-style todo list saved per savegame.
-- =========================================================

-- ── Module state ──────────────────────────────────────────

local _todos        = {}   -- {text=string, done=bool}
local _templateIdx  = 1
local _fieldIdx     = 0    -- 0 = "Any field"; >0 = index into _ownedFieldNums

local TEMPLATES = {
    { key = "ft_notes_template_harvest", fallback = "Harvest crops" },
    { key = "ft_notes_template_sow", fallback = "Sow seeds" },
    { key = "ft_notes_template_fertilize", fallback = "Apply fertilizer" },
    { key = "ft_notes_template_plow", fallback = "Plow / cultivate" },
    { key = "ft_notes_template_spray", fallback = "Spray fields" },
    { key = "ft_notes_template_sell", fallback = "Sell crops" },
    { key = "ft_notes_template_refuel", fallback = "Refuel vehicles" },
    { key = "ft_notes_template_repair", fallback = "Repair vehicles" },
    { key = "ft_notes_template_feed", fallback = "Feed animals" },
    { key = "ft_notes_template_clean", fallback = "Clean animal pens" },
    { key = "ft_notes_template_mow", fallback = "Mow grass" },
    { key = "ft_notes_template_bale", fallback = "Bale hay / straw" },
    { key = "ft_notes_template_collect_bales", fallback = "Collect bales" },
    { key = "ft_notes_template_contracts", fallback = "Check contracts" },
    { key = "ft_notes_template_shop", fallback = "Visit shop" },
    { key = "ft_notes_template_collect_prod", fallback = "Collect productions" },
    { key = "ft_notes_template_buy", fallback = "Buy equipment" },
    { key = "ft_notes_template_water", fallback = "Water crops" },
    { key = "ft_notes_template_weather", fallback = "Check weather" },
    { key = "ft_notes_template_field_maint", fallback = "Field maintenance" },
}

local function N(key, fallback)
    if FT_UI_TEXT ~= nil then return FT_UI_TEXT(key, fallback) end
    if g_i18n and key and g_i18n:hasText(key) then return g_i18n:getText(key) end
    return fallback or tostring(key or "")
end

local function templateText(idx)
    local t = TEMPLATES[idx] or TEMPLATES[1]
    if type(t) == "table" then return N(t.key, t.fallback) end
    return tostring(t or "---")
end

-- ── Owned field helper ───────────────────────────────────

local function notes_getOwnedFieldNums()
    local result = {}
    if not g_localPlayer or not g_farmlandManager or not g_fieldManager then
        return result
    end
    local farmId = g_localPlayer.farmId
    if not farmId then return result end
    local farmlandIds = g_farmlandManager:getOwnedFarmlandIdsByFarmId(farmId)
    for _, farmlandId in ipairs(farmlandIds) do
        local field = g_fieldManager.farmlandIdFieldMapping[farmlandId]
        if field then
            local fid = field:getId()
            if fid then
                table.insert(result, fid)
            end
        end
    end
    table.sort(result)
    return result
end

-- ── Save / Load ───────────────────────────────────────────

local function notes_getSavePath()
    if g_currentMission
    and g_currentMission.missionInfo
    and g_currentMission.missionInfo.savegameDirectory then
        return g_currentMission.missionInfo.savegameDirectory
               .. "/farm_tablet_notes.xml"
    end
    return nil
end

local function notes_save()
    local path = notes_getSavePath()
    if not path then return end
    local xml = XMLFile.create("FTNotes", path, "farmTabletNotes")
    if not xml then return end
    xml:setInt("farmTabletNotes#count", #_todos)
    for i, todo in ipairs(_todos) do
        local key = string.format("farmTabletNotes.item(%d)", i - 1)
        xml:setString(key .. "#text", todo.text or "")
        xml:setBool(key .. "#done",   todo.done or false)
    end
    xml:save()
    xml:delete()
end

local function notes_load()
    local path = notes_getSavePath()
    if not path or not fileExists(path) then return end
    local xml = XMLFile.load("FTNotes", path)
    if not xml then return end
    _todos = {}
    local count = xml:getInt("farmTabletNotes#count", 0)
    for i = 1, count do
        local key  = string.format("farmTabletNotes.item(%d)", i - 1)
        local text = xml:getString(key .. "#text", "")
        local done = xml:getBool(key .. "#done", false)
        if text ~= "" then
            table.insert(_todos, {text = text, done = done})
        end
    end
    xml:delete()
end

-- Hook into game lifecycle
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission,
    function() notes_load() end)

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile,
    function() notes_save() end)

-- ── Drawer ────────────────────────────────────────────────

FarmTabletUI:registerDrawer(FT.APP.NOTES, function(self)
    local AC = FT.appColor(FT.APP.NOTES)

    -- Count pending
    local pending = 0
    local done    = 0
    for _, t in ipairs(_todos) do
        if t.done then done = done + 1 else pending = pending + 1 end
    end

    if self:drawHelpPage("_notesHelp", FT.APP.NOTES, N("ft_app_notes", "Notes"), AC, {
        { title = N("ft_notes_todo_list", "Todo list"),
          body  = "Keep track of farm tasks.\n\n" ..
                  "Use < / > to select a task template and field,\n" ..
                  "then + ADD to add it to the list.\n" ..
                  "Todos are saved automatically per savegame." },
        { title = N("ft_notes_actions", "Actions"),
          body  = "DONE — mark a task as completed (■)\n" ..
                  "UNDO — mark it pending again (□)\n" ..
                  "✕    — remove the task entirely\n" ..
                  "CLEAR COMPLETED — remove all done tasks at once" },
    }) then return end

    local startY = self:drawAppHeader(N("ft_app_notes", "Notes"),
        pending > 0 and string.format(N("ft_notes_pending_fmt", "%d pending"), pending) or N("ft_notes_all_done", "All done!"))
    local x, cy, cw, _ = self:contentInner()
    local scrollY = self:getContentScrollY()
    local y       = startY + scrollY
    local BTN_H   = FT.py(22)
    local GAP     = FT.py(5)

    -- ── Template picker + Add ─────────────────────────────
    y = self:drawSection(y, N("ft_notes_new_task", "New task"))
    y = y - GAP

    local arrowW    = FT.px(28)
    local labelW    = cw - arrowW * 2 - FT.px(6)
    local template  = templateText(_templateIdx)

    -- Prev arrow
    local btnPrev = self.r:button(x, y - BTN_H, arrowW, BTN_H, "<",
        FT.C.BTN_NEUTRAL, {
        onClick = function()
            _templateIdx = ((_templateIdx - 2) % #TEMPLATES) + 1
        end
    })
    table.insert(self._contentBtns, btnPrev)

    -- Label display
    self.r:appRect(x + arrowW + FT.px(3), y - BTN_H,
        labelW, BTN_H, FT.C.BG_CARD)
    self.r:appText(x + arrowW + FT.px(3) + labelW * 0.5,
        y - BTN_H * 0.5 - FT.py(5),
        FT.FONT.SMALL, template, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)

    -- Next arrow
    local btnNext = self.r:button(x + arrowW + FT.px(3) + labelW + FT.px(3),
        y - BTN_H, arrowW, BTN_H, ">", FT.C.BTN_NEUTRAL, {
        onClick = function()
            _templateIdx = (_templateIdx % #TEMPLATES) + 1
        end
    })
    table.insert(self._contentBtns, btnNext)
    y = y - BTN_H - GAP

    -- ── Field picker ──────────────────────────────────────
    local ownedFields = notes_getOwnedFieldNums()
    local total = #ownedFields + 1  -- slot 0 = "Any field"
    if _fieldIdx >= total then _fieldIdx = 0 end

    if #ownedFields == 0 then
        self.r:appRect(x, y - BTN_H, cw, BTN_H, FT.C.BG_CARD)
        self.r:appText(x + cw * 0.5, y - BTN_H * 0.5 - FT.py(5),
            FT.FONT.SMALL, N("ft_notes_no_fields", "No fields owned"),
            RenderText.ALIGN_CENTER, FT.C.TEXT_DIM)
    else
        local fieldLabel = _fieldIdx == 0
            and N("ft_notes_any_field", "Any field")
            or (N("ft_common_field", "Field") .. " " .. tostring(ownedFields[_fieldIdx]))

        local btnFPrev = self.r:button(x, y - BTN_H, arrowW, BTN_H, "<",
            FT.C.BTN_NEUTRAL, {
            onClick = function()
                _fieldIdx = (_fieldIdx - 1 + total) % total
            end
        })
        table.insert(self._contentBtns, btnFPrev)

        self.r:appRect(x + arrowW + FT.px(3), y - BTN_H,
            labelW, BTN_H, FT.C.BG_CARD)
        self.r:appText(x + arrowW + FT.px(3) + labelW * 0.5,
            y - BTN_H * 0.5 - FT.py(5),
            FT.FONT.SMALL, fieldLabel, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)

        local btnFNext = self.r:button(x + arrowW + FT.px(3) + labelW + FT.px(3),
            y - BTN_H, arrowW, BTN_H, ">", FT.C.BTN_NEUTRAL, {
            onClick = function()
                _fieldIdx = (_fieldIdx + 1) % total
            end
        })
        table.insert(self._contentBtns, btnFNext)
    end
    y = y - BTN_H - GAP

    -- Add button
    local btnAdd = self.r:button(x, y - BTN_H, cw, BTN_H,
        N("ft_notes_add", "+ Add task"), FT.C.BTN_PRIMARY, {
        onClick = function()
            local todoText = templateText(_templateIdx)
            local fields = notes_getOwnedFieldNums()
            if _fieldIdx > 0 and fields[_fieldIdx] then
                todoText = todoText .. " - " .. N("ft_common_field", "Field") .. " " .. tostring(fields[_fieldIdx])
            end
            table.insert(_todos, {text = todoText, done = false})
            notes_save()
        end
    })
    table.insert(self._contentBtns, btnAdd)
    y = y - BTN_H - FT.py(8)

    -- ── Todo list ─────────────────────────────────────────
    y = self:drawRule(y - FT.py(4), 0.3)
    y = y - FT.py(6)
    y = self:drawSection(y,
        string.format(N("ft_notes_list_count_fmt", "Tasks (%d open - %d done)"), pending, done))
    y = y - GAP

    if #_todos == 0 then
        self.r:appText(x + cw * 0.5, y - FT.py(12), FT.FONT.SMALL,
            N("ft_notes_empty", "No tasks yet - add one above"),
            RenderText.ALIGN_CENTER, FT.C.TEXT_DIM)
        y = y - FT.py(24)
    else
        local statusW = FT.px(14)
        local actionW = FT.px(52)
        local removeW = FT.px(28)
        local textW   = cw - statusW - actionW - removeW - FT.px(9)

        for i, todo in ipairs(_todos) do
            if y < cy + FT.py(4) then break end

            -- Status glyph
            self.r:appText(x, y - FT.py(6),
                FT.FONT.SMALL, todo.done and "■" or "□",
                RenderText.ALIGN_LEFT,
                todo.done and FT.C.TEXT_DIM or AC)

            -- Task label
            local label = todo.text or ""
            if string.len(label) > 28 then
                label = string.sub(label, 1, 27) .. "…"
            end
            self.r:appText(x + statusW + FT.px(3), y - FT.py(6),
                FT.FONT.SMALL, label, RenderText.ALIGN_LEFT,
                todo.done and FT.C.TEXT_DIM or FT.C.TEXT_NORMAL)

            -- Done / Undo button
            local capturedIdx = i
            local btnDone = self.r:button(
                x + statusW + FT.px(3) + textW + FT.px(3),
                y - BTN_H, actionW, BTN_H,
                todo.done and N("ft_common_undo", "Undo") or N("ft_common_done", "Done"),
                todo.done and FT.C.BTN_NEUTRAL or FT.C.BTN_PRIMARY, {
                onClick = function()
                    if _todos[capturedIdx] then
                        _todos[capturedIdx].done = not _todos[capturedIdx].done
                        notes_save()
                    end
                end
            })
            table.insert(self._contentBtns, btnDone)

            -- Remove button
            local btnRm = self.r:button(
                x + statusW + FT.px(3) + textW + FT.px(3) + actionW + FT.px(3),
                y - BTN_H, removeW, BTN_H, "✕", FT.C.BTN_DANGER, {
                onClick = function()
                    table.remove(_todos, capturedIdx)
                    notes_save()
                end
            })
            table.insert(self._contentBtns, btnRm)

            y = y - BTN_H - GAP
        end
    end

    -- Clear completed button
    if done > 0 then
        y = y - FT.py(4)
        local btnClearDone = self.r:button(x, y - BTN_H, cw, BTN_H,
            string.format(N("ft_notes_clear_completed_fmt", "Clear %d completed"), done),
            FT.C.BTN_DANGER, {
            onClick = function()
                local remaining = {}
                for _, t in ipairs(_todos) do
                    if not t.done then table.insert(remaining, t) end
                end
                _todos = remaining
                notes_save()
            end
        })
        table.insert(self._contentBtns, btnClearDone)
        y = y - BTN_H
    end

    self:setContentHeight(startY - y + scrollY)
    self:drawInfoIcon("_notesHelp", AC)
    self:drawScrollBar()
end)
