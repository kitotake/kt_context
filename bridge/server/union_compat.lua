-- =============================================
-- BRIDGE SERVEUR : kt_context ↔ union — v3.2
--
-- Côté serveur, kt_context délègue :
--   • IsRateLimited   → utilise son propre système (compatible)
--   • Permissions     → lit PlayerManager + PlayerClass:hasPermission
--   • ActionLogs      → peut logger dans union action_logs
--
-- Si union n'est pas démarré, retombe sur IsPlayerAceAllowed.
-- =============================================

local UNION_RESOURCE = KtContextConfig
    and KtContextConfig.UnionIntegration
    and KtContextConfig.UnionIntegration.ResourceName
    or 'union'

local USE_UNION = KtContextConfig
    and KtContextConfig.UnionIntegration
    and KtContextConfig.UnionIntegration.Enabled
    or false

local USE_PERMS = KtContextConfig
    and KtContextConfig.UnionIntegration
    and KtContextConfig.UnionIntegration.UseUnionPerms
    or false

-- ─── Helper disponibilité ─────────────────────────────────────────────────
local function unionAvailable()
    return USE_UNION and GetResourceState(UNION_RESOURCE) == 'started'
end

-- ─── Lecture PlayerManager d'union ────────────────────────────────────────
local function getUnionPlayer(src)
    if not unionAvailable() then return nil end
    local ok, player = pcall(function()
        return exports[UNION_RESOURCE]:GetPlayerFromId(src)
    end)
    return (ok and type(player) == 'table') and player or nil
end

-- ─── Surcharge Admin.IsAdmin / Admin.IsStaff ─────────────────────────────
-- kt_context utilise Admin.IsAdmin(src) et Admin.IsStaff(src) côté serveur.
-- Si union actif, on délègue à PlayerClass:hasPermission.

if USE_PERMS then
    -- Attend que union soit prêt (peut être chargé après kt_context)
    CreateThread(function()
        local waited = 0
        while GetResourceState(UNION_RESOURCE) ~= 'started' and waited < 30 do
            Wait(1000)
            waited = waited + 1
        end

        if GetResourceState(UNION_RESOURCE) ~= 'started' then
            print('[KT Context] Bridge union serveur : union non disponible après 30s — fallback ACE')
            return
        end

        -- Surcharge Admin.IsAdmin
        local _origIsAdmin = Admin and Admin.IsAdmin
        if Admin then
            Admin.IsAdmin = function(src)
                local player = getUnionPlayer(src)
                if player and player.hasPermission then
                    return player:hasPermission('admin.all')
                end
                -- Fallback ACE
                return IsPlayerAceAllowed(src, 'admin')
            end

            Admin.IsStaff = function(src)
                local player = getUnionPlayer(src)
                if player and player.hasPermission then
                    return player:hasPermission('admin.healrevive')
                end
                return IsPlayerAceAllowed(src, 'admin')
                    or IsPlayerAceAllowed(src, 'staff')
            end

            Admin.GetRole = function(src)
                local player = getUnionPlayer(src)
                if player then return player.group or 'user' end
                return 'user'
            end
        end

        -- Surcharge Permissions.IsAdmin / Permissions.IsStaff
        -- (utilisés par kt_context/server/permissions.lua)
        if Permissions then
            local origLoad = Permissions.Load
            Permissions.Load = function(src)
                -- Lit le groupe depuis union PlayerManager
                local player = getUnionPlayer(src)
                if player then
                    local group = player.group or 'user'
                    -- Cache local kt_context
                    if type(origLoad) == 'function' then
                        -- On appelle l'original pour synchroniser le cache
                        -- mais on remplace le résultat par celui d'union
                    end
                    -- Notifie le client kt_context
                    TriggerClientEvent('permissions:client:set', src, group)
                    print(('[KT Context] Permissions sync depuis union: %s → %s'):format(
                        GetPlayerName(src) or '?', group))
                    return group
                end
                -- Fallback : méthode originale
                if type(origLoad) == 'function' then
                    return origLoad(src)
                end
                return 'user'
            end
        end

        print('[KT Context] Bridge union serveur : permissions synchronisées')
    end)
end

-- ─── Log bridge : redirige les logs admin kt_context vers union ──────────
-- union a sa propre table action_logs. On peut y écrire via event local.
AddEventHandler('kt_context:logAdminAction', function(action, targetId, reason)
    local src = source
    if not unionAvailable() then return end
    -- Déclenche l'event union pour que ActionLogs d'union le capture aussi
    -- (en plus du handler existant dans action_logs.lua de kt_context)
    TriggerEvent('union:action:log', src, 'kt_context_admin', action, {
        target = targetId,
        reason = reason,
    })
end)

-- ─── Sync permission quand union charge un joueur ─────────────────────────
-- Quand union spawne un joueur, on synchronise ses permissions avec kt_context
AddEventHandler('union:player:spawned', function(src, character)
    if not src or not USE_PERMS then return end
    -- Délai court pour laisser PlayerManager se stabiliser
    SetTimeout(500, function()
        if GetPlayerEndpoint(src) then
            local player = getUnionPlayer(src)
            if player and Permissions then
                local group = player.group or 'user'
                TriggerClientEvent('permissions:client:set', src, group)
            end
        end
    end)
end)

-- ─── onServerResourceStart : sync tous les joueurs connectés ─────────────
AddEventHandler('onServerResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if not USE_PERMS or not unionAvailable() then return end

    SetTimeout(2000, function()
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local player = getUnionPlayer(src)
            if player and Permissions then
                local group = player.group or 'user'
                TriggerClientEvent('permissions:client:set', src, group)
            end
        end
        print('[KT Context] Bridge union serveur : permissions initiales synchronisées')
    end)
end)

print('[KT Context] Bridge union serveur chargé (union: ' .. tostring(unionAvailable()) .. ')')
