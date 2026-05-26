# Bridge kt_context ↔ kt_interact

## Vue d'ensemble

Ce bridge permet à **kt_context** d'afficher et de déclencher les interactions **kt_interact** directement depuis le menu contextuel (ALT+clic ou menu radial Z).

## Architecture

```
kt_context/
├── bridge/
│   ├── client/
│   │   ├── union_compat.lua           (existant — inchangé)
│   │   └── kt_interact_compat.lua     ← NOUVEAU
│   ├── server/
│   │   ├── union_compat.lua           (existant — inchangé)
│   │   └── kt_interact_compat.lua     ← NOUVEAU
│   └── patches/
│       └── cursor_patched.lua         ← NOUVEAU (remplace cursor.lua)
└── fxmanifest.lua                     ← MODIFIÉ
```

## Installation

### Étape 1 — Copier les fichiers bridge

Depuis ce dossier, copiez dans votre ressource `kt_context` :

```
bridge/client/kt_interact_compat.lua   → kt_context/bridge/client/kt_interact_compat.lua
bridge/server/kt_interact_compat.lua   → kt_context/bridge/server/kt_interact_compat.lua
bridge/patches/cursor_patched.lua      → kt_context/bridge/patches/cursor_patched.lua
```

### Étape 2 — Remplacer le fxmanifest.lua

Remplacez `kt_context/fxmanifest.lua` par `fxmanifest_kt_context.lua`.

> **Important** : le nouveau manifest charge `bridge/patches/cursor_patched.lua`
> à la place de `client/alts_client/cursor.lua`. Ne supprimez pas l'original,
> il n'est simplement plus chargé.

### Étape 3 — Vérifier l'ordre dans server.cfg

```cfg
ensure kt_interact   # doit démarrer AVANT kt_context
ensure kt_context
```

## Fonctionnement

### Menu contextuel (ALT+clic)

Quand le joueur ALT+clique sur :

| Cible | Comportement |
|-------|-------------|
| **Véhicule** | Ajoute les interactions `globalVehicle` + `model` (si le modèle correspond) |
| **PNJ** | Ajoute les interactions `globalPed` |
| **Joueur** | Ajoute les interactions `globalPlayer` |
| **Objet/Prop** | Ajoute les interactions `globalObject` + `model` (si le modèle correspond) |
| **Vide** | Affiche les zones à portée (`zone sphere/box`) dans un sous-menu "Interactions" |

Les interactions sont filtrées par distance et triées du plus proche au plus loin.

### Menu radial (touche Z)

Le menu radial existant gagne automatiquement les interactions disponibles via
le menu général (ouverture du context menu au centre de l'écran).

### Déclenchement

Quand le joueur clique sur une interaction kt_interact dans le menu kt_context :
1. kt_context envoie `kt_interact_data:triggerEvent` au serveur
2. kt_interact vérifie les conditions (cooldown, ACE, items…)
3. En cas de refus, kt_context affiche une notification
4. En cas de succès, kt_interact dispatche l'event configuré

## API

### Côté Lua (client)

```lua
-- Obtenir les items menu pour un contexte spécifique
local items = KtInteract_GetMenuItems({
    type     = 'vehicle',   -- 'ped', 'vehicle', 'object', 'general'
    entity   = vehicleHandle,
    coords   = GetEntityCoords(vehicleHandle),
    isPlayer = false,
})

-- Obtenir les zones à portée (menu général)
local items = KtInteract_GetGeneralMenuItems()

-- Déclencher manuellement une interaction
KtInteract_Trigger('uuid-de-l-interaction')

-- Nombre d'interactions en cache
local count = KtInteract_GetCacheCount()
```

### Export depuis un autre script

```lua
-- Depuis n'importe quelle ressource :
local items = exports['kt_context']:KtInteract_GetMenuItems({ type = 'general' })
exports['kt_context']:KtInteract_Trigger('interaction-id')
```

## Mapping des icônes

kt_interact utilise FontAwesome, kt_context utilise Lucide.
Le bridge convertit automatiquement les icônes courantes :

| FontAwesome | Lucide |
|-------------|--------|
| `fas fa-hand-pointer` | `HandPointing` |
| `fas fa-box` | `Package` |
| `fas fa-car` | `Car` |
| `fas fa-lock` / `fas fa-unlock` | `Lock` / `LockOpen` |
| `fas fa-wrench` | `Wrench` |
| `fas fa-shield` | `Shield` |
| … | … |

Les icônes non mappées utilisent `Zap` comme fallback.

## Dépendances

- `kt_interact` ≥ v3.1.0
- `kt_context` ≥ v3.2.0
- `kt_lib` (déjà requis par les deux)

## Notes

- Le bridge écoute passivement les events `kt_interact_data:*` pour maintenir
  un cache local **sans requête SQL supplémentaire**.
- La synchronisation est automatique : ajout, mise à jour, suppression
  d'interactions sont reflétés en temps réel dans kt_context.
- Les notifications de refus (`kt_interact:triggerDenied`) s'affichent via
  le système de notifications kt_context.
