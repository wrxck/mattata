local calc = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')

function calc:init(configuration)
	calc.arguments = 'calc <expression>'
	calc.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('calc').table
	calc.help = configuration.commandPrefix .. 'calc <expression> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.'
end

function calc:onInlineQuery(inline_query, configuration, language)
	local input = mattata.input(inline_query.query):gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*'):gsub('to the power of', '^'):gsub('minus', '-')
    local str, res = http.request('https://api.mathjs.org/v1/?expr=' .. url.escape(input))
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
	local results = json.encode({{
		type = 'article',
		id = '1',
		title = str,
		description = 'Click to send the result.',
		input_message_content = { message_text = str }
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function calc:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, calc.help, nil, true, false, message.message_id) return end
	input = input:gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*'):gsub('to the power of', '^'):gsub('minus', '-')
	local str, res = http.request('https://api.mathjs.org/v1/?expr=' .. url.escape(input))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, str, nil, true, false, message.message_id)
end

return calc