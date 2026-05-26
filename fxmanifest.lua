-- =============================================
-- fxmanifest.lua — kt_context v3.2 + bridge kt_interact
-- REMPLACE le fxmanifest.lua original de kt_context
-- =============================================
fx_version 'cerulean'
game 'gta5'

author 'Kitotake'
description 'Systeme de menu contextuel NUI - React + TypeScript + SCSS (v3.2) + Bridge kt_interact'
version '3.2.1'

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
    'client/alts_client/overlay.lua',

    -- Bridge kt_interact (AVANT cursor.lua pour que les fonctions soient dispo)
    'bridge/client/kt_interact_compat.lua',

    -- cursor.lua patché (remplace l'original — contient l'injection kt_interact)
    'bridge/patches/cursor_patched.lua',

    -- ROTATION SYSTEM
    'client/alts_client/rotation/dataview.lua',
    'client/alts_client/rotation/client.lua',
    'client/alts_client/rotation/gizmo.lua',

    -- Bridge union (EN DERNIER côté client)
    'bridge/client/union_compat.lua',

    -- Exemples
    'client/examples/*.lua',
}

server_scripts {
    'server/main.lua',
    'server/permissions.lua',
    'server/admin.lua',
    'server/alts_server/action_logs.lua',
    'server/alts_server/rotation_server.lua',

    -- Bridge kt_interact serveur
    'bridge/server/kt_interact_compat.lua',

    -- Bridge union (EN DERNIER côté serveur)
    'bridge/server/union_compat.lua',
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
    'BuildOverlayMenu',
    'IsOverlayActive',
    'KtGetPlayerDisplayName',
    'KtGetLocalJob',
    'KtGetUniqueId',
    -- Nouveaux exports bridge kt_interact
    'KtInteract_GetMenuItems',
    'KtInteract_GetGeneralMenuItems',
    'KtInteract_Trigger',
    'KtInteract_GetCacheCount',
}
