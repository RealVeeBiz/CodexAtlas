--[[
    Client — Object streaming & entity cache
]]

VPI = VPI or {}
VPI.ObjectStore = VPI.ObjectStore or {}

---@type table<number, table>
local store = {}
---@type table<number, number> objectId -> entity
local entities = {}
---@type table<number, number> entity -> objectId
local entityToId = {}

function VPI.ObjectStore.Get(id)
    return store[id]
end

function VPI.ObjectStore.GetAll()
    return store
end

function VPI.ObjectStore.GetEntity(id)
    return entities[id]
end

function VPI.ObjectStore.GetIdFromEntity(entity)
    return entityToId[entity]
end

function VPI.ObjectStore.Upsert(obj)
    if not obj or not obj.id then return end
    store[obj.id] = obj
end

function VPI.ObjectStore.Remove(id)
    VPI.ObjectStore.Despawn(id)
    store[id] = nil
end

function VPI.ObjectStore.SetAll(list)
    local keep = {}
    for i = 1, #list do
        local obj = list[i]
        keep[obj.id] = true
        store[obj.id] = obj
    end
    for id in pairs(store) do
        if not keep[id] then
            VPI.ObjectStore.Remove(id)
        end
    end
end

---@param id number
---@return number|nil
function VPI.ObjectStore.Spawn(id)
    local obj = store[id]
    if not obj then return nil end
    if entities[id] and DoesEntityExist(entities[id]) then
        return entities[id]
    end

    local ok, hash = VPI.Client.Utils.LoadModel(obj.model)
    if not ok then
        VPI.Utils.Debug('Failed to load model %s', tostring(obj.model))
        return nil
    end

    local entity = CreateObjectNoOffset(hash, obj.x, obj.y, obj.z, false, false, false)
    if not entity or entity == 0 then return nil end

    SetEntityRotation(entity, obj.rot_x or 0.0, obj.rot_y or 0.0, obj.rot_z or 0.0, 2, true)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(hash)

    entities[id] = entity
    entityToId[entity] = id

    if Config.Target == 'ox_target' or Config.Target == 'both' then
        TriggerEvent('vpi:client:attachTarget', id, entity)
    end

    return entity
end

function VPI.ObjectStore.Despawn(id)
    local entity = entities[id]
    if entity then
        if Config.Target == 'ox_target' or Config.Target == 'both' then
            VPI.Target.RemoveEntity(entity)
        end
        entityToId[entity] = nil
        VPI.Client.Utils.DeleteEntity(entity)
        entities[id] = nil
    end
end

function VPI.ObjectStore.DespawnAll()
    for id in pairs(entities) do
        VPI.ObjectStore.Despawn(id)
    end
end

--- Distance-based streaming tick
CreateThread(function()
    local streamDist = (Config.Streaming and Config.Streaming.distance) or VPI.Constants.STREAM_DISTANCE
    local tick = (Config.Streaming and Config.Streaming.tickMs) or VPI.Constants.STREAM_TICK_MS
    local maxPerTick = (Config.Streaming and Config.Streaming.maxSpawnPerTick) or 12

    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local spawned = 0

        for id, obj in pairs(store) do
            local dist = VPI.Utils.Distance(coords, obj)
            local entity = entities[id]
            local exists = entity and DoesEntityExist(entity)

            if dist <= streamDist then
                if not exists and spawned < maxPerTick then
                    VPI.ObjectStore.Spawn(id)
                    spawned = spawned + 1
                end
            else
                if exists then
                    VPI.ObjectStore.Despawn(id)
                end
            end
        end

        Wait(tick)
    end
end)

RegisterNetEvent(VPI.Events.SYNC_OBJECTS, function(list)
    VPI.ObjectStore.SetAll(list or {})
end)

RegisterNetEvent(VPI.Events.OBJECT_CREATED, function(obj)
    VPI.ObjectStore.Upsert(obj)
end)

RegisterNetEvent(VPI.Events.OBJECT_UPDATED, function(obj)
    VPI.ObjectStore.Upsert(obj)
    local entity = entities[obj.id]
    if entity and DoesEntityExist(entity) then
        SetEntityCoordsNoOffset(entity, obj.x, obj.y, obj.z, false, false, false)
        SetEntityRotation(entity, obj.rot_x or 0.0, obj.rot_y or 0.0, obj.rot_z or 0.0, 2, true)
    end
end)

RegisterNetEvent(VPI.Events.OBJECT_REMOVED, function(payload)
    local id = type(payload) == 'table' and payload.id or payload
    VPI.ObjectStore.Remove(id)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    VPI.ObjectStore.DespawnAll()
end)
