-- =============================================
-- PERMISSIONS SERVEUR
-- =============================================
Permissions = {}

local cache = {}

local function GetIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

-- Charger les permissions depuis la DB (ou fallback ace)
function Permissions.Load(src)
    local identifier = GetIdentifier(src)

    -- Fallback ACE si pas de DB configurée
    local group = 'user'
    if IsPlayerAceAllowed(src, 'founder')   then group = 'founder'
    elseif IsPlayerAceAllowed(src, 'admin') then group = 'admin'
    elseif IsPlayerAceAllowed(src, 'moderator') then group = 'moderator'
    end

    cache[src] = group
    TriggerClientEvent('permissions:client:set', src, group)
    return group
end

function Permissions.Get(src)
    return cache[src] or Permissions.Load(src)
end

function Permissions.Has(src, required)
    local current = Permissions.Get(src)
    local hierarchy = { user = 1, moderator = 2, admin = 3, founder = 4 }
    return (hierarchy[current] or 0) >= (hierarchy[required] or 0)
end

-- ─── Événements ──────────────────────────────────────────────────────────────
AddEventHandler('playerJoining', function()
    Permissions.Load(source)
end)

AddEventHandler('playerDropped', function()
    cache[source] = nil
end)

RegisterNetEvent('kt_context:requestPermissions')
AddEventHandler('kt_context:requestPermissions', function()
    Permissions.Load(source)
end)