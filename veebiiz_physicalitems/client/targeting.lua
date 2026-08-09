--[[
    Client — Targeting (custom NUI + optional ox_target)
]]

VPI = VPI or {}
VPI.Targeting = VPI.Targeting or {}

local lastUiId = nil

---@param objectId number
---@param entity number
local function attachOxTarget(objectId, entity)
    local object = VPI.ObjectStore.Get(objectId)
    if not object then return end
    local interactions = VPI.Interaction.BuildForObject(object)
    local options = VPI.Target.BuildOptions(objectId, interactions)
    VPI.Target.RemoveEntity(entity)
    if #options > 0 then
        VPI.Target.AddEntity(entity, options)
    end
end

AddEventHandler('vpi:client:attachTarget', function(objectId, entity)
    if Config.Target == 'ox_target' or Config.Target == 'both' then
        attachOxTarget(objectId, entity)
    end
end)

AddEventHandler('vpi:client:targetSelect', function(objectId, action)
    VPI.Interaction.Run(objectId, action)
end)

--- Custom look-at targeting + world indicator + keybinds
CreateThread(function()
    local tick = Config.Interaction.tickMs or VPI.Constants.TARGET_TICK_MS
    while true do
        if VPI.Placement.IsActive() then
            VPI.Interaction.Hide()
            lastUiId = nil
            Wait(200)
        else
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local closestId, closestDist, closestObj = nil, Config.Interaction.distance + 0.001, nil

            -- Prefer raycast entity hit
            local ray = VPI.Raycast.Cached(tick)
            if ray.hit and ray.entity and ray.entity ~= 0 then
                local id = VPI.ObjectStore.GetIdFromEntity(ray.entity)
                if id then
                    local obj = VPI.ObjectStore.Get(id)
                    if obj then
                        local dist = VPI.Utils.Distance(pcoords, obj)
                        if dist <= Config.Interaction.distance then
                            closestId, closestDist, closestObj = id, dist, obj
                        end
                    end
                end
            end

            -- Fallback: nearest streamed object in front
            if not closestId then
                for id, obj in pairs(VPI.ObjectStore.GetAll()) do
                    local entity = VPI.ObjectStore.GetEntity(id)
                    if entity and DoesEntityExist(entity) then
                        local dist = VPI.Utils.Distance(pcoords, obj)
                        if dist < closestDist then
                            closestId, closestDist, closestObj = id, dist, obj
                        end
                    end
                end
            end

            if closestId and closestObj then
                local interactions = VPI.Interaction.BuildForObject(closestObj)
                if #interactions > 0 then
                    if lastUiId ~= closestId then
                        VPI.Interaction.Show(closestObj, interactions)
                        lastUiId = closestId
                    end

                    -- World-space indicator
                    if Config.Interaction.useWorldIndicator then
                        local entity = VPI.ObjectStore.GetEntity(closestId)
                        if entity then
                            local coords = GetEntityCoords(entity)
                            local def = VPI.Utils.GetItemDef(closestObj.item)
                            local label = def and def.label or closestObj.item
                            VPI.Client.Utils.DrawText3D(
                                vector3(coords.x, coords.y, coords.z + 0.25),
                                ('~w~%s'):format(label)
                            )
                        end
                    end

                    -- Hotkeys
                    for i = 1, #interactions do
                        local inter = interactions[i]
                        if inter.key == 'E' and IsControlJustPressed(0, 38) then
                            VPI.Interaction.Run(closestId, inter.name)
                        elseif inter.key == 'G' and IsControlJustPressed(0, 47) then
                            VPI.Interaction.Run(closestId, inter.name)
                        elseif inter.key == 'H' and IsControlJustPressed(0, 74) then
                            VPI.Interaction.Run(closestId, inter.name)
                        elseif inter.key == 'X' and IsControlJustPressed(0, 73) then
                            VPI.Interaction.Run(closestId, inter.name)
                        end
                    end

                    if Config.Debug then
                        VPI.Client.Utils.SendNui('debug', {
                            zone = select(1, VPI.Zones.GetCurrent()),
                            socket = closestObj.slot_id,
                            object = closestId,
                            entity = VPI.ObjectStore.GetEntity(closestId),
                            item = closestObj.item,
                            distance = ('%.2f'):format(closestDist),
                            state = closestObj.state,
                            ownership = closestObj.ownership,
                        })
                    end

                    Wait(0)
                else
                    if lastUiId then
                        VPI.Interaction.Hide()
                        lastUiId = nil
                    end
                    Wait(tick)
                end
            else
                if lastUiId then
                    VPI.Interaction.Hide()
                    lastUiId = nil
                end
                Wait(tick)
            end
        end
    end
end)
