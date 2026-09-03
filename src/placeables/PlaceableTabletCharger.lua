-- =========================================================
-- FarmTablet - Tablet Charging Station (placeable specialization)
-- =========================================================
-- A physical charging pad. When the LOCAL on-foot player steps into its trigger
-- it tells the Farm Tablet to top up its battery, through the public cross-mod
-- bridge (g_currentMission.farmTablet:setAtCharger). The tablet battery is local
-- flavour, so this is purely client-side: no network event, each player charges
-- their own tablet.
--
-- Trigger idiom verified against the decompiled base game:
--   PlaceableInfoTrigger / PlaceableCartridgePlayer use addTrigger + the
--   "(onEnter or onLeave) and g_localPlayer.rootNode == otherId" local-player test.
-- =========================================================

local modName = g_currentModName

PlaceableTabletCharger = {}
PlaceableTabletCharger.SPEC_TABLE_NAME = "spec_" .. modName .. ".tabletCharger"

function PlaceableTabletCharger.prerequisitesPresent(specializations)
    return true
end

function PlaceableTabletCharger.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTabletCharger)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTabletCharger)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTabletCharger)
end

function PlaceableTabletCharger.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onTabletChargerTriggerCallback", PlaceableTabletCharger.onTabletChargerTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "setTabletChargerActive", PlaceableTabletCharger.setTabletChargerActive)
    SpecializationUtil.registerFunction(placeableType, "setChargeLight", PlaceableTabletCharger.setChargeLight)
end

function PlaceableTabletCharger.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("TabletCharger")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".tabletCharger#triggerNode",   "Player charging trigger node", nil, false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".tabletCharger#indicatorNode",  "Charge indicator (emissive shader) node", nil, false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".tabletCharger#indicatorLight", "Charge indicator real light node", nil, false)
    schema:setXMLSpecializationType()
end

function PlaceableTabletCharger:onLoad(savegame)
    local spec = self[PlaceableTabletCharger.SPEC_TABLE_NAME]
    if spec == nil then
        self[PlaceableTabletCharger.SPEC_TABLE_NAME] = {}
        spec = self[PlaceableTabletCharger.SPEC_TABLE_NAME]
    end

    spec.triggerNode    = self.xmlFile:getValue("placeable.tabletCharger#triggerNode",   nil, self.components, self.i3dMappings)
    spec.indicatorNode  = self.xmlFile:getValue("placeable.tabletCharger#indicatorNode",  nil, self.components, self.i3dMappings)
    spec.indicatorLight = self.xmlFile:getValue("placeable.tabletCharger#indicatorLight", nil, self.components, self.i3dMappings)
    spec.playerInside   = false

    -- Make the trigger react to the on-foot player WITHOUT a manual collision-mask
    -- edit in GIANTS Editor: add the PLAYER bit here if the i3d did not ship it.
    -- CollisionFlag.setMaskFlag is the engine helper for this (CollisionFlag.lua:61).
    if spec.triggerNode ~= nil and not CollisionFlag.getHasMaskFlagSet(spec.triggerNode, CollisionFlag.PLAYER) then
        CollisionFlag.setMaskFlag(spec.triggerNode, CollisionFlag.PLAYER)
    end

    -- Indicator dark until a player is charging.
    if spec.indicatorLight ~= nil then
        setLightColor(spec.indicatorLight, 0, 0, 0)
    end
    if spec.indicatorNode ~= nil then
        setShaderParameter(spec.indicatorNode, "lightControl", 0, 0, 0, 0, false)
    end
end

function PlaceableTabletCharger:onFinalizePlacement()
    local spec = self[PlaceableTabletCharger.SPEC_TABLE_NAME]
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "onTabletChargerTriggerCallback", self)
        Logging.info("[FS25_FarmTablet] Tablet charging station placed: player trigger armed.")
    else
        Logging.warning("[FS25_FarmTablet] Tablet charging station has no triggerNode; charging will not work.")
    end
end

function PlaceableTabletCharger:onDelete()
    local spec = self[PlaceableTabletCharger.SPEC_TABLE_NAME]
    if spec == nil then return end
    -- Never leave the tablet stuck "charging" if the pad is removed while the
    -- player is standing on it.
    if spec.playerInside then
        self:setTabletChargerActive(false)
    end
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
        spec.triggerNode = nil
    end
end

-- Local on-foot player enters/leaves the pad. Verified idiom: react only to the
-- LOCAL player's rootNode (PlaceableInfoTrigger.lua, PlaceableCartridgePlayer.lua).
function PlaceableTabletCharger:onTabletChargerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if (onEnter or onLeave) and g_localPlayer ~= nil and g_localPlayer.rootNode == otherId then
        if onEnter then
            self:setTabletChargerActive(true)
        elseif onLeave then
            self:setTabletChargerActive(false)
        end
    end
end

function PlaceableTabletCharger:setTabletChargerActive(active)
    local spec = self[PlaceableTabletCharger.SPEC_TABLE_NAME]
    active = active == true
    spec.playerInside = active

    -- Register (or clear) this pad so the tablet can drive the indicator light to
    -- match ACTUAL charging, then tell it we stepped on / off. Nil-safe on a peer
    -- with no client tablet UI (e.g. a dedicated server).
    local bridge = g_currentMission ~= nil and g_currentMission.farmTablet or nil
    if bridge ~= nil then
        if bridge.setChargerPlaceable ~= nil then
            bridge:setChargerPlaceable(active and self or nil)
        end
        if bridge.setAtCharger ~= nil then
            bridge:setAtCharger(active)
        end
    end

    -- Off the instant the player leaves; while on the pad the tablet drives the
    -- light ON only when it is genuinely topping up (never while the tablet is open).
    if not active then
        self:setChargeLight(false)
    end
end

--- Driven by the tablet through g_currentMission.farmTablet:notifyChargeLight, so the
--- world indicator glows ONLY while the battery is actually charging - not merely
--- because a player is standing here with the tablet open.
function PlaceableTabletCharger:setChargeLight(on)
    local spec = self[PlaceableTabletCharger.SPEC_TABLE_NAME]
    if spec == nil then return end
    on = on == true
    if spec.indicatorNode ~= nil then
        setShaderParameter(spec.indicatorNode, "lightControl", on and 20 or 0, 0, 0, 0, false)
        if on then
            setShaderParameter(spec.indicatorNode, "colorScale", 0.2, 0.7, 1.0, 1.0, false)
        end
    end
    if spec.indicatorLight ~= nil then
        if on then
            setLightColor(spec.indicatorLight, 0.2, 0.7, 1.0)
        else
            setLightColor(spec.indicatorLight, 0, 0, 0)
        end
    end
end
