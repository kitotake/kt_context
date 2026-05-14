# KT Context Menu v2.0

Système de menu contextuel moderne pour FiveM — React 18 + TypeScript + SCSS + Framer Motion.

---

## 🚀 Installation

```bash
# 1. Copier le dossier dans resources/
cp -r kt_context /chemin/vers/resources/

# 2. Compiler le frontend (nécessite Node.js 18+)
cd kt_context/web
npm install
npm run build

# 3. Ajouter dans server.cfg
ensure kt_context
```

---

## ⌨️ Contrôles en jeu

| Touche | Action |
|--------|--------|
| **ALT GAUCHE** (maintenu) | Active le curseur |
| **Clic gauche** (curseur actif) | Ouvre le menu sur l'entité cliquée |
| **Z** | Ouvre le menu radial |
| **X** | Menu émotes rapides |
| **L** | Verrouiller/déverrouiller véhicule |
| **E** | Interagir avec une zone |
| **Échap** | Fermer le menu |

---

## 📖 Utilisation depuis un script Lua

### Ouvrir un menu à une position précise

```lua
-- Ouvre le menu aux coordonnées écran (pixels)
exports['kt_context']:OpenContextMenu(x, y, items, title)

-- Exemple : menu au centre de l'écran
local sw, sh = GetActiveScreenResolution()
exports['kt_context']:OpenContextMenu(sw/2, sh/2, {
    { id = "action_1", label = "Mon action",  icon = "Zap"   },
    { id = "action_2", label = "Autre chose", icon = "Star",
      submenu = {
          { id = "sub_1", label = "Sous-option 1", icon = "ArrowRight" },
          { id = "sub_2", label = "Sous-option 2", icon = "ArrowRight" },
      }
    },
    { id = "_div", divider = true, label = "" },   -- Séparateur
    { id = "danger", label = "Action rouge", icon = "Trash2", variant = "danger" },
}, "Mon Menu")
```

### Fermer le menu

```lua
exports['kt_context']:CloseContextMenu()
```

### Vérifier si le menu est ouvert

```lua
local open = exports['kt_context']:IsMenuOpen()
```

### Écouter les actions (client)

```lua
-- Quand l'utilisateur clique sur un item, le NUI callback "menuAction" est déclenché
-- Vous pouvez écouter l'événement générique :
AddEventHandler("kt_context:action", function(itemId, data)
    if itemId == "mon_action" then
        -- faire quelque chose
    end
end)
```

---

## 🗺️ Zones interactives

```lua
-- Créer une zone circulaire
exports['kt_context']:RegisterMenuZone({
    id     = "ma_zone",
    coords = vector3(150.15, -1040.9, 29.37),
    radius = 4.0,
    shape  = "circle",         -- "circle" ou "box"
    title  = "🏦 Banque",
    hint   = "Appuyez sur ~INPUT_CONTEXT~ pour interagir",
    marker = {
        type  = 2,
        color = { r=16, g=185, b=129, a=130 },
        size  = vector3(4.0, 4.0, 0.3),
    },
    items = {
        { id = "deposit",  label = "Déposer",  icon = "ArrowUpFromLine" },
        { id = "withdraw", label = "Retirer",  icon = "ArrowDownToLine" },
    },
    -- Condition optionnelle pour afficher la zone
    condition = function()
        return true
    end,
})

-- Supprimer une zone
exports['kt_context']:RemoveMenuZone("ma_zone")
```

---

## 🎨 Structure d'un item

```lua
{
    id          = "unique_id",        -- Identifiant unique (requis)
    label       = "Texte affiché",    -- Libellé (requis)
    icon        = "Zap",              -- Nom d'icône Lucide React
    description = "Sous-texte",       -- Description en gris sous le label
    disabled    = false,              -- Griser l'item
    color       = "#ef4444",          -- Couleur de la bordure gauche (hex)
    variant     = "danger",           -- "default"|"success"|"warning"|"danger"
    badge       = "admin",            -- Badge texte (ex: rôle)
    badgeColor  = "#f59e0b",          -- Couleur du badge
    divider     = true,               -- Séparateur (ignorez les autres champs)
    action      = function() end,     -- Callback local (optionnel)
    submenu     = { ... },            -- Sous-menu (jusqu'à 6 niveaux)
}
```

---

## 🔧 Icônes disponibles

Le menu utilise **Lucide React**. Tous les noms d'icônes sont disponibles sur :
👉 https://lucide.dev/icons/

Exemples courants : `Zap`, `Star`, `Heart`, `Lock`, `LockOpen`, `Car`, `User`,
`ShieldAlert`, `Trash2`, `MapPin`, `Navigation`, `DollarSign`, `Phone`, `Backpack`…

---

## 🛡️ Détection admin

Le menu détecte automatiquement si le joueur possède l'une des permissions ACE :
- `admin`
- `moderator`
- `founder`

Si c'est le cas, des options supplémentaires apparaissent en bas des menus d'entité
(joueur, véhicule, objet) et du menu général.

Pour configurer les rôles, éditez `config.lua` :

```lua
Config.AdminAces = {
    admin     = 'admin',
    moderator = 'moderator',
    founder   = 'founder',
}
```

---

## 📂 Structure du projet

```
kt_context/
├── fxmanifest.lua
├── config.lua
├── client/
│   ├── utils.lua           ← Fonctions utilitaires (chargé en 1er)
│   ├── main.lua            ← Logique principale + exports
│   ├── cursor.lua          ← Système curseur ALT + détection entités
│   ├── zones.lua           ← Zones interactives
│   └── alts_client/
│       ├── keybinds.lua    ← Raccourcis clavier
│       ├── quick_actions.lua← Actions rapides (véhicule, joueur, admin)
│       └── radial_menu.lua ← Menu radial (touche Z)
├── server/
│   ├── main.lua
│   └── alts_server/
│       └── action_logs.lua ← Logs serveur
└── web/
    ├── src/
    │   ├── components/
    │   │   ├── ContextMenu.tsx   ← Menu principal avec Framer Motion
    │   │   ├── MenuItemRow.tsx   ← Item + sous-menus récursifs
    │   │   ├── Cursor.tsx        ← Curseur custom animé
    │   │   └── DynamicIcon.tsx   ← Résolution dynamique Lucide
    │   ├── hooks/
    │   │   ├── useContextMenu.ts ← État + écoute NUI
    │   │   ├── useCursor.ts      ← État curseur
    │   │   └── useNuiEvent.ts    ← Listener messages NUI
    │   ├── styles/
    │   │   ├── global.scss
    │   │   ├── variables.scss
    │   │   └── menu.scss
    │   ├── types/menu.types.ts
    │   ├── utils/nui.ts
    │   ├── App.tsx
    │   └── main.tsx
    └── build/              ← Généré par npm run build
```

---

## 📝 Licence

MIT — Libre d'utilisation et de modification.
