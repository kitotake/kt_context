-- =============================================
-- BRIDGE CLIENT : kt_context ↔ union — v3.2
--
-- Ce fichier est chargé par kt_context UNIQUEMENT.
-- Il lit les données d'union (statebags, exports)
-- pour enrichir les fonctionnalités de kt_context :
--
--   • IsPlayerAdmin / IsPlayerStaff → lit le statebag union
--   • GetPlayerDisplayName → firstname + lastname depuis union
--   • GetCharacterJob → job depuis le personnage union actif
--
-- Si union n'est pas démarré, tout retombe sur les
-- valeurs par défaut (natif FiveM / ace).
-- =============================================

local UNION_RESOURCE = KtContextConfig.UnionIntegration.ResourceName or 'union'
local USE_UNION      = KtContextConfig.UnionIntegration.Enabled
local USE_PERMS      = KtContextConfig.UnionIntegration.UseUnionPerms
local USE_STATEBAG   = KtContextConfig.UnionIntegration.UseUnionStatebag

-- ─── Helper : union disponible ? ─────────────────────────────────────────
local function unionAvailable()
    return USE_UNION and GetResourceState(UNION_RESOURCE) == 'started'
end

-- ─── Lecture du statebag character ───────────────────────────────────────
local function getUnionCharacter()
    if not USE_STATEBAG or not unionAvailable() then return nil end
    local ok, char = pcall(function()
        return LocalPlayer.state.character
    end)
    return (ok and type(char) == 'table') and char or nil
end

local function getUnionJob()
    if not unionAvailable() then return nil end
    local ok, job = pcall(function()
        return LocalPlayer.state.job
    end)
    return (ok and type(job) == 'table') and job or nil
end

-- ─── API publique ─────────────────────────────────────────────────────────

-- Retourne le nom d'affichage d'un joueur (network player ID)
-- Si union actif + statebag dispo → "Prénom Nom"
-- Sinon → GetPlayerName() natif
function KtGetPlayerDisplayName(player)
    if USE_STATEBAG and unionAvailable() then
        local ok, char = pcall(function()
            return Player(GetPlayerPed(player)).state.character
        end)
        if ok and type(char) == 'table' and char.firstname then
            return char.firstname .. ' ' .. (char.lastname or '')
        end
    end
    return GetPlayerName(player) or ('Player_%d'):format(player)
end

-- Retourne le job du personnage local depuis union
-- { name = "police", grade = 2 } ou nil
function KtGetLocalJob()
    local job = getUnionJob()
    if job then return job end
    -- Fallback : statebag character.job
    local char = getUnionCharacter()
    if char then
        return { name = char.job or 'unemployed', grade = char.job_grade or 0 }
    end
    return nil
end

-- Retourne le unique_id du personnage actif (depuis union)
function KtGetUniqueId()
    local char = getUnionCharacter()
    return char and char.unique_id or nil
end

-- ─── Permissions : surcharge IsPlayerAdmin / IsPlayerStaff ───────────────
-- Si USE_PERMS = true, on lit le statebag union au lieu de Permissions.group
-- pour que kt_context soit synchronisé avec les permissions union.

if USE_PERMS and USE_UNION then
    -- Hierarchy union : user < staff < moderator < admin < founder
    local HIERARCHY = { user=1, staff=2, moderator=3, admin=4, founder=5 }

    local function getUnionGroup()
        -- Priorité 1 : statebag character (contient ped_model, pas group)
        -- Le group n'est PAS dans le statebag character — on lit Permissions
        -- qui est synchronisé par union via 'permissions:client:set'
        if Permissions and Permissions.group then
            return Permissions.group
        end
        return 'user'
    end

    -- Écrase définitivement les fonctions de sync.lua
    -- (sync.lua est chargé avant ce bridge dans fxmanifest)
    function IsPlayerAdmin()
        local group = getUnionGroup()
        return (HIERARCHY[group] or 0) >= HIERARCHY['admin']
    end

    function IsPlayerStaff()
        local group = getUnionGroup()
        return (HIERARCHY[group] or 0) >= HIERARCHY['staff']
    end

    function GetAdminRole()
        local group = getUnionGroup()
        if group == 'user' then return nil end
        return group
    end

    print('[KT Context] Bridge union : permissions synchronisées depuis union')
end

-- ─── Notification : optionnel via union ──────────────────────────────────
-- Si UseUnionNotify = true, on utilise union:notify au lieu du NUI kt_context
if KtContextConfig.UnionIntegration.UseUnionNotify and unionAvailable() then
    local _originalShow = ShowNotification
    function ShowNotification(message, notifType)
        notifType = notifType or 'info'
        TriggerEvent('union:notify', message, notifType, 3000)
        -- Garde aussi le DrawNotification natif en fallback
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end
    print('[KT Context] Bridge union : notifications via union:notify')
end

-- ─── Export vers d'autres ressources ─────────────────────────────────────
exports('KtGetPlayerDisplayName', KtGetPlayerDisplayName)
exports('KtGetLocalJob',          KtGetLocalJob)
exports('KtGetUniqueId',          KtGetUniqueId)

print('[KT Context] Bridge union client chargé (union actif: ' .. tostring(unionAvailable()) .. ')')
