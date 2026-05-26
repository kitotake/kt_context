-- =============================================
-- UTILS PARTAGÉS — v3.2
-- =============================================
SharedUtils = {}

function SharedUtils.isString(v)
    return type(v) == 'string' and #v > 0
end

function SharedUtils.isPositiveNumber(v)
    return type(v) == 'number' and v > 0
end

function SharedUtils.toArray(v)
    if type(v) ~= 'table' then return { v } end
    return v
end

function SharedUtils.tableCount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end
