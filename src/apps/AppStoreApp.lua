-- =========================================================
-- FarmTablet v2 – App Store
-- Lists all registered apps with metadata.
-- The MOD INTEGRATIONS section always shows all known
-- companion mods — installed ones have an OPEN button,
-- uninstalled ones appear dimmed with an install hint.
-- =========================================================

-- All companion mod integrations FarmTablet supports.
-- Shown in the Mod Integrations section whether or not the mod is active.
local KNOWN_INTEGRATIONS = {
    { appId = FT.APP.INCOME,         label = "Income Mod",         mod = "FS25_IncomeMod"            },
    { appId = FT.APP.TAX,            label = "Tax Mod",             mod = "FS25_TaxMod"               },
    { appId = FT.APP.NPC_FAVOR,      label = "NPC Favor",           mod = "FS25_NPCFavor"             },
    { appId = FT.APP.CROP_STRESS,    label = "Seasonal Crop Stress",mod = "FS25_SeasonalCropStress"   },
    { appId = FT.APP.SOIL_FERT,      label = "Soil Fertilizer",     mod = "FS25_SoilFertilizer"       },
    { appId = FT.APP.MARKET_DYNAMICS,label = "Market Dynamics",     mod = "FS25_MarketDynamics"       },
    { appId = FT.APP.WORKER_COSTS,   label = "Worker Costs",        mod = "FS25_WorkerCosts"          },
    { appId = FT.APP.RANDOM_EVENTS,  label = "Random World Events", mod = "FS25_RandomWorldEvents"    },
    { appId = FT.APP.USED_PLUS,      label = "UsedPlus",            mod = "FS25_UsedPlus"             },
    { appId = FT.APP.ROLEPLAY_PHONE, label = "Invoices / Phone",    mod = "(always active)"           },
}

FarmTabletUI:registerDrawer(FT.APP.APP_STORE, function(self)
    local AC = FT.appColor(FT.APP.APP_STORE)

    if self:drawHelpPage("_appStoreHelp", FT.APP.APP_STORE, "App Store", AC, {
        { title = "WHAT IS THE APP STORE",
          body  = "Lists every app registered with the Farm Tablet,\n" ..
                  "grouped into Built-in, Farming, and\n" ..
                  "Mod Integration categories." },
        { title = "OPEN BUTTON",
          body  = "Click OPEN on any app row to switch to it directly.\n" ..
                  "This is a shortcut — you can also click the icon in\n" ..
                  "the left sidebar at any time." },
        { title = "MOD INTEGRATIONS",
          body  = "All known companion mod integrations are listed here.\n" ..
                  "Active mods show in full colour with an OPEN button.\n" ..
                  "Dimmed rows are supported but not currently installed.\n" ..
                  "No setup needed — apps appear automatically when the\n" ..
                  "matching mod is loaded in your savegame." },
        { title = "VERSION / DEVELOPER",
          body  = "Built-in apps show 'Built-in' as their version.\n" ..
                  "Third-party companion apps show their own version\n" ..
                  "number and developer name." },
    }) then return end

    local apps    = self.system.registry:getAll()
    local scrollY = self:getContentScrollY()
    local afterHdr = self:drawAppHeader("App Store", #apps .. " installed")
    local x, contentY, cw, _ = self:contentInner()
    local y = afterHdr + scrollY

    -- ── Built-in and farm groups ───────────────────────────
    local groups     = {}
    local groupOrder = {}
    for _, app in ipairs(apps) do
        local g = app.group or "core"
        if g ~= "mods" then
            if not groups[g] then groups[g] = {}; table.insert(groupOrder, g) end
            table.insert(groups[g], app)
        end
    end

    local groupLabels = { core = "BUILT-IN", farm = "FARMING", finance = "FINANCE" }

    for _, gid in ipairs(groupOrder) do
        local list = groups[gid]
        if list and #list > 0 then
            y = self:drawSection(y, groupLabels[gid] or gid:upper())
            for _, app in ipairs(list) do
                local dispName = (g_i18n and g_i18n:getText(app.name)) or app.navLabel or app.id
                y = self:_drawAppRow(y, app, dispName, x, cw, false)
            end
            y = y - FT.py(4)
        end
    end

    -- ── Mod integrations ──────────────────────────────────
    y = self:drawSection(y, "MOD INTEGRATIONS")

    for _, known in ipairs(KNOWN_INTEGRATIONS) do
        local app       = self.system.registry:get(known.appId)
        local installed = app ~= nil
        local dispName  = (installed and g_i18n and g_i18n:getText(app.name))
                       or known.label
        y = self:_drawAppRow(y, app, dispName, x, cw, not installed, known)
    end

    self:setContentHeight(afterHdr - y + scrollY)
    self:drawInfoIcon("_appStoreHelp", AC)
    self:drawScrollBar()
end)

-- ── Row renderer helper ───────────────────────────────────
-- dimmed   = true for uninstalled companion mods
-- known    = KNOWN_INTEGRATIONS entry (used for hint text when dimmed)
function FarmTabletUI:_drawAppRow(y, app, dispName, x, cw, dimmed, known)
    local alpha = dimmed and 0.35 or 1.00

    -- Card background
    self.r:appRect(x - FT.px(4), y - FT.py(4), cw + FT.px(8), FT.py(30),
        dimmed and {0.08, 0.09, 0.12, 0.50} or FT.C.BG_CARD)

    -- App name
    local nameColor = dimmed
        and {FT.C.TEXT_DIM[1], FT.C.TEXT_DIM[2], FT.C.TEXT_DIM[3], alpha}
        or FT.C.TEXT_BRIGHT
    self.r:appText(x + FT.px(8), y + FT.py(10), FT.FONT.BODY,
        dispName, RenderText.ALIGN_LEFT, nameColor)

    -- Description / hint
    local desc
    if dimmed and known then
        desc = "Install " .. known.mod .. " to enable"
    elseif app then
        desc = app.description or ""
        if #desc > 44 then desc = desc:sub(1, 42) .. ">" end
    else
        desc = ""
    end
    self.r:appText(x + FT.px(8), y - FT.py(4), FT.FONT.TINY,
        desc, RenderText.ALIGN_LEFT,
        {FT.C.TEXT_DIM[1], FT.C.TEXT_DIM[2], FT.C.TEXT_DIM[3], alpha})

    -- Version / developer (right side)
    if app and not dimmed then
        self.r:appText(x + cw - FT.px(4), y + FT.py(10), FT.FONT.TINY,
            app.version or "Built-in", RenderText.ALIGN_RIGHT, FT.C.BRAND)
        self.r:appText(x + cw - FT.px(4), y - FT.py(4), FT.FONT.TINY,
            app.developer or "", RenderText.ALIGN_RIGHT, FT.C.TEXT_DIM)
    elseif dimmed then
        self.r:appText(x + cw - FT.px(4), y + FT.py(10), FT.FONT.TINY,
            "not installed", RenderText.ALIGN_RIGHT,
            {FT.C.MUTED[1], FT.C.MUTED[2], FT.C.MUTED[3], 0.45})
    end

    -- OPEN button (only for installed apps)
    if app and not dimmed then
        local appId = app.id
        local btn = self.r:button(x + cw - FT.px(48), y, FT.px(44), FT.py(14),
            "OPEN", FT.C.BTN_PRIMARY, { onClick = function() self:switchApp(appId) end })
        table.insert(self._contentBtns, btn)
    end

    return y - FT.py(34)
end
