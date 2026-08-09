--[[
    Server — Callbacks & net event handlers
]]

VPI = VPI or {}
VPI.Callbacks = VPI.Callbacks or {}

--- Per-player carry session (server-authoritative)
---@type table<number, table>
local carrySessions = {}

local function notify(src, message, nType)
    VPI.Lib.Notify(src, {
        title = 'Physical Items',
        description = message,
        type = nType or 'inform',
    })
end

function VPI.Callbacks.GetCarry(source)
    return carrySessions[source]
end

function VPI.Callbacks.ClearCarry(source)
    local session = carrySessions[source]
    if session and session.objectId then
        VPI.Objects.Unlock(session.objectId, source)
    end
    carrySessions[source] = nil
end

local function beginCarry(source, session)
    carrySessions[source] = session
    TriggerClientEvent(VPI.Events.CARRY_START, source, session)
end

---@param source number
---@param itemName string
---@param opts table|nil  { skipRemove = boolean, metadata = table, state = table }
---@return boolean, string|nil
function VPI.Callbacks.StartCarryFromItem(source, itemName, opts)
    opts = opts or {}
    if type(itemName) ~= 'string' then return false, 'invalid_item' end
    if carrySessions[source] then return false, 'already_carrying' end

    local ok, def = VPI.Validation.ItemIsPhysical(itemName)
    if not ok then return false, 'not_physical' end

    if not VPI.Validation.CanAccessOwnership(source, def.permissions) then
        return false, 'no_permission'
    end

    local state, metadata
    if opts.skipRemove then
        metadata = opts.metadata or {}
        if metadata.vpi and metadata.vpi.state then
            state = VPI.Utils.DeepCopy(metadata.vpi.state)
        elseif opts.state then
            state = VPI.Utils.DeepCopy(opts.state)
        elseif def.defaultState then
            state = VPI.Utils.DeepCopy(def.defaultState)
        else
            state = {}
        end
    else
        local consumed, payload, invErr = VPI.Inv.ConsumeForPlacement(source, itemName)
        if not consumed then return false, invErr or 'missing_item' end
        state = payload.state
        metadata = payload.metadata
    end

    beginCarry(source, {
        mode = VPI.Enums.CarryMode.FROM_INVENTORY,
        item = itemName,
        model = def.model,
        state = state,
        metadata = metadata,
        label = def.label,
    })
    return true, nil
end

lib.callback.register('vpi:getObjects', function()
    return VPI.Objects.GetAllPublic()
end)

lib.callback.register('vpi:getZones', function()
    return Config.Zones
end)

lib.callback.register('vpi:getCarry', function(source)
    return carrySessions[source]
end)

lib.callback.register('vpi:getObject', function(_, id)
    return VPI.Objects.GetPublic(id)
end)

lib.callback.register('vpi:canEdit', function(source)
    return VPI.Permissions.CanUseEditor(source)
end)

--- Take physical item from inventory into carry mode
RegisterNetEvent(VPI.Events.CREATE_FROM_ITEM, function(itemName)
    local src = source
    if not VPI.Validation.CheckCooldown(src, 'create') then return end
    local ok, err = VPI.Callbacks.StartCarryFromItem(src, itemName)
    if not ok then
        local messages = {
            already_carrying = 'You are already carrying something.',
            not_physical = 'This item cannot become physical.',
            no_permission = 'You do not have permission to use this item.',
            missing_item = 'Item not found in inventory.',
        }
        notify(src, messages[err] or 'Unable to take item.', 'error')
    end
end)

