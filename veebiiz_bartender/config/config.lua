--[[
    VeeBiiz Bartender — Extension settings
]]

BarConfig = BarConfig or {}

--- Job required for bar ownership / item permissions
BarConfig.Job = 'bartender'

--- Wait for veebiiz_physicalitems before registering (ms)
BarConfig.BootDelayMs = 750

--- Optional: spawn starter props into empty sockets on resource start
BarConfig.SeedStarterStock = false

BarConfig.StarterStock = {
    -- { zone = 'bahama_bar', slot = 'bottle_01', item = 'whisky' },
    -- { zone = 'bahama_bar', slot = 'glass_01', item = 'glass' },
}
