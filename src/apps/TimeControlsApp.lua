-- =========================================================
-- FarmTablet - Time Controls (retired hub tile)
-- =========================================================
-- IA merge: time scale + skip-to live inside Farm Admin.
-- This file keeps the source() wire and redirects any drawer
-- open to Farm Admin so old deep-links do not blank the tablet.
-- =========================================================

FarmTabletUI:registerDrawer(FT.APP.TIME_CONTROLS, function(self)
    -- Immediate redirect; Farm Admin owns the controls.
    if self.switchApp then
        self:switchApp(FT.APP.FARM_ADMIN)
    else
        self.system.currentApp = FT.APP.FARM_ADMIN
    end
end)
