local bible = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local mattata = require('mattata')

function bible:init(configuration)
	bible.arguments = 'bible <reference>'
	bible.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bible', true).table
	bible.inlineCommands = bible.commands
	bible.help = configuration.commandPrefix .. 'bible <reference> - Returns a verse from the American Standard Version of the Bible. Results from biblia.com.'
end

function bible:onInlineCallback(inline_query, configuration)
	local url = configuration.apis.bible .. configuration.keys.bible .. '&passage=' .. URL.escape(inline_query.query)
    local output = HTTP.request(url)
	if output:len() > 4000 then
		output = 'The requested passage is too long to post here. Please, try and be more specific.'
	end
	local results = '[{"type":"article","id":"1","title":"/bible","description":"' .. bible.help .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function bible:onMessageReceive(msg, configuration)
	local input = mattata.input_from_msg(msg)
	if not input then
		mattata.sendMessage(msg.chat.id, bible.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.bible .. configuration.keys.bible .. '&passage=' .. URL.escape(input)
	local output, res = HTTP.request(url)
	if not output or res ~= 200 or output:len() == 0 then
		output = configuration.errors.results
	end
	if output:len() > 4000 then
		output = 'The requested passage is too long to post here. Please, try and be more specific.'
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return bible