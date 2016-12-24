local bible = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')

function bible:init(configuration)
	assert(configuration.keys.bible, 'bible.lua requires an API key, and you haven\'t got one configured!')
	bible.arguments = 'bible <reference>'
	bible.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('bible').table
	bible.help = configuration.commandPrefix .. 'bible <reference> - Recites the given verse from the Bible.'
end

function bible:onInlineQuery(inline_query, configuration)
	local input = mattata.input(inline_query.query)
	local url = 'http://api.biblia.com/v1/bible/content/ASV.txt?key=' .. configuration.keys.bible .. '&passage=' .. url.escape(inline_query.query)
    local output = http.request(url)
	if output:len() > 4000 then output = 'The requested passage is too long to post here. Please, try and be more specific.' end
	local results = '[{"type":"article","id":"1","title":"/bible","description":"' .. bible.help .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function bible:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then mattata.sendMessage(message.chat.id, bible.help, nil, true, false, message.message_id) return end
	local str, res = http.request('http://api.biblia.com/v1/bible/content/ASV.txt?key=' .. configuration.keys.bible .. '&passage=' .. url.escape(input))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	if not str or str:len() == 0 then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	if str:len() > 1024 then mattata.sendMessage(message.chat.id, language.errors.bibleLength, nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, str, nil, true, false, message.message_id)
end

return bible