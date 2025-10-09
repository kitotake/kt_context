# KT Context Menu

Système de menu contextuel moderne pour FiveM/RedM avec React + TypeScript + SCSS

## 🚀 Installation

1. Cloner le repository dans votre dossier `resources`
2. Installer les dépendances: `npm install`
3. Build le projet: `npm run build`
4. Ajouter `ensure kt_context` dans votre `server.cfg`

## 📖 Utilisation

### Depuis un script client

```lua
exports['kt_context']:OpenContextMenu(500, 300, {
    {
        id = "action_1",
        label = "Mon action",
        icon = "🎮",
        description = "Description"
    }
}, "Mon Menu")

exports['kt_context']:CloseContextMenu()

local isOpen = exports['kt_context']:IsMenuOpen()
```

### Créer des menus personnalisés

Voir `client/main.lua` pour des exemples complets.

## 🎨 Personnalisation

Modifiez les variables SCSS dans `src/components/ContextMenu.scss`:

```scss
$color-primary: #3b82f6;
$color-bg-menu: rgba(17, 24, 39, 0.95);

```

## 📝 License

MIT
