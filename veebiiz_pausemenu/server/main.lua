local Framework = nil
local FrameworkName = 'standalone'

local function detectFramework()
    if Config.ForceFramework then
        FrameworkName = Config.ForceFramework
        return
    end

    if GetResourceState('qbx_core') == 'started' then
        FrameworkName = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        FrameworkName = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        FrameworkName = 'esx'
    else
        FrameworkName = 'standalone'
    end
end

local function initFramework()
    detectFramework()

    if FrameworkName == 'qbox' then
        Framework = exports.qbx_core
    elseif FrameworkName == 'qb' then
        Framework = exports['qb-core']:GetCoreObject()
    elseif FrameworkName == 'esx' then
        Framework = exports['es_extended']:getSharedObject()
    end
end

local function formatMoney(amount)
    amount = tonumber(amount) or 0
    local formatted = tostring(math.floor(amount + 0.5))
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

local function playtimeLabel(seconds)
    seconds = tonumber(seconds) or 0
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ('%dh %dm'):format(hours, mins)
    end
    return ('%dm'):format(mins)
end

local function getQBPlayer(src)
    if FrameworkName == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    end
    if Framework and Framework.Functions then
        return Framework.Functions.GetPlayer(src)
    end
    return nil
end

local function buildPlayerPayload(src)
    local name = GetPlayerName(src) or ('Player %s'):format(src)
    local identifiers = GetPlayerIdentifiers(src) or {}
    local license = nil
    for _, id in ipairs(identifiers) do
        if id:find('license:') == 1 then
            license = id
            break
        end
    end

    local payload = {
        serverId = src,
        name = name,
        job = 'Civilian',
        jobGrade = '',
        cash = formatMoney(0),
        bank = formatMoney(0),
        gang = '',
        playtime = playtimeLabel(0),
        ping = GetPlayerPing(src) or 0,
        framework = FrameworkName,
        licenseShort = license and license:sub(-8) or '—',
        playersOnline = #GetPlayers(),
        maxClients = GetConvarInt('sv_maxclients', 48),
    }

    if FrameworkName == 'qb' or FrameworkName == 'qbox' then
        local player = getQBPlayer(src)
        if player and player.PlayerData then
            local pd = player.PlayerData
            local char = pd.charinfo or {}
            if char.firstname or char.lastname then
                payload.name = (('%s %s'):format(char.firstname or '', char.lastname or '')):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
            end
            if pd.job then
                payload.job = pd.job.label or pd.job.name or payload.job
                if pd.job.grade then
                    payload.jobGrade = pd.job.grade.name or tostring(pd.job.grade.level or '')
                end
            end
            if pd.gang and pd.gang.name and pd.gang.name ~= 'none' then
                payload.gang = pd.gang.label or pd.gang.name
            end
            if pd.money then
                payload.cash = formatMoney(pd.money.cash or pd.money['cash'] or 0)
                payload.bank = formatMoney(pd.money.bank or pd.money['bank'] or 0)
            end
            if pd.metadata and pd.metadata.playtime then
                payload.playtime = playtimeLabel(pd.metadata.playtime)
            end
        end
    elseif FrameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            payload.name = xPlayer.getName and xPlayer.getName() or payload.name
            local job = xPlayer.getJob and xPlayer.getJob() or nil
            if job then
                payload.job = job.label or job.name or payload.job
                payload.jobGrade = job.grade_label or tostring(job.grade or '')
            end
            if xPlayer.getAccount then
                local cashAcc = xPlayer.getAccount('money')
                local bankAcc = xPlayer.getAccount('bank')
                payload.cash = formatMoney(cashAcc and cashAcc.money or 0)
                payload.bank = formatMoney(bankAcc and bankAcc.money or 0)
            elseif xPlayer.getMoney then
                payload.cash = formatMoney(xPlayer.getMoney())
            end
        end
    end

    return payload
end

CreateThread(function()
    Wait(500)
    initFramework()
    print(('[veebiiz_pausemenu] Framework: %s'):format(FrameworkName))
end)

RegisterNetEvent('veebiiz_pausemenu:requestPlayerData', function()
    local src = source
    TriggerClientEvent('veebiiz_pausemenu:receivePlayerData', src, buildPlayerPayload(src))
end)

RegisterNetEvent('veebiiz_pausemenu:disconnect', function()
    local src = source
    DropPlayer(src, 'Disconnected via pause menu.')
end)
