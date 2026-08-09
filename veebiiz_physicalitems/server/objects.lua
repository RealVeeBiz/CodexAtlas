--[[
    Server — Object Manager
]]

VPI = VPI or {}
VPI.Objects = VPI.Objects or {}

local objects = {} ---@type table<number, table>
local bySocket = {} ---@type table<string, number>
local locks = {} ---@type table<number, { source: number, expires: number }>
local runtimeInteractions = {} ---@type table<string, table>
local runtimeItems = {} ---@type table<string, table>

local function socketKey(zoneId, slotId)
    return ('%s:%s'):format(zoneId, slotId)
end

local function publicObject(obj)
    if not obj then return nil end
    return {
        id = obj.id,
        zone_id = obj.zone_id,
        slot_id = obj.slot_id,
        item = obj.item,
        model = obj.model,
        x = obj.x, y = obj.y, z = obj.z,
        rot_x = obj.rot_x, rot_y = obj.rot_y, rot_z = obj.rot_z,
        state = obj.state or {},
        metadata = obj.metadata or {},
        owner = obj.owner,
        ownership = obj.ownership,
        job = obj.job,
        locked = locks[obj.id] ~= nil,
    }
end

function VPI.Objects.Get(id)
    return objects[id]
end

function VPI.Objects.GetAll()
    return objects
end

function VPI.Objects.GetPublic(id)
    return publicObject(objects[id])
end

