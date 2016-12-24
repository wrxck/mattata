local catfact = {}
local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function catfact:init(configuration)
	catfact.arguments = 'catfact'
	catfact.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('catfact').table
	catfact.help = configuration.commandPrefix .. 'catfact - A random cat-related fact!'
end

function catfact:onInlineQuery(inline_query, configuration, language)
	local jstr, res = http.request('http://catfacts-api.appspot.com/api/facts')
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
	local jdat = json.decode(jstr)
	local results = json.encode({{
		type = 'article',
		id = '1',
		title = jdat.facts[1]:gsub('â', ' '),
		description = 'Click to send the result.',
		input_message_content = { message_text = jdat.facts[1]:gsub('â', ' ') }
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function catfact:onMessage(message, configuration, language)
	local jstr, res = http.request('http://catfacts-api.appspot.com/api/facts')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.facts[1]:gsub('â', ' '), nil, true, false, message.message_id)
end

return catfact