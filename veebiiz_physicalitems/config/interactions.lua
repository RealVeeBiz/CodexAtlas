--[[
    VeeBiiz Physical Items — Built-in Interaction Definitions

    Runtime registration also available via:
      exports.veebiiz_physicalitems:RegisterInteraction(name, definition)
]]

Config = Config or {}
Config.Interactions = Config.Interactions or {}

local function def(name, data)
    data.name = name
    data.label = data.label or name
    data.icon = data.icon or 'hand'
    data.priority = data.priority or 50
    data.key = data.key
    Config.Interactions[name] = data
end

def('pickup', {
    label = 'Take',
    icon = 'hand',
    priority = 100,
    key = 'E',
    description = 'Pick up and carry this object.',
})

def('move', {
    label = 'Move',
    icon = 'arrows-up-down-left-right',
    priority = 90,
    key = 'G',
    description = 'Move this object to another compatible socket.',
})

def('place', {
    label = 'Place',
    icon = 'check',
    priority = 95,
    key = 'RETURN',
})

def('rotate', {
    label = 'Rotate',
    icon = 'rotate',
    priority = 40,
    key = 'R',
})

def('inspect', {
    label = 'Inspect',
    icon = 'eye',
    priority = 20,
    key = 'X',
})

def('use', {
    label = 'Use',
    icon = 'bolt',
    priority = 70,
})

def('pour', {
    label = 'Pour',
    icon = 'droplet',
    priority = 80,
    key = 'H',
    requiresTargetObject = true,
    targetCategories = { 'glassware' },
    sourceCategories = { 'drink', 'mixer' },
})

def('fill', {
    label = 'Fill',
    icon = 'fill',
    priority = 75,
})

def('drink', {
    label = 'Drink',
    icon = 'wine-glass',
    priority = 70,
    key = 'H',
})

def('eat', {
    label = 'Eat',
    icon = 'utensils',
    priority = 70,
})

def('cook', {
    label = 'Cook',
    icon = 'fire',
    priority = 70,
    requiresTargetObject = true,
})

def('wash', {
    label = 'Wash',
    icon = 'droplets',
    priority = 30,
})

def('repair', {
    label = 'Repair',
    icon = 'wrench',
    priority = 70,
    requiresTargetObject = true,
})

def('mix', {
    label = 'Mix',
    icon = 'flask',
    priority = 75,
    requiresTargetObject = true,
})

def('open', {
    label = 'Open',
    icon = 'lock-open',
    priority = 60,
})

def('close', {
    label = 'Close',
    icon = 'lock',
    priority = 60,
})

def('add_ice', {
    label = 'Add Ice',
    icon = 'snowflake',
    priority = 78,
    requiresTargetObject = true,
    targetCategories = { 'glassware' },
})

def('add_garnish', {
    label = 'Add Garnish',
    icon = 'leaf',
    priority = 77,
    requiresTargetObject = true,
    targetCategories = { 'glassware' },
})
