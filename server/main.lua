-- =============================================
-- SERVEUR PRINCIPAL
-- =============================================

-- Transfert d'argent entre joueurs
RegisterServerEvent('kt_context:server:transferMoney')
AddEventHandler('kt_context:server:transferMoney', function(targetId, amount)
    local source = source
    if not targetId or type(targetId) ~= 'number' then return end
    if not amount or type(amount) ~= 'number' or amount <= 0 or amount > 999999 then
        TriggerClientEvent('kt_context:notify', source, 'Montant invalide', 'error')
        return
    end
    if source == targetId then
        TriggerClientEvent('kt_context:notify', source, "Impossible de vous envoyer de l'argent", 'error')
        return
    end
    -- Brancher ESX/QBCore ici
    TriggerClientEvent('kt_context:notify', source,   ('Vous avez donné %d$ à %s'):format(amount, GetPlayerName(targetId)), 'success')
    TriggerClientEvent('kt_context:notify', targetId, ('Vous avez reçu %d$ de %s'):format(amount, GetPlayerName(source)),   'success')
end)

-- Notification client
RegisterNetEvent('kt_context:notify')
AddEventHandler('kt_context:notify', function(message, notifType)
    -- relay vers client si besoin
end)

-- Log menu ouvert
RegisterServerEvent('kt_context:logMenuOpen')
AddEventHandler('kt_context:logMenuOpen', function(menuName)
    local source = source
    print(('[KT Context] %s (%d) a ouvert: %s'):format(GetPlayerName(source), source, menuName))
end)

-- ─── Commande de test ping ────────────────────────────────────────────────────
RegisterCommand('ktping', function(source)
    TriggerClientEvent('kt_context:notify', source, '🟢 kt_context opérationnel', 'success')
end, false)