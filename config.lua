
Config = {}

Config.Locale = 'fr'


Config.DefaultPosition = {
    x = 500,
    y = 300
}

Config.Animations = {
    wave = {
        dict = "gestures@m@standing@casual",
        anim = "gesture_hello",
        duration = 3000
    },
    dance = {
        scenario = "WORLD_HUMAN_PARTYING",
        duration = -1
    },
    sit = {
        scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER",
        duration = -1
    }
}

Config.MenuZones = {
    {
        name = "armurerie",
        coords = vector3(0.0, 0.0, 0.0),
        distance = 2.0,
        marker = {
            type = 2,
            size = {x = 0.3, y = 0.3, z = 0.3},
            color = {r = 255, g = 255, b = 255, a = 200}
        },
        title = "Armurerie",
        items = {
           
        }
    }
}

Config.Locales = {
    fr = {
        press_to_open = "Appuyez sur ~INPUT_CONTEXT~ pour ouvrir",
        vehicle_locked = "🔒 Véhicule verrouillé",
        vehicle_unlocked = "🔓 Véhicule déverrouillé",
        no_vehicle = "Aucun véhicule à proximité",
        not_enough_money = "Vous n'avez pas assez d'argent",
        money_given = "Vous avez donné %s$",
        money_received = "Vous avez reçu %s$"
    },
    en = {
        press_to_open = "Press ~INPUT_CONTEXT~ to open",
        vehicle_locked = "🔒 Vehicle locked",
        vehicle_unlocked = "🔓 Vehicle unlocked",
        no_vehicle = "No vehicle nearby",
        not_enough_money = "You don't have enough money",
        money_given = "You gave $%s",
        money_received = "You received $%s"
    }
}
