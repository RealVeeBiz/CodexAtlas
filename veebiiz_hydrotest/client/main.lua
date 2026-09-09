local uiOpen = false
local mode = nil -- 'test' | 'admin' | 'welcome'

local function nui(action, data)
    SendNUIMessage({
        action = action,
        data = data or {},
    })
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeUi()
    if not uiOpen then return end
    uiOpen = false
    mode = nil
    setFocus(false)
    nui('close')
    TriggerServerEvent('veebiiz_hydrotest:cancelSession')
end

local function openWelcome()
    if uiOpen then return end
    uiOpen = true
    mode = 'welcome'
    setFocus(true)
    nui('openWelcome', {
        title = Config.Title,
        subtitle = Config.Subtitle,
        questionsPerTest = Config.QuestionsPerTest,
        passPercent = Config.PassPercent,
        theme = Config.Theme,
        footerHint = Config.FooterHint,
    })
end

local function notify(msg, nType)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg or ''))
    EndTextCommandThefeedPostTicker(false, false)

    -- Prefer ox_lib if present
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = Config.Title,
            description = tostring(msg or ''),
            type = nType == 'error' and 'error' or (nType == 'success' and 'success' or 'inform'),
        })
    end
end

RegisterNetEvent('veebiiz_hydrotest:notify', function(msg, nType)
    notify(msg, nType)
end)

RegisterNetEvent('veebiiz_hydrotest:openTest', function(payload)
    uiOpen = true
    mode = 'test'
    setFocus(true)
    nui('openTest', payload)
end)

RegisterNetEvent('veebiiz_hydrotest:showResult', function(result, message)
    nui('showResult', {
        result = result,
        message = message,
    })
    if message and message ~= '' then
        notify(message, result and result.passed and 'success' or 'error')
    end
end)

RegisterNetEvent('veebiiz_hydrotest:openAdmin', function(payload)
    uiOpen = true
    mode = 'admin'
    setFocus(true)
    nui('openAdmin', payload)
end)

RegisterNetEvent('veebiiz_hydrotest:adminSaved', function(questions)
    nui('adminSaved', { questions = questions })
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('startTest', function(data, cb)
    local name = data and data.name or ''
    TriggerServerEvent('veebiiz_hydrotest:requestStart', name)
    cb({ ok = true })
end)

RegisterNUICallback('submitTest', function(data, cb)
    TriggerServerEvent('veebiiz_hydrotest:submit', data and data.answers or {})
    cb({ ok = true })
end)

RegisterNUICallback('adminUpsert', function(data, cb)
    TriggerServerEvent('veebiiz_hydrotest:adminUpsert', data and data.question or data)
    cb({ ok = true })
end)

RegisterNUICallback('adminDelete', function(data, cb)
    TriggerServerEvent('veebiiz_hydrotest:adminDelete', data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('adminSaveAll', function(data, cb)
    TriggerServerEvent('veebiiz_hydrotest:adminSave', data and data.questions or {})
    cb({ ok = true })
end)

RegisterCommand(Config.Commands.test, function()
    if uiOpen then
        closeUi()
        return
    end
    openWelcome()
end, false)

RegisterCommand(Config.Commands.admin, function()
    if uiOpen and mode == 'admin' then
        closeUi()
        return
    end
    TriggerServerEvent('veebiiz_hydrotest:requestAdmin')
end, false)

exports('Open', openWelcome)
exports('OpenAdmin', function()
    TriggerServerEvent('veebiiz_hydrotest:requestAdmin')
end)
exports('Close', closeUi)
exports('IsOpen', function()
    return uiOpen
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if uiOpen then
        setFocus(false)
    end
end)
