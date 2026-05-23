-- =============================================
-- VALIDATEURS PARTAGÉS
-- =============================================
Validators = {}

function Validators.MenuItem(item)
    if type(item) ~= 'table' then
        return false, 'item must be a table'
    end
    if type(item.id) ~= 'string' or #item.id == 0 then
        return false, 'item.id must be a non-empty string'
    end
    if item.divider then return true end
    if type(item.label) ~= 'string' or #item.label == 0 then
        return false, 'item.label must be a non-empty string'
    end
    return true
end

function Validators.MenuItems(items)
    if type(items) ~= 'table' or #items == 0 then
        return false, 'items must be a non-empty array'
    end
    for i, item in ipairs(items) do
        local ok, reason = Validators.MenuItem(item)
        if not ok then
            return false, ('item[%d]: %s'):format(i, reason)
        end
        if item.submenu then
            local subOk, subReason = Validators.MenuItems(item.submenu)
            if not subOk then
                return false, ('item[%d].submenu: %s'):format(i, subReason)
            end
        end
    end
    return true
end