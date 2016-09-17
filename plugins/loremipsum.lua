local loremipsum = {}
local functions = require('functions')
local HTTP = require('socket.http')
function loremipsum:init(configuration)
	loremipsum.command = 'loremipsum'
	loremipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('loremipsum', true).table
	loremipsum.doc = configuration.command_prefix .. 'loremipsum - Generates a few Lorem Ipsum sentences!'
end
function loremipsum:action(msg, configuration)
	local output = '`' .. HTTP.request(configuration.loremipsum_api) .. '`'
	functions.send_reply(self, msg, output, true)
end
return loremipsum