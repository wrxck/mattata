local randomword = {}
local HTTP = require('socket.http')
local functions = require('functions')
function randomword:init(configuration)
	randomword.command = 'randomword'
	randomword.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('randomword', true):t('rw', true).table
	randomword.doc = configuration.command_prefix .. 'randomword \nGenerates a random word.'
end
function randomword:action(msg, configuration)
	local word = HTTP.request(configuration.randomword_api)
	functions.send_reply(self, msg, '`' .. word .. '`', true)
end
return randomword