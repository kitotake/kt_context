# KT Context Menu v3.1 — Changelog & Documentation

## Bugs corrigés

### Critiques
- **`rotation_server.lua`** — appelait des natives CLIENT côté serveur (`GetEntityCoords`, `PlayerPedId`, `CreateObject`…). Désormais le serveur ne fait que logger et valider, tout le placement/rotation est 100% côté client.
- **`config_rotation.lua`** — conflitait avec `config.lua` (double `Config = {}`). Fusionné dans `shared/config.lua` sous `Config.Rotation`.
- **`server/permissions.lua`** — `AddEventHandler('playerJoining')` n'est pas un événement FiveM natif. Corrigé en `playerConnecting` + `onServerResourceStart` pour les joueurs déjà connectés.
- **Double `IsPlayerAdmin()`** — définie dans `utils.lua` ET `sync.lua`, causait un conflit selon l'ordre de chargement. `utils.lua` définit maintenant uniquement un alias temporaire, `sync.lua` écrase définitivement.
- **`ContextMenu.scss`** importé mais remplacé par `menu.scss` — styles dupliqués supprimés.

### Mineurs
- `door_all_open` / `door_all_close` manquaient dans les handlers de `main.lua`
- `veh_lights` manquait dans les handlers statiques
- `win_up` / `win_down` plantaient si pas dans un véhicule
- `useNuiEvent` — ref handler potentiellement stale, corrigé avec `useRef`

---

## Système de rotation des props

### Placement (limité à 3m)
```lua
-- Via commande
/placeprop [nom_du_model]   -- place devant le joueur (max 3m)
/deleteprop                  -- supprime le prop actif
/propmenu                    -- ouvre le menu de gestion
/deletenearby                -- supprime tous les props proches (admin/staff)

-- Via export
exports['kt_context']:PlaceProp('prop_mp_barrier_01a')
exports['kt_context']:DeleteProp()
exports['kt_context']:OpenPropMenu()
```

### Menu de gestion du prop
Rotation par axe (**X Pitch**, **Y Roll**, **Z Yaw**) par pas de 15° (configurable).
- Reset rotation
- Rotation automatique (tourne en continu sur l'axe choisi)
- Geler / Dégeler la position
- Suppression avec confirmation

### Config
```lua
Config.Limits.PropMaxDistance = 3.0    -- m depuis le joueur (défaut 3m)
Config.Limits.PropMaxHeight   = 2.0    -- écart vertical max
Config.Limits.PropRotateStep  = 15.0   -- degrés par clic
Config.Limits.PropMaxActive   = 1      -- 1 prop actif max par joueur
```

---

## Limites d'utilisation

### Interactions PNJ
```lua
Config.Limits.NpcCooldown    = 5000   -- 5s entre deux interactions
Config.Limits.NpcMaxDistance = 3.0    -- portée max 3m
```

### Animations
```lua
Config.Limits.AnimCooldown       = 2000  -- 2s entre deux animations
Config.Limits.AnimBlockInVehicle = true  -- interdit en véhicule
```

### Déplacement pendant un menu
Le menu **se ferme automatiquement** si le joueur s'éloigne de plus de **3m** depuis son ouverture.
```lua
Config.Limits.MaxInteractMoveDistance = 3.0  -- m (défaut 3m)
```

---

## Système Admin / Staff

### Hiérarchie
```
user < staff < moderator < admin < founder
```

### Permissions par action
| Action                  | Minimum requis |
|-------------------------|----------------|
| Heal/Armor soi-même     | staff          |
| Réparer un véhicule     | staff          |
| TP vers un joueur       | admin          |
| Supprimer une entité    | admin          |
| Kick un joueur          | admin          |
| God Mode / Invisible    | admin          |
| Placer des props        | admin          |
| Changer un groupe       | admin          |

### Confirmation obligatoire (admin)
La suppression d'entités et le kick demandent une confirmation dans le menu.
```lua
Config.Limits.AdminConfirmDelete = true   -- activer/désactiver
```

### Rate limiting serveur
```lua
Config.Limits.ServerActionCooldown = 500  -- ms min entre events serveur
```

---

## Nouvelles features

### Système de notifications NUI
Remplace `DrawNotification` natif GTA par des notifications élégantes dans le coin bas-droite.
```lua
ShowNotification('Message', 'success')  -- info | success | warning | error
```
Côté Lua, `ShowNotification` envoie maintenant automatiquement un message NUI + le DrawNotification natif en fallback.

### Cooldown global
```lua
HasCooldown('ma_cle')              -- true si cooldown actif
SetCooldown('ma_cle', 3000)        -- activer pour 3000ms
ClearCooldown('ma_cle')            -- vider manuellement
```

### Staff vs Admin
`IsPlayerStaff()` disponible côté client — retourne `true` pour staff, moderator, admin, founder.

---

## Installation

```bash
cd kt_context/web
npm install
npm run build
```

```
# server.cfg
ensure kt_context
```

---

## Structure des fichiers modifiés

```
kt_context/
├── shared/config.lua              ← Config fusionnée (rotation incluse)
├── client/
│   ├── utils.lua                  ← +cooldowns, +IsPlayerStaff, -IsPlayerAdmin (alias)
│   ├── sync.lua                   ← Source unique IsPlayerAdmin/GetAdminRole/IsPlayerStaff
│   ├── main.lua                   ← +distance check 3m, +cooldown anims, +handlers prop
│   └── alts_client/
│       ├── entity_menus.lua       ← +cooldown NPC, +distance check, +confirmation admin
│       ├── quick_actions.lua      ← +cooldowns anims, +IsPlayerStaff pour heal
│       └── rotation_client.lua    ← REFAIT - 3m limit, menu, auto-rotate, cleanup
├── server/
│   ├── permissions.lua            ← FIX playerConnecting, +rate limiting, +onServerResourceStart
│   ├── admin.lua                  ← +rate limiting, +staff checks
│   └── alts_server/
│       └── rotation_server.lua    ← REFAIT - plus de natives client côté serveur
├── fxmanifest.lua                 ← +rotation_client, +rotation_server, +exports prop
└── web/src/
    ├── App.tsx                    ← +NotificationSystem
    └── components/
        └── NotificationSystem.tsx ← NOUVEAU - notifications NUI animées
```
