fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'veebiiz_bartender'
author 'VeeBiiz'
description 'Bartender / bar extension for veebiiz_physicalitems — bottles, glasses, pour, mix, garnish.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/items.lua',
    'config/recipes.lua',
    'config/zones.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

files {
    'items_ox_inventory.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'veebiiz_physicalitems',
}
