--[[
    VeeBiiz Physical Items — Placement Zones & Sockets

    Objects can ONLY be placed into sockets inside these zones.
    Coordinates below are example Bahama Mamas-style bar sockets.
    Adjust to your map / MLO before production use.
]]

Config = Config or {}
Config.Zones = Config.Zones or {}

--[[
    Zone schema:
    {
        id = string,
        label = string,
        coords = vec3,          -- zone center
        radius = number,        -- simple radius zone (or use points/poly)
        points = vec3[]?,       -- optional poly points
        minZ / maxZ,
        ownership = 'public'|'job'|'zone'|'player',
        job = string?,
        sockets = { Socket, ... }
    }

    Socket schema:
    {
        id = string,
        label = string,
        coords = vec3,
        rotation = vec3,
        allowedItems = string[],
        allowedCategories = string[]?,
        maxObjects = number,
        allowedInteractions = string[]?,
        ownership = string?,
        job = string?,
        metadataRules = table?,
    }
]]

Config.Zones['bahama_bar'] = {
    id = 'bahama_bar',
    label = 'Bahama Bar',
    coords = vec3(-1392.50, -605.80, 30.32),
    radius = 12.0,
    minZ = 29.0,
    maxZ = 33.5,
    ownership = 'job',
    job = 'bartender',
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
            job = 'bartender',
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
            job = 'bartender',
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
            job = 'bartender',
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
            job = 'bartender',
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
            job = 'bartender',
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
            job = 'bartender',
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
            job = 'bartender',
        },
    },
}
