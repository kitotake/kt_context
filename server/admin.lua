-- =============================================
-- ADMIN SERVEUR — v3.1 (fixed)
-- FIXES :
--   - Rate limiting sur kick/freeze/spectate
--   - Staff peut heal mais pas kick/ban
--   - Logs systematiques (Config.Limits.AdminLogAll)
-- =============================================
Admin = {}

function Admin.IsAdmin(src)
    return Permissions and Permissions.Has(src, 'admin') or IsPlayerAceAllowed(src, 'admin')
end

function Admin.IsStaff(src)
    return Permissions and Permissions.Has(src, 'staff') or Admin.IsAdmin(src)
end

function Admin.GetRole(src)
    return Permissions and Permissions.GetRole(src) or 'user'
end

-- ─── Kick ─────────────────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:admin:kick')
AddEventHandler('kt_context:admin:kick', function(targetId, reason)
    local src = source
    if not Admin.IsAdmin(src) then
        print(('[KT Admin] Tentative kick non autorisee par %d'):format(src))
        ActionLogs:Add(src, 'suspicious', 'kick_attempt', { target = targetId })
        return
    end
    if IsRateLimited and IsRateLimited(src, 'admin_kick', 3000) then
        TriggerClientEvent('kt_context:notify', src, 'Action trop rapide', 'warning')
        return
    end
    if not GetPlayerName(targetId) then
        TriggerClientEvent('kt_context:notify', src, 'Joueur introuvable', 'error')
        return
    end
    DropPlayer(targetId, reason or 'Expulse par un administrateur')
    TriggerClientEvent('kt_context:notify', src, ('Joueur %d expulse'):format(targetId), 'success')
    ActionLogs:Add(src, 'admin', 'kick', { target = targetId, reason = reason })
end)

-- ─── Freeze ───────────────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:admin:freeze')
AddEventHandler('kt_context:admin:freeze', function(targetId)
    local src = source
    if not Admin.IsStaff(src) then return end
    if IsRateLimited and IsRateLimited(src, 'admin_freeze', 2000) then return end
    TriggerClientEvent('kt_context:admin:freezeClient', targetId, true)
    ActionLogs:Add(src, 'admin', 'freeze', { target = targetId })
end)

-- ─── Spectate ─────────────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:admin:spectate')
AddEventHandler('kt_context:admin:spectate', function(targetId)
    local src = source
    if not Admin.IsStaff(src) then return end
    TriggerClientEvent('kt_context:admin:spectateClient', src, targetId)
    ActionLogs:Add(src, 'admin', 'spectate', { target = targetId })
end)

-- ─── Heal d'un joueur cible (staff autorise) ──────────────────────────────────
RegisterServerEvent('kt_context:admin:healTarget')
AddEventHandler('kt_context:admin:healTarget', function(targetId)
    local src = source
    if not Admin.IsStaff(src) then
        TriggerClientEvent('kt_context:notify', src, 'Acces refuse', 'error')
        return
    end
    TriggerClientEvent('kt_context:admin:healClient', targetId)
    ActionLogs:Add(src, 'admin', 'heal_target', { target = targetId })
end)

-- ─── Logs admin client ────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:logAdminAction')
AddEventHandler('kt_context:logAdminAction', function(action, targetId, reason)
    local src = source
    if not Admin.IsStaff(src) then
        ActionLogs:Add(src, 'suspicious', 'admin_attempt_' .. tostring(action), { warning = 'Non autorise' })
        return
    end
    ActionLogs:Add(src, 'admin', action, { targetId = targetId, reason = reason })
end)

-- ─── Commande debug ───────────────────────────────────────────────────────────
RegisterCommand('checkadmin', function(src)
    local role    = Admin.GetRole(src)
    local isAdmin = Admin.IsAdmin(src)
    local isStaff = Admin.IsStaff(src)
    print(('[KT Admin] %s | Role: %s | Admin: %s | Staff: %s'):format(
        GetPlayerName(src) or '?', role, tostring(isAdmin), tostring(isStaff)))
    TriggerClientEvent('kt_context:notify', src,
        ('Role: %s | Admin: %s'):format(role, tostring(isAdmin)), 'info')
end, false)
