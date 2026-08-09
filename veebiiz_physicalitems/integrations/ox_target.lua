--[[
    Integration — ox_target (client)
]]

VPI = VPI or {}
VPI.Target = VPI.Target or {}

local RESOURCE = 'ox_target'
local registered = {}

local function ready()
    return GetResourceState(RESOURCE) == 'started'
end

---@param entity number
---@param options table
function VPI.Target.AddEntity(entity, options)
    if not ready() or not entity or entity == 0 then return end
    exports.ox_target:addLocalEntity(entity, options)
    registered[entity] = true
end

---@param entity number
function VPI.Target.RemoveEntity(entity)
    if not ready() or not entity then return end
    if registered[entity] then
        pcall(function()
            exports.ox_target:removeLocalEntity(entity)
        end)
        registered[entity] = nil
    end
end

function VPI.Target.ClearAll()
    for entity in pairs(registered) do
        VPI.Target.RemoveEntity(entity)
    end
end

---@param objectId number
---@param interactions table
---@return table
function VPI.Target.BuildOptions(objectId, interactions)
    local options = {}
    for i = 1, #interactions do
        local inter = interactions[i]
        options[#options + 1] = {
            name = ('vpi_%s_%s'):format(objectId, inter.name),
            icon = inter.icon and ('fa-solid fa-%s'):format(inter.icon) or 'fa-solid fa-hand',
            label = inter.label,
            distance = Config.Interaction.distance,
            onSelect = function()
                TriggerEvent('vpi:client:targetSelect', objectId, inter.name)
            end,
        }
    end
    return options
end
