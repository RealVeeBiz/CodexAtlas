--[[
    VeeBiiz Physical Items — Prop / model helpers
]]

Config = Config or {}

Config.Props = {
    --- Fallback model when an item model fails to load
    fallback = 'prop_cs_cardbox_01',

    --- Optional model aliases (item model → actual game model)
    aliases = {
        -- ['custom_whisky'] = 'prop_whiskey_bottle',
    },

    --- Category → default model when item.model is omitted
    categoryDefaults = {
        drink = 'prop_whiskey_bottle',
        glassware = 'prop_cs_shot_glass',
        ingredient = 'prop_bar_beans',
        mixer = 'prop_ecola_can',
        misc = 'prop_cs_cardbox_01',
    },

    --- Load timeout (ms)
    loadTimeout = 5000,
}

---@param model string|number
---@return string|number
function Config.ResolvePropModel(model)
    if type(model) == 'string' and Config.Props.aliases[model] then
        return Config.Props.aliases[model]
    end
    return model or Config.Props.fallback
end
