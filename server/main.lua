-- =============================================
-- SERVEUR PRINCIPAL
-- =============================================

-- Transfert d'argent entre joueurs
RegisterServerEvent("kt_context:server:transferMoney")
AddEventHandler("kt_context:server:transferMoney", function(targetId, amount)
    local source = source
    if not targetId or type(targetId) ~= "number" then return end
    if not amount or type(amount) ~= "number" or amount <= 0 or amount > 999999 then
        TriggerClientEvent("kt_context:notify", source, "Montant invalide", "error")
        return
    end
    if source == targetId then
        TriggerClientEvent("kt_context:notify", source, "Impossible de vous envoyer de l'argent", "error")
        return
    end
    -- Implémentation ESX/QBCore à brancher ici
    TriggerClientEvent("kt_context:notify", source,   string.format("Vous avez donné %d$ à %s", amount, GetPlayerName(targetId)), "success")
    TriggerClientEvent("kt_context:notify", targetId, string.format("Vous avez reçu %d$ de %s", amount, GetPlayerName(source)),   "success")
end)

-- Log menu ouvert
RegisterServerEvent("kt_context:logMenuOpen")
AddEventHandler("kt_context:logMenuOpen", function(menuName)
    local source = source
    print(string.format("[KT Context] %s (%d) a ouvert le menu: %s", GetPlayerName(source), source, menuName))
end)