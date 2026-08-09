--[[
    Physical item definitions registered into veebiiz_physicalitems at runtime.
]]

BarConfig = BarConfig or {}
BarConfig.Items = BarConfig.Items or {}

local job = BarConfig.Job or 'bartender'

local function carry(bone, pos, rot)
    return {
        bone = bone or 57005,
        position = pos or vec3(0.12, 0.02, -0.02),
        rotation = rot or vec3(-80.0, 0.0, 0.0),
    }
end

---@param name string
---@param def table
local function define(name, def)
    def.name = name
    def.physical = true
    def.canPickup = def.canPickup ~= false
    def.canPlace = def.canPlace ~= false
    def.canMove = def.canMove ~= false
    def.category = def.category or 'misc'
    def.interactions = def.interactions or { 'pickup', 'move', 'inspect' }
    def.carry = def.carry or carry()
    def.defaultState = def.defaultState or {}
    def.permissions = def.permissions or { ownership = 'job', job = job }
    def.placement = def.placement or { requireSocket = true }
    def.animations = def.animations or {}
    BarConfig.Items[name] = def
end

define('whisky', {
    label = 'Whisky',
    model = 'prop_whiskey_bottle',
    category = 'drink',
    description = 'A bottle of aged whisky.',
    carry = carry(57005, vec3(0.12, 0.02, -0.02), vec3(-80.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'pour', 'inspect' },
    defaultState = { amount = 700, capacity = 700, liquid = 'whisky', unit = 'ml' },
    animations = {
        carry = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
        pour = { dict = 'mp_common', clip = 'givetake1_a', flag = 48, duration = 2200 },
    },
    placement = { requireSocket = true, categories = { 'bottle' } },
})

define('vodka', {
    label = 'Vodka',
    model = 'prop_vodka_bottle',
    category = 'drink',
    carry = carry(57005, vec3(0.12, 0.03, -0.02), vec3(-80.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'pour', 'inspect' },
    defaultState = { amount = 700, capacity = 700, liquid = 'vodka', unit = 'ml' },
    placement = { requireSocket = true, categories = { 'bottle' } },
})

define('rum', {
    label = 'Rum',
    model = 'prop_rum_bottle',
    category = 'drink',
    carry = carry(57005, vec3(0.12, 0.02, -0.02), vec3(-80.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'pour', 'inspect' },
    defaultState = { amount = 700, capacity = 700, liquid = 'rum', unit = 'ml' },
    placement = { requireSocket = true, categories = { 'bottle' } },
})

define('glass', {
    label = 'Glass',
    model = 'prop_cs_shot_glass',
    category = 'glassware',
    carry = carry(57005, vec3(0.13, 0.04, -0.03), vec3(-90.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'drink', 'inspect', 'wash' },
    defaultState = { liquid = nil, amount = 0, capacity = 200, ice = false, garnish = nil, unit = 'ml' },
    placement = { requireSocket = true, categories = { 'glass' } },
})

define('ice', {
    label = 'Ice',
    model = 'prop_bar_beans',
    category = 'ingredient',
    carry = carry(57005, vec3(0.10, 0.02, -0.02), vec3(0.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'add_ice', 'inspect' },
    defaultState = { amount = 1 },
    placement = { requireSocket = true, categories = { 'ingredient' } },
})

define('lemon', {
    label = 'Lemon',
    model = 'ng_proc_food_ornge1a',
    category = 'ingredient',
    carry = carry(57005, vec3(0.12, 0.03, -0.02), vec3(0.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'add_garnish', 'inspect' },
    defaultState = { garnish = 'lemon' },
    placement = { requireSocket = true, categories = { 'ingredient' } },
})

define('coke', {
    label = 'Coke',
    model = 'prop_ecola_can',
    category = 'mixer',
    carry = carry(57005, vec3(0.11, 0.02, -0.02), vec3(-70.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'pour', 'mix', 'inspect' },
    defaultState = { amount = 330, capacity = 330, liquid = 'coke', unit = 'ml' },
    placement = { requireSocket = true, categories = { 'bottle', 'mixer' } },
})

define('tonic', {
    label = 'Tonic',
    model = 'prop_energy_drink',
    category = 'mixer',
    carry = carry(57005, vec3(0.11, 0.02, -0.02), vec3(-70.0, 0.0, 0.0)),
    interactions = { 'pickup', 'move', 'pour', 'mix', 'inspect' },
    defaultState = { amount = 330, capacity = 330, liquid = 'tonic', unit = 'ml' },
    placement = { requireSocket = true, categories = { 'bottle', 'mixer' } },
})