--- Pickup world object into inventory carry / hand
RegisterNetEvent(VPI.Events.TAKE_OBJECT, function(objectId)
    local src = source
    objectId = tonumber(objectId)
    if not objectId then return end
    if not VPI.Validation.CheckCooldown(src, 'take') then return end
    if carrySessions[src] then
        notify(src, 'You are already carrying something.', 'error')
        return
    end

    local obj = VPI.Objects.Get(objectId)
    if not obj then
        notify(src, 'Object no longer exists.', 'error')
        return
    end

    if VPI.Objects.IsLocked(objectId, src) then
        notify(src, 'Object is locked.', 'error')
        return
    end

    local allowed, permErr = VPI.Permissions.CanInteract(src, obj, 'pickup')
    if not allowed then
        notify(src, 'No permission.', 'error')
        return
    end

    local near = VPI.Validation.InDistance(src, obj, Config.Interaction.distance)
    if not near then
        notify(src, 'Too far away.', 'error')
        return
    end

    local lockOk = VPI.Objects.Lock(objectId, src)
    if not lockOk then
        notify(src, 'Object is locked.', 'error')
        return
    end

    -- Remove from world first (anti-dupe), then give inventory + carry attach
    local snapshot = VPI.Utils.DeepCopy(obj)
    local removed = VPI.Objects.Remove(objectId)
    if not removed then
        VPI.Objects.Unlock(objectId, src)
        notify(src, 'Failed to take object.', 'error')
        return
    end

    local given, giveErr = VPI.Inv.ReturnObject(src, snapshot)
    if not given then
        -- rollback
        VPI.Objects.Create({
            zone_id = snapshot.zone_id,
            slot_id = snapshot.slot_id,
            item = snapshot.item,
            model = snapshot.model,
            state = snapshot.state,
            metadata = snapshot.metadata,
            owner = snapshot.owner,
            ownership = snapshot.ownership,
            job = snapshot.job,
        }, true)
        notify(src, 'Inventory full.', 'error')
        VPI.Utils.Debug('take rollback %s', tostring(giveErr))
        return
    end

    -- Immediately re-consume into carry session so prop stays in hand
    local consumed, payload = VPI.Inv.ConsumeForPlacement(src, snapshot.item)
    if not consumed then
        notify(src, 'Taken, but carry failed.', 'error')
        return
    end

    beginCarry(src, {
        mode = VPI.Enums.CarryMode.FROM_WORLD,
        item = snapshot.item,
        model = snapshot.model,
        state = payload.state or snapshot.state,
        metadata = payload.metadata or snapshot.metadata,
        label = (VPI.Utils.GetItemDef(snapshot.item) or {}).label,
        fromObjectId = snapshot.id,
    })
end)

--- Start moving an existing world object
RegisterNetEvent(VPI.Events.START_MOVE, function(objectId)
    local src = source
    objectId = tonumber(objectId)
    if not objectId then return end
    if not VPI.Validation.CheckCooldown(src, 'move') then return end
    if carrySessions[src] then
        notify(src, 'You are already carrying something.', 'error')
        return
    end

    local obj = VPI.Objects.Get(objectId)
    if not obj then
        notify(src, 'Object no longer exists.', 'error')
        return
    end

    local allowed = VPI.Permissions.CanInteract(src, obj, 'move')
    if not allowed then
        notify(src, 'No permission.', 'error')
        return
    end

    local near = VPI.Validation.InDistance(src, obj, Config.Interaction.distance)
    if not near then
        notify(src, 'Too far away.', 'error')
        return
    end

    local lockOk, lockErr = VPI.Objects.Lock(objectId, src)
    if not lockOk then
        notify(src, 'Object is locked.', 'error')
        return
    end

    -- Hide from world while moving (keep DB row)
    TriggerClientEvent(VPI.Events.OBJECT_REMOVED, -1, { id = objectId, temporary = true })

    beginCarry(src, {
        mode = VPI.Enums.CarryMode.MOVING,
        objectId = objectId,
        item = obj.item,
        model = obj.model,
        state = obj.state,
        metadata = obj.metadata,
        label = (VPI.Utils.GetItemDef(obj.item) or {}).label,
        fromZone = obj.zone_id,
        fromSlot = obj.slot_id,
    })
end)

