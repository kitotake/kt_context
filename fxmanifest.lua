fx_version 'cerulean'
game 'gta5'

author 'Kitotake'
description 'Système de menu contextuel NUI – React + TypeScript + SCSS (v2.0)'
version '2.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua',
}


ui_page 'web/dist/index.html'

client_scripts {
    'client/utils.lua',
    'client/main.lua',
    'client/cursor.lua',
    'client/zones.lua',
    'client/sync.lua',
    'client/alts_client/keybinds.lua',
    'client/alts_client/quick_actions.lua',
    'client/alts_client/radial_menu.lua',
    'client/examples/*.lua'
}

server_scripts {
    'server/main.lua',
    'server/admin.lua',
    'server/permissions.lua',
    'server/alts_server/action_logs.lua'
}

files {
    'web/dist/index.html',
    'web/dist/**/*'
}

exports {
    'OpenContextMenu',
    'CloseContextMenu',
    'IsMenuOpen',
    'RegisterMenuZone',
    'RemoveMenuZone'
}

dependencies {}
