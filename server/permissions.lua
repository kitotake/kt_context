Permissions = {}

local cache = {}

-- =============================================
-- GET IDENTIFIER
-- =============================================
local function GetIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and string.find(id, "license:") then
            return id
        end
    end
    return nil
end

-- =============================================
-- LOAD PERMISSION
-- =============================================
function Permissions.Load(src)
    local identifier = GetIdentifier(src)
    if not identifier then return "user" end

    local result = MySQL.single.await(
        'SELECT `group`, banned FROM users WHERE identifier = ?',
        { identifier }
    )

    if not result then
        MySQL.insert.await(
            'INSERT INTO users (identifier, `group`) VALUES (?, ?)',
            { identifier, "user" }
        )

        cache[src] = "user"
        return "user"
    end

    if result.banned == 1 then
        DropPlayer(src, "Banned from server")
        return nil
    end

    cache[src] = result.group or "user"
    return cache[src]
end

-- =============================================
-- GET
-- =============================================
function Permissions.Get(src)
    return cache[src] or Permissions.Load(src)
end

-- =============================================
-- SET GROUP
-- =============================================
function Permissions.Set(src, group)
    local identifier = GetIdentifier(src)
    if not identifier then return end

    cache[src] = group

    MySQL.update.await(
        'UPDATE users SET `group` = ? WHERE identifier = ?',
        { group, identifier }
    )
end

-- =============================================
-- CHECK PERMISSION (HIERARCHY)
-- =============================================
function Permissions.Has(src, required)
    local current = Permissions.Get(src)
    if not current then return false end

    local hierarchy = {
        user = 1,
        moderator = 2,
        admin = 3,
        founder = 4
    }

    return (hierarchy[current] or 0) >= (hierarchy[required] or 0)
end

-- =============================================
-- EVENTS
-- =============================================
AddEventHandler('playerJoining', function()
    local src = source
    Permissions.Load(src)
end)

AddEventHandler('playerDropped', function()
    cache[source] = nil
end)