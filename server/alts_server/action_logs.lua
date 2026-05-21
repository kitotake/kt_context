-- =============================================
-- LOGS D'ACTIONS SERVEUR — v3.2
-- FIX : ce fichier est la SOURCE UNIQUE du handler 'kt_context:logAdminAction'
--       (admin.lua ne doit PAS redéfinir ce handler)
-- =============================================

ActionLogs = { logs = {}, maxLogs = 1000 }

function ActionLogs:Add(src, actionType, action, data)
    local entry = {
        source     = src,
        playerName = GetPlayerName(src) or '?',
        identifier = GetPlayerIdentifierByType(src, 'license') or 'unknown',
        actionType = actionType,
        action     = action,
        data       = data or {},
        timestamp  = os.time(),
        date       = os.date('%Y-%m-%d %H:%M:%S'),
    }
    table.insert(self.logs, 1, entry)
    if #self.logs > self.maxLogs then
        table.remove(self.logs)
    end
    print(('[KT Log] [%s] %s (%d) — %s: %s'):format(
        entry.date, entry.playerName, src, actionType, action))
    return entry
end

function ActionLogs:GetLast(n)
    local result = {}
    for i = 1, math.min(n or 10, #self.logs) do
        result[i] = self.logs[i]
    end
    return result
end

function ActionLogs:GetByPlayer(src)
    local result = {}
    for _, log in ipairs(self.logs) do
        if log.source == src then
            table.insert(result, log)
        end
    end
    return result
end

-- ─── Événements ──────────────────────────────────────────────────────────────
RegisterServerEvent('kt_context:logAction')
AddEventHandler('kt_context:logAction', function(actionType, action, data)
    ActionLogs:Add(source, actionType, action, data)
end)

RegisterServerEvent('kt_context:logVehicleAction')
AddEventHandler('kt_context:logVehicleAction', function(action, vehicleData)
    ActionLogs:Add(source, 'vehicle', action, vehicleData)
end)

RegisterServerEvent('kt_context:logPlayerAction')
AddEventHandler('kt_context:logPlayerAction', function(action, targetId)
    ActionLogs:Add(source, 'player', action, { targetId = targetId })
end)

-- FIX : handler UNIQUE pour logAdminAction (supprimé dans admin.lua)
-- La vérification ACE est faite ici ; si Permissions est chargé, on l'utilise en priorité.
RegisterServerEvent('kt_context:logAdminAction')
AddEventHandler('kt_context:logAdminAction', function(action, targetId, reason)
    local src = source
    local isStaff = (Permissions and Permissions.IsStaff(src))
        or IsPlayerAceAllowed(src, 'admin')
        or IsPlayerAceAllowed(src, 'staff')
        or IsPlayerAceAllowed(src, 'moderator')

    if not isStaff then
        ActionLogs:Add(src, 'suspicious', 'admin_attempt_' .. tostring(action),
            { warning = 'Non autorisé' })
        return
    end
    ActionLogs:Add(src, 'admin', action, { targetId = targetId, reason = reason })
end)

-- ─── Commande logs ────────────────────────────────────────────────────────────
RegisterCommand('ktlogs', function(src, args)
    if not IsPlayerAceAllowed(src, 'admin') then
        TriggerClientEvent('kt_context:notify', src, 'Accès refusé', 'error')
        return
    end
    local n    = tonumber(args[1]) or 10
    local logs = ActionLogs:GetLast(n)
    for _, log in ipairs(logs) do
        print(('[KT Log] %s | %s | %s | %s'):format(
            log.date, log.playerName, log.actionType, log.action))
    end
    TriggerClientEvent('kt_context:notify', src,
        ('%d log(s) affichés — voir console'):format(#logs), 'info')
end, false)