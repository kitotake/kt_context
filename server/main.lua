-- =============================================
-- SERVEUR PRINCIPAL — v3.2
-- =============================================

RegisterServerEvent('kt_context:server:transferMoney')
AddEventHandler('kt_context:server:transferMoney', function(targetId, amount)
    local src = source
    if not targetId or type(targetId) ~= 'number' then return end
    if not amount or type(amount) ~= 'number' or amount <= 0 or amount > 999999 then
        TriggerClientEvent('kt_context:notify', src, 'Montant invalide', 'error')
        return
    end
    if src == targetId then
        TriggerClientEvent('kt_context:notify', src, "Impossible de vous envoyer de l'argent", 'error')
        return
    end
    -- Brancher ESX/QBCore ici
    TriggerClientEvent('kt_context:notify', src,      ('Vous avez donné %d$ à %s'):format(amount, GetPlayerName(targetId)), 'success')
    TriggerClientEvent('kt_context:notify', targetId, ('Vous avez reçu %d$ de %s'):format(amount, GetPlayerName(src)),     'success')
end)

RegisterNetEvent('kt_context:notify')
AddEventHandler('kt_context:notify', function() end)

RegisterServerEvent('kt_context:logMenuOpen')
AddEventHandler('kt_context:logMenuOpen', function(menuName)
    local src = source
    print(('[KT Context] %s (%d) a ouvert: %s'):format(GetPlayerName(src) or '?', src, menuName))
end)

RegisterCommand('ktping', function(src)
    TriggerClientEvent('kt_context:notify', src, '🟢 kt_context opérationnel', 'success')
end, false)