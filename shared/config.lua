-- =============================================
-- CONFIG KT_CONTEXT — v3.2
-- COMPAT UNION : utilise KtContextConfig
-- pour ne pas écraser Config d'union.
-- =============================================
KtContextConfig = {}

KtContextConfig.Locale = 'fr'
KtContextConfig.CursorKey     = 19
KtContextConfig.CursorKeyName = 'LALT'
KtContextConfig.InteractionDistance = 5.0
KtContextConfig.MaxSubmenuDepth     = 6
KtContextConfig.AdminGroups = { 'admin', 'moderator', 'founder' }
KtContextConfig.StaffGroups = { 'admin', 'moderator', 'founder', 'staff' }

KtContextConfig.Limits = {
    NpcCooldown             = 5000,
    NpcMaxDistance          = 3.0,
    AnimCooldown            = 2000,
    AnimBlockInVehicle      = true,
    PropMaxDistance         = 3.0,
    PropMaxHeight           = 2.0,
    PropMaxActive           = 1,
    PropRotateStep          = 15.0,
    AdminConfirmDelete      = true,
    AdminLogAll             = true,
    ServerActionCooldown    = 500,
    MaxInteractMoveDistance = 3.0,
}

KtContextConfig.Rotation = {
    DefaultPropName = 'prop_mp_barrier_01a',
    DefaultPosition = vector3(0.0, 0.0, 0.0),
    DefaultRotation = vector3(0.0, 0.0, 0.0),
    DeleteRadius    = 5.0,
    SnapToGround    = true,
    AllowedProps    = {},
}

KtContextConfig.Overlay = {
    PlayerNames = {
        Enabled       = false,
        MaxDistance   = 30.0,
        ShowId        = true,
        ShowDistance  = false,
        ShowHealth    = false,
        TextScale     = 0.35,
        -- COMPAT UNION : affiche firstname + lastname depuis statebag
        UseUnionNames = true,
    },
    PlayerBlips = {
        Enabled     = false,
        MaxDistance = 200.0,
        Sprite      = 1,
        Color       = 0,
        Scale       = 0.7,
    },
    RangeCircle = {
        Enabled = false,
        Radius  = 50.0,
        Color   = { r=59, g=130, b=246, a=60 },
    },
    VehicleInfo = {
        Enabled     = false,
        MaxDistance = 15.0,
        ShowPlate   = true,
        ShowSpeed   = false,
        ShowHealth  = false,
    },
}

-- ── Intégration Union Framework ───────────────────────────────────────────
KtContextConfig.UnionIntegration = {
    Enabled          = true,
    ResourceName     = 'union',
    -- Utilise PermissionSystem d'union côté serveur
    UseUnionPerms    = true,
    -- Enrichit l'overlay avec firstname/lastname/job depuis statebags
    UseUnionStatebag = true,
    -- false = garde le système NUI kt_context pour les notifications
    UseUnionNotify   = false,
}

KtContextConfig.Locales = {
    fr = {
        press_to_open         = 'Appuyez sur ~INPUT_CONTEXT~ pour ouvrir',
        vehicle_locked        = '🔒 Véhicule verrouillé',
        vehicle_unlocked      = '🔓 Véhicule déverrouillé',
        no_vehicle            = 'Aucun véhicule à proximité',
        not_enough_money      = "Vous n'avez pas assez d'argent",
        money_given           = 'Vous avez donné %s$',
        money_received        = 'Vous avez reçu %s$',
        admin_options         = 'Options Admin',
        cursor_hint           = 'Maintenez ALT et cliquez pour interagir',
        no_options            = 'Aucune interaction disponible',
        too_far               = 'Trop loin pour interagir',
        cooldown_wait         = 'Attendez avant de refaire cette action',
        npc_too_far           = 'Le PNJ est trop loin',
        prop_placed           = '📦 Objet placé',
        prop_deleted          = '🗑️ Objet supprimé',
        prop_too_far          = 'Trop loin pour placer un objet (max 3m)',
        prop_limit            = 'Vous avez déjà un objet placé',
        confirm_delete        = 'Confirmer la suppression ?',
        anim_vehicle          = 'Impossible en véhicule',
        access_denied         = '⛔ Accès refusé',
        overlay_player_names  = 'Noms des joueurs',
        overlay_player_blips  = 'Blips joueurs sur carte',
        overlay_range_circle  = 'Cercle de portée',
        overlay_vehicle_info  = 'Infos véhicules',
        overlay_enabled       = '✅ Overlay activé',
        overlay_disabled      = '❌ Overlay désactivé',
    },
    en = {
        press_to_open         = 'Press ~INPUT_CONTEXT~ to open',
        vehicle_locked        = '🔒 Vehicle locked',
        vehicle_unlocked      = '🔓 Vehicle unlocked',
        no_vehicle            = 'No vehicle nearby',
        not_enough_money      = "You don't have enough money",
        money_given           = 'You gave $%s',
        money_received        = 'You received $%s',
        admin_options         = 'Admin Options',
        cursor_hint           = 'Hold ALT and click to interact',
        no_options            = 'No interactions available',
        too_far               = 'Too far to interact',
        cooldown_wait         = 'Wait before doing this action again',
        npc_too_far           = 'NPC is too far away',
        prop_placed           = '📦 Object placed',
        prop_deleted          = '🗑️ Object deleted',
        prop_too_far          = 'Too far to place object (max 3m)',
        prop_limit            = 'You already have an active object',
        confirm_delete        = 'Confirm deletion?',
        anim_vehicle          = 'Cannot do this in a vehicle',
        access_denied         = '⛔ Access denied',
        overlay_player_names  = 'Player names',
        overlay_player_blips  = 'Player blips on map',
        overlay_range_circle  = 'Range circle',
        overlay_vehicle_info  = 'Vehicle info',
        overlay_enabled       = '✅ Overlay enabled',
        overlay_disabled      = '❌ Overlay disabled',
    }
}

-- ── Alias pour compatibilité standalone (sans union) ─────────────────────
-- Si union est chargé en premier, Config existe déjà (Config.spawn défini).
-- On ne l'écrase PAS. Tous les modules kt_context utilisent KtContextConfig.
if not Config or not Config.spawn then
    Config = KtContextConfig
end

-- L() locale : utilise _t() d'union si disponible, sinon KtContextConfig
function KtL(key)
    local locale = KtContextConfig.Locales[KtContextConfig.Locale]
        or KtContextConfig.Locales['fr']
    return locale[key] or key
end

if not L then L = KtL end
