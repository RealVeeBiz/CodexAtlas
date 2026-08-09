fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'veebiiz_physicalitems'
author 'VeeBiiz'
description 'Generic physical item framework — inventory items become persistent world props with socket placement, carry, interactions and object state.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/enums.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'config/config.lua',
    'config/items.lua',
    'config/props.lua',
    'config/zones.lua',
    'config/interactions.lua',
    'config/recipes.lua',
}

client_scripts {
    'integrations/ox_lib.lua',
    'integrations/ox_target.lua',
    'integrations/qbox.lua',
    'client/utils.lua',
    'client/raycast.lua',
    'client/animations.lua',
    'client/attachments.lua',
    'client/zones.lua',
    'client/objects.lua',
    'client/carry.lua',
    'client/pickup.lua',
    'client/placement.lua',
    'client/interaction.lua',
    'client/targeting.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'integrations/ox_lib.lua',
    'integrations/ox_inventory.lua',
    'integrations/qbox.lua',
    'server/validation.lua',
    'server/permissions.lua',
    'server/persistence.lua',
    'server/inventory.lua',
    'server/objects.lua',
    'server/callbacks.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/src/app.js',
    'web/src/style.css',
    'web/src/components/*.js',
    'web/build/*',
    'examples/bartender/*.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
}

provides {
    'veebiiz_physicalitems',
}