--- Place carried item / finish move
RegisterNetEvent(VPI.Events.PLACE_OBJECT, function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if not VPI.Validation.CheckCooldown(src, 'place') then return end

    local session = carrySessions[src]
    if not session then
        notify(src, 'You are not carrying anything.', 'error')
        return
    end

    local zoneId = payload.zoneId
    local socketId = payload.socketId
    if type(zoneId) ~= 'string' or type(socketId) ~= 'string' then
        notify(src, 'Invalid placement.', 'error')
        return
    end

    local can, zone, socket, err = VPI.Validation.CanPlaceInSocket(zoneId, socketId, session.item)
    if not can then
        notify(src, err == 'invalid_placement' and 'Invalid placement' or 'Cannot place here.', 'error')
        return
    end

    local near = VPI.Validation.InDistance(src, socket.coords, Config.Placement.distance)
    if not near then
        notify(src, 'Too far from socket.', 'error')
        return
    end

    if not VPI.Validation.CanAccessOwnership(src, socket.ownership or zone.ownership, nil, socket.job or zone.job) then
        notify(src, 'No permission for this socket.', 'error')
        return
    end

    if session.mode == VPI.Enums.CarryMode.MOVING and session.objectId then
        local occupied = VPI.Objects.GetInSocket(zoneId, socketId)
        if occupied and occupied.id ~= session.objectId then
            notify(src, 'Socket is full.', 'error')
            return
        end

        local okMove, moveErr = VPI.Objects.Update(session.objectId, {
            zone_id = zoneId,
            slot_id = socketId,
            state = session.state,
        })
        if not okMove then
            notify(src, 'Failed to move object.', 'error')
            VPI.Utils.Debug('move fail %s', tostring(moveErr))
            return
        end

        VPI.Objects.Unlock(session.objectId, src)
        local updated = VPI.Objects.Get(session.objectId)
        if updated then
            TriggerClientEvent(VPI.Events.OBJECT_CREATED, -1, VPI.Objects.GetPublic(session.objectId))
        end
        carrySessions[src] = nil
        TriggerClientEvent(VPI.Events.CARRY_STOP, src)
        notify(src, 'Object moved.', 'success')
        return
    end

    -- New placement from inventory / world take
    if VPI.Objects.CountInSocket(zoneId, socketId) >= (socket.maxObjects or 1) then
        notify(src, 'Socket is full.', 'error')
        return
    end

    local owner = VPI.Framework.GetIdentifier(src)
    local created, createErr = VPI.Objects.Create({
        zone_id = zoneId,
        slot_id = socketId,
        item = session.item,
        model = session.model,
        state = session.state,
        metadata = session.metadata,
        owner = owner,
    }, true)

    if not created then
        notify(src, createErr == 'invalid_placement' and 'Invalid placement' or 'Failed to place object.', 'error')
        return
    end

    carrySessions[src] = nil
    TriggerClientEvent(VPI.Events.CARRY_STOP, src)
    notify(src, 'Object placed.', 'success')
end)

RegisterNetEvent(VPI.Events.CANCEL_CARRY, function()
    local src = source
    local session = carrySessions[src]
    if not session then return end

    if session.mode == VPI.Enums.CarryMode.MOVING and session.objectId then
        VPI.Objects.Unlock(session.objectId, src)
        local obj = VPI.Objects.Get(session.objectId)
        if obj then
            TriggerClientEvent(VPI.Events.OBJECT_CREATED, -1, VPI.Objects.GetPublic(session.objectId))
        end
        carrySessions[src] = nil
        TriggerClientEvent(VPI.Events.CARRY_STOP, src)
        return
    end

    -- Return item to inventory
    local ok = VPI.Inventory.GivePhysicalItem(src, session.item, session.state, session.metadata)
    if not ok then
        notify(src, 'Could not return item to inventory.', 'error')
        return
    end

    carrySessions[src] = nil
    TriggerClientEvent(VPI.Events.CARRY_STOP, src)
    notify(src, 'Placement cancelled.', 'inform')
end)

