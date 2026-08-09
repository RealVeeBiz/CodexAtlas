--[[
    Client — Utilities
]]

VPI = VPI or {}
VPI.Client = VPI.Client or {}
VPI.Client.Utils = VPI.Client.Utils or {}

---@param model string|number
---@param timeout number|nil
---@return boolean, number
function VPI.Client.Utils.LoadModel(model, timeout)
    local hash = VPI.Utils.ModelHash(Config.ResolvePropModel(model))
    if not IsModelValid(hash) and not IsModelInCdimage(hash) then
        hash = VPI.Utils.ModelHash(Config.Props.fallback)
    end

    if HasModelLoaded(hash) then return true, hash end

    RequestModel(hash)
    local deadline = GetGameTimer() + (timeout or Config.Props.loadTimeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then
            return false, hash
        end
        Wait(10)
    end
    return true, hash
end

---@param dict string
---@param timeout number|nil
---@return boolean
function VPI.Client.Utils.LoadAnimDict(dict, timeout)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + (timeout or 5000)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then return false end
        Wait(10)
    end
    return true
end

---@param entity number
function VPI.Client.Utils.DeleteEntity(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---@param coords vector3|table
---@param text string
function VPI.Client.Utils.DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function VPI.Client.Utils.Notify(data)
    VPI.Lib.Notify(data)
end

---@param action string
---@param data table
function VPI.Client.Utils.SendNui(action, data)
    SendNUIMessage({
        action = action,
        data = data or {},
    })
end
