local placedProp = nil
local pitchValue = 0.0
local pitchSpeed = 1.0 -- Vitesse de rotation du pitch
local isRotating = true

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

        -- Garde une référence du prop pour le manipuler
        placedProp = prop
        print("Prop placé.")
    else
        print("Un prop est déjà placé. Supprime-le d'abord.")
    end
end

-- Fonction pour supprimer tous les props dans une zone
function deletePropsInZone()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local handle, object = FindFirstObject()
    local success

    repeat
        local objCoords = GetEntityCoords(object)
        local distance = #(playerCoords - objCoords)

        -- Si l'objet est dans le rayon défini, on le supprime
        if distance < Config.DeleteRadius then
            if IsEntityAnObject(object) then
                DeleteObject(object)
                print("Prop supprimé.")
            end
        end

        success, object = FindNextObject(handle)
    until not success

    EndFindObject(handle)
end

-- Fonction pour faire bouger le prop autour de son axe de pitch (Y)
function rotatePropOnPitch()
    if placedProp then
        -- Ajuste la rotation pitch avec la vitesse définie
        pitchValue = pitchValue + pitchSpeed
        -- On récupère la rotation actuelle et on ajuste uniquement le pitch (Y)
        local currentRotation = GetEntityRotation(placedProp, 2)
        SetEntityRotation(placedProp, currentRotation.x, pitchValue, currentRotation.z, 2, true)
        print("Pitch ajusté: " .. pitchValue)
    else
        print("Aucun prop n'est placé.")
    end
end

-- Fonction pour détecter la touche E et ajuster le pitch
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Vérifie en permanence si la touche E est pressée

        -- Si le joueur appuie sur la touche E
        if IsControlJustPressed(0, 38) then -- 38 est la touche 'E'
            if placedProp then
                -- Si le prop existe, démarre la rotation du pitch entre 1 et -100
                isRotating = not isRotating -- Active ou désactive la rotation

                Citizen.CreateThread(function()
                    while isRotating do
                        Citizen.Wait(10) -- Intervalle de rotation rapide
                        
                        -- Bouger entre 1 et -100 degrés
                        if pitchValue <= -500 then
                            pitchSpeed = 1.0 -- Change la direction pour remonter
                        elseif pitchValue >= 1 then
                            pitchSpeed = -1.0 -- Change la direction pour descendre
                        end

                        -- Ajuste la rotation
                        rotatePropOnPitch()
                    end
                end)
            else
                print("Aucun prop n'est placé.")
            end
        end
    end
end)

-- Commande pour placer le prop
RegisterCommand('placeprop', function()
    placeProp()
end, false)

-- Commande pour supprimer tous les props dans une zone définie
RegisterCommand('deleteprop', function()
    deletePropsInZone()
end, false)

-- Commande pour faire bouger le prop sur le pitch manuellement
RegisterCommand('pitchprop', function()
    rotatePropOnPitch()
end, false)
