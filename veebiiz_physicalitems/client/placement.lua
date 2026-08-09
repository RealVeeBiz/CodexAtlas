--[[
    Client — Socket placement + ghost preview
]]

VPI = VPI or {}
VPI.Placement = VPI.Placement or {}

local active = false
local ghost = nil
local currentSocket = nil
local currentZoneId = nil
local valid = false
local itemName = nil

local function deleteGhost()
    if ghost and DoesEntityExist(ghost) then
        VPI.Client.Utils.DeleteEntity(ghost)
    end
    ghost = nil
end

local function setGhostTint(isValid)
    if not ghost or not DoesEntityExist(ghost) then return end
    local c = isValid and VPI.Constants.GHOST_VALID_COLOR or VPI.Constants.GHOST_INVALID_COLOR
    SetEntityAlpha(ghost, Config.Placement.ghostAlpha or VPI.Constants.GHOST_ALPHA, false)
    -- Approximate validity via light alpha + marker color; entity paint is limited for props
    ResetEntityAlpha(ghost)
    SetEntityAlpha(ghost, Config.Placement.ghostAlpha or VPI.Constants.GHOST_ALPHA, false)
end

local function ensureGhost(model, coords, rot)
    if not ghost or not DoesEntityExist(ghost) then
        local ok, hash = VPI.Client.Utils.LoadModel(model)
        if not ok then return end
        ghost = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
        SetEntityCollision(ghost, false, false)
        FreezeEntityPosition(ghost, true)
        SetEntityAlpha(ghost, Config.Placement.ghostAlpha or VPI.Constants.GHOST_ALPHA, false)
        SetModelAsNoLongerNeeded(hash)
    end
    SetEntityCoordsNoOffset(ghost, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(ghost, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, 2, true)
end

---@param session table
function VPI.Placement.Enter(session)
    active = true
    itemName = session.item
    currentSocket = nil
    currentZoneId = nil
    valid = false
end

function VPI.Placement.Exit()
    active = false
    itemName = nil
    currentSocket = nil
    currentZoneId = nil
    valid = false
    deleteGhost()
    VPI.Client.Utils.SendNui('placement', { active = false })
end

function VPI.Placement.IsActive()
    return active
end

function VPI.Placement.Confirm()
    if not active or not currentSocket or not currentZoneId then
        VPI.Client.Utils.Notify({ description = 'No valid socket nearby.', type = 'error' })
        return
    end
    if not valid then
        VPI.Client.Utils.Notify({ description = 'Invalid placement', type = 'error' })
        return
    end

    TriggerServerEvent(VPI.Events.PLACE_OBJECT, {
        zoneId = currentZoneId,
        socketId = currentSocket.id,
    })
end

function VPI.Placement.Cancel()
    VPI.Pickup.Cancel()
end

CreateThread(function()
    while true do
        if active and itemName then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local socket, zone, zoneId = VPI.Zones.FindCompatibleSocket(itemName, coords, Config.Placement.socketSearchRadius)

            if socket and zoneId then
                currentSocket = socket
                currentZoneId = zoneId
                valid = VPI.Zones.SocketValidForItem(itemName, socket)

                -- Occupancy check (client hint only)
                if valid then
                    local session = VPI.Carry.GetSession()
                    for id, obj in pairs(VPI.ObjectStore.GetAll()) do
                        if obj.zone_id == zoneId and obj.slot_id == socket.id then
                            if not (session and session.mode == VPI.Enums.CarryMode.MOVING and session.objectId == id) then
                                valid = false
                            end
                        end
                    end
                end

                local session = VPI.Carry.GetSession()
                ensureGhost(session and session.model or itemName, socket.coords, socket.rotation or vec3(0, 0, 0))
                setGhostTint(valid)

                -- Validity marker under ghost
                local c = valid and VPI.Constants.GHOST_VALID_COLOR or VPI.Constants.GHOST_INVALID_COLOR
                DrawMarker(
                    25,
                    socket.coords.x, socket.coords.y, socket.coords.z - 0.12,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.25, 0.25, 0.25,
                    c.r, c.g, c.b, 160,
                    false, false, 2, false, nil, nil, false
                )

                VPI.Client.Utils.SendNui('placement', {
                    active = true,
                    valid = valid,
                    zoneId = zoneId,
                    zoneLabel = zone and zone.label,
                    socketId = socket.id,
                    socketLabel = socket.label,
                    item = itemName,
                })
            else
                currentSocket = nil
                currentZoneId = nil
                valid = false
                deleteGhost()
                VPI.Client.Utils.SendNui('placement', {
                    active = true,
                    valid = false,
                    item = itemName,
                })
            end

            -- Controls
            if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) then -- ENTER
                VPI.Placement.Confirm()
            end
            if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then -- BACKSPACE / ESC
                VPI.Placement.Cancel()
            end

            Wait(0)
        else
            Wait(300)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    deleteGhost()
end)
