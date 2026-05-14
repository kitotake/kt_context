-- =============================================
-- ZONES INTERACTIVES
-- =============================================

local registeredZones = {}
local activeZone      = nil

-- ─── Enregistrement d'une zone ───────────────────────────────────────────────
--[[
  RegisterMenuZone({
    id       = "my_zone",
    coords   = vector3(100.0, 200.0, 30.0),
    radius   = 3.0,          -- ou size = vector3(w, h, d) pour une boîte
    shape    = "circle",     -- "circle" | "box"
    heading  = 0.0,          -- rotation pour les boîtes
    title    = "Ma Zone",
    items    = { ... },
    marker   = {             -- optionnel
      type   = 2,
      color  = {r=59, g=130, b=246, a=150},
      size   = vector3(1.0, 1.0, 0.5),
    },
    hint     = "Appuyez sur ~INPUT_CONTEXT~",
    condition = function() return true end,  -- optionnel
  })
]]
function RegisterMenuZone(zoneData)
    assert(zoneData.id,     "[KT Context] Zone sans id")
    assert(zoneData.coords, "[KT Context] Zone sans coords")
    assert(zoneData.items,  "[KT Context] Zone sans items")

    zoneData.shape   = zoneData.shape   or "circle"
    zoneData.radius  = zoneData.radius  or 2.0
    zoneData.heading = zoneData.heading or 0.0

    registeredZones[zoneData.id] = zoneData
    print(string.format("[KT Context] Zone enregistrée: %s (%s)", zoneData.id, zoneData.shape))
    return zoneData.id
end

-- Supprimer une zone
function RemoveMenuZone(zoneId)
    registeredZones[zoneId] = nil
end

-- ─── Thread de gestion des zones ─────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local sleep   = 500
        local ped     = PlayerPedId()
        local coords  = GetEntityCoords(ped)
        local inZone  = nil

        for id, zone in pairs(registeredZones) do
            -- Vérifier condition optionnelle
            if not zone.condition or zone.condition() then
                local inside = false

                if zone.shape == "circle" then
                    local dist = #(coords - zone.coords)
                    inside = dist < zone.radius

                elseif zone.shape == "box" then
                    -- Vérification boîte orientée
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

                    -- Dessiner le marker si défini
                    if zone.marker then
                        local m = zone.marker
                        local c = m.color or { r=59, g=130, b=246, a=120 }
                        local s = m.size   or vector3(zone.radius * 2, zone.radius * 2, 0.3)
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

                    -- Hint d'interaction
                    if zone.hint then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName(zone.hint)
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end

                    -- Déclenchement via E (control 38)
                    if IsControlJustReleased(0, 38) then
                        -- Position au milieu de l'écran
                        local sw, sh = GetActiveScreenResolution()
                        OpenContextMenu(sw / 2, sh / 2, zone.items, zone.title or "Zone")
                    end
                    break
                end
            end
        end

        -- Notif NUI de changement de zone
        if inZone ~= activeZone then
            activeZone = inZone
            SendNUIMessage({
                type = "zoneChange",
                data = { inZone = inZone ~= nil, zoneId = inZone and inZone.id or nil }
            })
        end

        Wait(sleep)
    end
end)

-- ─── Export ──────────────────────────────────────────────────────────────────
exports("RegisterMenuZone", RegisterMenuZone)
exports("RemoveMenuZone",   RemoveMenuZone)

-- ─── Exemples de zones (commentés par défaut) ─────────────────────────────────
--[[
Citizen.CreateThread(function()
    Wait(2000)

    RegisterMenuZone({
        id     = "zone_mechanic",
        coords = vector3(-352.66, -133.72, 38.56),
        radius = 3.0,
        shape  = "circle",
        title  = "🔧 Atelier Mécanique",
        hint   = "Appuyez sur ~INPUT_CONTEXT~ pour accéder à l'atelier",
        marker = {
            type  = 2,
            color = { r=59, g=130, b=246, a=120 },
            size  = vector3(3.0, 3.0, 0.3),
        },
        items = {
            { id = "repair_vehicle",   label = "Réparer le véhicule",     icon = "Wrench"     },
            { id = "upgrade_vehicle",  label = "Améliorer le véhicule",   icon = "Star"       },
            { id = "change_color",     label = "Changer la couleur",      icon = "Palette"    },
        },
    })

    RegisterMenuZone({
        id     = "zone_bank",
        coords = vector3(150.15, -1040.9, 29.37),
        radius = 5.0,
        shape  = "circle",
        title  = "🏦 Banque",
        hint   = "Appuyez sur ~INPUT_CONTEXT~ pour accéder à la banque",
        marker = {
            type  = 2,
            color = { r=16, g=185, b=129, a=120 },
            size  = vector3(4.0, 4.0, 0.3),
        },
        items = {
            { id = "bank_deposit",  label = "Déposer de l'argent",   icon = "ArrowUpFromLine" },
            { id = "bank_withdraw", label = "Retirer de l'argent",   icon = "ArrowDownToLine" },
            { id = "bank_balance",  label = "Voir le solde",         icon = "Wallet"          },
        },
    })
end)
]]
