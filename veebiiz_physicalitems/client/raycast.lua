--[[
    Client — Optimized Raycast
]]

VPI = VPI or {}
VPI.Raycast = VPI.Raycast or {}

local lastResult = nil
local lastAt = 0

---@param distance number|nil
---@return boolean, vector3, number, vector3
function VPI.Raycast.Camera(distance)
    distance = distance or Config.Interaction.raycastDistance or 8.0
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local rx = math.rad(camRot.x)
    local rz = math.rad(camRot.z)
    local dir = vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
        math.cos(rz) * math.abs(math.cos(rx)),
        math.sin(rx)
    )
    local dest = camCoord + (dir * distance)

    local handle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        dest.x, dest.y, dest.z,
        -1,
        PlayerPedId(),
        0
    )
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)
    return hit == 1, endCoords, entityHit, surfaceNormal
end

--- Throttled raycast for targeting loops
---@param minInterval number|nil
---@return table
function VPI.Raycast.Cached(minInterval)
    local now = GetGameTimer()
    if lastResult and (now - lastAt) < (minInterval or 50) then
        return lastResult
    end
    local hit, coords, entity, normal = VPI.Raycast.Camera()
    lastResult = {
        hit = hit,
        coords = coords,
        entity = entity,
        normal = normal,
    }
    lastAt = now
    return lastResult
end
