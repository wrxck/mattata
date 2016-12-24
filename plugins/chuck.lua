local chuck = {}
local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function chuck:init(configuration)
	chuck.arguments = 'chuck'
	chuck.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('chuck').table
	chuck.help = configuration.commandPrefix .. 'chuck - Generates a Chuck Norris joke!'
end

function chuck:onInlineQuery(inline_query, configuration, language)
	local jstr, res = http.request('http://api.icndb.com/jokes/random')
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
		title = jdat.value.joke,
		description = 'Click to send the result.',
		input_message_content = { message_text = jdat.value.joke }
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function chuck:onMessage(message, configuration, language)
	local jstr, res = http.request('http://api.icndb.com/jokes/random')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.value.joke, nil, true, false, message.message_id)
end

return chuck