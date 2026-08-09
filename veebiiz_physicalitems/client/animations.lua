--[[
    Client — Animations
]]

VPI = VPI or {}
VPI.Animations = VPI.Animations or {}

local current = nil

---@param anim table|nil
function VPI.Animations.Play(anim)
    if not anim or not anim.dict or not anim.clip then return end
    local ped = PlayerPedId()
    if not VPI.Client.Utils.LoadAnimDict(anim.dict) then return end
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, anim.duration or -1, anim.flag or 49, 0.0, false, false, false)
    current = anim
end

function VPI.Animations.Stop()
    local ped = PlayerPedId()
    if current then
        StopAnimTask(ped, current.dict, current.clip, 1.0)
        current = nil
    end
    ClearPedSecondaryTask(ped)
end

---@param itemName string
---@param kind string
function VPI.Animations.PlayItem(itemName, kind)
    local def = VPI.Utils.GetItemDef(itemName)
    local anim = def and def.animations and def.animations[kind]
    if not anim and kind == 'carry' then
        anim = Config.Carry.defaultAnim
    end
    VPI.Animations.Play(anim)
end

RegisterNetEvent(VPI.Events.PLAY_INTERACTION, function(payload)
    if type(payload) ~= 'table' then return end
    local item = payload.sourceItem
    local kind = payload.animation or payload.action
    if item then
        VPI.Animations.PlayItem(item, kind)
    end
    if payload.duration then
        VPI.Lib.Progress({
            duration = payload.duration,
            label = payload.action or 'Interacting...',
            useWhileDead = false,
            canCancel = false,
            disable = { move = true, car = true, combat = true },
        })
        VPI.Animations.Stop()
        if VPI.Carry and VPI.Carry.IsCarrying() then
            VPI.Animations.PlayItem(VPI.Carry.GetItem(), 'carry')
        end
    end
end)
