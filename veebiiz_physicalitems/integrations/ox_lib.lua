--[[
    Integration — ox_lib
]]

VPI = VPI or {}
VPI.Lib = VPI.Lib or {}

local isServer = IsDuplicityVersion()

function VPI.Lib.Notify(sourceOrData, data)
    if isServer then
        TriggerClientEvent(VPI.Events.NOTIFY, sourceOrData, data)
        return
    end

    local payload = sourceOrData
    if lib and lib.notify then
        lib.notify({
            title = payload.title or 'Physical Items',
            description = payload.description or payload.message or '',
            type = payload.type or 'inform',
            position = Config.Notify.position,
            duration = payload.duration or Config.Notify.duration,
        })
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(payload.description or payload.message or '')
    EndTextCommandThefeedPostTicker(false, true)
end

function VPI.Lib.Progress(data)
    if isServer then return true end
    if lib and lib.progressBar then
        return lib.progressBar(data)
    end
    Wait(data.duration or 1000)
    return true
end

function VPI.Lib.Callback(name, cb)
    if isServer then
        lib.callback.register(name, cb)
    end
end

function VPI.Lib.Await(name, ...)
    if isServer then return nil end
    return lib.callback.await(name, false, ...)
end
