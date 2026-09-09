fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'veebiiz_hydrotest'
author 'VeeBiiz'
description 'Hydro-Québec competence test — name entry, random questions, admin question editor.'
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
    'data/questions.json',
}
