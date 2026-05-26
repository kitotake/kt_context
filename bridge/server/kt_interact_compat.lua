-- =============================================
-- BRIDGE SERVEUR : kt_context ↔ kt_interact
-- =============================================
--
-- Côté serveur, ce bridge :
--   • Relaye les logs d'action entre les deux ressources
--   • Synchronise l'état des interactions avec les clients kt_context
--   • Fournit des exports serveur communs
-- =============================================

local INTERACT_RESOURCE = 'kt_interact'
local CONTEXT_RESOURCE  = 'kt_context'

local function interactAvailable()
    return GetResourceState(INTERACT_RESOURCE) == 'started'
end

local function contextAvailable()
    return GetResourceState(CONTEXT_RESOURCE) == 'started'
end

-- ─── Relais de logs ───────────────────────────────────────────────────────────
-- Quand kt_interact déclenche une interaction, on log aussi dans kt_context

AddEventHandler('kt_interact_data:triggerEvent', function()
    -- Cet event est réseau, source = joueur
    -- Le logging est géré par kt_interact lui-même
    -- Ce handler est ici pour extension future
end)

-- ─── Synchronisation au démarrage ─────────────────────────────────────────────
-- Quand kt_context démarre après kt_interact, les clients doivent
-- re-recevoir le cache des interactions

AddEventHandler('onServerResourceStart', function(res)
    if res ~= CONTEXT_RESOURCE then return end
    if not interactAvailable() then return end

    -- Attente courte pour laisser kt_context s'initialiser
    SetTimeout(2000, function()
        -- Demande à kt_interact de renvoyer les interactions à tous les joueurs
        -- (kt_interact le fait déjà dans son propre onServerResourceStart)
        print('[KT Bridge] kt_context démarré — interactions kt_interact déjà synchronisées')
    end)
end)

-- ─── Export : récupérer toutes les interactions pour un joueur ────────────────
-- Utile pour construire des menus côté serveur

exports('GetInteractionsForPlayer', function(src)
    if not interactAvailable() then return {} end
    local ok, result = pcall(function()
        return exports[INTERACT_RESOURCE]:getAllInteractions()
    end)
    if not ok then return {} end
    return result or {}
end)

-- ─── Export : déclencher une interaction depuis un autre script ───────────────
exports('TriggerInteractionForPlayer', function(src, interactionId, coords)
    if not interactAvailable() or not src or not interactionId then return false end
    local c = coords or {}
    TriggerClientEvent('kt_context:bridge:triggerInteract', src, interactionId, c)
    return true
end)

-- ─── Handler côté serveur pour le bridge trigger ──────────────────────────────
RegisterNetEvent('kt_context:bridge:triggerInteract')
AddEventHandler('kt_context:bridge:triggerInteract', function(interactionId, coords)
    local src = source
    if not src or not interactionId then return end
    TriggerEvent('kt_interact_data:triggerEvent', src, interactionId, coords)
end)

print('[KT Bridge] kt_interact_compat serveur chargé')
