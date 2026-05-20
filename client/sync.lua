-- =============================================
-- SYNC PERMISSIONS CLIENT — v3.1 (fixed)
-- SOURCE UNIQUE de verite pour IsPlayerAdmin / GetAdminRole / IsPlayerStaff.
-- utils.lua definit des aliases temporaires AVANT ce fichier,
-- ici on les ecrase definitivement.
-- =============================================

Permissions = { group = 'user' }

local HIERARCHY = { user = 1, staff = 2, moderator = 3, admin = 4, founder = 5 }

RegisterNetEvent('permissions:client:set', function(group)
    Permissions.group = group or 'user'
    print(('[KT Perms Client] Groupe recu: %s'):format(Permissions.group))
end)

function RefreshPermissions()
    TriggerServerEvent('kt_context:requestPermissions')
end

function HasPermission(required)
    return (HIERARCHY[Permissions.group] or 0) >= (HIERARCHY[required] or 0)
end

-- Ecrase les aliases de utils.lua
function IsPlayerAdmin()
    return HasPermission('admin')
end

function IsPlayerStaff()
    return HasPermission('staff')
end

function GetAdminRole()
    if Permissions.group == 'user' then return nil end
    return Permissions.group
end

-- Demande le groupe au serveur au demarrage
Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('kt_context:requestPermissions')
end)
