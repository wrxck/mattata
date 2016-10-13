local randomword = {}
local HTTP = require('dependencies.socket.http')
local functions = require('functions')
function randomword:init(configuration)
	randomword.command = 'randomword'
	randomword.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('randomword', true):t('rw', true).table
	randomword.documentation = configuration.command_prefix .. 'randomword - Generates a random word. Alias: ' .. configuration.command_prefix .. 'rw.'
end
function randomword:action(msg, configuration)
	local str, res = HTTP.request(configuration.apis.randomword)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	functions.send_reply(msg, 'Your random word is: *' .. str .. '*.', true, '{"inline_keyboard":[[{"text":"Generate another!", "callback_data":"randomword"}]]}')
end
return randomword