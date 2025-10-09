-- =============================================
-- SYSTÈME DE LOGS POUR ACTIONS & KEYBINDS
-- =============================================

local ActionLogs = {
    logs = {},
    maxLogs = 1000,
    webhooks = {
        admin = "",  -- Webhook Discord pour actions admin
        general = "", -- Webhook Discord pour actions générales
        suspicious = "" -- Webhook pour actions suspectes
    }
}

-- Ajouter un log
function ActionLogs:Add(source, actionType, action, data)
    local playerName = GetPlayerName(source)
    local identifier = GetPlayerIdentifierByType(source, "license")
    local timestamp = os.time()
    
    local logEntry = {
        source = source,
        playerName = playerName,
        identifier = identifier,
        actionType = actionType,
        action = action,
        data = data or {},
        timestamp = timestamp,
        date = os.date("%Y-%m-%d %H:%M:%S", timestamp)
    }
    
    table.insert(self.logs, 1, logEntry)
    
    -- Limiter la taille des logs
    if #self.logs > self.maxLogs then
        table.remove(self.logs, #self.logs)
    end
    
    -- Envoyer au webhook si configuré
    self:SendToWebhook(logEntry)
    
    -- Afficher dans la console
    print(string.format(
        "[KT Context] [%s] %s (%s) - %s: %s",
        logEntry.date,
        playerName,
        source,
        actionType,
        action
    ))
    
    return logEntry
end

-- Obtenir les logs
function ActionLogs:Get(filters)
    if not filters then
        return self.logs
    end
    
    local filtered = {}
    
    for _, log in ipairs(self.logs) do
        local match = true
        
        if filters.source and log.source ~= filters.source then
            match = false
        end
        
        if filters.actionType and log.actionType ~= filters.actionType then
            match = false
        end
        
        if filters.action and log.action ~= filters.action then
            match = false
        end
        
        if filters.startTime and log.timestamp < filters.startTime then
            match = false
        end
        
        if filters.endTime and log.timestamp > filters.endTime then
            match = false
        end
        
        if match then
            table.insert(filtered, log)
        end
    end
    
    return filtered
end

-- Envoyer au webhook Discord
function ActionLogs:SendToWebhook(logEntry)
    local webhookUrl = nil
    
    if logEntry.actionType == "admin" then
        webhookUrl = self.webhooks.admin
    elseif logEntry.actionType == "suspicious" then
        webhookUrl = self.webhooks.suspicious
    else
        webhookUrl = self.webhooks.general
    end
    
    if not webhookUrl or webhookUrl == "" then
        return
    end
    
    local color = 3447003 -- Bleu par défaut
    if logEntry.actionType == "admin" then
        color = 15844367 -- Rouge pour admin
    elseif logEntry.actionType == "suspicious" then
        color = 16776960 -- Jaune pour suspect
    end
    
    local embed = {
        {
            ["title"] = "Action Loguée",
            ["description"] = string.format("**%s** a effectué une action", logEntry.playerName),
            ["color"] = color,
            ["fields"] = {
                {
                    ["name"] = "Type",
                    ["value"] = logEntry.actionType,
                    ["inline"] = true
                },
                {
                    ["name"] = "Action",
                    ["value"] = logEntry.action,
                    ["inline"] = true
                },
                {
                    ["name"] = "Joueur",
                    ["value"] = string.format("%s (ID: %d)", logEntry.playerName, logEntry.source),
                    ["inline"] = false
                },
                {
                    ["name"] = "Identifier",
                    ["value"] = logEntry.identifier or "N/A",
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "KT Context Menu System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S", logEntry.timestamp)
        }
    }
    
    -- Ajouter les données supplémentaires
    if logEntry.data and next(logEntry.data) then
        local dataStr = json.encode(logEntry.data)
        table.insert(embed[1].fields, {
            ["name"] = "Données",
            ["value"] = "```json\n" .. dataStr .. "\n```",
            ["inline"] = false
        })
    end
    
    PerformHttpRequest(webhookUrl, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print("[KT Context] Erreur webhook Discord: " .. err)
        end
    end, 'POST', json.encode({
        username = "KT Context Logger",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Effacer les logs
function ActionLogs:Clear()
    self.logs = {}
    print("[KT Context] Logs effacés")
end

-- Exporter les logs vers un fichier
function ActionLogs:ExportToFile(filename)
    filename = filename or ("logs_" .. os.date("%Y%m%d_%H%M%S") .. ".json")
    local path = "logs/" .. filename
    
    SaveResourceFile(GetCurrentResourceName(), path, json.encode(self.logs, {indent = true}))
    print("[KT Context] Logs exportés vers: " .. path)
    
    return path
end

-- Events serveur pour logger les actions
RegisterServerEvent("kt_context:logAction")
AddEventHandler("kt_context:logAction", function(actionType, action, data)
    local source = source
    ActionLogs:Add(source, actionType, action, data)
end)

-- Keybind utilisé
RegisterServerEvent("kt_context:logKeybind")
AddEventHandler("kt_context:logKeybind", function(keybindId, keybindName)
    local source = source
    ActionLogs:Add(source, "keybind", keybindId, {
        name = keybindName
    })
end)

-- Action véhicule
RegisterServerEvent("kt_context:logVehicleAction")
AddEventHandler("kt_context:logVehicleAction", function(action, vehicleData)
    local source = source
    ActionLogs:Add(source, "vehicle", action, vehicleData)
end)

-- Action joueur
RegisterServerEvent("kt_context:logPlayerAction")
AddEventHandler("kt_context:logPlayerAction", function(action, targetId)
    local source = source
    local targetName = targetId and GetPlayerName(targetId) or "N/A"
    
    ActionLogs:Add(source, "player", action, {
        targetId = targetId,
        targetName = targetName
    })
end)

-- Action admin
RegisterServerEvent("kt_context:logAdminAction")
AddEventHandler("kt_context:logAdminAction", function(action, targetId, reason)
    local source = source
    
    -- Vérifier les permissions
    if not IsPlayerAceAllowed(source, "admin") then
        ActionLogs:Add(source, "suspicious", "admin_attempt_" .. action, {
            targetId = targetId,
            reason = reason,
            warning = "Tentative non autorisée"
        })
        return
    end
    
    local targetName = targetId and GetPlayerName(targetId) or "N/A"
    
    ActionLogs:Add(source, "admin", action, {
        targetId = targetId,
        targetName = targetName,
        reason = reason
    })
end)

-- Menu ouvert
RegisterServerEvent("kt_context:logMenuOpen")
AddEventHandler("kt_context:logMenuOpen", function(menuName)
    local source = source
    ActionLogs:Add(source, "menu", "open_" .. menuName, {})
end)

-- Commandes admin pour gérer les logs
RegisterCommand("logs", function(source, args)
    if not IsPlayerAceAllowed(source, "admin") then
        TriggerClientEvent("chat:addMessage", source, {
            color = {255, 0, 0},
            args = {"[Logs]", "Accès refusé"}
        })
        return
    end
    
    if args[1] == "clear" then
        ActionLogs:Clear()
        TriggerClientEvent("chat:addMessage", source, {
            color = {0, 255, 0},
            args = {"[Logs]", "Logs effacés avec succès"}
        })
    elseif args[1] == "export" then
        local path = ActionLogs:ExportToFile()
        TriggerClientEvent("chat:addMessage", source, {
            color = {0, 255, 0},
            args = {"[Logs]", "Logs exportés vers: " .. path}
        })
    elseif args[1] == "count" then
        TriggerClientEvent("chat:addMessage", source, {
            color = {59, 130, 246},
            args = {"[Logs]", string.format("%d logs enregistrés", #ActionLogs.logs)}
        })
    elseif args[1] == "player" and args[2] then
        local targetId = tonumber(args[2])
        local playerLogs = ActionLogs:Get({ source = targetId })
        
        TriggerClientEvent("chat:addMessage", source, {
            color = {59, 130, 246},
            args = {"[Logs]", string.format("%d logs pour le joueur %d", #playerLogs, targetId)}
        })
        
        -- Afficher les 5 derniers
        for i = 1, math.min(5, #playerLogs) do
            local log = playerLogs[i]
            TriggerClientEvent("chat:addMessage", source, {
                color = {200, 200, 200},
                args = {"", string.format("[%s] %s: %s", log.date, log.actionType, log.action)}
            })
        end
    else
        TriggerClientEvent("chat:addMessage", source, {
            color = {255, 165, 0},
            args = {"[Logs]", "Usage: /logs [clear|export|count|player <id>]"}
        })
    end
end, false)

RegisterCommand("viewlogs", function(source, args)
    if not IsPlayerAceAllowed(source, "admin") then return end
    
    local limit = tonumber(args[1]) or 10
    limit = math.min(limit, 50)
    
    TriggerClientEvent("chat:addMessage", source, {
        color = {59, 130, 246},
        args = {"[Logs]", string.format("=== %d derniers logs ===", limit)}
    })
    
    for i = 1, math.min(limit, #ActionLogs.logs) do
        local log = ActionLogs.logs[i]
        TriggerClientEvent("chat:addMessage", source, {
            color = {200, 200, 200},
            args = {"", string.format(
                "[%s] %s (%d) - %s: %s",
                log.date,
                log.playerName,
                log.source,
                log.actionType,
                log.action
            )}
        })
    end
end, false)

RegisterCommand("searchlogs", function(source, args)
    if not IsPlayerAceAllowed(source, "admin") then return end
    
    if not args[1] then
        TriggerClientEvent("chat:addMessage", source, {
            color = {255, 165, 0},
            args = {"[Logs]", "Usage: /searchlogs <type> [action]"}
        })
        return
    end
    
    local filters = {
        actionType = args[1],
        action = args[2]
    }
    
    local results = ActionLogs:Get(filters)
    
    TriggerClientEvent("chat:addMessage", source, {
        color = {59, 130, 246},
        args = {"[Logs]", string.format("%d résultats trouvés", #results)}
    })
    
    for i = 1, math.min(10, #results) do
        local log = results[i]
        TriggerClientEvent("chat:addMessage", source, {
            color = {200, 200, 200},
            args = {"", string.format(
                "[%s] %s - %s",
                log.date,
                log.playerName,
                log.action
            )}
        })
    end
end, false)

-- Export
_G.ActionLogs = ActionLogs