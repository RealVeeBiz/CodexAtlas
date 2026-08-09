--[[
    Client — Interaction framework
]]

VPI = VPI or {}
VPI.Interaction = VPI.Interaction or {}

local custom = {} ---@type table<string, table>
local focusedId = nil
local nuiOpen = false

---@param name string
---@param def table
function VPI.Interaction.Register(name, def)
    def = def or {}
    def.name = name
    custom[name] = def
    Config.Interactions[name] = def
end

---@param name string
---@return table|nil
function VPI.Interaction.Get(name)
    return custom[name] or Config.Interactions[name]
end

---@param object table
---@return table[]
function VPI.Interaction.BuildForObject(object)
    local def = VPI.Utils.GetItemDef(object.item) or {}
    local names = def.interactions or { 'pickup', 'move', 'inspect' }
    local list = {}
    local carrying = VPI.Carry.IsCarrying()
    local carryItem = VPI.Carry.GetItem()

    for i = 1, #names do
        local name = names[i]
        local inter = VPI.Interaction.Get(name)
        if inter then
            local include = true
            if inter.canInteract then
                local ok, result = pcall(inter.canInteract, object)
                include = ok and result
            end

            -- Hide pickup/move while already carrying
            if carrying and (name == 'pickup' or name == 'move') then
                include = false
            end

            -- Object↔object actions are injected from recipes when carrying a source
            if inter.requiresTargetObject then
                include = false
            end

            if include then
                list[#list + 1] = {
                    name = name,
                    label = inter.label,
                    icon = inter.icon,
                    key = inter.key,
                    priority = inter.priority or 50,
                }
            end
        end
    end

    -- If carrying something, inject recipe interactions against this object
    if carrying and carryItem then
        local sourceDef = VPI.Utils.GetItemDef(carryItem)
        local targetDef = def
        local recipes = Config.FindRecipes(carryItem, object.item, nil, sourceDef, targetDef, object.state)
        local seen = {}
        for i = 1, #recipes do
            local r = recipes[i]
            if not seen[r.interaction] then
                seen[r.interaction] = true
                local inter = VPI.Interaction.Get(r.interaction) or {}
                list[#list + 1] = {
                    name = r.interaction,
                    label = r.label or inter.label or r.interaction,
                    icon = inter.icon or 'bolt',
                    key = inter.key or 'H',
                    priority = inter.priority or 85,
                    recipe = true,
                }
            end
        end
    end

    table.sort(list, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)

    return list
end

---@param object table
---@return table
function VPI.Interaction.BuildStateLines(object)
    local state = object.state or {}
    local lines = {}
    local def = VPI.Utils.GetItemDef(object.item)

    if state.amount and state.capacity then
        local unit = state.unit or 'ml'
        lines[#lines + 1] = ('%s / %s %s'):format(state.amount, state.capacity, string.upper(unit))
    elseif state.amount then
        lines[#lines + 1] = tostring(state.amount)
    end
    if state.liquid then
        lines[#lines + 1] = tostring(state.liquid)
    end
    if state.ice then lines[#lines + 1] = 'Ice' end
    if state.garnish then lines[#lines + 1] = tostring(state.garnish) end

    return {
        label = (def and def.label) or object.item,
        category = def and def.category or 'item',
        lines = lines,
        state = state,
    }
end

function VPI.Interaction.Show(object, interactions)
    focusedId = object.id
    nuiOpen = true
    local info = VPI.Interaction.BuildStateLines(object)
    VPI.Client.Utils.SendNui('showPrompt', {
        objectId = object.id,
        label = info.label,
        category = info.category,
        lines = info.lines,
        state = info.state,
        interactions = interactions,
        world = Config.Interaction.useWorldIndicator,
    })
end

function VPI.Interaction.Hide()
    if not nuiOpen and not focusedId then return end
    focusedId = nil
    nuiOpen = false
    VPI.Client.Utils.SendNui('hidePrompt', {})
end

function VPI.Interaction.GetFocused()
    return focusedId
end

---@param objectId number
---@param action string
function VPI.Interaction.Run(objectId, action)
    local inter = VPI.Interaction.Get(action)
    local object = VPI.ObjectStore.Get(objectId)

    if action == 'pickup' then
        VPI.Pickup.Take(objectId)
        VPI.Interaction.Hide()
        return
    end

    if action == 'move' then
        VPI.Pickup.Move(objectId)
        VPI.Interaction.Hide()
        return
    end

    if inter and inter.action then
        local ok, err = pcall(inter.action, object)
        if not ok then
            VPI.Utils.Debug('interaction action error %s', tostring(err))
        end
    end

    local payload = { action = action, objectId = objectId }
    if VPI.Carry.IsCarrying() then
        -- carried item acts on this world object
        payload.targetId = objectId
        payload.objectId = nil
    end
    TriggerServerEvent(VPI.Events.INTERACT, payload)
end

RegisterNetEvent('vpi:client:registerInteraction', function(name, def)
    VPI.Interaction.Register(name, def)
end)

RegisterNetEvent('vpi:client:registerItem', function(name, def)
    Config.Items[name] = def
end)
