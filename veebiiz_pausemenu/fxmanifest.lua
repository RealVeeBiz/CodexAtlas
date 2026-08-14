fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'veebiiz_pausemenu'
author 'VeeBiiz'
description 'Custom pause menu — replaces the default GTA V escape menu with live player data, rules, and community links.'
version '1.0.0'

shared_scripts {
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}
