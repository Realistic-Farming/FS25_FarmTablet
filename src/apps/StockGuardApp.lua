-- =========================================================
-- FarmTablet – StockGuard (SG5) read-only glance
-- =========================================================
-- UI3 equipment domain. Reads ONLY mission.stockGuard.getClientView.
-- No commands, quotes, selection, getManagementView, or sessions.
-- STOCK: amount (finite nonnegative), amountUnit, knowledge (SGViews/SGRecords).
-- =========================================================

local function _sgHost()
    return g_currentMission and g_currentMission.stockGuard or nil
end

local function _snap()
    local host = _sgHost()
    if host == nil or type(host.getClientView) ~= "function" then
        return nil, "ABSENT"
    end
    local ok, snap = pcall(host.getClientView)
    if not ok then
        return nil, "THROW"
    end
    if type(snap) ~= "table" then
        return nil, "ERROR"
    end
    return snap, nil
end

local function _tr(key, fallback, ...)
    if type(FT) == "table" and type(FT.l10nFormat) == "function" then
        local ok, s = pcall(FT.l10nFormat, key, fallback, ...)
        if ok and type(s) == "string" and s ~= "" then return s end
    end
    if select("#", ...) > 0 then
        local ok, s = pcall(string.format, fallback, ...)
        if ok then return s end
    end
    return fallback
end

--- A profile constant is an identity, never a name. NATIVE_FILL_UNIT_V1 and NATIVE_STORAGE_SLOT_V1 reached the
--- screen as row titles because SGViews substitutes carrier.binding.profileId when the native read has no label.
--- Anything of that shape, or anything equal to the row's own carrierKind, is treated as no label at all.
local function _isProfileId(s, row)
    if type(s) ~= "string" or s == "" then return true end
    if type(row) == "table" and s == row.carrierKind then return true end
    return string.match(s, "^NATIVE_[A-Z0-9_]+_V%d+$") ~= nil
end

--- The product, as the localised fill type title the rest of the suite uses. Nil when the row names no material
--- or the game does not know it, so nothing is invented.
local function _productTitle(row)
    if type(row) ~= "table" or type(row.materialRef) ~= "table" then return nil end
    local name = row.materialRef.fillTypeName
    if type(name) ~= "string" or name == "" then return nil end
    if g_fillTypeManager ~= nil and type(g_fillTypeManager.getFillTypeByName) == "function" then
        local ok, ft = pcall(g_fillTypeManager.getFillTypeByName, g_fillTypeManager, name)
        if ok and type(ft) == "table" then
            local t = ft.title
            if type(t) == "string" and t ~= "" then return t end
        end
    end
    return name
end

local function _rowTitle(row)
    if type(row) ~= "table" then return _tr("ft_sg_row_unknown", "Item") end

    local product = _productTitle(row)
    local place = (not _isProfileId(row.label, row)) and row.label or nil

    -- Product first, then where it is. Either alone is still useful; neither leaves the honest fallback.
    if product ~= nil and place ~= nil then
        return _tr("ft_sg_row_product_at", "%s - %s", product, place)
    end
    if product ~= nil then return product end
    if place ~= nil then return place end

    if row.rowKind == "PROCESS" then return _tr("ft_sg_process_unnamed", "Process") end
    if row.rowKind == "STOCK" then return _tr("ft_sg_stock_unnamed", "Stock") end
    if row.rowKind == "CARRIER" then return _tr("ft_sg_carrier_unnamed", "Carrier") end
    return _tr("ft_sg_row_unknown", "Item")
end

local function _kindLabel(row)
    if type(row) ~= "table" then return "" end
    local k = row.rowKind
    if k == "STOCK" then return _tr("ft_sg_kind_stock", "Stock") end
    if k == "PROCESS" then return _tr("ft_sg_kind_process", "Process") end
    if k == "CARRIER" then return _tr("ft_sg_kind_carrier", "Carrier") end
    if k == "SITE" then return _tr("ft_sg_kind_site", "Site") end
    if k == "GROUND" then return _tr("ft_sg_kind_ground", "Ground") end
    if k == "LIBRARY" then return _tr("ft_sg_kind_library", "Library") end
    return ""
end

local function _formatNumber(n)
    if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
        return nil
    end
    if n < 0 then return nil end
    if n == 0 then return "0" end
    local a = math.abs(n)
    if a >= 100 then return string.format("%.0f", n) end
    if a >= 10 then return string.format("%.1f", n) end
    if a >= 1 then return string.format("%.2f", n) end
    return string.format("%.4g", n)
