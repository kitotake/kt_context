# KT Context Menu v3.2 — Changelog & Documentation

## Nouveautés v3.2

### Système d'overlay avec checkboxes
Le menu contextuel supporte maintenant des **items checkbox** permettant d'activer/désactiver des fonctionnalités en temps réel.

**Overlays disponibles (accessibles via ALT+clic → Affichages, ou touche O) :**

| Overlay | Description | Config |
|---------|-------------|--------|
| Noms des joueurs | Texte 3D flottant au-dessus des têtes | `Config.Overlay.PlayerNames` |
| Blips joueurs sur carte | Points sur la minimap pour les joueurs proches | `Config.Overlay.PlayerBlips` |
| Cercle de portée | Cercle autour du joueur local | `Config.Overlay.RangeCircle` |
| Infos véhicules | Plaque/vitesse/santé des véhicules proches | `Config.Overlay.VehicleInfo` |

**Config (shared/config.lua) :**
```lua
Config.Overlay = {
    PlayerNames = {
        Enabled      = false,   -- désactivé par défaut
        MaxDistance  = 30.0,    -- distance max d'affichage
        ShowId       = true,    -- afficher l'ID serveur
        ShowDistance = false,
        ShowHealth   = false,
    },
    PlayerBlips = {
        Enabled     = false,
        MaxDistance = 200.0,
    },
    RangeCircle = {
        Enabled = false,
        Radius  = 50.0,
    },
    VehicleInfo = {
        Enabled     = false,
        MaxDistance = 15.0,
        ShowPlate   = true,
        ShowSpeed   = false,
    },
}
```

**Raccourcis clavier :**
- `O` → Ouvre le menu des overlays directement
- `Z` → Menu radial (inclut les overlays)
- `ALT` maintenu + clic → Menu contextuel (inclut les overlays)

---

## Bugs corrigés v3.2

### Critiques
- **`overlay.lua`** — `_clearPlayerBlips` déclarée APRÈS son appel dans `AddEventHandler` → déplacée avant.
- **`radial_menu.lua`** — `BuildOverlayMenu()` appelée avant le chargement d'`overlay.lua` → appel défensif avec `if BuildOverlayMenu then`.
- **`cursor.lua`** — même protection défensive sur `BuildOverlayMenu`.
- **`keybinds.lua`** — même protection défensive.

### v3.1 (conservés)
- `rotation_server.lua` — plus de natives CLIENT côté serveur
- `config_rotation.lua` — fusionné dans `shared/config.lua`
- `server/permissions.lua` — `playerConnecting` au lieu de `playerJoining`
- Double `IsPlayerAdmin()` — source unique dans `sync.lua`
- `door_all_open/close`, `veh_lights`, `win_up/down` — handlers corrigés

---

## Système de checkboxes NUI

### Côté Lua
```lua
-- Dans un menu, ajouter un item checkbox :
{
    id          = 'mon_overlay',
    label       = 'Afficher les noms',
    icon        = 'Users',
    type        = 'checkbox',   -- ← type checkbox
    checked     = false,        -- ← état initial
    description = 'Distance max : 30m',
}

-- Écouter les changements :
AddEventHandler('kt_context:checkboxAction', function(id, checked, data)
    if id == 'mon_overlay' then
        -- checked = true/false
        MaFonction(checked)
    end
end)
```

### Côté React (automatique)
Le composant `CheckboxItem` envoie `checkboxAction` via NUI callback.
`main.lua` reçoit et dispatch via `TriggerEvent('kt_context:checkboxAction', id, checked, data)`.

---

## Système de rotation des props

```lua
/placeprop [nom_du_model]   -- place devant le joueur (max 3m)
/deleteprop                  -- supprime le prop actif
/propmenu                    -- ouvre le menu de gestion
/deletenearby                -- supprime tous les props proches (admin/staff)
```

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

## Structure des fichiers

```
kt_context/
├── shared/config.lua              ← Config fusionnée + Config.Overlay (nouveau)
├── client/
│   ├── utils.lua
│   ├── sync.lua
│   ├── main.lua                   ← +checkboxAction NUI callback
│   ├── zones.lua
│   └── alts_client/
│       ├── overlay.lua            ← NOUVEAU — overlays + checkboxes
│       ├── cursor.lua             ← +BuildOverlayMenu dans menu général
│       ├── entity_menus.lua
│       ├── keybinds.lua           ← +raccourci O pour overlay
│       ├── quick_actions.lua
│       ├── radial_menu.lua        ← +entrée overlays
│       ├── debug_target.lua
│       └── rotation/
│           ├── client.lua
│           ├── dataview.lua
│           └── gizmo.lua
├── server/
│   ├── main.lua
│   ├── permissions.lua
│   ├── admin.lua
│   └── alts_server/
│       ├── action_logs.lua
│       └── rotation_server.lua
├── fxmanifest.lua                 ← +overlay.lua, +exports BuildOverlayMenu
└── web/src/
    ├── App.tsx                    ← +DEV_ITEMS avec checkboxes overlay
    ├── components/
    │   ├── CheckboxItem.tsx       ← envoie checkboxAction (pas menuAction)
    │   ├── MenuItemRow.tsx        ← détection type=checkbox
    │   ├── ContextMenu.tsx
    │   ├── NotificationSystem.tsx
    │   ├── Cursor.tsx
    │   └── DynamicIcon.tsx
    └── styles/
        ├── variables.scss
        ├── global.scss
        └── menu.scss              ← styles checkbox intégrés (plus checkbox.scss séparé)
```
