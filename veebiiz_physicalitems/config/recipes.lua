--[[
    VeeBiiz Physical Items — Object ↔ Object Interaction Recipes

    Core ships with no domain recipes. Extensions register via:
      exports.veebiiz_physicalitems:RegisterRecipe({ ... })
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
---@field consumeCarry boolean|nil  -- clear carry session after a successful recipe use
---@field addToTarget table|nil     -- patch applied to target.state
---@field animation string|nil
---@field duration number|nil

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
