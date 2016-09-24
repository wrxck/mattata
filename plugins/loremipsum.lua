local loremipsum = {}
local functions = require('functions')
local HTTP = require('socket.http')
function loremipsum:init(configuration)
	loremipsum.command = 'loremipsum'
	loremipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('loremipsum', true).table
	loremipsum.doc = configuration.command_prefix .. 'loremipsum - Generates a few Lorem Ipsum sentences!'
end
function loremipsum:action(msg, configuration)
	local str, res = HTTP.request(configuration.loremipsum_api)
	local output = '`' .. str .. '`'
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		functions.send_reply(msg, output, true)
		return
	end
end
return loremipsum