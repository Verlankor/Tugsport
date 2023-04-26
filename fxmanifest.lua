fx_version 'cerulean'
game 'gta5'

description 'QB-Tugsport'
version '1.0'

shared_script 'config.lua'

client_scripts {
  'client.lua',
}

lua54 'yes'

server_script 'server.lua'

dependencies {
  'qb-core',
  'qb-target'
}

escrow_ignore {
  '*.lua',
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/script.js',
  'html/style.css',
  'html/water.png',
  'html/check.png',
  'html/x.png'
}