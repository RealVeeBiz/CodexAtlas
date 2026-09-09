Config = {}

-- Branding shown in the NUI
Config.Title = 'Hydro-Québec'
Config.Subtitle = 'Test de compétence'
Config.FooterHint = 'ESC pour fermer'

-- How many questions are drawn at random for each attempt
Config.QuestionsPerTest = 8

-- Minimum correct answers (absolute) OR pass score percent — use percent
Config.PassPercent = 70

-- Shuffle answer options each question
Config.ShuffleAnswers = true

-- Commands
Config.Commands = {
    test = 'hydrotest',   -- open the competence test
    admin = 'hydroadmin', -- open the question editor (ACE required)
}

--[[
  ACE permission for the admin editor.
  Example server.cfg:
    add_ace group.admin hydrotest.admin allow
]]
Config.AdminAce = 'hydrotest.admin'

-- Allow admins in these framework groups (checked after ACE)
-- Set empty to rely on ACE only.
Config.AdminGroups = {
    'admin',
    'god',
    'superadmin',
}

-- Optional: grant a job / metadata key when the player passes (QB/Qbox/ESX hooks)
Config.OnPass = {
    enabled = false,
    -- Set metadata flag (QB/Qbox) or ESX metadata when available
    metadataKey = 'hydro_certified',
    metadataValue = true,
    -- Optional notify message
    notify = 'Félicitations — certification Hydro-Québec réussie.',
}

Config.OnFail = {
    notify = 'Échec du test. Révisez le matériel et réessayez.',
}

-- Theme (Hydro-Québec inspired teal)
Config.Theme = {
    primary = '#00A3A1',
    primaryDark = '#007A78',
    background = '#0B1C1C',
    surface = '#122626',
    text = '#F2F7F7',
    danger = '#E04F4F',
    success = '#3CB371',
}
