-- =============================================
-- PERMISSIONS SERVEUR — oxmysql + table users
-- =============================================
Permissions = {}

local cache = {}

-- Hiérarchie des groupes
local HIERARCHY = { user = 1, moderator = 2, admin = 3, founder = 4 }

-- Récupère l'identifier license: du joueur
local function GetLicense(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and string.sub(id, 1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

-- Charge le groupe depuis la DB et met en cache
function Permissions.Load(src)
    local license = GetLicense(src)
    if not license then
        cache[src] = 'user'
        TriggerClientEvent('permissions:client:set', src, 'user')
        return 'user'
    end

    exports.oxmysql:scalar(
        'SELECT `group` FROM `users` WHERE `identifier` = ? LIMIT 1',
        { license },
        function(group)
            local g = group or 'user'
            cache[src] = g
            TriggerClientEvent('permissions:client:set', src, g)
            print(('[KT Perms] %s (%d) → groupe: %s'):format(GetPlayerName(src), src, g))
        end
    )
end

-- Retourne le groupe (depuis cache, ou recharge si absent)
function Permissions.Get(src)
    if cache[src] then return cache[src] end
    -- Pas encore chargé : on renvoie 'user' par sécurité (le Load est async)
    Permissions.Load(src)
    return 'user'
end

-- Vérifie si src a au moins le niveau `required`
function Permissions.Has(src, required)
    local current = cache[src] or 'user'
    return (HIERARCHY[current] or 0) >= (HIERARCHY[required] or 0)
end

-- Alias pratique
function Permissions.IsAdmin(src)
    return Permissions.Has(src, 'admin')
end

function Permissions.GetRole(src)
    return cache[src] or 'user'
end

-- ─── Événements ──────────────────────────────────────────────────────────────
AddEventHandler('playerJoining', function()
    Permissions.Load(source)
end)

AddEventHandler('playerDropped', function()
    cache[source] = nil
end)

-- Le client peut demander un refresh (ex: après changement de groupe en jeu)
RegisterNetEvent('kt_context:requestPermissions')
AddEventHandler('kt_context:requestPermissions', function()
    Permissions.Load(source)
end)

-- ─── Commande debug ───────────────────────────────────────────────────────────
RegisterCommand('ktgroup', function(src, args)
    local target = tonumber(args[1]) or src
    local group  = cache[target] or 'non chargé'
    local name   = GetPlayerName(target) or '?'
    print(('[KT Perms] %s (%d) → %s'):format(name, target, group))
    TriggerClientEvent('kt_context:notify', src, ('Groupe de %s : %s'):format(name, group), 'info')
end, false)