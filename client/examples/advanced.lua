
function OpenPlayerInteractionMenu(targetId, targetName)
    local items = {
        {
            id = "player_info",
            label = "Voir l'identité",
            description = "Afficher les informations du joueur",
            icon = "👤"
        },
        {
            id = "player_trade",
            label = "Proposer un échange",
            description = "Échanger des objets",
            icon = "🤝"
        },
        {
            id = "player_money",
            label = "Transactions",
            icon = "💰",
            submenu = {
                {
                    id = "give_money_50",
                    label = "Donner 50$",
                    icon = "💵"
                },
                {
                    id = "give_money_100",
                    label = "Donner 100$",
                    icon = "💵"
                },
                {
                    id = "give_money_500",
                    label = "Donner 500$",
                    icon = "💵"
                },
                {
                    id = "give_money_custom",
                    label = "Montant personnalisé...",
                    icon = "💳"
                }
            }
        },
        {
            id = "player_emotes",
            label = "Interactions sociales",
            icon = "😊",
            submenu = {
                {
                    id = "handshake",
                    label = "Serrer la main",
                    icon = "🤝"
                },
                {
                    id = "hug",
                    label = "Faire un câlin",
                    icon = "🤗"
                },
                {
                    id = "high_five",
                    label = "Taper dans la main",
                    icon = "✋"
                }
            }
        },
        {
            id = "player_admin",
            label = "Actions administrateur",
            icon = "🛡️",
            disabled = not IsPlayerAceAllowed(PlayerId(), "admin"),
            submenu = {
                {
                    id = "admin_tp",
                    label = "Se téléporter",
                    icon = "📍"
                },
                {
                    id = "admin_spectate",
                    label = "Spectater",
                    icon = "👁️"
                },
                {
                    id = "admin_kick",
                    label = "Expulser",
                    icon = "❌",
                    color = "#ef4444"
                },
                {
                    id = "admin_ban",
                    label = "Bannir",
                    icon = "🚫",
                    color = "#dc2626"
                }
            }
        }
    }
    
    OpenContextMenu(nil, nil, items, "🎮 " .. targetName)
end

function OpenAdvancedVehicleMenu()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        vehicle = GetVehiclePedIsIn(ped, true)
    end
    
    if vehicle == 0 then
        ShowNotification("Aucun véhicule à proximité", "error")
        return
    end
    
    local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local fuelLevel = GetVehicleFuelLevel(vehicle)
    
    local items = {
        {
            id = "vehicle_info",
            label = "Informations",
            description = string.format("Moteur: %.0f%% | Carrosserie: %.0f%% | Essence: %.0f%%", 
                engineHealth/10, bodyHealth/10, fuelLevel),
            icon = "ℹ️"
        },
        {
            id = "vehicle_lock",
            label = GetVehicleDoorLockStatus(vehicle) == 1 and "Verrouiller" or "Déverrouiller",
            description = "Contrôler l'accès au véhicule",
            icon = GetVehicleDoorLockStatus(vehicle) == 1 and "🔓" or "🔒"
        },
        {
            id = "vehicle_engine",
            label = "Gestion du moteur",
            icon = "🔧",
            disabled = not isDriver,
            submenu = {
                {
                    id = "engine_toggle",
                    label = GetIsVehicleEngineRunning(vehicle) and "Éteindre" or "Allumer",
                    icon = "🔌"
                },
                {
                    id = "engine_boost",
                    label = "Mode sport",
                    description = "Augmenter les performances",
                    icon = "⚡"
                }
            }
        },
        {
            id = "vehicle_doors",
            label = "Contrôle des portes",
            icon = "🚪",
            submenu = {
                {
                    id = "door_fl",
                    label = "Avant gauche",
                    icon = "🚪"
                },
                {
                    id = "door_fr",
                    label = "Avant droite",
                    icon = "🚪"
                },
                {
                    id = "door_rl",
                    label = "Arrière gauche",
                    icon = "🚪"
                },
                {
                    id = "door_rr",
                    label = "Arrière droite",
                    icon = "🚪"
                },
                {
                    id = "door_hood",
                    label = "Capot",
                    icon = "🔩"
                },
                {
                    id = "door_trunk",
                    label = "Coffre",
                    icon = "📦"
                },
                {
                    id = "door_all_close",
                    label = "Tout fermer",
                    icon = "🔒"
                }
            }
        },
        {
            id = "vehicle_windows",
            label = "Contrôle des vitres",
            icon = "🪟",
            disabled = not IsPedInAnyVehicle(ped, false),
            submenu = {
                {
                    id = "window_all_up",
                    label = "Toutes monter",
                    icon = "⬆️"
                },
                {
                    id = "window_all_down",
                    label = "Toutes descendre",
                    icon = "⬇️"
                }
            }
        },
        {
            id = "vehicle_extras",
            label = "Extras & Personnalisation",
            icon = "✨",
            submenu = {
                {
                    id = "toggle_livery",
                    label = "Changer la livrée",
                    icon = "🎨"
                },
                {
                    id = "toggle_neon",
                    label = "Néons",
                    icon = "💡"
                },
                {
                    id = "horn",
                    label = "Tester le klaxon",
                    icon = "📢"
                }
            }
        },
        {
            id = "vehicle_admin",
            label = "Actions administrateur",
            icon = "🛠️",
            disabled = not IsPlayerAceAllowed(PlayerId(), "admin"),
            submenu = {
                {
                    id = "admin_repair",
                    label = "Réparer complètement",
                    description = "Restaurer le véhicule",
                    icon = "🔧"
                },
                {
                    id = "admin_refuel",
                    label = "Remplir le réservoir",
                    icon = "⛽"
                },
                {
                    id = "admin_upgrade",
                    label = "Améliorer au maximum",
                    icon = "⭐"
                },
                {
                    id = "admin_delete",
                    label = "Supprimer",
                    icon = "🗑️",
                    color = "#ef4444"
                }
            }
        }
    }
    
    OpenContextMenu(nil, nil, items, "🚗 Menu Véhicule")
