-- =============================================
-- ROTATION SERVEUR — v3.2
--
-- FIX CRITIQUE (v3.1) : suppression des natives CLIENT côté serveur
-- Ce fichier gère UNIQUEMENT le logging et la validation.
-- Placement/rotation = 100% côté client (rotation/client.lua).
-- =============================================

local _activePropsByPlayer = {}

-- ─── Log prop placé ───────────────────────────────────────────────────────────
RegisterNetEvent('kt_context:prop:placed')
AddEventHandler('kt_context:prop:placed', function(model, coords)
    local src = source
    if IsRateLimited and IsRateLimited(src, 'prop_place', 1000) then return end

    _activePropsByPlayer[src] = {
        model  = model,
        coords = coords,
        time   = os.time(),
    }
    print(('[KT Prop] %s (%d) a placé : %s à %.1f,%.1f,%.1f'):format(
        GetPlayerName(src) or '?', src, tostring(model),
        coords and coords.x or 0,
        coords and coords.y or 0,
        coords and coords.z or 0
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
    print(('[KT Prop] %s (%d) a supprimé son prop'):format(
        GetPlayerName(src) or '?', src))
    if ActionLogs then
        ActionLogs:Add(src, 'prop', 'delete', {})
    end
end)

-- ─── Cleanup déconnexion ──────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    _activePropsByPlayer[source] = nil
end)

-- ─── Commande admin : voir props actifs ───────────────────────────────────────
RegisterCommand('ktprops', function(src)
    if Permissions and not Permissions.IsAdmin(src) then
        TriggerClientEvent('kt_context:notify', src, 'Accès refusé', 'error')
        return
    end
    local count = 0
    for playerId, data in pairs(_activePropsByPlayer) do
        local name = GetPlayerName(playerId) or '?'
        print(('[KT Props] %s (%d) → %s (placé à %s)'):format(
            name, playerId, tostring(data.model),
            os.date('%H:%M:%S', data.time)))
        count = count + 1
    end
    TriggerClientEvent('kt_context:notify', src,
        ('%d prop(s) actif(s) — voir console'):format(count), 'info')
end, false)

exports('GetActiveProps', function() return _activePropsByPlayer end)