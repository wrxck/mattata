local randomword = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function randomword:init(configuration)
	randomword.arguments = 'randomword'
	randomword.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('randomword'):c('rw').table
	randomword.help = configuration.commandPrefix .. 'randomword - Generates a random word. Alias: ' .. configuration.commandPrefix .. 'rw.'
end

function randomword:onCallbackQuery(callback_query, message, language)
	if callback_query.data == 'randomword' then
		local str, res = HTTP.request('http://www.setgetgo.com/randomword/get.php')
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, language.errors.connection, nil, true)
			return
		end
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Generate another',
					callback_data = 'randomword'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, 'Your random word is *' .. str .. '*!', 'Markdown', true, JSON.encode(keyboard))
	end
end

function randomword:onChannelPost(channel_post, configuration)
	local str, res = HTTP.request('http://www.setgetgo.com/randomword/get.php')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Generate another',
				callback_data = 'randomword'
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, 'Your random word is *' .. str .. '*!', 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
end

function randomword:onMessage(message, language)
	local str, res = HTTP.request('http://www.setgetgo.com/randomword/get.php')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Generate another',
				callback_data = 'randomword'
			}
		}
	}
	mattata.sendMessage(message.chat.id, 'Your random word is *' .. str .. '*!', 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
end

return randomword