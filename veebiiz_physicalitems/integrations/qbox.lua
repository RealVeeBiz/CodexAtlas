--[[
    Integration — Qbox / QBX
]]

VPI = VPI or {}
VPI.Framework = VPI.Framework or {}

local isServer = IsDuplicityVersion()

local function qbxReady()
    return GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started'
end

---@param source number|nil
---@return table|nil
function VPI.Framework.GetPlayer(source)
    if not isServer then
        if GetResourceState('qbx_core') == 'started' then
            return exports.qbx_core:GetPlayerData()
        end
        return nil
    end

    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetPlayer(source)
    end

    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayer(source)
    end

    return nil
end

---@param source number|nil
---@return string|nil
function VPI.Framework.GetIdentifier(source)
    local player = VPI.Framework.GetPlayer(source)
    if not player then
        if isServer then
            return GetPlayerIdentifierByType(source --[[@as string]], 'license')
        end
        return nil
    end

    if player.PlayerData and player.PlayerData.citizenid then
        return player.PlayerData.citizenid
    end
    if player.citizenid then return player.citizenid end
    return nil
end

---@param source number|nil
---@return string|nil, number|nil
function VPI.Framework.GetJob(source)
    local player = VPI.Framework.GetPlayer(source)
    if not player then return nil, nil end

    local data = player.PlayerData or player
    local job = data.job
    if not job then return nil, nil end
    return job.name, job.grade and (job.grade.level or job.grade) or 0
end

---@param source number|nil
---@param jobName string
---@param minGrade number|nil
---@return boolean
function VPI.Framework.HasJob(source, jobName, minGrade)
    local name, grade = VPI.Framework.GetJob(source)
    if not name or name ~= jobName then return false end
    if minGrade and (grade or 0) < minGrade then return false end
    return true
end

---@param source number|nil
---@return boolean
function VPI.Framework.IsAdmin(source)
    if isServer then
        if IsPlayerAceAllowed(source --[[@as string]], Config.Editor.acePermission) then
            return true
        end
        if IsPlayerAceAllowed(source --[[@as string]], 'command') then
            return true
        end
    end

    local name = VPI.Framework.GetJob(source)
    if name and Config.Editor.jobs then
        return VPI.Utils.Contains(Config.Editor.jobs, name)
    end
    return false
end

function VPI.Framework.IsReady()
    return qbxReady()
end
