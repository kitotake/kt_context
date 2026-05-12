fx_version 'cerulean'
game 'gta5'

author 'Kitotake'
description 'Système de menu contextuel NUI avec React + TypeScript'
version '1.0.0'

ui_page 'web/build/index.html'

client_scripts {
    'client/utils.lua',        -- Utils doit être chargé EN PREMIER
    'client/main.lua',
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
    'IsMenuOpen'
}

dependencies {
    -- Aucune dépendance requise
}