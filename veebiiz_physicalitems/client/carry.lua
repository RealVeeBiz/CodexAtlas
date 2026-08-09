--[[
    Client — Carry System
]]

VPI = VPI or {}
VPI.Carry = VPI.Carry or {}

local session = nil
local carryEntity = nil

function VPI.Carry.IsCarrying()
    return session ~= nil
end

function VPI.Carry.GetSession()
    return session
end

function VPI.Carry.GetItem()
    return session and session.item or nil
end

function VPI.Carry.GetEntity()
    return carryEntity
end

local function cleanupEntity()
    if carryEntity then
        VPI.Attachments.Detach(carryEntity)
        VPI.Client.Utils.DeleteEntity(carryEntity)
        carryEntity = nil
    end
end

---@param data table
function VPI.Carry.Start(data)
    session = data
    cleanupEntity()

    local ok, hash = VPI.Client.Utils.LoadModel(data.model)
    if not ok then
        VPI.Client.Utils.Notify({ description = 'Failed to load prop.', type = 'error' })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    carryEntity = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityCollision(carryEntity, false, false)
    VPI.Attachments.AttachToHand(carryEntity, data.item)
    SetModelAsNoLongerNeeded(hash)

    VPI.Animations.PlayItem(data.item, 'carry')
    VPI.Placement.Enter(data)
    VPI.Client.Utils.SendNui('carry', {
        active = true,
        item = data.item,
        label = data.label,
        state = data.state,
        mode = data.mode,
    })
end

function VPI.Carry.Stop()
    VPI.Placement.Exit()
    VPI.Animations.Stop()
    cleanupEntity()
    session = nil
    VPI.Client.Utils.SendNui('carry', { active = false })
    VPI.Client.Utils.SendNui('hidePrompt', {})
end

RegisterNetEvent(VPI.Events.CARRY_START, function(data)
    VPI.Carry.Start(data)
end)

RegisterNetEvent(VPI.Events.CARRY_STOP, function()
    VPI.Carry.Stop()
end)

-- Block incompatible actions while carrying
CreateThread(function()
    while true do
        if session then
            local ped = PlayerPedId()
            if Config.Carry.blockWeapon then
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 37, true)
            end
            if Config.Carry.blockCombat then
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
            end
            if Config.Carry.blockVehicle and IsPedInAnyVehicle(ped, false) then
                VPI.Client.Utils.Notify({ description = 'Cannot carry in a vehicle.', type = 'error' })
                TriggerServerEvent(VPI.Events.CANCEL_CARRY)
                Wait(500)
            end
            -- Keep carry anim alive
            if not IsEntityPlayingAnim(ped, Config.Carry.defaultAnim.dict, Config.Carry.defaultAnim.clip, 3) then
                local def = VPI.Utils.GetItemDef(session.item)
                local anim = def and def.animations and def.animations.carry or Config.Carry.defaultAnim
                if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
                    VPI.Animations.Play(anim)
                end
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupEntity()
end)
