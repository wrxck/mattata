--[[

    Based on calc.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local calc = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')

function calc:init(configuration)
	calc.arguments = 'calc <expression>'
	calc.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('calc').table
	calc.inlineCommands = calc.commands
	calc.help = configuration.commandPrefix .. 'calc <expression> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.'
end

function calc:onInlineCallback(inline_query, configuration, language)
	local input = inline_query.query:gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
    local str, res = HTTP.request('https://api.mathjs.org/v1/?expr=' .. URL.escape(input))
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
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = output,
			description = 'Click to send the result.',
			input_message_content = {
				message_text = output
			}
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function calc:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, calc.help, 'Markdown', true, false, channel_post.message_id)
		return
	end
	input = input:gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
	local str, res = HTTP.request('https://api.mathjs.org/v1/?expr=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, output, nil, true, false, channel_post.message_id)
end

function calc:onMessageReceive(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, calc.help, 'Markdown', true, false, message.message_id)
		return
	end
	input = input:gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
	local str, res = HTTP.request('https://api.mathjs.org/v1/?expr=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return calc