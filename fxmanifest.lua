fx_version 'cerulean'
game 'gta5'

author 'Kitotake'
description 'Système de menu contextuel NUI – React + TypeScript + SCSS (v2.0)'
version '2.0.0'

ui_page 'web/build/index.html'

client_scripts {
    'config.lua',
    'client/utils.lua',
    'client/main.lua',
    'client/cursor.lua',
    'client/zones.lua',
    'client/alts_client/keybinds.lua',
    'client/alts_client/quick_actions.lua',
    'client/alts_client/radial_menu.lua',
    'client/examples/*.lua'
}

server_scripts {
    'server/main.lua',
    'server/alts_server/action_logs.lua'
}

shared_scripts {
    'config.lua'
}

files {
    'web/build/index.html',
    'web/build/**/*'
}

exports {
    'OpenContextMenu',
    'CloseContextMenu',
    'IsMenuOpen',
    'RegisterMenuZone'
}

dependencies {}
