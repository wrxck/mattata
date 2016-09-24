local randomword = {}
local HTTP = require('socket.http')
local functions = require('functions')
function randomword:init(configuration)
	randomword.command = 'randomword'
	randomword.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('randomword', true):t('rw', true).table
	randomword.doc = configuration.command_prefix .. 'randomword - Generates a random word. Alias: ' .. configuration.command_prefix .. 'rw.'
end
function randomword:action(msg, configuration)
	local word, res = HTTP.request(configuration.randomword_api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		functions.send_reply(msg, '*Your random word is:* `' .. word .. '`', true)
		return
	end
end
return randomword