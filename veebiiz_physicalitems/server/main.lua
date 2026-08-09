--[[
    Server — Main bootstrap & public exports
]]

VPI = VPI or {}

local function loadRuntimeZones()
    local resource = GetCurrentResourceName()

    for zoneId, _ in pairs(Config.Zones) do
        local raw = LoadResourceFile(resource, ('config/runtime_zones/%s.json'):format(zoneId))
        if raw and raw ~= '' then
            local ok, decoded = pcall(json.decode, raw)
            if ok and type(decoded) == 'table' then
                Config.Zones[zoneId] = decoded
                VPI.Utils.Debug('Loaded runtime zone %s', zoneId)
            end
        end
    end

    local indexRaw = LoadResourceFile(resource, 'config/runtime_zones/index.json')
    if indexRaw and indexRaw ~= '' then
        local ok, list = pcall(json.decode, indexRaw)
        if ok and type(list) == 'table' then
            for i = 1, #list do
                local id = list[i]
                local raw = LoadResourceFile(resource, ('config/runtime_zones/%s.json'):format(id))
                if raw then
                    local ok2, zone = pcall(json.decode, raw)
                    if ok2 and zone then
                        Config.Zones[id] = zone
                    end
                end
            end
        end
    end
end

CreateThread(function()
    VPI.Persistence.EnsureSchema()
    loadRuntimeZones()

    if Config.Persistence.loadOnStart ~= false then
        local count = VPI.Objects.LoadFromDatabase()
        print(('[veebiiz_physicalitems] Ready — %s persistent objects loaded.'):format(count))
    else
        print('[veebiiz_physicalitems] Ready — persistence load skipped.')
    end
end)

-- ═══════════════════════════════════════════
-- Public Exports
-- ═══════════════════════════════════════════

exports('RegisterItem', function(name, def)
    return VPI.Objects.RegisterItem(name, def)
end)

exports('CreateObject', function(data)
    return VPI.Objects.Create(data, true)
end)

exports('RemoveObject', function(id)
    return VPI.Objects.Remove(id)
end)

exports('GetObject', function(id)
    return VPI.Objects.GetPublic(id)
end)

exports('GetObjectsNear', function(coords, radius)
    return VPI.Objects.GetNear(coords, radius or 10.0)
end)

exports('RegisterInteraction', function(name, def)
    return VPI.Objects.RegisterInteraction(name, def)
end)

exports('RegisterZone', function(zoneId, def)
    return VPI.Objects.RegisterZone(zoneId, def)
end)

exports('RegisterSocket', function(zoneId, socket)
    return VPI.Objects.RegisterSocket(zoneId, socket)
end)

exports('RegisterRecipe', function(recipe)
    Config.Recipes[#Config.Recipes + 1] = recipe
    return true
end)

exports('GetZones', function()
    return Config.Zones
end)

exports('UpdateObjectState', function(id, state)
    return VPI.Objects.Update(id, { state = state })
end)

--- Start carrying a physical item from inventory (server API)
exports('StartCarryItem', function(source, itemName)
    return VPI.Callbacks.StartCarryFromItem(source, itemName)
end)

--- ox_inventory item use export
--- Item definition example:
---   server = { export = 'veebiiz_physicalitems.usePhysicalItem' }
exports('usePhysicalItem', function(event, item, inventory, slot, data)
    local src = inventory and inventory.id
    if type(src) ~= 'number' then return false end

    if event == 'usingItem' then
        if VPI.Callbacks.GetCarry(src) then
            VPI.Lib.Notify(src, {
                title = 'Physical Items',
                description = 'You are already carrying something.',
                type = 'error',
            })
            return false
        end

        local ok, def = VPI.Validation.ItemIsPhysical(item.name)
        if not ok then return false end
        if not VPI.Validation.CanAccessOwnership(src, def.permissions) then
            VPI.Lib.Notify(src, {
                title = 'Physical Items',
                description = 'You do not have permission to use this item.',
                type = 'error',
            })
            return false
        end
        return -- allow ox_inventory to consume the item
    end

    if event == 'usedItem' then
        local metadata = {}
        if type(item) == 'table' and type(item.metadata) == 'table' then
            metadata = item.metadata
        elseif type(slot) == 'table' and type(slot.metadata) == 'table' then
            metadata = slot.metadata
        elseif type(slot) == 'number' and inventory and inventory.items and inventory.items[slot] then
            metadata = inventory.items[slot].metadata or {}
        end

        VPI.Callbacks.StartCarryFromItem(src, item.name, {
            skipRemove = true,
            metadata = metadata,
        })
    end
end)

print('[veebiiz_physicalitems] Server main loaded.')
