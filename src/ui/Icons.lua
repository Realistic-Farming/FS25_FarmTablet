-- =========================================================
-- FarmTablet v2 – FT_Icons
-- Loads and renders the baked glossy app-icon textures (gui/icons/<id>.dds,
-- mipmapped via tools/gen_icons.py) plus shared UI images (wallpaper, frame).
-- User-supplied custom backgrounds stay PNG and load through renderAbs().
--
-- Overlays are created once and CACHED for the session, then repositioned /
-- resized / tinted each frame. That keeps icon rendering cheap enough to
-- animate (press feedback, launch zoom) without recreating textures.
--
-- Coordinate convention matches FarmTablet: (x, y) is the BOTTOM-LEFT corner
-- in normalised screen space, y increasing upward (Overlay default alignment).
-- =========================================================
FT_Icons = FT_Icons or {}

FT_Icons._guiDir = nil
FT_Icons._cache  = {}     -- key -> Overlay | false (false = load failed)

--- Initialise with the mod directory. Safe to call more than once.
function FT_Icons.init(modDirectory)
    FT_Icons._guiDir = (modDirectory or "") .. "gui/"
    FT_Icons._cache  = {}
end

-- Internal: fetch (or lazily create) a cached overlay for an absolute path.
local function getOverlay(key, path)
    local cached = FT_Icons._cache[key]
    if cached ~= nil then
        return cached or nil
    end
    local ov = nil
    if Overlay ~= nil and Overlay.new ~= nil then
        ov = Overlay.new(path, 0, 0, 0.1, 0.1)
    end
    if ov ~= nil and ov.overlayId ~= nil and ov.overlayId ~= 0 then
        FT_Icons._cache[key] = ov
        return ov
    end
    -- Couldn't load — remember the failure so we don't retry every frame.
    if ov ~= nil and ov.delete then ov:delete() end
    FT_Icons._cache[key] = false
    return nil
end

-- BUILD 15:39 (PB-05). Icon files are named after the app id, so an id without
-- a matching gui/icons/<id>.dds asks the engine for a file that is not in the
-- zip and earns a missing-resource line in the log every session. That is what
-- Brian saw as the `excavator.dds` error: EXCAVATOR is the merged id for the old
-- Digging and Bucket Tracker apps and nothing ever baked a tile under the new
-- name. AppRegistry has an `icon` field, but its values ("store", "fields",
-- "admin", ...) do not match the shipped filenames either, so it is not usable
-- as the resolver.
--
-- These are the ids that have no tile of their own, pointed at the closest
-- shipped tile. Every one is a real, meaningful icon: the point of the fix is to
-- silence the error WITHOUT handing a registered app a blank or dead icon, so
-- the fallback monogram tile is deliberately not used here.
local ICON_ALIAS = {
    excavator  = "digging",           -- merge source: same earth/sand tile
    dairy      = "animals",
    dairy_core = "animals",
    prostaff   = "personnel",         -- co-op staff, same people tile
    organic    = "soil_fertilizer",
}

--- Returns (overlay, isFallback) for an app id. Falls back to _fallback.dds
--- (a neutral tile) when the app has no baked icon, so the caller can draw a
--- text monogram on top.
function FT_Icons.getAppOverlay(appId)
    if FT_Icons._guiDir == nil then return nil, true end
    local file = ICON_ALIAS[appId] or tostring(appId)
    local ov = getOverlay("icon:" .. file,
                          FT_Icons._guiDir .. "icons/" .. file .. ".dds")
    if ov ~= nil then return ov, false end
    local fb = getOverlay("icon:_fallback", FT_Icons._guiDir .. "icons/_fallback.dds")
    return fb, true
end

--- True if a baked icon exists for this app id (no fallback needed).
function FT_Icons.hasIcon(appId)
    if FT_Icons._guiDir == nil then return false end
    local _, isFallback = FT_Icons.getAppOverlay(appId)
    return not isFallback
end

--- Render an app icon as a square of side `size`, scaled about its centre by
--- `scale` (for press / launch animation), at opacity `alpha`.
--- Returns true if the fallback tile was used (caller should draw a monogram).
function FT_Icons.renderIcon(appId, x, y, size, scale, alpha)
    scale = scale or 1.0
    alpha = alpha or 1.0
    local ov, isFallback = FT_Icons.getAppOverlay(appId)
    if ov == nil then return isFallback end
    local s  = size * scale
    local cx = x + size * 0.5
    local cy = y + size * 0.5
    ov:setPosition(cx - s * 0.5, cy - s * 0.5)
    ov:setDimension(s, s)
    ov:setColor(1, 1, 1, alpha)
    ov:render()
    return isFallback
end

--- Render an arbitrary gui image (e.g. wallpaper.dds) stretched to a rect.
--- `relPath` is relative to gui/ (e.g. "wallpaper.dds").
--- `tint` is an optional {r,g,b} multiply colour; alpha is separate.
function FT_Icons.renderImage(key, relPath, x, y, w, h, alpha, tint)
    if FT_Icons._guiDir == nil then return false end
    alpha = alpha or 1.0
    local ov = getOverlay("img:" .. key, FT_Icons._guiDir .. relPath)
    if ov == nil then return false end
    ov:setPosition(x, y)
    ov:setDimension(w, h)
    if tint then
        ov:setColor(tint[1], tint[2], tint[3], alpha)
    else
        ov:setColor(1, 1, 1, alpha)
    end
    ov:render()
    return true
end

--- Render an image from an ABSOLUTE path (e.g. a user PNG in the savegame's
--- FTBackground folder) stretched to a rect. Cached by the path string, so a
--- different file is a different cache entry. Returns false if it can't load.
function FT_Icons.renderAbs(absPath, x, y, w, h, alpha)
    if not absPath or absPath == "" then return false end
    alpha = alpha or 1.0
    local ov = getOverlay("abs:" .. absPath, absPath)
    if ov == nil then return false end
    ov:setPosition(x, y)
    ov:setDimension(w, h)
    ov:setColor(1, 1, 1, alpha)
    ov:render()
    return true
end

--- Drop a cached absolute-path overlay so it reloads next render (used when the
--- player re-selects a background whose file may have changed on disk).
function FT_Icons.invalidate(absPath)
    local key = "abs:" .. tostring(absPath)
    local ov = FT_Icons._cache[key]
    if ov and ov.delete then ov:delete() end
    FT_Icons._cache[key] = nil
end

--- Delete every cached overlay. Call on mod unload only (NOT on tablet close —
--- the cache is meant to persist across open/close cycles).
function FT_Icons.deleteAll()
    for _, ov in pairs(FT_Icons._cache) do
        if ov and ov.delete then ov:delete() end
    end
    FT_Icons._cache = {}
end
