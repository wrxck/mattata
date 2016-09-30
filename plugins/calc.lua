local calc = {}
local URL = require('socket.url')
local HTTP = require('socket.http')
local functions = require('functions')
function calc:init(configuration)
	calc.command = 'calc <expression>'
	calc.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('calc', true).table
	calc.inline_triggers = calc.triggers
	calc.documentation = configuration.command_prefix .. 'calc <expression> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.'
end
function calc:inline_callback(inline_query, configuration)
	local input = inline_query.query:gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
	local url = configuration.apis.calc .. URL.escape(input)
    local output = HTTP.request(url)
	local results = '[{"type":"article","id":"50","title":"/calc","description":"' .. calc.documentation .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function calc:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, calc.documentation)
		return
	else
		input = input:gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
	end
	local output, res = HTTP.request(configuration.apis.calc .. URL.escape(input))
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	functions.send_reply(msg, output, true)
end
return calc