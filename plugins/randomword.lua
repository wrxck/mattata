local randomword = {}
local HTTP = require('socket.http')
local mattata = require('mattata')

function randomword:init(configuration)
	randomword.arguments = 'randomword'
	randomword.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('randomword'):c('rw').table
	randomword.help = configuration.commandPrefix .. 'randomword - Generates a random word. Alias: ' .. configuration.commandPrefix .. 'rw.'
end

function randomword:onQueryReceive(callback, msg, configuration)
	if callback.data == 'new_randomword' then
		local str, res = HTTP.request(configuration.apis.randomword)
		if res ~= 200 then
			mattata.editMessageText(msg.chat.id, msg.message_id, configuration.errors.connection, nil, true, '{"inline_keyboard":[[{"text":"Try again", "callback_data":"new_randomword"}]]}')
			return
		end
		mattata.editMessageText(msg.chat.id, msg.message_id, 'Your random word is: *' .. str .. '*.', 'Markdown', true, '{"inline_keyboard":[[{"text":"Generate another", "callback_data":"new_randomword"}]]}')
	end
end

function randomword:onMessageReceive(msg, configuration)
	local str, res = HTTP.request(configuration.apis.randomword)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendMessage(msg.chat.id, 'Your random word is: *' .. str .. '*.', 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"Generate another", "callback_data":"new_randomword"}]]}')
end

return randomword