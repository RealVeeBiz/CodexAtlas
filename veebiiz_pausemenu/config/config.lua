Config = {}

-- Server branding shown in the pause menu hero
Config.ServerName = 'VeeBiiz RP'
Config.ServerTagline = 'Stay sharp. Play fair. Build the city.'

-- Theme accents (NUI also hardcodes CSS vars; keep in sync if you restyle)
Config.Theme = {
    primary = '#F5C518',
    background = '#0A0A0A',
}

-- When true, ESC / P open this menu instead of the native pause menu
Config.ReplaceNativePause = true

-- Allow opening the native map from the menu
Config.AllowMap = true

-- Allow opening native game settings from the menu
Config.AllowSettings = true

-- Show disconnect confirmation before quitting to desktop / server list
Config.ConfirmDisconnect = true

-- How often (ms) the client asks the server for fresh player stats while the menu is open
Config.RefreshInterval = 3000

--[[
  Framework auto-detect order: qbx_core → qb-core → es_extended → standalone
  Set ForceFramework to 'qbox' | 'qb' | 'esx' | 'standalone' to skip detection.
]]
Config.ForceFramework = nil

-- Rules shown in the Rules tab (edit freely)
Config.Rules = {
    {
        title = 'Respect players & staff',
        body = 'No harassment, hate speech, or toxic behavior. Treat everyone the way you want to be treated in-character and out.',
    },
    {
        title = 'No RDM / VDM',
        body = 'Random deathmatch and vehicle deathmatch without valid roleplay are not allowed. Always have a reason.',
    },
    {
        title = 'Value your life',
        body = 'Fear RP matters. Do not act invincible. Comply when outnumbered or under clear threat.',
    },
    {
        title = 'No metagaming',
        body = 'Do not use Discord, streams, or OOC info inside character decisions. Keep IC and OOC separate.',
    },
    {
        title = 'No powergaming',
        body = 'Do not force actions on others or invent unreal outcomes. Leave room for mutual roleplay.',
    },
    {
        title = 'Report, do not escalate',
        body = 'Use /report or Discord tickets for rule breaks. Fighting fire with fire will get you banned too.',
    },
}

-- External community links (opened via FiveM openUrl)
Config.Links = {
    {
        id = 'discord',
        label = 'Discord',
        description = 'Voice, tickets, and announcements',
        url = 'https://discord.gg/your-invite',
        icon = 'discord',
    },
    {
        id = 'website',
        label = 'Website',
        description = 'Rules, lore, and applications',
        url = 'https://example.com',
        icon = 'globe',
    },
    {
        id = 'store',
        label = 'Store',
        description = 'Support the server',
        url = 'https://example.com/store',
        icon = 'cart',
    },
    {
        id = 'tiktok',
        label = 'TikTok',
        description = 'Clips & community highlights',
        url = 'https://www.tiktok.com/@yourhandle',
        icon = 'video',
    },
}

-- Optional keybind hint text in the footer
Config.FooterHint = 'ESC to resume · Use the sidebar to navigate'
