--[[
    VeeBiiz Physical Items — Core Configuration
]]

Config = Config or {}

Config.Debug = false
Config.Locale = 'en'

--- Framework adapter: 'qbox' | 'auto'
Config.Framework = 'auto'

--- Inventory adapter: 'ox_inventory'
Config.Inventory = 'ox_inventory'

--- Targeting adapter: 'ox_target' | 'custom' | 'both'
Config.Target = 'both'

Config.Streaming = {
    distance = 100.0,
    tickMs = 1000,
    maxSpawnPerTick = 12,
}

Config.Interaction = {
    distance = 2.0,
    raycastDistance = 8.0,
    tickMs = 150,
    useWorldIndicator = true,
    useNuiMenu = true,
}

Config.Placement = {
    distance = 3.5,
    socketSearchRadius = 4.0,
    confirmKey = 'RETURN',
    cancelKeys = { 'BACK', 'ESCAPE' },
    ghostAlpha = 140,
    requireSocket = true, -- never free-place
}

Config.Carry = {
    blockWeapon = true,
    blockVehicle = true,
    blockCombat = true,
    defaultAnim = {
        dict = 'anim@heists@box_carry@',
        clip = 'idle',
        flag = 49,
    },
}

Config.Security = {
    cooldownMs = 750,
    lockTimeoutMs = 15000,
    maxDistanceSlop = 0.75,
    validateOwnership = true,
    validateInventory = true,
}

Config.Persistence = {
    table = 'physical_objects',
    autosaveState = true,
    loadOnStart = true,
}

Config.Editor = {
    enabled = true,
    acePermission = 'vpi.editor',
    command = 'pieditor',
    jobs = { 'admin', 'god' }, -- optional job gate when ACE is not set
}

Config.Notify = {
    position = 'top-right',
    duration = 3500,
}

Config.Keys = {
    take = 'E',
    move = 'G',
    interact = 'H',
    inspect = 'X',
    place = 'RETURN',
    cancel = 'BACK',
}
