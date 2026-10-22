fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'BLN Studio <bln.tebex.io>'
description 'DevTool, Multiple Coords Collector'
version '1.0.2'

client_scripts {
    'config.lua',
    'c.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html'
}

server_scripts {
    'vcheck.lua'
}