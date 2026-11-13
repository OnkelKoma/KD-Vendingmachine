fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'kd-vendingmachine'
author 'KD Scripts'
description 'Immersive, themed vending machines with a realistic custom NUI. Supports QBox, QBCore, ESX and standalone.'
version '1.0.0'
repository 'https://github.com/kd-scripts/kd-vendingmachine'

ui_page 'web/index.html'

shared_scripts {
    'config/config.lua',
    'shared/locale.lua',
    'locales/*.lua',
    'shared/utils.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/animation.lua',
    'client/props.lua',
    'client/interaction.lua',
    'client/main.lua',
}

server_scripts {
    'config/server.lua',
    'bridge/server.lua',
    'server/stock.lua',
    'server/main.lua',
}

files {
    'web/index.html',
    'web/css/*.css',
    'web/js/*.js',
}
