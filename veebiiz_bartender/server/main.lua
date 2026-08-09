--[[
    Registers bartender items, recipes, and bar zones into veebiiz_physicalitems.
]]

local RESOURCE = 'veebiiz_physicalitems'

local function waitForCore()
    local deadline = GetGameTimer() + 30000
    while GetResourceState(RESOURCE) ~= 'started' do
        if GetGameTimer() > deadline then
            print('[veebiiz_bartender] ERROR: veebiiz_physicalitems did not start in time.')
            return false
        end
        Wait(200)
    end
    Wait(BarConfig.BootDelayMs or 750)
    return true
end

local function registerAll()
    local countItems, countRecipes, countZones = 0, 0, 0

    for name, def in pairs(BarConfig.Items or {}) do
        exports[RESOURCE]:RegisterItem(name, def)
        countItems = countItems + 1
    end

    for i = 1, #(BarConfig.Recipes or {}) do
        exports[RESOURCE]:RegisterRecipe(BarConfig.Recipes[i])
        countRecipes = countRecipes + 1
    end

    for zoneId, zone in pairs(BarConfig.Zones or {}) do
        exports[RESOURCE]:RegisterZone(zoneId, zone)
        countZones = countZones + 1
    end

    if BarConfig.SeedStarterStock then
        for i = 1, #(BarConfig.StarterStock or {}) do
            local entry = BarConfig.StarterStock[i]
            local ok, err = pcall(function()
                exports[RESOURCE]:CreateObject({
                    zone_id = entry.zone,
                    slot_id = entry.slot,
                    item = entry.item,
                })
            end)
            if not ok then
                print(('[veebiiz_bartender] Seed failed for %s/%s: %s'):format(
                    tostring(entry.zone), tostring(entry.slot), tostring(err)
                ))
            end
        end
    end

    print(('[veebiiz_bartender] Registered %s items, %s recipes, %s zones.'):format(
        countItems, countRecipes, countZones
    ))
end

CreateThread(function()
    if not waitForCore() then return end
    registerAll()
end)

--- Optional helper: register an extra cocktail at runtime from another resource
exports('RegisterCocktail', function(recipe)
    if type(recipe) ~= 'table' or type(recipe.id) ~= 'string' then
        return false, 'invalid_recipe'
    end
    recipe.interaction = recipe.interaction or 'mix'
    exports[RESOURCE]:RegisterRecipe(recipe)
    return true
end)
