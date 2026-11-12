fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'XS-Housing'
author 'XyraL'
description 'Houses, apartments, MLOs and offices for Qbox and QBCore, built in game, with furniture, yards, keys, rent, mortgages, break-ins and raids.'
version '1.1.1'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'shared/locale.lua',
    'shared/util.lua',
    'shared/data/shells.lua',
    'shared/data/ipls.lua',
    'shared/interiors.lua',
    'shared/furniture.lua',
    'shared/settings.lua',
}

client_scripts {
    'bridge/framework.lua',
    'bridge/target.lua',
    'bridge/inventory.lua',
    'bridge/clothing.lua',
    'bridge/garage.lua',
    'bridge/weather.lua',
    'bridge/phone.lua',
    'client/ui.lua',
    'client/settings.lua',
    'client/main.lua',
    'client/sound.lua',
    'client/doorpick.lua',
    'client/placement.lua',
    'client/polygon.lua',
    'client/ipl.lua',
    'client/properties.lua',
    'client/enter.lua',
    'client/furniture.lua',
    'client/panel.lua',
    'client/security.lua',
    'client/agency.lua',
    'client/builder.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/framework.lua',
    'bridge/inventory.lua',
    'bridge/banking.lua',
    'bridge/dispatch.lua',
    'bridge/doorlock.lua',
    'bridge/garage.lua',
    'bridge/phone.lua',
    'server/db.lua',
    'server/settings.lua',
    'server/logs.lua',
    'server/properties.lua',
    'server/access.lua',
    'server/doors.lua',
    'server/storage.lua',
    'server/fridge.lua',
    'server/furniture.lua',
    'server/seasons.lua',
    'server/ownership.lua',
    'server/enter.lua',
    'server/security.lua',
    'server/agency.lua',
    'server/pictures.lua',
    'server/builder.lua',
    'server/compat.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/tv.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/img/*.svg',
}
