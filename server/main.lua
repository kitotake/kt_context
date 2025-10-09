RegisterServerEvent("kt_context:server:transferMoney")
AddEventHandler("kt_context:server:transferMoney", function(targetId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if xPlayer and xTarget then
        if xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            xTarget.addMoney(amount)
            
            TriggerClientEvent("esx:showNotification", source, 
                "Vous avez donné $" .. amount .. " à " .. GetPlayerName(targetId))
            TriggerClientEvent("esx:showNotification", targetId, 
                "Vous avez reçu $" .. amount .. " de " .. GetPlayerName(source))
        else
            TriggerClientEvent("esx:showNotification", source, 
                "~r~Vous n'avez pas assez d'argent")
        end
    end
end)

RegisterServerEvent("kt_context:server:getPlayerInfo")
AddEventHandler("kt_context:server:getPlayerInfo", function(targetId)
    local source = source
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if xTarget then
        local info = {
            name = GetPlayerName(targetId),
            identifier = xTarget.identifier,
            job = xTarget.job.label,
            money = xTarget.getMoney(),
            bank = xTarget.getAccount('bank').money
        }
        
        TriggerClientEvent("kt_context:client:displayPlayerInfo", source, info)
    end
end)