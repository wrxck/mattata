local catfact = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function catfact:init(configuration)
	catfact.arguments = 'catfact'
	catfact.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('catfact').table
	catfact.inlineCommands = catfact.commands
	catfact.help = configuration.commandPrefix .. 'catfact - A random cat-related fact!'
end

function catfact:onInlineQuery(inline_query, language)
	local jstr, res = HTTP.request('http://catfacts-api.appspot.com/api/facts')
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
			title = jdat.facts[1]:gsub('â', ' '),
			description = 'Click to send the result.',
			input_message_content = {
				message_text = jdat.facts[1]:gsub('â', ' ')
			}
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function catfact:onChannelPost(channel_post, configuration)
	local jstr, res = HTTP.request('http://catfacts-api.appspot.com/api/facts')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, jdat.facts[1]:gsub('â', ' '), nil, true, false, channel_post.message_id)
end

function catfact:onMessage(message, language)
	local jstr, res = HTTP.request('http://catfacts-api.appspot.com/api/facts')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.facts[1]:gsub('â', ' '), nil, true, false, message.message_id)
end

return catfact