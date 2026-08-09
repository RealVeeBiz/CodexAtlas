--[[
    Bar placement zone + sockets.

    Coordinates are Bahama Mamas-style examples — adjust to your MLO before
    production use (or place with /pieditor and copy the runtime JSON here).
]]

BarConfig = BarConfig or {}

local job = BarConfig.Job or 'bartender'

BarConfig.Zones = {
    bahama_bar = {
        id = 'bahama_bar',
        label = 'Bahama Bar',
        coords = vec3(-1392.50, -605.80, 30.32),
        radius = 12.0,
        minZ = 29.0,
        maxZ = 33.5,
        ownership = 'job',
        job = job,
        sockets = {
            {
                id = 'bottle_01',
                label = 'Bottle Slot 1',
                coords = vec3(-1391.85, -605.20, 30.95),
                rotation = vec3(0.0, 0.0, 120.0),
                allowedItems = { 'whisky', 'vodka', 'rum', 'coke', 'tonic' },
                allowedCategories = { 'bottle', 'mixer' },
                maxObjects = 1,
                allowedInteractions = { 'pickup', 'move', 'pour', 'inspect' },
                ownership = 'job',
                job = job,
            },
            {
                id = 'bottle_02',
                label = 'Bottle Slot 2',
                coords = vec3(-1391.55, -605.45, 30.95),
                rotation = vec3(0.0, 0.0, 120.0),
                allowedItems = { 'whisky', 'vodka', 'rum', 'coke', 'tonic' },
                allowedCategories = { 'bottle', 'mixer' },
                maxObjects = 1,
                ownership = 'job',
                job = job,
            },
            {
                id = 'bottle_03',
                label = 'Bottle Slot 3',
                coords = vec3(-1391.25, -605.70, 30.95),
                rotation = vec3(0.0, 0.0, 120.0),
                allowedItems = { 'whisky', 'vodka', 'rum', 'coke', 'tonic' },
                allowedCategories = { 'bottle', 'mixer' },
                maxObjects = 1,
                ownership = 'job',
                job = job,
            },
            {
                id = 'glass_01',
                label = 'Glass Slot 1',
                coords = vec3(-1392.10, -606.10, 30.82),
                rotation = vec3(0.0, 0.0, 30.0),
                allowedItems = { 'glass' },
                allowedCategories = { 'glassware' },
                maxObjects = 1,
                allowedInteractions = { 'pickup', 'move', 'drink', 'inspect', 'wash' },
                ownership = 'job',
                job = job,
            },
            {
                id = 'glass_02',
                label = 'Glass Slot 2',
                coords = vec3(-1392.35, -606.30, 30.82),
                rotation = vec3(0.0, 0.0, 30.0),
                allowedItems = { 'glass' },
                allowedCategories = { 'glassware' },
                maxObjects = 1,
                ownership = 'job',
                job = job,
            },
            {
                id = 'mixing_01',
                label = 'Mixing Slot',
                coords = vec3(-1392.60, -605.90, 30.85),
                rotation = vec3(0.0, 0.0, 0.0),
                allowedItems = { 'glass', 'whisky', 'vodka', 'rum', 'coke', 'tonic', 'ice', 'lemon' },
                maxObjects = 1,
                allowedInteractions = { 'pickup', 'move', 'mix', 'pour', 'inspect' },
                ownership = 'job',
                job = job,
            },
            {
                id = 'ingredient_01',
                label = 'Ingredient Slot',
                coords = vec3(-1391.00, -605.90, 30.90),
                rotation = vec3(0.0, 0.0, 0.0),
                allowedItems = { 'ice', 'lemon' },
                allowedCategories = { 'ingredient' },
                maxObjects = 1,
                ownership = 'job',
                job = job,
            },
        },
    },
}
