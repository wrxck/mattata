local randomword = {}
local HTTP = require('socket.http')
local mattata = require('mattata')

function randomword:init(configuration)
	randomword.arguments = 'randomword'
	randomword.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('randomword'):c('rw').table
	randomword.help = configuration.commandPrefix .. 'randomword - Generates a random word. Alias: ' .. configuration.commandPrefix .. 'rw.'
end

function randomword:onQueryReceive(callback, message, configuration)
	if callback.data == 'new_randomword' then
		local str, res = HTTP.request(configuration.apis.randomword)
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, configuration.errors.connection, nil, true, '{"inline_keyboard":[[{"text":"Try again", "callback_data":"new_randomword"}]]}')
			return
		end
		mattata.editMessageText(message.chat.id, message.message_id, 'Your random word is: *' .. str .. '*.', 'Markdown', true, '{"inline_keyboard":[[{"text":"Generate another", "callback_data":"new_randomword"}]]}')
	end
end

function randomword:onMessageReceive(message, configuration)
	local str, res = HTTP.request(configuration.apis.randomword)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	mattata.sendMessage(message.chat.id, 'Your random word is: *' .. str .. '*.', 'Markdown', true, false, message.message_id, '{"inline_keyboard":[[{"text":"Generate another", "callback_data":"new_randomword"}]]}')
end

return randomword