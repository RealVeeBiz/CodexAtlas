--[[
    VeeBiiz Physical Items — Shared Enums
]]

VPI = VPI or {}
VPI.Enums = VPI.Enums or {}

VPI.Enums.ObjectState = {
    WORLD = 'world',
    CARRIED = 'carried',
    LOCKED = 'locked',
    GHOST = 'ghost',
}

VPI.Enums.Ownership = {
    PUBLIC = 'public',
    PLAYER = 'player',
    JOB = 'job',
    ZONE = 'zone',
}

VPI.Enums.PlacementResult = {
    OK = 'ok',
    INVALID_SOCKET = 'invalid_socket',
    INVALID_ITEM = 'invalid_item',
    SOCKET_FULL = 'socket_full',
    OUT_OF_ZONE = 'out_of_zone',
    NO_PERMISSION = 'no_permission',
    TOO_FAR = 'too_far',
    LOCKED = 'locked',
    COOLDOWN = 'cooldown',
    NO_ITEM = 'no_item',
    CANCELLED = 'cancelled',
}

VPI.Enums.Interaction = {
    PICKUP = 'pickup',
    PLACE = 'place',
    MOVE = 'move',
    ROTATE = 'rotate',
    INSPECT = 'inspect',
    USE = 'use',
    POUR = 'pour',
    FILL = 'fill',
    DRINK = 'drink',
    EAT = 'eat',
    COOK = 'cook',
    WASH = 'wash',
    REPAIR = 'repair',
    MIX = 'mix',
    OPEN = 'open',
    CLOSE = 'close',
    ADD_ICE = 'add_ice',
    ADD_GARNISH = 'add_garnish',
}

VPI.Enums.GhostValidity = {
    VALID = 'valid',
    INVALID = 'invalid',
    NONE = 'none',
}

VPI.Enums.CarryMode = {
    NONE = 'none',
    FROM_INVENTORY = 'from_inventory',
    FROM_WORLD = 'from_world',
    MOVING = 'moving',
}
