--[[
    Client — Zone Manager
]]

VPI = VPI or {}
VPI.Zones = VPI.Zones or {}

local zones = {}
local currentZoneId = nil

function VPI.Zones.SetAll(data)
    zones = data or {}
end

function VPI.Zones.GetAll()
    return zones
end

function VPI.Zones.Get(id)
    return zones[id]
end

function VPI.Zones.GetCurrent()
    return currentZoneId and zones[currentZoneId] or nil, currentZoneId
end

---@param coords vector3
---@return string|nil, table|nil
function VPI.Zones.GetAt(coords)
    for id, zone in pairs(zones) do
        local center = zone.coords
        local radius = zone.radius or 10.0
        if center and VPI.Utils.Distance(coords, center) <= radius then
            local z = coords.z
            if (not zone.minZ or z >= zone.minZ) and (not zone.maxZ or z <= zone.maxZ) then
                return id, zone
            end
        end
    end
    return nil, nil
end

---@param itemName string
---@param fromCoords vector3|nil
---@param maxDist number|nil
---@return table|nil, table|nil, string|nil  socket, zone, zoneId
function VPI.Zones.FindCompatibleSocket(itemName, fromCoords, maxDist)
    fromCoords = fromCoords or GetEntityCoords(PlayerPedId())
    maxDist = maxDist or Config.Placement.socketSearchRadius or 4.0

    local bestValid, bestValidZone, bestValidZoneId, bestValidDist = nil, nil, nil, maxDist + 0.001
    local bestAny, bestAnyZone, bestAnyZoneId, bestAnyDist = nil, nil, nil, maxDist + 0.001

    for zoneId, zone in pairs(zones) do
        if zone.sockets then
            for i = 1, #zone.sockets do
                local socket = zone.sockets[i]
                local dist = VPI.Utils.Distance(fromCoords, socket.coords)
                if dist <= maxDist then
                    if dist < bestAnyDist then
                        bestAny, bestAnyZone, bestAnyZoneId, bestAnyDist = socket, zone, zoneId, dist
                    end
                    if VPI.Zones.SocketValidForItem(itemName, socket) and dist < bestValidDist then
                        bestValid, bestValidZone, bestValidZoneId, bestValidDist = socket, zone, zoneId, dist
                    end
                end
            end
        end
    end

    if bestValid then
        return bestValid, bestValidZone, bestValidZoneId
    end
    return bestAny, bestAnyZone, bestAnyZoneId
end

---@param itemName string
---@param socket table
---@return boolean
function VPI.Zones.SocketValidForItem(itemName, socket)
    if not socket then return false end
    if VPI.Utils.SocketAllowsItem(socket, itemName) then return true end
    local def = VPI.Utils.GetItemDef(itemName)
    if def and socket.allowedCategories and VPI.Utils.Contains(socket.allowedCategories, def.category) then
        return true
    end
    return false
end

CreateThread(function()
    local interval = Config.ZONE_TICK_MS or VPI.Constants.ZONE_TICK_MS
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local id = VPI.Zones.GetAt(coords)
        if id ~= currentZoneId then
            currentZoneId = id
            if Config.Debug and id then
                VPI.Utils.Debug('Entered zone %s', id)
            end
        end
        Wait(interval)
    end
end)

RegisterNetEvent(VPI.Events.SYNC_ZONES, function(data)
    VPI.Zones.SetAll(data)
end)
