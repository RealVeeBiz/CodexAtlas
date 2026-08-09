--[[
    VeeBiiz Physical Items — Shared Constants
]]

VPI = VPI or {}
VPI.Constants = {
    RESOURCE = 'veebiiz_physicalitems',
    STREAM_DISTANCE = 100.0,
    INTERACT_DISTANCE = 2.0,
    PLACE_DISTANCE = 3.5,
    RAYCAST_DISTANCE = 8.0,
    GHOST_ALPHA = 140,
    GHOST_VALID_COLOR = { r = 80, g = 200, b = 120 },
    GHOST_INVALID_COLOR = { r = 220, g = 60, b = 60 },
    DEFAULT_BONE = 57005, -- SKEL_R_Hand
    COOLDOWN_MS = 750,
    LOCK_TIMEOUT_MS = 15000,
    NUI_FADE_MS = 180,
    STREAM_TICK_MS = 1000,
    ZONE_TICK_MS = 500,
    TARGET_TICK_MS = 150,
    MAX_OBJECTS_SOFT = 2000,
}

VPI.Events = {
    -- Client → Server
    REQUEST_SYNC = 'vpi:server:requestSync',
    TAKE_OBJECT = 'vpi:server:takeObject',
    PLACE_OBJECT = 'vpi:server:placeObject',
    MOVE_OBJECT = 'vpi:server:moveObject',
    START_MOVE = 'vpi:server:startMove',
    CANCEL_CARRY = 'vpi:server:cancelCarry',
    INTERACT = 'vpi:server:interact',
    CREATE_FROM_ITEM = 'vpi:server:createFromItem',
    EDITOR_SAVE = 'vpi:server:editorSave',
    EDITOR_DELETE_ZONE = 'vpi:server:editorDeleteZone',

    -- Server → Client
    SYNC_OBJECTS = 'vpi:client:syncObjects',
    OBJECT_CREATED = 'vpi:client:objectCreated',
    OBJECT_UPDATED = 'vpi:client:objectUpdated',
    OBJECT_REMOVED = 'vpi:client:objectRemoved',
    OBJECT_STATE = 'vpi:client:objectState',
    CARRY_START = 'vpi:client:carryStart',
    CARRY_STOP = 'vpi:client:carryStop',
    NOTIFY = 'vpi:client:notify',
    SYNC_ZONES = 'vpi:client:syncZones',
    PLAY_INTERACTION = 'vpi:client:playInteraction',
}
