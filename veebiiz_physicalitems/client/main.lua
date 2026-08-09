--[[
    Client — Bootstrap, NUI callbacks, editor, exports
]]

VPI = VPI or {}

local editorOpen = false

CreateThread(function()
    Wait(500)
    -- Seed zones from shared config immediately
    VPI.Zones.SetAll(Config.Zones)
    TriggerServerEvent(VPI.Events.REQUEST_SYNC)
end)

RegisterNetEvent(VPI.Events.NOTIFY, function(data)
    VPI.Lib.Notify(data)
end)

-- NUI callbacks
RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    editorOpen = false
    cb({ ok = true })
end)

RegisterNUICallback('selectInteraction', function(data, cb)
    if data and data.objectId and data.action then
        VPI.Interaction.Run(tonumber(data.objectId), data.action)
    end
    cb({ ok = true })
end)

RegisterNUICallback('confirmPlace', function(_, cb)
    VPI.Placement.Confirm()
    cb({ ok = true })
end)

RegisterNUICallback('cancelPlace', function(_, cb)
    VPI.Placement.Cancel()
    cb({ ok = true })
end)

RegisterNUICallback('editorSave', function(data, cb)
    SetNuiFocus(false, false)
    editorOpen = false
    if data and data.zone then
        TriggerServerEvent(VPI.Events.EDITOR_SAVE, { zone = data.zone })
    end
    cb({ ok = true })
end)

RegisterNUICallback('editorCancel', function(_, cb)
    SetNuiFocus(false, false)
    editorOpen = false
    cb({ ok = true })
end)

RegisterNUICallback('editorGetCoords', function(_, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local rot = GetEntityRotation(PlayerPedId(), 2)
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        rot_x = rot.x,
        rot_y = rot.y,
        rot_z = rot.z,
    })
end)

local function openEditor()
    local zones = VPI.Zones.GetAll()
    local coords = GetEntityCoords(PlayerPedId())
    SetNuiFocus(true, true)
    editorOpen = true
    VPI.Client.Utils.SendNui('openEditor', {
        zones = zones,
        items = Config.Items,
        interactions = Config.Interactions,
        playerCoords = { x = coords.x, y = coords.y, z = coords.z },
    })
end

RegisterCommand(Config.Editor.command or 'pieditor', function()
    if not Config.Editor.enabled then return end
    local allowed = lib.callback.await('vpi:canEdit', false)
    if not allowed then
        VPI.Client.Utils.Notify({ description = 'No permission to use the zone editor.', type = 'error' })
        return
    end
    openEditor()
end, false)

-- Register canEdit callback on server side — added below via ensure
CreateThread(function()
    -- client only waits for command
end)

-- Debug draw
CreateThread(function()
    while true do
        if Config.Debug then
            local zone, zoneId = VPI.Zones.GetCurrent()
            local coords = GetEntityCoords(PlayerPedId())
            if zone then
                DrawMarker(
                    1,
                    zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    (zone.radius or 5.0) * 2.0, (zone.radius or 5.0) * 2.0, 1.0,
                    60, 140, 255, 40,
                    false, false, 2, false, nil, nil, false
                )
                if zone.sockets then
                    for i = 1, #zone.sockets do
                        local s = zone.sockets[i]
                        DrawMarker(
                            28,
                            s.coords.x, s.coords.y, s.coords.z,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.12, 0.12, 0.12,
                            255, 200, 40, 180,
                            false, false, 2, false, nil, nil, false
                        )
                        VPI.Client.Utils.DrawText3D(s.coords, s.id)
                    end
                end
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Client exports
exports('RegisterItem', function(name, def)
    Config.Items[name] = def
    return true
end)

exports('RegisterInteraction', function(name, def)
    return VPI.Interaction.Register(name, def)
end)

exports('RegisterZone', function(zoneId, def)
    local zones = VPI.Zones.GetAll()
    def.id = zoneId
    zones[zoneId] = def
    VPI.Zones.SetAll(zones)
    return true
end)

exports('RegisterSocket', function(zoneId, socket)
    local zone = VPI.Zones.Get(zoneId)
    if not zone then return false end
    zone.sockets = zone.sockets or {}
    zone.sockets[#zone.sockets + 1] = socket
    return true
end)

exports('GetObject', function(id)
    return VPI.ObjectStore.Get(id)
end)

exports('GetObjectsNear', function(coords, radius)
    local list = {}
    for id, obj in pairs(VPI.ObjectStore.GetAll()) do
        if VPI.Utils.Distance(coords, obj) <= (radius or 10.0) then
            list[#list + 1] = obj
        end
    end
    return list
end)

exports('IsCarrying', function()
    return VPI.Carry.IsCarrying()
end)

exports('GetCarrySession', function()
    return VPI.Carry.GetSession()
end)

print('[veebiiz_physicalitems] Client main loaded.')
