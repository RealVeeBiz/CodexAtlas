--[[
    VeeBiiz Physical Items — Object ↔ Object Interaction Recipes

    Recipes describe how a carried/source object can interact with a target object.
    The bartender example uses these; cooking/mechanics can register more at runtime.
]]

Config = Config or {}
Config.Recipes = Config.Recipes or {}

---@class VPIRecipe
---@field id string
---@field label string
---@field interaction string
---@field sourceItems string[]|nil
---@field sourceCategories string[]|nil
---@field targetItems string[]|nil
---@field targetCategories string[]|nil
---@field consumeSource number|nil  -- amount to reduce from source.state.amount
---@field addToTarget table|nil     -- patch applied to target.state
---@field animation string|nil
---@field duration number|nil

local function recipe(def)
    Config.Recipes[#Config.Recipes + 1] = def
end

recipe({
    id = 'pour_spirit_to_glass',
    label = 'Pour',
    interaction = 'pour',
    sourceItems = { 'whisky', 'vodka', 'rum' },
    sourceCategories = { 'drink' },
    targetItems = { 'glass' },
    targetCategories = { 'glassware' },
    consumeSource = 40,
    addToTarget = {
        -- liquid is copied from source.state.liquid at runtime
        amountDelta = 40,
        setIce = false,
    },
    animation = 'pour',
    duration = 2200,
})

recipe({
    id = 'pour_mixer_to_glass',
    label = 'Pour Mixer',
    interaction = 'pour',
    sourceItems = { 'coke', 'tonic' },
    sourceCategories = { 'mixer' },
    targetItems = { 'glass' },
    targetCategories = { 'glassware' },
    consumeSource = 60,
    addToTarget = { amountDelta = 60 },
    animation = 'pour',
    duration = 1800,
})

recipe({
    id = 'add_ice_to_glass',
    label = 'Add Ice',
    interaction = 'add_ice',
    sourceItems = { 'ice' },
    targetItems = { 'glass' },
    targetCategories = { 'glassware' },
    consumeSource = 1,
    addToTarget = { ice = true },
    animation = 'use',
    duration = 1200,
})

recipe({
    id = 'add_lemon_to_glass',
    label = 'Add Garnish',
    interaction = 'add_garnish',
    sourceItems = { 'lemon' },
    targetItems = { 'glass' },
    targetCategories = { 'glassware' },
    consumeSource = 1,
    addToTarget = { garnish = 'lemon' },
    animation = 'use',
    duration = 1200,
})

recipe({
    id = 'whisky_coke_mix',
    label = 'Mix Whisky Coke',
    interaction = 'mix',
    sourceItems = { 'coke' },
    targetItems = { 'glass' },
    requireTargetState = { liquid = 'whisky' },
    consumeSource = 80,
    addToTarget = {
        liquid = 'whisky_coke',
        amountDelta = 80,
    },
    animation = 'pour',
    duration = 2000,
})

--- Find matching recipes for a source/target pair
---@param sourceItem string
---@param targetItem string
---@param interaction string|nil
---@param sourceDef table|nil
---@param targetDef table|nil
---@param targetState table|nil
---@return table[]
function Config.FindRecipes(sourceItem, targetItem, interaction, sourceDef, targetDef, targetState)
    local matches = {}
    for i = 1, #Config.Recipes do
        local r = Config.Recipes[i]
        if not interaction or r.interaction == interaction then
            local sourceOk = true
            local targetOk = true

            if r.sourceItems and not VPI.Utils.Contains(r.sourceItems, sourceItem) then
                sourceOk = false
            end
            if sourceOk and r.sourceCategories and sourceDef then
                sourceOk = VPI.Utils.Contains(r.sourceCategories, sourceDef.category)
            end

            if r.targetItems and not VPI.Utils.Contains(r.targetItems, targetItem) then
                targetOk = false
            end
            if targetOk and r.targetCategories and targetDef then
                targetOk = VPI.Utils.Contains(r.targetCategories, targetDef.category)
            end

            if targetOk and r.requireTargetState and targetState then
                for k, v in pairs(r.requireTargetState) do
                    if targetState[k] ~= v then
                        targetOk = false
                        break
                    end
                end
            end

            if sourceOk and targetOk then
                matches[#matches + 1] = r
            end
        end
    end
    return matches
end