--- Generic object interaction (pour, drink, inspect, recipes, etc.)
RegisterNetEvent(VPI.Events.INTERACT, function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if not VPI.Validation.CheckCooldown(src, 'interact') then return end

    local action = payload.action
    local objectId = tonumber(payload.objectId)
    local targetId = tonumber(payload.targetId)

    if type(action) ~= 'string' then return end

    -- Interactions that operate on a world object
    if objectId then
        local obj = VPI.Objects.Get(objectId)
        if not obj then
            notify(src, 'Object no longer exists.', 'error')
            return
        end

        local allowed = VPI.Permissions.CanInteract(src, obj, action)
        if not allowed then
            notify(src, 'No permission.', 'error')
            return
        end

        local near = VPI.Validation.InDistance(src, obj, Config.Interaction.distance + 1.0)
        if not near then
            notify(src, 'Too far away.', 'error')
            return
        end

        if action == 'inspect' then
            notify(src, ('%s — %s'):format(obj.item, json.encode(obj.state or {})), 'inform')
            return
        end

        if action == 'drink' then
            local state = VPI.Utils.DeepCopy(obj.state or {})
            if not state.liquid or (state.amount or 0) <= 0 then
                notify(src, 'Glass is empty.', 'error')
                return
            end
            state.amount = 0
            state.liquid = nil
            state.ice = false
            state.garnish = nil
            VPI.Objects.Update(objectId, { state = state })
            TriggerClientEvent(VPI.Events.PLAY_INTERACTION, src, { action = 'drink', objectId = objectId })
            notify(src, 'You drank it.', 'success')
            return
        end

        if action == 'wash' then
            local state = { liquid = nil, amount = 0, capacity = (obj.state and obj.state.capacity) or 200, ice = false, garnish = nil, unit = 'ml' }
            VPI.Objects.Update(objectId, { state = state })
            notify(src, 'Glass washed.', 'success')
            return
        end
    end

    -- Carried source → world target (pour, add ice, mix, etc.)
    local session = carrySessions[src]
    if session and targetId then
        local target = VPI.Objects.Get(targetId)
        if not target then
            notify(src, 'Target object missing.', 'error')
            return
        end

        local near = VPI.Validation.InDistance(src, target, Config.Interaction.distance + 1.0)
        if not near then
            notify(src, 'Too far away.', 'error')
            return
        end

        local sourceDef = VPI.Utils.GetItemDef(session.item)
        local targetDef = VPI.Utils.GetItemDef(target.item)
        local recipes = Config.FindRecipes(session.item, target.item, action, sourceDef, targetDef, target.state)
        if #recipes == 0 then
            notify(src, 'Incompatible interaction.', 'error')
            return
        end

        local recipe = recipes[1]
        local consume = recipe.consumeSource or 0
        local sourceAmount = session.state and session.state.amount or 0
        -- Recipes with consumeCarry (e.g. ice/garnish) may omit amount tracking
        if consume > 0 and not recipe.consumeCarry and sourceAmount < consume then
            notify(src, 'Not enough remaining.', 'error')
            return
        end

        local newSource, newTarget = VPI.Objects.ApplyRecipe(session.state, session.item, target, recipe)
        session.state = newSource
        VPI.Objects.Update(targetId, { state = newTarget })

        TriggerClientEvent(VPI.Events.PLAY_INTERACTION, src, {
            action = recipe.interaction,
            animation = recipe.animation,
            duration = recipe.duration,
            targetId = targetId,
            sourceItem = session.item,
        })

        -- Consumable carried sources (ice, garnish, etc.): clear carry after use
        if recipe.consumeCarry and consume > 0 then
            carrySessions[src] = nil
            TriggerClientEvent(VPI.Events.CARRY_STOP, src)
        end

        notify(src, recipe.label or action, 'success')
        return
    end
end)

RegisterNetEvent(VPI.Events.REQUEST_SYNC, function()
    local src = source
    TriggerClientEvent(VPI.Events.SYNC_OBJECTS, src, VPI.Objects.GetAllPublic())
    TriggerClientEvent(VPI.Events.SYNC_ZONES, src, Config.Zones)
    TriggerClientEvent(VPI.Events.SYNC_RUNTIME, src, {
        items = VPI.Objects.GetRuntimeItems(),
        interactions = VPI.Objects.GetRuntimeInteractions(),
        recipes = Config.Recipes,
    })
    if carrySessions[src] then
        TriggerClientEvent(VPI.Events.CARRY_START, src, carrySessions[src])
    end
end)

RegisterNetEvent(VPI.Events.EDITOR_SAVE, function(payload)
    local src = source
    if not VPI.Permissions.CanUseEditor(src) then
        notify(src, 'No permission.', 'error')
        return
    end
    if type(payload) ~= 'table' or type(payload.zone) ~= 'table' then return end

    local zone = payload.zone
    if type(zone.id) ~= 'string' then return end
    Config.Zones[zone.id] = zone
    TriggerClientEvent(VPI.Events.SYNC_ZONES, -1, Config.Zones)
    notify(src, ('Zone %s saved (runtime). Persist to config/zones.lua for permanence.'):format(zone.id), 'success')
    -- Runtime save file for persistence across restarts within resource
    SaveResourceFile(GetCurrentResourceName(), ('config/runtime_zones/%s.json'):format(zone.id), json.encode(zone, { indent = true }), -1)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local session = carrySessions[src]
    if not session then return end

    if session.mode == VPI.Enums.CarryMode.MOVING and session.objectId then
        VPI.Objects.Unlock(session.objectId, src)
        local obj = VPI.Objects.Get(session.objectId)
        if obj then
            TriggerClientEvent(VPI.Events.OBJECT_CREATED, -1, VPI.Objects.GetPublic(session.objectId))
        end
    else
        -- Drop item back as worldless inventory loss prevention: recreate at nearest? return fails offline.
        -- Persist orphan by placing into a holding metadata dump is out of scope; re-insert inventory is impossible.
        -- Best-effort: leave item "lost" only if moving; for inventory carry, try nothing offline.
        VPI.Utils.Debug('playerDropped with carry session item=%s mode=%s', tostring(session.item), tostring(session.mode))
    end
    carrySessions[src] = nil
end)
