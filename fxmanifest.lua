fx_version 'cerulean'
game 'gta5'

author 'Kitotake'
description 'Système de menu contextuel NUI avec React + TypeScript'
version '1.0.0'

ui_page 'nui/build/index.html'

client_scripts {
    'client/main.lua',
    'client/utils.lua',
    'client/examples/*.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'nui/build/index.html',
    'nui/build/**/*'
}

dependencies {
    -- Aucune dépendance requise
}