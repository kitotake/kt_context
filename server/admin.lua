Admin = {}

-- =============================================
-- Admin Roles
-- =============================================

Admin.Roles = {
    founder = 'group.founder',
    admin = 'group.admin',
    moderator = 'group.moderator'
}

-- =============================================
-- Get Player Role
-- =============================================

function Admin.GetPlayerRole(source)
    for role, ace in pairs(Admin.Roles) do
        if IsPlayerAceAllowed(source, ace) then
            return role
        end
    end

    return nil
end

-- =============================================
-- Is Player Admin
-- =============================================

function Admin.IsPlayerAdmin(source)
    return Admin.GetPlayerRole(source) ~= nil
end

-- =============================================
-- Callback Event
-- =============================================

RegisterNetEvent('admin:server:requestPermissions', function()
    local source = source

    local isAdmin = Admin.IsPlayerAdmin(source)
    local role = Admin.GetPlayerRole(source)

    TriggerClientEvent('admin:client:receivePermissions', source, {
        isAdmin = isAdmin,
        role = role
    })
end)

-- =============================================
-- Debug Command
-- =============================================

RegisterCommand('checkadmin', function(source)
    local isAdmin = Admin.IsPlayerAdmin(source)
    local role = Admin.GetPlayerRole(source) or 'none'

    print(('[ADMIN] %s | Admin: %s | Role: %s')
        :format(GetPlayerName(source), tostring(isAdmin), role))

    TriggerClientEvent('chat:addMessage', source, {
        args = {
            '^2ADMIN',
            ('Status: %s | Role: %s')
                :format(tostring(isAdmin), role)
        }
    })
end, false)
RegisterCommand('checkgroup', function(source)
    local group = Permissions.Get(source)

    print(('[PERMS] %s = %s')
        :format(GetPlayerName(source), group))
end)