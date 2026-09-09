local RESOURCE = GetCurrentResourceName()
local QUESTIONS_FILE = 'data/questions.json'

local Framework = nil
local FrameworkName = 'standalone'

local function detectFramework()
    if GetResourceState('qbx_core') == 'started' then
        FrameworkName = 'qbox'
        Framework = exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        FrameworkName = 'qb'
        Framework = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        FrameworkName = 'esx'
        Framework = exports['es_extended']:getSharedObject()
    else
        FrameworkName = 'standalone'
    end
end

local function loadQuestions()
    local raw = LoadResourceFile(RESOURCE, QUESTIONS_FILE)
    if not raw or raw == '' then
        return {}
    end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        print(('[veebiiz_hydrotest] Failed to parse %s'):format(QUESTIONS_FILE))
        return {}
    end
    return data
end

local function saveQuestions(list)
    local encoded = json.encode(list)
    if not encoded then
        return false
    end
    return SaveResourceFile(RESOURCE, QUESTIONS_FILE, encoded, #encoded)
end

local Questions = {}

local function refreshCache()
    Questions = loadQuestions()
end

local function clone(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = clone(v)
    end
    return out
end

local function shuffle(list)
    local t = clone(list)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function activeQuestions()
    local out = {}
    for _, q in ipairs(Questions) do
        if q.active ~= false then
            out[#out + 1] = q
        end
    end
    return out
end

local function isAceAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce) == true
        or IsPlayerAceAllowed(src, 'command') == true
end

local function isGroupAdmin(src)
    local groups = Config.AdminGroups or {}
    if #groups == 0 then return false end

    if FrameworkName == 'qbox' or FrameworkName == 'qb' then
        local player
        if FrameworkName == 'qbox' then
            player = exports.qbx_core:GetPlayer(src)
        elseif Framework and Framework.Functions then
            player = Framework.Functions.GetPlayer(src)
        end
        local group = player and player.PlayerData and player.PlayerData.group
        if group then
            for _, g in ipairs(groups) do
                if group == g then return true end
            end
        end
    elseif FrameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer and xPlayer.getGroup then
            local group = xPlayer.getGroup()
            for _, g in ipairs(groups) do
                if group == g then return true end
            end
        end
    end
    return false
end

local function canAdmin(src)
    return isAceAdmin(src) or isGroupAdmin(src)
end

local function publicQuestion(q, shuffleAnswers)
    local answers = clone(q.answers or {})
    local correct = tonumber(q.correct) or 0
    local order = {}
    for i = 1, #answers do
        order[i] = i - 1
    end

    if shuffleAnswers then
        local paired = {}
        for i, text in ipairs(answers) do
            paired[i] = { text = text, original = i - 1 }
        end
        paired = shuffle(paired)
        answers = {}
        order = {}
        local newCorrect = 0
        for i, item in ipairs(paired) do
            answers[i] = item.text
            order[i] = item.original
            if item.original == correct then
                newCorrect = i - 1
            end
        end
        correct = newCorrect
    end

    return {
        id = q.id,
        category = q.category or '',
        question = q.question,
        answers = answers,
        -- correct index is kept server-side only for grading; still send mapped index
        -- via session store rather than to client until submit... actually we need
        -- to grade on server. Store correct in session.
        _correct = correct,
    }
end

-- Active test sessions: [src] = { name, questions = {id, correct}, started }
local Sessions = {}

local function buildTestFor(src, candidateName)
    local pool = activeQuestions()
    if #pool == 0 then
        return nil, 'Aucune question active.'
    end

    local count = math.min(Config.QuestionsPerTest or 8, #pool)
    local picked = shuffle(pool)
    local selected = {}
    for i = 1, count do
        selected[i] = picked[i]
    end

    local clientQuestions = {}
    local answerKey = {}

    for i, q in ipairs(selected) do
        local packed = publicQuestion(q, Config.ShuffleAnswers ~= false)
        answerKey[q.id] = packed._correct
        clientQuestions[i] = {
            id = packed.id,
            category = packed.category,
            question = packed.question,
            answers = packed.answers,
        }
    end

    Sessions[src] = {
        name = candidateName,
        key = answerKey,
        total = #clientQuestions,
        started = os.time(),
    }

    return {
        title = Config.Title,
        subtitle = Config.Subtitle,
        candidateName = candidateName,
        questions = clientQuestions,
        passPercent = Config.PassPercent or 70,
        theme = Config.Theme,
        footerHint = Config.FooterHint,
    }
end

local function grade(src, answers)
    local session = Sessions[src]
    if not session then
        return nil, 'Aucune session active.'
    end

    local correct = 0
    local detail = {}
    answers = answers or {}

    for id, expected in pairs(session.key) do
        local given = answers[id]
        local ok = tonumber(given) == tonumber(expected)
        if ok then correct = correct + 1 end
        detail[#detail + 1] = { id = id, correct = ok }
    end

    local total = session.total
    local percent = total > 0 and math.floor((correct / total) * 100 + 0.5) or 0
    local passed = percent >= (Config.PassPercent or 70)

    local result = {
        name = session.name,
        correct = correct,
        total = total,
        percent = percent,
        passed = passed,
        detail = detail,
        passPercent = Config.PassPercent or 70,
    }

    Sessions[src] = nil

    if passed and Config.OnPass and Config.OnPass.enabled then
        applyPassReward(src)
    end

    return result
end

function applyPassReward(src)
    local key = Config.OnPass.metadataKey
    local value = Config.OnPass.metadataValue
    if not key then return end

    if FrameworkName == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData(key, value)
        end
    elseif FrameworkName == 'qb' and Framework then
        local player = Framework.Functions.GetPlayer(src)
        if player and player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData(key, value)
        end
    elseif FrameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer and xPlayer.setMeta then
            xPlayer.setMeta(key, value)
        end
    end
end

local function newId()
    return ('q%s'):format(tostring(os.time()) .. tostring(math.random(100, 999)))
end

local function sanitizeQuestion(input, existingId)
    if type(input) ~= 'table' then return nil, 'Données invalides.' end
    local question = tostring(input.question or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if question == '' then return nil, 'La question est requise.' end

    local answers = input.answers
    if type(answers) ~= 'table' or #answers < 2 then
        return nil, 'Au moins 2 réponses sont requises.'
    end

    local cleanAnswers = {}
    for i, a in ipairs(answers) do
        local text = tostring(a or ''):gsub('^%s+', ''):gsub('%s+$', '')
        if text == '' then
            return nil, ('Réponse #%d vide.'):format(i)
        end
        cleanAnswers[#cleanAnswers + 1] = text
    end

    local correct = tonumber(input.correct)
    if not correct or correct < 0 or correct >= #cleanAnswers then
        return nil, 'Index de bonne réponse invalide.'
    end

    local id = existingId
    if not id or id == '' then
        local incoming = tostring(input.id or '')
        id = incoming ~= '' and incoming or newId()
    end

    return {
        id = id,
        category = tostring(input.category or 'Général'),
        question = question,
        answers = cleanAnswers,
        correct = correct,
        active = input.active ~= false,
    }
end

CreateThread(function()
    Wait(200)
    math.randomseed(GetGameTimer() + os.time())
    detectFramework()
    refreshCache()
    print(('[veebiiz_hydrotest] Loaded %d questions · framework=%s'):format(#Questions, FrameworkName))
end)

RegisterNetEvent('veebiiz_hydrotest:requestStart', function(candidateName)
    local src = source
    candidateName = tostring(candidateName or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if candidateName == '' or #candidateName < 2 then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Entrez votre nom pour commencer.', 'error')
        return
    end

    local payload, err = buildTestFor(src, candidateName)
    if not payload then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, err or 'Impossible de démarrer.', 'error')
        return
    end

    TriggerClientEvent('veebiiz_hydrotest:openTest', src, payload)
end)

RegisterNetEvent('veebiiz_hydrotest:submit', function(answers)
    local src = source
    local result, err = grade(src, answers)
    if not result then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, err or 'Erreur de correction.', 'error')
        return
    end

    local msg = result.passed
        and (Config.OnPass and Config.OnPass.notify)
        or (Config.OnFail and Config.OnFail.notify)

    TriggerClientEvent('veebiiz_hydrotest:showResult', src, result, msg)
end)

RegisterNetEvent('veebiiz_hydrotest:cancelSession', function()
    Sessions[source] = nil
end)

RegisterNetEvent('veebiiz_hydrotest:requestAdmin', function()
    local src = source
    if not canAdmin(src) then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Accès admin refusé.', 'error')
        return
    end

    TriggerClientEvent('veebiiz_hydrotest:openAdmin', src, {
        title = Config.Title,
        subtitle = 'Administration des questions',
        questions = Questions,
        theme = Config.Theme,
        footerHint = Config.FooterHint,
        settings = {
            questionsPerTest = Config.QuestionsPerTest,
            passPercent = Config.PassPercent,
        },
    })
end)

RegisterNetEvent('veebiiz_hydrotest:adminSave', function(list)
    local src = source
    if not canAdmin(src) then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Accès admin refusé.', 'error')
        return
    end

    if type(list) ~= 'table' then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Payload invalide.', 'error')
        return
    end

    local cleaned = {}
    for _, item in ipairs(list) do
        local q, err = sanitizeQuestion(item, item and item.id)
        if not q then
            TriggerClientEvent('veebiiz_hydrotest:notify', src, err or 'Question invalide.', 'error')
            return
        end
        cleaned[#cleaned + 1] = q
    end

    if not saveQuestions(cleaned) then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Échec de la sauvegarde.', 'error')
        return
    end

    Questions = cleaned
    TriggerClientEvent('veebiiz_hydrotest:adminSaved', src, Questions)
    TriggerClientEvent('veebiiz_hydrotest:notify', src, ('%d questions enregistrées.'):format(#Questions), 'success')
end)

RegisterNetEvent('veebiiz_hydrotest:adminUpsert', function(item)
    local src = source
    if not canAdmin(src) then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Accès admin refusé.', 'error')
        return
    end

    local existingId = item and item.id
    local foundIndex = nil
    if existingId then
        for i, q in ipairs(Questions) do
            if q.id == existingId then
                foundIndex = i
                break
            end
        end
    end

    local q, err = sanitizeQuestion(item, foundIndex and Questions[foundIndex].id or nil)
    if not q then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, err or 'Question invalide.', 'error')
        return
    end

    if foundIndex then
        Questions[foundIndex] = q
    else
        Questions[#Questions + 1] = q
    end

    if not saveQuestions(Questions) then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Échec de la sauvegarde.', 'error')
        return
    end

    TriggerClientEvent('veebiiz_hydrotest:adminSaved', src, Questions)
    TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Question enregistrée.', 'success')
end)

RegisterNetEvent('veebiiz_hydrotest:adminDelete', function(id)
    local src = source
    if not canAdmin(src) then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Accès admin refusé.', 'error')
        return
    end

    id = tostring(id or '')
    local nextList = {}
    local removed = false
    for _, q in ipairs(Questions) do
        if q.id == id then
            removed = true
        else
            nextList[#nextList + 1] = q
        end
    end

    if not removed then
        TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Question introuvable.', 'error')
        return
    end

    Questions = nextList
    saveQuestions(Questions)
    TriggerClientEvent('veebiiz_hydrotest:adminSaved', src, Questions)
    TriggerClientEvent('veebiiz_hydrotest:notify', src, 'Question supprimée.', 'success')
end)

AddEventHandler('playerDropped', function()
    Sessions[source] = nil
end)

exports('GetQuestions', function()
    return clone(Questions)
end)

exports('IsCertified', function(src)
    -- Lightweight helper: frameworks may store metadata; default unknown
    return false
end)
