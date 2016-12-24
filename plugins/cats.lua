local cats = {}
local mattata = require('mattata')
local http = require('socket.http')

function cats:init(configuration)
	assert(configuration.keys.cats, 'cats.lua requires an API key, and you haven\'t got one configured!')
	cats.arguments = 'cat'
	cats.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('cat'):command('sarah').table
	cats.help = configuration.commandPrefix .. 'cat - A random picture of a cat!'
end

function cats:onInlineQuery(inline_query, configuration, language)
	local str, res = http.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
	str = str:match('<img src="(.-)">')
	if res ~= 200 then
		local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'An error occured!',
			description = language.errors.connection,
			input_message_content = { message_text = language.errors.connection }
		}})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local results = json.encode({{
		type = 'photo',
		id = '1',
		photo_url = str,
		thumb_url = str,
		caption = 'Meow!'
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function cats:onMessage(message, configuration, language)
	local str, res = http.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, str:match('<img src="(.-)">'), 'Meow!', false, message.message_id)
end

return cats