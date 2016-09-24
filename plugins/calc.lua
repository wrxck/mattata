local calc = {}
local URL = require('socket.url')
local HTTP = require('socket.http')
local functions = require('functions')
function calc:init(configuration)
	calc.command = 'calc <expression>'
	calc.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('calc', true).table
	calc.doc = configuration.command_prefix .. 'calc <expression> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.'
end
function calc:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, calc.doc, true)
		return
	else
		input = input:gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*')
		local str, res = HTTP.request(configuration.calc_api .. URL.escape(input))
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		else
			local output = '`' .. str .. '`'
			functions.send_reply(msg, output, true)
			return
		end
	end
end
return calc