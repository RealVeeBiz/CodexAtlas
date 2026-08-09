--[[
    ox_inventory item definitions for veebiiz_bartender.

    Copy these into ox_inventory/data/items.lua (or your items pack).
    Adjust weights / labels as needed for your server.
]]

return {
    ['whisky'] = {
        label = 'Whisky',
        weight = 700,
        stack = false,
        close = true,
        description = 'A bottle of aged whisky.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['vodka'] = {
        label = 'Vodka',
        weight = 700,
        stack = false,
        close = true,
        description = 'A clear bottle of vodka.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['rum'] = {
        label = 'Rum',
        weight = 700,
        stack = false,
        close = true,
        description = 'A bottle of rum.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['glass'] = {
        label = 'Glass',
        weight = 100,
        stack = false,
        close = true,
        description = 'An empty drinking glass.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['ice'] = {
        label = 'Ice',
        weight = 50,
        stack = true,
        close = true,
        description = 'Cubed ice for drinks.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['lemon'] = {
        label = 'Lemon',
        weight = 40,
        stack = true,
        close = true,
        description = 'Fresh lemon garnish.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['coke'] = {
        label = 'Coke',
        weight = 330,
        stack = false,
        close = true,
        description = 'A can of cola mixer.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
    ['tonic'] = {
        label = 'Tonic',
        weight = 330,
        stack = false,
        close = true,
        description = 'A bottle of tonic water.',
        server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
    },
}
