-- =============================================
-- SYNC PERMISSIONS CLIENT
-- =============================================
Permissions = { group = 'user' }

RegisterNetEvent('permissions:client:set', function(group)
    Permissions.group = group
end)

function HasPermission(required)
    local hierarchy = { user = 1, moderator = 2, admin = 3, founder = 4 }
    return (hierarchy[Permissions.group] or 0) >= (hierarchy[required] or 0)
end