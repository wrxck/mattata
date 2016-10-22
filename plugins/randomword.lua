local randomword = {}
local HTTP = require('dependencies.socket.http')
local mattata = require('mattata')

function randomword:init(configuration)
	randomword.arguments = 'randomword'
	randomword.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('randomword', true):c('rw', true).table
	randomword.help = configuration.commandPrefix .. 'randomword - Generates a random word. Alias: ' .. configuration.commandPrefix .. 'rw.'
end

function randomword:onMessageReceive(msg, configuration)
	local str, res = HTTP.request(configuration.apis.randomword)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendMessage(msg.chat.id, 'Your random word is: *' .. str .. '*.', 'Markdown', true, false, msg.message_id, nil, '{"inline_keyboard":[[{"text":"Generate another!", "callback_data":"randomword"}]]}')
end

return randomword