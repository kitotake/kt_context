-- client/nui/focus.lua
-- Gestion du focus NUI (curseur souris, blocage des inputs).

local focus = {}

local SetNuiFocus          = SetNuiFocus
local SetNuiFocusKeepInput = SetNuiFocusKeepInput
local SetCursorLocation    = SetCursorLocation

local _focused = false

---@return boolean
function focus.isFocused()
    return _focused
end

---Active ou désactive le focus NUI.
---@param value  boolean
---@param cursor boolean?
function focus.set(value, cursor)
    if value then
        SetCursorLocation(0.5, 0.5)
    end

    _focused = value
    SetNuiFocus(value, cursor or false)
    SetNuiFocusKeepInput(value)
end

return focus