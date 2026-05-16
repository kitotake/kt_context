-- =============================================
-- ADMIN SERVEUR — basé sur Permissions (DB)
-- =============================================
Admin = {}

function Admin.IsAdmin(src)
    return Permissions.Has(src, 'admin')
end

function Admin.GetRole(src)
    return Permissions.GetRole(src)
end

-- ─── Actions admin ────────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:admin:kick')
AddEventHandler('kt_context:admin:kick', function(targetId, reason)
    local src = source
    if not Admin.IsAdmin(src) then
        print(('[KT Admin] Tentative kick non autorisée par %d'):format(src))
        return
    end
    if not GetPlayerName(targetId) then return end
    DropPlayer(targetId, reason or 'Expulsé par un administrateur')
    TriggerClientEvent('kt_context:notify', src, ('Joueur %d expulsé'):format(targetId), 'success')
    ActionLogs:Add(src, 'admin', 'kick', { target = targetId, reason = reason })
end)

RegisterServerEvent('kt_context:admin:freeze')
AddEventHandler('kt_context:admin:freeze', function(targetId)
    local src = source
    if not Admin.IsAdmin(src) then return end
    TriggerClientEvent('kt_context:admin:freezeClient', targetId, true)
    ActionLogs:Add(src, 'admin', 'freeze', { target = targetId })
end)

RegisterServerEvent('kt_context:admin:spectate')
AddEventHandler('kt_context:admin:spectate', function(targetId)
    local src = source
    if not Admin.IsAdmin(src) then return end
    TriggerClientEvent('kt_context:admin:spectateClient', src, targetId)
    ActionLogs:Add(src, 'admin', 'spectate', { target = targetId })
end)

-- ─── Logs admin (actions depuis le client) ────────────────────────────────────
RegisterServerEvent('kt_context:logAdminAction')
AddEventHandler('kt_context:logAdminAction', function(action, targetId, reason)
    local src = source
    if not Admin.IsAdmin(src) then
        ActionLogs:Add(src, 'suspicious', 'admin_attempt_' .. tostring(action), { warning = 'Non autorisé' })
        return
    end
    ActionLogs:Add(src, 'admin', action, { targetId = targetId, reason = reason })
end)

-- ─── Commande debug ───────────────────────────────────────────────────────────
RegisterCommand('checkadmin', function(src)
    local role = Admin.GetRole(src)
    local isAdmin = Admin.IsAdmin(src)
    print(('[KT Admin] %s | Groupe: %s | Admin: %s'):format(GetPlayerName(src), role, tostring(isAdmin)))
    TriggerClientEvent('kt_context:notify', src, ('Groupe: %s | Admin: %s'):format(role, tostring(isAdmin)), 'info')
end, false)