end

local function _unitLabel(unit)
    if type(unit) ~= "string" or unit == "" or unit == "UNAVAILABLE" then
        return nil
    end
    if unit == "LITRE" then return _tr("ft_sg_unit_litre", "L") end
    if unit == "KILOGRAM" then return _tr("ft_sg_unit_kg", "kg") end
    if unit == "UNIT" then return _tr("ft_sg_unit_each", "ea") end
    return unit
end

--- Finite nonnegative number only (SGRecords.isAmount spirit).
local function _validAmount(amount)
    if type(amount) == "number" then
        if amount ~= amount or amount == math.huge or amount == -math.huge then return nil end
        if amount < 0 then return nil end
        return amount
    end
    return nil
end

--- STOCK rows: amount + amountUnit + knowledge. Explicit status words always.
function StockGuardTabletFormatAmount(row)
    if type(row) ~= "table" then
        return _tr("ft_sg_amount_none", "—"), "DIM"
    end
    if row.rowKind ~= "STOCK" then
        if row.enabled == true then return _tr("ft_sg_process_on", "On"), "OK" end
        if row.enabled == false then return _tr("ft_sg_process_off", "Off"), "DIM" end
        return _tr("ft_sg_amount_none", "—"), "DIM"
    end

    local knowledge = row.knowledge
    local amount = row.amount
    if type(amount) == "table" then
        return _tr("ft_sg_amount_bad", "Unavailable"), "DIM"
    end
    -- Non-numeric strings / negatives are not quantities.
    if type(amount) == "string" then
        return _tr("ft_sg_amount_bad", "Unavailable"), "DIM"
    end
    local n = _validAmount(amount)
    local unit = _unitLabel(row.amountUnit)
    local num = n ~= nil and _formatNumber(n) or nil

    local qty = nil
    if num ~= nil and unit ~= nil then
        qty = num .. " " .. unit
    elseif num ~= nil and unit == nil then
        qty = _tr("ft_sg_amount_unit_missing", "%s (unit unavailable)", num)
    end

    if knowledge == "UNKNOWN" then
        if qty ~= nil then return _tr("ft_sg_amount_unknown_with", "Unknown (%s)", qty), "WARN" end
        return _tr("ft_sg_amount_unknown", "Unknown"), "WARN"
    end
    if knowledge == "PARTIAL" then
        if qty ~= nil then return _tr("ft_sg_amount_partial_with", "Partial · %s", qty), "WARN" end
        return _tr("ft_sg_amount_partial", "Partial"), "WARN"
    end
    if knowledge == "HISTORICAL" then
        if qty ~= nil then return _tr("ft_sg_amount_historical_with", "Historical · %s", qty), "DIM" end
        return _tr("ft_sg_amount_historical", "Historical"), "DIM"
    end
    if knowledge == "UNAVAILABLE" then
        if qty ~= nil then return _tr("ft_sg_amount_unavailable_with", "Unavailable · %s", qty), "DIM" end
        return _tr("ft_sg_amount_unavailable", "Unavailable"), "DIM"
    end
    -- KNOWN (or unspecified with valid amount)
    if qty ~= nil then return qty, "OK" end
    if n == nil and amount ~= nil then
        return _tr("ft_sg_amount_bad", "Unavailable"), "DIM"
    end
    return _tr("ft_sg_amount_none", "—"), "DIM"
end

local function _tone(kind)
    if kind == "OK" then return FT.C.POSITIVE end
    if kind == "WARN" then return FT.C.WARNING end
    if kind == "NEG" then return FT.C.NEGATIVE end
    return FT.C.TEXT_DIM
end

local function _selectionCaption(view)
    if type(view) ~= "table" then
        return _tr("ft_sg_context_none", "No farm view yet")
    end
    local kind = view.selectionKind
    if kind == "FARM" then return _tr("ft_sg_context_farm", "This farm view") end
    if kind == "SITE" then
        local label = view.siteLabel or view.label
        if type(label) == "string" and label ~= "" then
            return _tr("ft_sg_context_site_named", "Site · %s", label)
        end
        return _tr("ft_sg_context_site", "One site")
    end
    if kind == "GROUND" then return _tr("ft_sg_context_ground", "Ground selection") end
    if kind == "LIBRARY" then return _tr("ft_sg_context_library", "Library") end
    return _tr("ft_sg_context_other", "Current Stock selection")
