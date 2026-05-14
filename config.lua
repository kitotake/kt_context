-- =============================================
-- CONFIG GLOBAL
-- =============================================
Config = {}

Config.Locale = 'fr'

-- Touche de déclenchement du curseur (ALT GAUCHE = 19)
Config.CursorKey = 19         -- Left Alt
Config.CursorKeyName = 'LALT' -- Nom pour RegisterKeyMapping

-- Distance max pour détecter les entités au clic
Config.InteractionDistance = 5.0

-- Rôles admin autorisés à voir les options supplémentaires
Config.AdminRoles = {
    'admin',
    'moderator',
    'founder',
    'superadmin'
}

-- Ace permissions requises pour les rôles admin
Config.AdminAces = {
    admin    = 'admin',
    moderator = 'moderator',
    founder  = 'founder',
}

-- Profondeur max des sous-menus
Config.MaxSubmenuDepth = 6

-- Animation du curseur (durée en ms)
Config.CursorFadeIn = 150

-- Zones interactives prédéfinies
-- Chaque zone déclenche un menu lorsqu'un joueur entre dedans et clique
Config.MenuZones = {}

-- Locales
Config.Locales = {
    fr = {
        press_to_open     = "Appuyez sur ~INPUT_CONTEXT~ pour ouvrir",
        vehicle_locked    = "🔒 Véhicule verrouillé",
        vehicle_unlocked  = "🔓 Véhicule déverrouillé",
        no_vehicle        = "Aucun véhicule à proximité",
        not_enough_money  = "Vous n'avez pas assez d'argent",
        money_given       = "Vous avez donné %s$",
        money_received    = "Vous avez reçu %s$",
        admin_options     = "Options Admin",
        cursor_hint       = "Maintenez ALT et cliquez pour interagir",
    },
    en = {
        press_to_open     = "Press ~INPUT_CONTEXT~ to open",
        vehicle_locked    = "🔒 Vehicle locked",
        vehicle_unlocked  = "🔓 Vehicle unlocked",
        no_vehicle        = "No vehicle nearby",
        not_enough_money  = "You don't have enough money",
        money_given       = "You gave $%s",
        money_received    = "You received $%s",
        admin_options     = "Admin Options",
        cursor_hint       = "Hold ALT and click to interact",
    }
}

-- Helper locale
function L(key)
    local locale = Config.Locales[Config.Locale] or Config.Locales['fr']
    return locale[key] or key
end
