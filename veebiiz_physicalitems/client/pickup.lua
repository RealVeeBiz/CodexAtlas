--[[
    Client — Pickup / Take / Move entry points
]]

VPI = VPI or {}
VPI.Pickup = VPI.Pickup or {}

function VPI.Pickup.Take(objectId)
    if VPI.Carry.IsCarrying() then
        VPI.Client.Utils.Notify({ description = 'Already carrying an object.', type = 'error' })
        return
    end
    TriggerServerEvent(VPI.Events.TAKE_OBJECT, objectId)
end

function VPI.Pickup.Move(objectId)
    if VPI.Carry.IsCarrying() then
        VPI.Client.Utils.Notify({ description = 'Already carrying an object.', type = 'error' })
        return
    end
    TriggerServerEvent(VPI.Events.START_MOVE, objectId)
end

function VPI.Pickup.Cancel()
    if not VPI.Carry.IsCarrying() then return end
    TriggerServerEvent(VPI.Events.CANCEL_CARRY)
end
