-- =============================================
-- ROTATION SERVEUR — v3.1 (fixed)
-- 
-- FIX CRITIQUE : la version originale appelait des natives CLIENT
-- (GetEntityCoords, PlayerPedId, CreateObject…) côté SERVEUR.
-- Ces natives n'existent pas côté serveur sans entity-aware framework.
-- 
-- Solution : le serveur gère uniquement le logging et la validation.
-- Le placement/rotation se fait 100% côté client (rotation_client.lua).
-- =============================================

-- Tracking des props actifs par joueur (pour validation serveur)
local _activePropsByPlayer = {}

-- ─── Log prop placement ───────────────────────────────────────────────────────
RegisterNetEvent('kt_context:prop:placed')
AddEventHandler('kt_context:prop:placed', function(model, coords)
    local src = source
    if IsRateLimited and IsRateLimited(src, 'prop_place', 1000) then return end

    _activePropsByPlayer[src] = { model = model, coords = coords, time = os.time() }
    print(('[KT Prop] %s (%d) a placé : %s à %.1f,%.1f,%.1f'):format(
        GetPlayerName(src) or '?', src, tostring(model),
        coords and coords.x or 0, coords and coords.y or 0, coords and coords.z or 0
    ))
    if ActionLogs then
        ActionLogs:Add(src, 'prop', 'place', { model = model })
    end
end)

-- ─── Log prop supprimé ────────────────────────────────────────────────────────
RegisterNetEvent('kt_context:prop:deleted')
AddEventHandler('kt_context:prop:deleted', function()
    local src = source
    _activePropsByPlayer[src] = nil
    print(('[KT Prop] %s (%d) a supprimé son prop'):format(GetPlayerName(src) or '?', src))
end)

-- ─── Cleanup à la déconnexion ─────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    _activePropsByPlayer[source] = nil
end)

-- ─── Commande admin : voir props actifs ───────────────────────────────────────
RegisterCommand('ktprops', function(src, args)
    if Permissions and not Permissions.IsAdmin(src) then
        TriggerClientEvent('kt_context:notify', src, 'Accès refusé', 'error')
        return
    end
    local count = 0
    for playerId, data in pairs(_activePropsByPlayer) do
        local name = GetPlayerName(playerId) or '?'
        print(('[KT Props] %s (%d) → %s'):format(name, playerId, tostring(data.model)))
        count = count + 1
    end
    TriggerClientEvent('kt_context:notify', src,
        ('%d prop(s) actif(s) — voir console'):format(count), 'info')
end, false)

-- ─── Export API ───────────────────────────────────────────────────────────────
exports('GetActiveProps', function() return _activePropsByPlayer end)
