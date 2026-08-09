--[[
    Server — Validation
]]

VPI = VPI or {}
VPI.Validation = VPI.Validation or {}

local cooldowns = {}

---@param source number
---@param key string
---@return boolean
function VPI.Validation.CheckCooldown(source, key)
    local now = GetGameTimer()
    local bucket = cooldowns[source]
    if not bucket then
        cooldowns[source] = {}
        bucket = cooldowns[source]
    end
    local last = bucket[key] or 0
    if now - last < (Config.Security.cooldownMs or 750) then
        return false
    end
    bucket[key] = now
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
end)

---@param source number
---@param coords vector3|table
---@param maxDist number
---@return boolean, number
function VPI.Validation.InDistance(source, coords, maxDist)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false, 9999.0 end
    local pcoords = GetEntityCoords(ped)
    local dist = VPI.Utils.Distance(pcoords, coords)
    local slop = Config.Security.maxDistanceSlop or 0.75
    return dist <= (maxDist + slop), dist
end

---@param itemName string
---@return boolean, table|nil, string|nil
function VPI.Validation.ItemIsPhysical(itemName)
    local def = VPI.Utils.GetItemDef(itemName)
    if not def then return false, nil, 'unknown_item' end
    if not def.physical then return false, def, 'not_physical' end
    return true, def, nil
end

---@param zoneId string
---@param socketId string
---@param itemName string
---@return boolean, table|nil, table|nil, string|nil
function VPI.Validation.CanPlaceInSocket(zoneId, socketId, itemName)
    local zone = VPI.Utils.GetZone(zoneId)
    if not zone then return false, nil, nil, 'invalid_zone' end

    local socket = VPI.Utils.GetSocket(zoneId, socketId)
    if not socket then return false, zone, nil, 'invalid_socket' end

    local okItem, def = VPI.Validation.ItemIsPhysical(itemName)
    if not okItem then return false, zone, socket, 'invalid_item' end

    if not VPI.Utils.SocketAllowsItem(socket, itemName) then
        -- also allow category match
        local cats = socket.allowedCategories
        if cats and def.category and VPI.Utils.Contains(cats, def.category) then
            return true, zone, socket, nil
        end
        return false, zone, socket, 'invalid_placement'
    end

    return true, zone, socket, nil
end

---@param source number
---@param ownership table|string|nil
---@param owner string|nil
---@param job string|nil
---@return boolean
function VPI.Validation.CanAccessOwnership(source, ownership, owner, job)
    if not Config.Security.validateOwnership then return true end

    local kind = ownership
    if type(ownership) == 'table' then
        kind = ownership.ownership or ownership.type or 'public'
        job = job or ownership.job
        owner = owner or ownership.owner
    end

    kind = kind or VPI.Enums.Ownership.PUBLIC

    if kind == VPI.Enums.Ownership.PUBLIC then
        return true
    end

    if kind == VPI.Enums.Ownership.PLAYER then
        local id = VPI.Framework.GetIdentifier(source)
        return id ~= nil and id == owner
    end

    if kind == VPI.Enums.Ownership.JOB or kind == VPI.Enums.Ownership.ZONE then
        if not job then return true end
        return VPI.Framework.HasJob(source, job)
    end

    return false
end
