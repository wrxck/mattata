local catfact = {}
local JSON = require('dkjson')
local mattata = require('mattata')
local HTTP = require('socket.http')

function catfact:init(configuration)
	catfact.arguments = 'catfact'
	catfact.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('catfact', true).table
	catfact.inlineCommands = catfact.commands
	catfact.help = configuration.commandPrefix .. 'catfact - A random cat-related fact!'
end

function catfact:onInlineCallback(inline_query, configuration)
	local jstr = HTTP.request(configuration.apis.catfact)
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"1","title":"/catfact","description":"' .. catfact.help .. '","input_message_content":{"message_text":"' .. jdat.facts[1] .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function catfact:onMessageReceive(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.catfact)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(msg.chat.id, jdat.facts[1]:gsub('â', ' '), nil, true, false, msg.message_id, nil)
end

return catfact