function VPI.Objects.GetAllPublic()
    local list = {}
    for _, obj in pairs(objects) do
        list[#list + 1] = publicObject(obj)
    end
    return list
end

---@param coords vector3|table
---@param radius number
---@return table[]
function VPI.Objects.GetNear(coords, radius)
    local list = {}
    for _, obj in pairs(objects) do
        if VPI.Utils.Distance(coords, obj) <= radius then
            list[#list + 1] = publicObject(obj)
        end
    end
    return list
end

function VPI.Objects.GetInSocket(zoneId, slotId)
    local id = bySocket[socketKey(zoneId, slotId)]
    return id and objects[id] or nil
end

function VPI.Objects.CountInSocket(zoneId, slotId)
    return VPI.Objects.GetInSocket(zoneId, slotId) and 1 or 0
end

function VPI.Objects.Index(obj)
    objects[obj.id] = obj
    if obj.zone_id and obj.slot_id then
        bySocket[socketKey(obj.zone_id, obj.slot_id)] = obj.id
    end
end

function VPI.Objects.Unindex(id)
    local obj = objects[id]
    if not obj then return end
    if obj.zone_id and obj.slot_id then
        local key = socketKey(obj.zone_id, obj.slot_id)
        if bySocket[key] == id then
            bySocket[key] = nil
        end
    end
    objects[id] = nil
    locks[id] = nil
end

---@param id number
---@param source number
---@return boolean, string|nil
function VPI.Objects.Lock(id, source)
    local lock = locks[id]
    local now = GetGameTimer()
    if lock then
        if lock.expires < now then
            locks[id] = nil
        elseif lock.source ~= source then
            return false, 'locked'
        end
    end
    locks[id] = { source = source, expires = now + (Config.Security.lockTimeoutMs or 15000) }
    return true, nil
end

function VPI.Objects.Unlock(id, source)
    local lock = locks[id]
    if lock and (not source or lock.source == source) then
        locks[id] = nil
    end
end

function VPI.Objects.IsLocked(id, source)
    local lock = locks[id]
    if not lock then return false end
    if lock.expires < GetGameTimer() then
        locks[id] = nil
        return false
    end
    if source and lock.source == source then return false end
    return true
end

local function broadcast(event, payload, except)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and src ~= except then
            TriggerClientEvent(event, src, payload)
        end
    end
end

function VPI.Objects.BroadcastCreated(obj)
    broadcast(VPI.Events.OBJECT_CREATED, publicObject(obj))
end

function VPI.Objects.BroadcastUpdated(obj)
    broadcast(VPI.Events.OBJECT_UPDATED, publicObject(obj))
end

function VPI.Objects.BroadcastRemoved(id)
    broadcast(VPI.Events.OBJECT_REMOVED, { id = id })
end

---@param data table
---@param persist boolean|nil
---@return table|nil, string|nil
function VPI.Objects.Create(data, persist)
    local def = VPI.Utils.GetItemDef(data.item)
    if not def and not runtimeItems[data.item] then
        return nil, 'unknown_item'
    end
    def = def or runtimeItems[data.item]

    local can, zone, socket, err = VPI.Validation.CanPlaceInSocket(data.zone_id, data.slot_id, data.item)
    if not can then return nil, err end

    if VPI.Objects.CountInSocket(data.zone_id, data.slot_id) >= (socket.maxObjects or 1) then
        return nil, 'socket_full'
    end

    local rx, ry, rz = VPI.Utils.UnpackRot(socket.rotation)
    local x, y, z = VPI.Utils.UnpackCoords(socket.coords)

    local obj = {
        zone_id = data.zone_id,
        slot_id = data.slot_id,
        item = data.item,
        model = data.model or def.model,
        x = data.x or x,
        y = data.y or y,
        z = data.z or z,
        rot_x = data.rot_x or rx,
        rot_y = data.rot_y or ry,
        rot_z = data.rot_z or rz,
        state = data.state or VPI.Utils.DeepCopy(def.defaultState or {}),
        metadata = data.metadata or {},
        owner = data.owner,
        ownership = data.ownership or (def.permissions and def.permissions.ownership) or zone.ownership or 'public',
        job = data.job or (def.permissions and def.permissions.job) or zone.job,
    }

    if persist ~= false then
        local id = VPI.Persistence.Insert(obj)
        if not id then return nil, 'db_insert_failed' end
        obj.id = id
    else
        obj.id = data.id or (100000 + math.random(1, 99999))
    end

    VPI.Objects.Index(obj)
    VPI.Objects.BroadcastCreated(obj)
    return obj, nil
end

---@param id number
---@param data table
---@return boolean, string|nil
function VPI.Objects.Update(id, data)
    local obj = objects[id]
    if not obj then return false, 'missing_object' end

    if data.zone_id and data.slot_id and (data.zone_id ~= obj.zone_id or data.slot_id ~= obj.slot_id) then
        local can, _, socket, err = VPI.Validation.CanPlaceInSocket(data.zone_id, data.slot_id, obj.item)
        if not can then return false, err end
        local existing = VPI.Objects.GetInSocket(data.zone_id, data.slot_id)
        if existing and existing.id ~= id then
            return false, 'socket_full'
        end
        if obj.zone_id and obj.slot_id then
            local oldKey = socketKey(obj.zone_id, obj.slot_id)
            if bySocket[oldKey] == id then bySocket[oldKey] = nil end
        end
        obj.zone_id = data.zone_id
        obj.slot_id = data.slot_id
        local x, y, z = VPI.Utils.UnpackCoords(socket.coords)
        local rx, ry, rz = VPI.Utils.UnpackRot(socket.rotation)
        obj.x, obj.y, obj.z = x, y, z
        obj.rot_x, obj.rot_y, obj.rot_z = rx, ry, rz
        bySocket[socketKey(obj.zone_id, obj.slot_id)] = id
    end

    if data.state then obj.state = data.state end
    if data.metadata then obj.metadata = data.metadata end
    if data.owner ~= nil then obj.owner = data.owner end

    VPI.Persistence.Update(id, obj)
    VPI.Objects.BroadcastUpdated(obj)
    return true, nil
end

---@param id number
---@return boolean
function VPI.Objects.Remove(id)
    local obj = objects[id]
    if not obj then return false end
    VPI.Persistence.Delete(id)
    VPI.Objects.Unindex(id)
    VPI.Objects.BroadcastRemoved(id)
    return true
end

function VPI.Objects.LoadFromDatabase()
    local rows = VPI.Persistence.LoadAll()
    objects = {}
    bySocket = {}
    for i = 1, #rows do
        local obj = rows[i]
        -- normalize state from nested metadata
        if obj.metadata and obj.metadata.state then
            obj.state = obj.metadata.state
            obj.ownership = obj.ownership or obj.metadata.ownership
            obj.job = obj.job or obj.metadata.job
            obj.metadata = obj.metadata.extra or obj.metadata
        end
        VPI.Objects.Index(obj)
    end
    VPI.Utils.Debug('Loaded %s physical objects', tostring(#rows))
    return #rows
end

function VPI.Objects.RegisterItem(name, def)
    def = def or {}
    def.name = name
    def.physical = def.physical ~= false
    def.canPickup = def.canPickup ~= false
    def.canPlace = def.canPlace ~= false
    def.canMove = def.canMove ~= false
    def.interactions = def.interactions or { 'pickup', 'move', 'inspect' }
    def.carry = def.carry or {
        bone = 57005,
        position = vec3(0.12, 0.02, -0.02),
        rotation = vec3(-80.0, 0.0, 0.0),
    }
    Config.Items[name] = def
    runtimeItems[name] = def
    TriggerClientEvent('vpi:client:registerItem', -1, name, def)
    return true
end

function VPI.Objects.RegisterInteraction(name, def)
    def = def or {}
    def.name = name
    Config.Interactions[name] = def
    runtimeInteractions[name] = def
    TriggerClientEvent('vpi:client:registerInteraction', -1, name, def)
    return true
end

function VPI.Objects.RegisterZone(zoneId, def)
    def.id = zoneId
    Config.Zones[zoneId] = def
    TriggerClientEvent(VPI.Events.SYNC_ZONES, -1, Config.Zones)
    return true
end

function VPI.Objects.RegisterSocket(zoneId, socket)
    local zone = Config.Zones[zoneId]
    if not zone then return false end
    zone.sockets = zone.sockets or {}
    for i = 1, #zone.sockets do
        if zone.sockets[i].id == socket.id then
            zone.sockets[i] = socket
            TriggerClientEvent(VPI.Events.SYNC_ZONES, -1, Config.Zones)
            return true
        end
    end
    zone.sockets[#zone.sockets + 1] = socket
    TriggerClientEvent(VPI.Events.SYNC_ZONES, -1, Config.Zones)
    return true
end

--- Apply a recipe between source object (carried state) and target object
---@param sourceState table
---@param sourceItem string
---@param target table
---@param recipe table
---@return table, table
function VPI.Objects.ApplyRecipe(sourceState, sourceItem, target, recipe)
    local newSource = VPI.Utils.DeepCopy(sourceState or {})
    local newTarget = VPI.Utils.DeepCopy(target.state or {})

    local consume = recipe.consumeSource or 0
    if consume > 0 and newSource.amount then
        newSource.amount = math.max(0, (newSource.amount or 0) - consume)
    end

    local patch = recipe.addToTarget or {}
    if patch.amountDelta then
        newTarget.amount = math.min(
            newTarget.capacity or 99999,
            (newTarget.amount or 0) + patch.amountDelta
        )
    end
    if patch.liquid then
        newTarget.liquid = patch.liquid
    elseif recipe.interaction == 'pour' and newSource.liquid then
        if not newTarget.liquid or newTarget.liquid == newSource.liquid or (newTarget.amount or 0) <= 0 then
            newTarget.liquid = newSource.liquid
        end
    end
    if patch.ice ~= nil then newTarget.ice = patch.ice end
    if patch.setIce ~= nil then newTarget.ice = patch.setIce end
    if patch.garnish ~= nil then newTarget.garnish = patch.garnish end

    for k, v in pairs(patch) do
        if k ~= 'amountDelta' and k ~= 'setIce' and k ~= 'liquid' and k ~= 'ice' and k ~= 'garnish' then
            newTarget[k] = v
        end
    end

    return newSource, newTarget
end
