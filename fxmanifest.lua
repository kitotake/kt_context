fx_version 'cerulean'
game 'gta5'

author      'Kitotake'
description 'Système de menu contextuel NUI — React + TypeScript + SCSS (v3.0)'
version     '3.0.0'

ui_page 'web/dist/index.html'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua',
    'shared/validators.lua',
}

client_scripts {
    -- 1. Utils (fonctions de base, RotationToDirection, ShowNotification…)
    'client/utils.lua',

    -- 2. Sync permissions (définit Permissions.group)
    'client/sync.lua',

    -- 3. Menu principal (OpenContextMenu, CloseContextMenu, IsMenuOpen, handlers)
    'client/main.lua',

    -- 4. Zones interactives
    'client/zones.lua',

    -- 5. Modules alt-client — ordre important :
    --    entity_menus.lua AVANT cursor.lua car cursor appelle Build*Menu
    'client/alts_client/keybinds.lua',
    'client/alts_client/quick_actions.lua',
    'client/alts_client/radial_menu.lua',
    'client/alts_client/debug_target.lua',
    'client/alts_client/entity_menus.lua',   -- << NOUVEAU — Build*Menu
    'client/alts_client/cursor.lua',          -- dépend de entity_menus.lua

    -- 6. Exemples (chargés en dernier)
    'client/examples/*.lua',
}

server_scripts {
    'server/main.lua',
    'server/permissions.lua',
    'server/admin.lua',
    'server/alts_server/action_logs.lua',
}

files {
    'web/dist/index.html',
    'web/dist/**/*',
}

exports {
    'OpenContextMenu',
    'CloseContextMenu',
    'IsMenuOpen',
    'RegisterMenuZone',
    'RemoveMenuZone',
    'RegisterKeybind',
    'ToggleKeybind',
    'ToggleAllKeybinds',
}