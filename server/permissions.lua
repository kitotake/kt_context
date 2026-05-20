-- =============================================
-- PERMISSIONS SERVEUR — v3.1 (fixed)
-- FIX : 'playerJoining' → 'playerConnecting' (nom correct FiveM)
-- FIX : Rate limiting serveur anti-spam
-- =============================================
Permissions = {}

local cache         = {}
local _rateLimits   = {}  -- [src] = { action = timestamp }

local HIERARCHY = { user = 1, staff = 2, moderator = 3, admin = 4, founder = 5 }

local function GetLicense(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and string.sub(id, 1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

-- ─── Rate limiting ────────────────────────────────────────────────────────────
function IsRateLimited(src, action, ms)
    ms = ms or (Config and Config.Limits and Config.Limits.ServerActionCooldown or 500)
    if not _rateLimits[src] then _rateLimits[src] = {} end
    local last = _rateLimits[src][action]
    local now  = os.time() * 1000

    -- os.time() est en secondes, GetGameTimer() n'est pas dispo côté serveur
    -- On utilise os.clock() * 1000 pour ms
    local nowMs = math.floor(os.clock() * 1000)
    local lastMs = _rateLimits[src][action] or 0

    if (nowMs - lastMs) < ms then
        return true
    end
    _rateLimits[src][action] = nowMs
    return false
end

-- ─── Chargement permissions ───────────────────────────────────────────────────
function Permissions.Load(src)
    local license = GetLicense(src)
    if not license then
        cache[src] = 'user'
        TriggerClientEvent('permissions:client:set', src, 'user')
        return 'user'
    end

    -- Essaie oxmysql si disponible, sinon fallback ACE
    if exports.oxmysql then
        exports.oxmysql:scalar(
            'SELECT `group` FROM `users` WHERE `identifier` = ? LIMIT 1',
            { license },
            function(group)
                local g = group or 'user'
                cache[src] = g
                TriggerClientEvent('permissions:client:set', src, g)
                print(('[KT Perms] %s (%d) → groupe: %s'):format(GetPlayerName(src) or '?', src, g))
            end
        )
    else
        -- Fallback ACE (serveurs sans oxmysql)
        local group = 'user'
        if IsPlayerAceAllowed(src, 'founder')   then group = 'founder'
        elseif IsPlayerAceAllowed(src, 'admin') then group = 'admin'
        elseif IsPlayerAceAllowed(src, 'moderator') then group = 'moderator'
        elseif IsPlayerAceAllowed(src, 'staff')     then group = 'staff'
        end
        cache[src] = group
        TriggerClientEvent('permissions:client:set', src, group)
        print(('[KT Perms ACE] %s (%d) → groupe: %s'):format(GetPlayerName(src) or '?', src, group))
    end
end

function Permissions.Get(src)
    if cache[src] then return cache[src] end
    Permissions.Load(src)
    return 'user'
end

function Permissions.Has(src, required)
    local current = cache[src] or 'user'
    return (HIERARCHY[current] or 0) >= (HIERARCHY[required] or 0)
end

function Permissions.IsAdmin(src)
    return Permissions.Has(src, 'admin')
end

function Permissions.IsStaff(src)
    return Permissions.Has(src, 'staff')
end

function Permissions.GetRole(src)
    return cache[src] or 'user'
end

-- ─── Événements — FIX: playerConnecting au lieu de playerJoining ──────────────
-- 'playerJoining' n'est pas un événement natif FiveM.
-- 'playerConnecting' se déclenche à la connexion (avant spawn).
-- Utiliser aussi 'onServerResourceStart' pour les joueurs déjà connectés.
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    deferrals.update(('[KT] Chargement permissions pour %s…'):format(name))
    Permissions.Load(src)
    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local src = source
    cache[src] = nil
    _rateLimits[src] = nil
end)

-- Refresh si le client le demande
RegisterNetEvent('kt_context:requestPermissions')
AddEventHandler('kt_context:requestPermissions', function()
    Permissions.Load(source)
end)

-- Charger pour les joueurs déjà connectés au démarrage de la ressource
AddEventHandler('onServerResourceStart', function(res)
    if res == GetCurrentResourceName() then
        for _, playerId in ipairs(GetPlayers()) do
            Permissions.Load(tonumber(playerId))
        end
    end
end)

-- ─── Commandes debug ──────────────────────────────────────────────────────────
RegisterCommand('ktgroup', function(src, args)
    local target = tonumber(args[1]) or src
    local group  = cache[target] or 'non chargé'
    local name   = GetPlayerName(target) or '?'
    print(('[KT Perms] %s (%d) → %s'):format(name, target, group))
    TriggerClientEvent('kt_context:notify', src,
        ('Groupe de %s : %s'):format(name, group), 'info')
end, false)

RegisterCommand('ktsetgroup', function(src, args)
    if not Permissions.IsAdmin(src) then return end
    local target = tonumber(args[1])
    local group  = args[2]
    if not target or not group then return end
    if not HIERARCHY[group] then
        TriggerClientEvent('kt_context:notify', src, 'Groupe invalide', 'error')
        return
    end
    cache[target] = group
    TriggerClientEvent('permissions:client:set', target, group)
    TriggerClientEvent('kt_context:notify', src,
        ('Groupe de %d → %s'):format(target, group), 'success')
    print(('[KT Admin] %s a changé le groupe de %d → %s'):format(GetPlayerName(src) or '?', target, group))
end, false)
