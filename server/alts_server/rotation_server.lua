local placedProp = nil

-- Fonction pour placer le prop
function placeProp()
    if not placedProp then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local forward = GetEntityForwardVector(playerPed)

        -- Positionne le prop un peu devant le joueur
        local propCoords = playerCoords + forward * 1.5

        -- Crée le prop avec les informations du fichier config.lua
        local prop = CreateObject(GetHashKey(Config.PropName), propCoords.x, propCoords.y, propCoords.z, true, true, true)
        SetEntityRotation(prop, Config.DefaultRotation.x, Config.DefaultRotation.y, Config.DefaultRotation.z, 2, true)

        -- Garde une référence du prop pour le supprimer
        placedProp = prop
        print("Prop placé.")
    else
        print("Un prop est déjà placé. Supprime-le d'abord.")
    end
end

-- Fonction pour supprimer le prop
function deleteProp()
    if placedProp then
        DeleteObject(placedProp)
        placedProp = nil
        print("Prop supprimé.")
    else
        print("Aucun prop à supprimer.")
    end
end

-- Commande pour placer le prop
RegisterCommand('placeprop', function()
    placeProp()
end, false)

-- Commande pour supprimer le prop
RegisterCommand('deleteprop', function()
    deleteProp()
end, false)
