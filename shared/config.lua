-- =============================================
-- CONFIG GLOBAL — v3.1 (fixed)
-- =============================================
Config = {}

Config.Locale = 'fr'

-- Touche de déclenchement du curseur (ALT GAUCHE = 19)
Config.CursorKey     = 19
Config.CursorKeyName = 'LALT'

-- Distance max pour détecter les entités au clic
Config.InteractionDistance = 5.0

-- Profondeur max des sous-menus
Config.MaxSubmenuDepth = 6

-- Rôles admin (groupes DB)
Config.AdminGroups = { 'admin', 'moderator', 'founder' }
Config.StaffGroups = { 'admin', 'moderator', 'founder', 'staff' }

-- ─── Limites d'utilisation ────────────────────────────────────────────────────
Config.Limits = {
    -- Interactions PNJ
    NpcCooldown        = 5000,   -- ms entre deux interactions PNJ
    NpcMaxDistance     = 3.0,    -- m portée max pour interagir avec un PNJ

    -- Animations
    AnimCooldown       = 2000,   -- ms entre deux animations
    AnimBlockInVehicle = true,   -- bloquer les anims en véhicule

    -- Props / objets posés
    PropMaxDistance    = 3.0,    -- m max depuis le joueur pour placer un prop
    PropMaxHeight      = 2.0,    -- m d'écart vertical autorisé
    PropMaxActive      = 1,      -- nb de props actifs par joueur
    PropRotateStep     = 15.0,   -- degrés par clic de rotation

    -- Actions admin
    AdminConfirmDelete = true,   -- demander confirmation avant suppression d'entité
    AdminLogAll        = true,   -- logger TOUTES les actions admin

    -- Rate limiting serveur (anti-spam)
    ServerActionCooldown = 500,  -- ms min entre deux events serveur par joueur

    -- Déplacement joueur (for zones, interactions)
    MaxInteractMoveDistance = 3.0, -- m max depuis l'ouverture du menu
}

-- ─── Rotation (fusionné depuis config_rotation.lua) ──────────────────────────
Config.Rotation = {
    DefaultPropName     = 'prop_mp_barrier_01a',
    DefaultPosition     = vector3(0.0, 0.0, 0.0), -- sera recalculé au placement
    DefaultRotation     = vector3(0.0, 0.0, 0.0),
    DeleteRadius        = 5.0,
    SnapToGround        = true,
    AllowedProps        = {},   -- vide = tous autorisés (admin seulement si rempli)
}

-- ─── Animation du curseur ─────────────────────────────────────────────────────
Config.CursorFadeIn = 150

-- ─── Locales ──────────────────────────────────────────────────────────────────
Config.Locales = {
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
    }
}

function L(key)
    local locale = Config.Locales[Config.Locale] or Config.Locales['fr']
    return locale[key] or key
end
