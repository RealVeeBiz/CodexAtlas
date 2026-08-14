local menuOpen = false
local refreshing = false
local allowNativeUntil = 0

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

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    refreshing = false
    setFocus(false)
    nui('close')
end

local function openMenu()
    if menuOpen then return end
    if IsPauseMenuActive() then
        SetFrontendActive(false)
    end

    menuOpen = true
    setFocus(true)

    nui('open', {
        serverName = Config.ServerName,
        tagline = Config.ServerTagline,
        rules = Config.Rules,
        links = Config.Links,
        allowMap = Config.AllowMap,
        allowSettings = Config.AllowSettings,
        confirmDisconnect = Config.ConfirmDisconnect,
        footerHint = Config.FooterHint,
        theme = Config.Theme,
    })

    TriggerServerEvent('veebiiz_pausemenu:requestPlayerData')
end

local function toggleMenu()
    if menuOpen then
        closeMenu()
    else
        openMenu()
    end
end

RegisterNetEvent('veebiiz_pausemenu:receivePlayerData', function(payload)
    if not menuOpen then return end
    nui('playerData', payload or {})
end)

-- Keep stats fresh while the menu is open
CreateThread(function()
    while true do
        local interval = Config.RefreshInterval or 3000
        Wait(interval)
        if menuOpen and not refreshing then
            refreshing = true
            TriggerServerEvent('veebiiz_pausemenu:requestPlayerData')
            refreshing = false
        end
    end
end)

local function nativeAllowed()
    return GetGameTimer() < allowNativeUntil
end

-- Replace / suppress native pause + open custom menu on ESC / P
CreateThread(function()
    while true do
        if Config.ReplaceNativePause then
            Wait(0)

            if nativeAllowed() then
                -- Let map / settings frontend stay open briefly after menu hand-off
            else
                DisableControlAction(0, 199, true) -- P
                DisableControlAction(0, 200, true) -- ESC

                if IsPauseMenuActive() and not menuOpen then
                    SetFrontendActive(false)
                end

                if not menuOpen then
                    if IsDisabledControlJustReleased(0, 200) or IsDisabledControlJustReleased(0, 199) then
                        openMenu()
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- While NUI is open, keep the native pause from sneaking back in
CreateThread(function()
    while true do
        if menuOpen then
            Wait(0)
            SetPauseMenuActive(false)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true) -- BACK
        else
            Wait(200)
        end
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('resume', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('openMap', function(_, cb)
    closeMenu()
    if Config.AllowMap then
        allowNativeUntil = GetGameTimer() + 8000
        ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, -1)
    end
    cb({ ok = true })
end)

RegisterNUICallback('openSettings', function(_, cb)
    closeMenu()
    if Config.AllowSettings then
        allowNativeUntil = GetGameTimer() + 8000
        ActivateFrontendMenu(`FE_MENU_VERSION_LANDING_MENU`, false, -1)
    end
    cb({ ok = true })
end)

RegisterNUICallback('openLink', function(data, cb)
    local url = data and data.url
    if type(url) == 'string' and url ~= '' then
        nui('openExternal', { url = url })
    end
    cb({ ok = true })
end)

RegisterNUICallback('disconnect', function(_, cb)
    closeMenu()
    TriggerServerEvent('veebiiz_pausemenu:disconnect')
    cb({ ok = true })
end)

-- Optional command for testing without ESC
RegisterCommand('pausemenu', function()
    toggleMenu()
end, false)

exports('Open', openMenu)
exports('Close', closeMenu)
exports('Toggle', toggleMenu)
exports('IsOpen', function()
    return menuOpen
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if menuOpen then
        setFocus(false)
    end
end)
