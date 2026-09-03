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

    -- Tell the tablet to top up (true) or stop (false). Nil-safe if FarmTablet has
    -- no client UI on this peer (e.g. a dedicated server).
    local bridge = g_currentMission ~= nil and g_currentMission.farmTablet or nil
    if bridge ~= nil and bridge.setAtCharger ~= nil then
        bridge:setAtCharger(active)
    end

    -- World-side feedback: indicator glows cyan while a player is charging.
    if spec.indicatorNode ~= nil then
        setShaderParameter(spec.indicatorNode, "lightControl", active and 20 or 0, 0, 0, 0, false)
        if active then
            setShaderParameter(spec.indicatorNode, "colorScale", 0.2, 0.7, 1.0, 1.0, false)
        end
    end
    if spec.indicatorLight ~= nil then
        if active then
            setLightColor(spec.indicatorLight, 0.2, 0.7, 1.0)
        else
            setLightColor(spec.indicatorLight, 0, 0, 0)
        end
    end
end
