local chuck = {}
local JSON = require('dkjson')
local mattata = require('mattata')
local HTTP = require('socket.http')

function chuck:init(configuration)
	chuck.arguments = 'chuck'
	chuck.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('chuck').table
	chuck.inlineCommands = chuck.commands
	chuck.help = configuration.commandPrefix .. 'chuck - Generates a Chuck Norris joke!'
end

function chuck:onInlineCallback(inline_query, configuration)
	local jstr = HTTP.request(configuration.apis.chuck)
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"1","title":"/chuck","description":"' .. chuck.help .. '","input_message_content":{"message_text":"' .. jdat.value.joke .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function chuck:onMessageReceive(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.chuck)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(msg.chat.id, mattata.htmlEscape(jdat.value.joke), nil, true, false, msg.message_id, nil)
end

return chuck