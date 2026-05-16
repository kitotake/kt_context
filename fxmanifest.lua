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
    'client/utils.lua',
    'client/sync.lua',
    'client/main.lua',
    'client/cursor.lua',
    'client/zones.lua',
    'client/alts_client/keybinds.lua',
    'client/alts_client/quick_actions.lua',
    'client/alts_client/radial_menu.lua',
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