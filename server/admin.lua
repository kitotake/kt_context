-- =============================================
-- ADMIN SERVEUR
-- =============================================
Admin = {}

Admin.Roles = {
    founder   = 'group.founder',
    admin     = 'group.admin',
    moderator = 'group.moderator',
}

function Admin.GetPlayerRole(source)
    for role, ace in pairs(Admin.Roles) do
        if IsPlayerAceAllowed(source, ace) then return role end
    end
    return nil
end

function Admin.IsAdmin(source)
    return Admin.GetPlayerRole(source) ~= nil
end

-- ─── Actions admin ────────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:admin:kick')
AddEventHandler('kt_context:admin:kick', function(targetId, reason)
    local source = source
    if not Admin.IsAdmin(source) then return end
    if not GetPlayerName(targetId) then return end
    DropPlayer(targetId, reason or 'Expulsé par un administrateur')
    TriggerClientEvent('kt_context:notify', source, ('Joueur %d expulsé'):format(targetId), 'success')
    ActionLogs:Add(source, 'admin', 'kick', { target = targetId, reason = reason })
end)

RegisterServerEvent('kt_context:admin:freeze')
AddEventHandler('kt_context:admin:freeze', function(targetId)
    local source = source
    if not Admin.IsAdmin(source) then return end
    TriggerClientEvent('kt_context:admin:freezeClient', targetId, true)
    ActionLogs:Add(source, 'admin', 'freeze', { target = targetId })
end)

RegisterServerEvent('kt_context:admin:spectate')
AddEventHandler('kt_context:admin:spectate', function(targetId)
    local source = source
    if not Admin.IsAdmin(source) then return end
    TriggerClientEvent('kt_context:admin:spectateClient', source, targetId)
    ActionLogs:Add(source, 'admin', 'spectate', { target = targetId })
end)

-- ─── Debug command ────────────────────────────────────────────────────────────
RegisterCommand('checkadmin', function(source)
    local role = Admin.GetPlayerRole(source) or 'user'
    print(('[ADMIN] %s | Role: %s'):format(GetPlayerName(source), role))
    TriggerClientEvent('kt_context:notify', source, ('Rôle: %s'):format(role), 'info')
end, false)