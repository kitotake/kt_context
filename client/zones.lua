-- =============================================
-- ZONES INTERACTIVES — FIXED
-- FIX: OpenContextMenu gère maintenant son propre focus si curseur inactif
-- Pas de changement fonctionnel ici, mais on utilise la touche E correctement
-- =============================================

local registeredZones = {}
local activeZone      = nil

function RegisterMenuZone(zoneData)
    assert(zoneData.id,     '[KT Context] Zone sans id')
    assert(zoneData.coords, '[KT Context] Zone sans coords')
    assert(zoneData.items,  '[KT Context] Zone sans items')

    local ok, reason = Validators.MenuItems(zoneData.items)
    if not ok then
        print(('[KT Context] Zone "%s" items invalides: %s'):format(zoneData.id, reason))
        return nil
    end

    zoneData.shape   = zoneData.shape   or 'circle'
    zoneData.radius  = zoneData.radius  or 2.0
    zoneData.heading = zoneData.heading or 0.0

    registeredZones[zoneData.id] = zoneData
    print(('[KT Context] Zone enregistrée: %s (%s r=%.1f)'):format(
        zoneData.id, zoneData.shape, zoneData.radius))
    return zoneData.id
end

function RemoveMenuZone(zoneId)
    if registeredZones[zoneId] then
        registeredZones[zoneId] = nil
        print(('[KT Context] Zone supprimée: %s'):format(zoneId))
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep  = 500
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inZone = nil

        for id, zone in pairs(registeredZones) do
            if not zone.condition or zone.condition() then
                local inside = false

                if zone.shape == 'circle' then
                    local dist = #(coords - zone.coords)
                    inside = dist < zone.radius
                elseif zone.shape == 'box' then
                    inside = IsPointInAngledArea(
                        coords.x, coords.y, coords.z,
                        zone.coords.x - zone.size.x / 2,
                        zone.coords.y - zone.size.y / 2,
                        zone.coords.z,
                        zone.coords.x + zone.size.x / 2,
                        zone.coords.y + zone.size.y / 2,
                        zone.coords.z + zone.size.z,
                        zone.heading,
                        false
                    )
                end

                if inside then
                    inZone = zone
                    sleep  = 0

                    if zone.marker then
                        local m = zone.marker
                        local c = m.color or { r=59, g=130, b=246, a=120 }
                        local s = m.size  or vector3(zone.radius * 2, zone.radius * 2, 0.3)
                        DrawMarker(
                            m.type or 2,
                            zone.coords.x, zone.coords.y, zone.coords.z + 0.02,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, zone.heading,
                            s.x, s.y, s.z,
                            c.r, c.g, c.b, c.a,
                            false, true, 2, false, nil, nil, false
                        )
                    end

                    if zone.hint then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(zone.hint)
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end

                    -- FIX: On n'ouvre le menu depuis une zone que si le menu n'est pas déjà ouvert
                    -- et que le curseur n'est pas actif (le curseur a sa propre logique)
                    if IsControlJustReleased(0, 38) and not IsMenuOpen() and not IsCursorActive() then
                        local sw, sh = GetActiveScreenResolution()
                        OpenContextMenu(sw / 2, sh / 2, zone.items, zone.title or 'Zone')
                    end
                    break
                end
            end
        end

        if inZone ~= activeZone then
            activeZone = inZone
            SendNUIMessage({
                type = 'zoneChange',
                data = {
                    inZone = inZone ~= nil,
                    zoneId = inZone and inZone.id or nil,
                    title  = inZone and inZone.title or nil,
                }
            })
        end

        Wait(sleep)
    end
end)

exports('RegisterMenuZone', RegisterMenuZone)
exports('RemoveMenuZone',   RemoveMenuZone)