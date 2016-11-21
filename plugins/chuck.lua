local chuck = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function chuck:init(configuration)
	chuck.arguments = 'chuck'
	chuck.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('chuck').table
	chuck.inlineCommands = chuck.commands
	chuck.help = configuration.commandPrefix .. 'chuck - Generates a Chuck Norris joke!'
end

function chuck:onInlineCallback(inline_query, language)
	local jstr, res = HTTP.request('http://api.icndb.com/jokes/random')
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
	local jdat = JSON.decode(jstr)
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = jdat.value.joke,
			description = 'Click to send the result.',
			input_message_content = {
				message_text = jdat.value.joke
			}
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function chuck:onChannelPostReceive(channel_post, configuration)
	local jstr, res = HTTP.request('http://api.icndb.com/jokes/random')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, mattata.htmlEscape(jdat.value.joke), nil, true, false, channel_post.message_id)
end

function chuck:onMessageReceive(message, language)
	local jstr, res = HTTP.request('http://api.icndb.com/jokes/random')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, mattata.htmlEscape(jdat.value.joke), nil, true, false, message.message_id)
end

return chuck