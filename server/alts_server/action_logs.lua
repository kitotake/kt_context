-- =============================================
-- LOGS D'ACTIONS SERVEUR
-- =============================================

local ActionLogs = { logs = {}, maxLogs = 1000 }

function ActionLogs:Add(source, actionType, action, data)
    local entry = {
        source     = source,
        playerName = GetPlayerName(source),
        identifier = GetPlayerIdentifierByType(source, "license"),
        actionType = actionType,
        action     = action,
        data       = data or {},
        timestamp  = os.time(),
        date       = os.date("%Y-%m-%d %H:%M:%S"),
    }
    table.insert(self.logs, 1, entry)
    if #self.logs > self.maxLogs then table.remove(self.logs) end
    print(string.format("[KT Log] [%s] %s (%d) – %s: %s",
        entry.date, entry.playerName, source, actionType, action))
    return entry
end

RegisterServerEvent("kt_context:logAction")
AddEventHandler("kt_context:logAction", function(actionType, action, data)
    ActionLogs:Add(source, actionType, action, data)
end)

RegisterServerEvent("kt_context:logVehicleAction")
AddEventHandler("kt_context:logVehicleAction", function(action, vehicleData)
    ActionLogs:Add(source, "vehicle", action, vehicleData)
end)

RegisterServerEvent("kt_context:logPlayerAction")
AddEventHandler("kt_context:logPlayerAction", function(action, targetId)
    ActionLogs:Add(source, "player", action, { targetId = targetId })
end)

RegisterServerEvent("kt_context:logAdminAction")
AddEventHandler("kt_context:logAdminAction", function(action, targetId, reason)
    if not IsPlayerAceAllowed(source, "admin") then
        ActionLogs:Add(source, "suspicious", "admin_attempt_" .. action, { warning = "Non autorisé" })
        return
    end
    ActionLogs:Add(source, "admin", action, { targetId = targetId, reason = reason })
end)

_G.ActionLogs = ActionLogs -- Expose global pour accès depuis d'autres ressources (ex: admin.lua)