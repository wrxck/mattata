--[[

    Based on calc.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local calc = {}
local URL = require('socket.url')
local HTTP = require('socket.http')
local mattata = require('mattata')

function calc:init(configuration)
	calc.arguments = 'calc <expression>'
	calc.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('calc').table
	calc.inlineCommands = calc.commands
	calc.help = configuration.commandPrefix .. 'calc <expression> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.'
end

function calc:onInlineCallback(inline_query, configuration)
	local input = inline_query.query:gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
	local url = configuration.apis.calc .. URL.escape(input)
    local output = HTTP.request(url)
	local results = '[{"type":"article","id":"1","title":"/calc","description":"' .. calc.help .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function calc:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, calc.help, 'Markdown', true, false, message.message_id, nil)
		return
	else
		input = input:gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
	end
	local output, res = HTTP.request(configuration.apis.calc .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
end

return calc