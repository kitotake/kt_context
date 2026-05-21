-- =============================================
-- config_rotation.lua — OBSOLÈTE / RÉFÉRENCE UNIQUEMENT
--
-- FIX CRITIQUE : ce fichier ne doit PLUS déclarer Config = {}
-- car il écraserait shared/config.lua.
-- Les valeurs de rotation sont maintenant dans shared/config.lua
-- sous Config.Rotation (voir ce fichier).
--
-- Ce fichier N'EST PAS dans fxmanifest.lua et ne sera pas chargé.
-- Conservé uniquement pour référence historique.
-- =============================================

--[[
Config.Rotation = {
    DefaultPropName  = 'vw_prop_vw_luckywheel_02a',
    DefaultPosition  = vector3(-2089.622070, 3143.182373, 32.801514),
    DefaultRotation  = vector3(0.0, 100.0, 0.0),
    DeleteRadius     = 5.0,
}
-- Ces valeurs sont maintenant dans shared/config.lua → Config.Rotation
--]]