end

function OpenInventoryMenu(items)
    local menuItems = {}
    
    local categories = {
        weapons = { label = "Armes", icon = "🔫", items = {} },
        consumables = { label = "Consommables", icon = "🍔", items = {} },
        tools = { label = "Outils", icon = "🔧", items = {} },
        misc = { label = "Divers", icon = "📦", items = {} }
    }
    
    for _, item in ipairs(items) do
        local category = item.category or "misc"
        table.insert(categories[category].items, {
            id = "use_" .. item.name,
            label = item.label,
            description = string.format("Quantité: %d", item.count),
            icon = item.icon or "📦"
        })
    end
    
    for catKey, category in pairs(categories) do
        if #category.items > 0 then
            table.insert(menuItems, {
                id = "cat_" .. catKey,
                label = category.label,
                description = string.format("%d objets", #category.items),
                icon = category.icon,
                submenu = category.items
            })
        end
    end
    
    table.insert(menuItems, 1, {
        id = "inventory_sort",
        label = "Trier",
        icon = "🔄",
        submenu = {
            { id = "sort_name", label = "Par nom" },
            { id = "sort_quantity", label = "Par quantité" },
            { id = "sort_recent", label = "Plus récent" }
        }
    })
    
    table.insert(menuItems, {
        id = "inventory_drop",
        label = "Jeter un objet",
        description = "Abandonner un objet au sol",
        icon = "🗑️"
    })
    
    OpenContextMenu(nil, nil, menuItems, "🎒 Inventaire")
end


function OpenPhoneMenu()
    local items = {
        {
            id = "phone_contacts",
            label = "Contacts",
            description = "12 contacts disponibles",
            icon = "👥",
            submenu = {
                {
                    id = "contact_add",
                    label = "Ajouter un contact",
                    icon = "➕"
                },
                {
                    id = "contact_view",
                    label = "Voir les contacts",
                    icon = "📋"
                }
            }
        },
        {
            id = "phone_messages",
            label = "Messages",
            description = "3 nouveaux messages",
            icon = "💬"
        },
        {
            id = "phone_calls",
            label = "Appels",
            icon = "📞",
            submenu = {
                {
                    id = "call_recent",
                    label = "Appels récents",
                    icon = "📋"
                },
                {
                    id = "call_new",
                    label = "Composer un numéro",
                    icon = "🔢"
                }
            }
        },
        {
            id = "phone_apps",
            label = "Applications",
            icon = "📱",
            submenu = {
                {
                    id = "app_bank",
                    label = "Banque",
                    icon = "🏦"
                },
                {
                    id = "app_gps",
                    label = "GPS",
                    icon = "🗺️"
                },
                {
                    id = "app_camera",
                    label = "Appareil photo",
                    icon = "📸"
                },
                {
                    id = "app_music",
                    label = "Musique",
                    icon = "🎵"
                }
            }
        },
        {
            id = "phone_settings",
            label = "Paramètres",
            icon = "⚙️",
            submenu = {
                {
                    id = "settings_volume",
                    label = "Volume",
                    icon = "🔊"
                },
                {
                    id = "settings_wallpaper",
                    label = "Fond d'écran",
                    icon = "🖼️"
                },
                {
                    id = "settings_airplane",
                    label = "Mode avion",
                    icon = "✈️"
                }
            }
        }
    }
    
    OpenContextMenu(nil, nil, items, "📱 Téléphone")
end

function OpenContextualMenu()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local items = {}
    
    local vehicle, vehDist = GetClosestVehicle(coords)
    if vehDist < 5.0 then
        table.insert(items, {
            id = "vehicle_menu",
            label = "Interagir avec le véhicule",
            description = string.format("%.1fm", vehDist),
            icon = "🚗"
        })
    end
    
    local player, playerDist = GetClosestPlayer(coords)
    if player ~= -1 and playerDist < 3.0 then
        table.insert(items, {
            id = "player_interact",
            label = "Interagir avec " .. GetPlayerName(player),
            description = string.format("%.1fm", playerDist),
            icon = "👤"
        })
    end
    
    table.insert(items, {
        id = "general_actions",
        label = "Actions générales",
        icon = "⚡",
        submenu = {
            { id = "emotes", label = "Émotes", icon = "😊" },
            { id = "inventory", label = "Inventaire", icon = "🎒" },
            { id = "phone", label = "Téléphone", icon = "📱" }
        }
    })
    
    if #items == 0 then
        table.insert(items, {
            id = "no_action",
            label = "Aucune action disponible",
            disabled = true,
            icon = "❌"
        })
    end
    
    OpenContextMenu(nil, nil, items, "Menu Contextuel")
end



RegisterCommand("playermenu", function(source, args)
    local targetId = tonumber(args[1])
    if targetId then
        OpenPlayerInteractionMenu(targetId, GetPlayerName(targetId))
    else
        ShowNotification("Usage: /playermenu [ID]", "error")
    end
end, false)

RegisterCommand("vmenu", OpenAdvancedVehicleMenu, false)
RegisterCommand("phone", OpenPhoneMenu, false)
RegisterCommand("cmenu", OpenContextualMenu, false)

-- Bind pour ouvrir le menu contextuel avec une touche
RegisterKeyMapping("cmenu", "Ouvrir le menu contextuel", "keyboard", "F1")