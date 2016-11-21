--[[

    Based on cats.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local cats = {}
local mattata = require('mattata')
local HTTP = require('socket.http')

function cats:init(configuration)
	cats.arguments = 'cat'
	cats.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('cat'):c('sarah').table
	cats.inlineCommands = cats.commands
	cats.help = configuration.commandPrefix .. 'cat - A random picture of a cat!'
end

function cats:onInlineCallback(inline_query, language)
	local str, res = HTTP.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
	str = str:match('<img src="(.-)">')
	if res ~= 200 then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = {
					message_text = language.errors.connection
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local results = JSON.encode({
		{
			type = 'photo',
			id = '1',
			photo_url = str,
			thumb_url = str,
			caption = 'Meow!'
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function cats:onChannelPostReceive(channel_post, configuration)
	local str, res = HTTP.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendPhoto(channel_post.chat.id, str:match('<img src="(.-)">'), 'Meow!', false, channel_post.message_id)
end

function cats:onMessageReceive(message, configuration, language)
	local str, res = HTTP.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, str:match('<img src="(.-)">'), 'Meow!', false, message.message_id)
end

return cats