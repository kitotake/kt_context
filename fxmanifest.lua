fx_version 'cerulean'
game 'gta5'

author 'Kitotake'
description 'Systeme de menu contextuel NUI - React + TypeScript + SCSS (v3.1)'
version '3.1.0'

ui_page 'web/dist/index.html'

shared_script '@kt_lib/init.lua'

shared_scripts {
    'shared/locales/*.lua',
    'shared/config.lua',
    'shared/utils.lua',
    'shared/validators.lua',
}

client_scripts {
    'client/utils.lua',
    'client/sync.lua',
    'client/main.lua',
    'client/zones.lua',

    'client/alts_client/keybinds.lua',
    'client/alts_client/quick_actions.lua',
    'client/alts_client/radial_menu.lua',
    'client/alts_client/debug_target.lua',
    'client/alts_client/entity_menus.lua',
    'client/alts_client/cursor.lua',

    -- ROTATION SYSTEM
    -- dataview doit être chargé AVANT gizmo et client
    'client/alts_client/rotation/dataview.lua',
    'client/alts_client/rotation/client.lua',
    'client/alts_client/rotation/gizmo.lua',

    -- Exemples (glob unique, pas de doublon)
    'client/examples/*.lua',
}

server_scripts {
    'server/main.lua',
    'server/permissions.lua',
    'server/admin.lua',
    'server/alts_server/action_logs.lua',
    'server/alts_server/rotation_server.lua',
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
    'PlaceProp',
    'DeleteProp',
    'OpenPropMenu',
    'useGizmo',
}