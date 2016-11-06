--[[

    Based on bible.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local bible = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local mattata = require('mattata')

function bible:init(configuration)
	bible.arguments = 'bible <reference>'
	bible.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bible').table
	bible.inlineCommands = bible.commands
	bible.help = configuration.commandPrefix .. 'bible <reference> - Recites the given verse from the Bible.'
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

function bible:onMessageReceive(message, configuration)
	local input = mattata.input(message.text_lower)
	if not input then
		mattata.sendMessage(message.chat.id, bible.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = configuration.apis.bible .. configuration.keys.bible .. '&passage=' .. URL.escape(input)
	local str, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	if not str or str:len() == 0 then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
	if str:len() > 4096 then
		mattata.sendMessage(message.chat.id, 'The requested passage is too long to post here. Please, try and be more specific.', nil, true, false, message.message_id, nil)
		return
	end
	mattata.sendMessage(message.chat.id, str, nil, true, false, message.message_id, nil)
end

return bible