end

local function _statusKind(snap)
    if type(snap) ~= "table" then return "ERROR" end
    local st = tostring(snap.state or "")
    local reason = tostring(snap.reason or "")
    if st == "DENIED" or reason:find("DENIED", 1, true) or reason:find("ACCESS", 1, true) or reason:find("FARM", 1, true) and reason:find("LOSS", 1, true) then
        return "DENIED"
    end
    if st == "ERROR" then return "ERROR" end
    if st == "UNAVAILABLE" then return "UNAVAILABLE" end
    if st == "WAITING" then return "WAITING" end
    if snap.usable == true and st == "READY" then return "READY" end
    if st == "READY" and snap.usable ~= true then return "WAITING" end
    return "WAITING"
end

FarmTabletUI:registerDrawer(FT.APP.STOCK_GUARD, function(self)
    local AC = FT.appColor(FT.APP.STOCK_GUARD)
    local draws = self._sgDrawLog

    local function note(kind, a, b)
        if type(draws) == "table" then
            draws[#draws + 1] = { kind = kind, a = a, b = b }
        end
    end

    if self:drawHelpPage("_stockGuardHelp", FT.APP.STOCK_GUARD, _tr("ft_ui_app_stock_guard", "Stock Guard"), AC, {
        { title = _tr("ft_sg_help_what_title", "What this app shows"),
          body  = _tr("ft_sg_help_what_body",
            "A read-only look at stock and processes Stock Guard already published for this farm. It does not buy, sell, start, or stop anything. Use Esc → Realistic Farming → Stock Guard for that."), literalTitle = true, literalBody = true },
        { title = _tr("ft_sg_help_amounts_title", "Amounts"),
          body  = _tr("ft_sg_help_amounts_body",
            "When Stock Guard knows an amount and unit, both are shown. Partial or unknown knowledge is labelled. This page is never a whole-farm total by itself."), literalTitle = true, literalBody = true },
        { title = _tr("ft_sg_help_first_title", "First opening"),
          body  = _tr("ft_sg_help_first_body",
            "If nothing appears yet, open Esc Stock Guard once on this farm so a view can be published. This tablet app will not request or change that selection for you."), literalTitle = true, literalBody = true },
    -- literalHeader: the header is already resolved by _tr.
    }, true) then return end

    -- literalTitle, literalSubtitle: both are already resolved by _tr.
    local startY = self:drawAppHeader(_tr("ft_ui_app_stock_guard", "Stock Guard"), _tr("ft_sg_subtitle", "Read-only"), true, true)
    local y = startY
    local scrollY = self.scrollOffset and self:scrollOffset() or 0

    local snap, why = _snap()
    if snap == nil then
        if why == "ABSENT" then
            local a = _tr("ft_sg_absent_title", "Stock Guard is not available")
            local b = _tr("ft_sg_absent_body", "Install or enable FS25_StockGuard to use this app.")
            y = self:drawRow(y, a, b, nil, FT.C.NEGATIVE, true, true)
            note("ABSENT", a, b)
        elseif why == "THROW" then
            local a = _tr("ft_sg_error_title", "Could not read stock")
            local b = _tr("ft_sg_error_body", "Try again after the farm has finished loading.")
            y = self:drawRow(y, a, b, nil, FT.C.NEGATIVE, true, true)
            note("THROW", a, b)
        else
            local a = _tr("ft_sg_error_title", "Could not read stock")
            local b = _tr("ft_sg_error_body", "Try again after the farm has finished loading.")
            y = self:drawRow(y, a, b, nil, FT.C.NEGATIVE, true, true)
            note("ERROR", a, b)
        end
        self:setContentHeight(startY - y + scrollY)
        self:drawScrollBar()
        self:drawInfoIcon("_stockGuardHelp", AC)
        return
    end

    local sk = _statusKind(snap)
    if sk ~= "READY" then
        y = self:drawSection(y, _tr("ft_sg_section_status", "STATUS"))
        if sk == "DENIED" then
            local a = _tr("ft_sg_status_denied", "Access denied")
            local b = _tr("ft_sg_status_denied_hint", "This farm view is not available to you right now.")
            y = self:drawRow(y, a, b, nil, FT.C.NEGATIVE, true, true)
            note("DENIED", a, b)
        elseif sk == "ERROR" then
            local a = _tr("ft_sg_status_error", "Stock view error")
            local b = _tr("ft_sg_status_error_hint", "Close and reopen Esc Stock Guard, then try again.")
            y = self:drawRow(y, a, b, nil, FT.C.NEGATIVE, true, true)
            note("ERROR_STATE", a, b)
        elseif sk == "UNAVAILABLE" then
            local a = _tr("ft_sg_status_unavailable", "Stock view unavailable")
            local b = _tr("ft_sg_status_unavailable_hint", "Stock Guard has nothing to show for this farm right now.")
            y = self:drawRow(y, a, b, nil, FT.C.WARNING)
            note("UNAVAILABLE", a, b)
        else
            local a = _tr("ft_sg_status_waiting", "Waiting for a published farm view")
            local b = _tr("ft_sg_status_hint", "Open Esc → Realistic Farming → Stock Guard once. This app stays read-only.")
            y = self:drawRow(y, a, b, nil, FT.C.WARNING)
            note("WAITING", a, b)
        end
        self:setContentHeight(startY - y + scrollY)
        self:drawScrollBar()
        self:drawInfoIcon("_stockGuardHelp", AC)
        return
    end

    local view = snap.view
    if type(view) ~= "table" then
        local a = _tr("ft_sg_empty_payload", "No stock list in the current view")
        y = self:drawRow(y, a, "", nil, FT.C.TEXT_DIM)
        note("EMPTY_PAYLOAD", a, "")
        self:setContentHeight(startY - y + scrollY)
        self:drawScrollBar()
        self:drawInfoIcon("_stockGuardHelp", AC)
        return
    end

    y = self:drawSection(y, _tr("ft_sg_section_where", "WHERE"))
    local where = _selectionCaption(view)
    y = self:drawRow(y, _tr("ft_sg_where_label", "Showing"), where)
    note("WHERE", where, nil)
    y = self:drawRow(y, _tr("ft_sg_where_note", "Note"),
        _tr("ft_sg_not_whole_farm", "This list is only the current Stock Guard page, not a farm-wide total."), nil, FT.C.TEXT_DIM)

    local rows = view.rows
    local continued = view.nextPageCursor ~= nil and tostring(view.nextPageCursor) ~= ""
    y = self:drawSection(y, _tr("ft_sg_section_list", "LIST"))
    if type(rows) ~= "table" or #rows < 1 then
        if continued then
            local a = _tr("ft_sg_empty_continued", "This page is empty")
            local b = _tr("ft_sg_empty_continued_hint", "More pages exist in Esc Stock Guard.")
            y = self:drawRow(y, a, b, nil, FT.C.TEXT_DIM)
            note("EMPTY_CONTINUED", a, b)
        else
            local a = _tr("ft_sg_empty", "Nothing on this view")
            local b = _tr("ft_sg_empty_hint", "Empty for the current Stock Guard selection.")
            y = self:drawRow(y, a, b, nil, FT.C.TEXT_DIM)
            note("EMPTY", a, b)
        end
    else
        for _, row in ipairs(rows) do
            if type(row) == "table" then
                local kind = _kindLabel(row)
                local title = _rowTitle(row)
                local left = kind ~= "" and (kind .. " · " .. title) or title
                local amt, tone = StockGuardTabletFormatAmount(row)
                y = self:drawRow(y, left, amt, nil, _tone(tone))
                note("ROW", left, amt)
            end
        end
        if continued then
            y = self:drawRow(y, _tr("ft_sg_more_pages", "More pages"),
                _tr("ft_sg_more_pages_hint", "Continue in Esc Stock Guard."), nil, FT.C.TEXT_DIM)
            note("MORE", "more", nil)
        end
    end

    y = y - (FT.py and FT.py(6) or 6)
    y = self:drawRow(y, _tr("ft_sg_actions_label", "Actions"),
        _tr("ft_sg_actions_esc", "Use Esc Stock Guard"), nil, FT.C.TEXT_DIM)

    self:setContentHeight(startY - y + scrollY)
    local hx, hy, hw, hh = self:contentInner()
    local shieldH = (hy + hh) - startY
    if shieldH > 0 then
        self.r:appRect(hx, startY, hw, shieldH, FT.C.BG_PANEL)
    end
    self:drawAppHeader(_tr("ft_ui_app_stock_guard", "Stock Guard"), _tr("ft_sg_subtitle", "Read-only"))
    self:drawScrollBar()
    self:drawInfoIcon("_stockGuardHelp", AC)
end)
