local calc = {}
local URL = require('socket.url')
local HTTP = require('socket.http')
local functions = require('functions')
function calc:init(configuration)
	calc.command = 'calc <expression>'
	calc.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('calc', true).table
	calc.doc = configuration.command_prefix .. 'calc <expression> - Calculates solutions to, well, mathematical expressions. The results are provided by mathjs.org.'
end
function calc:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(self, msg, calc.doc, true)
		return
	end
	local url = configuration.calc_api .. URL.escape(input)
	local output = HTTP.request(url)
	output = '`' .. output .. '`'
	functions.send_reply(self, msg, output, true)
end
return calc