-- =============================================
-- SYNC PERMISSIONS CLIENT
-- =============================================
-- Le serveur envoie le groupe DB au client lors du join
-- (et sur demande via kt_context:requestPermissions)

Permissions = { group = 'user' }

local HIERARCHY = { user = 1, moderator = 2, admin = 3, founder = 4 }

RegisterNetEvent('permissions:client:set', function(group)
    Permissions.group = group or 'user'
    print(('[KT Perms Client] Groupe reçu: %s'):format(Permissions.group))
end)

-- Demande un refresh au serveur (utile si le groupe change en live)
function RefreshPermissions()
    TriggerServerEvent('kt_context:requestPermissions')
end

-- Vérifie si le joueur a au moins le niveau demandé
function HasPermission(required)
    return (HIERARCHY[Permissions.group] or 0) >= (HIERARCHY[required] or 0)
end

-- Utilisé partout dans le projet
function IsPlayerAdmin()
    return HasPermission('admin')
end

function GetAdminRole()
    if Permissions.group == 'user' then return nil end
    return Permissions.group
end

-- Demande le groupe au serveur au démarrage (sécurité si le event join est manqué)
Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('kt_context:requestPermissions')
end)