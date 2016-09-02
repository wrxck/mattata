local calc = {}
local URL = require('socket.url')
local HTTPS = require('ssl.https')
local functions = require('mattata.functions')
calc.command = 'calc <expression>'
function calc:init(configuration)
	calc.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('calc', true).table
	calc.doc = configuration.command_prefix .. [[calc <expression>
Calculates solutions to, well, mathematical expressions. The results are provided by mathjs.org.]]
end
function calc:action(msg, configuration)
	local input = functions.input(msg.text):gsub("π", "3.14159265359"):gsub("pi", "3.14159265359"):gsub("phi", "1.61803398875"):gsub("the golden ratio", "1.61803398875"):gsub("φ", "1.61803398875")
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_message(self, msg.chat.id, calc.doc, true, msg.message_id, true)
			return
		end
	end
	local url = configuration.calc_api .. URL.escape(input)
	local output = HTTPS.request(url)
	if not output then
		functions.send_reply(self, msg, configuration.errors.connection_error)
		return
	end
	output = '`' .. output .. '`'
	functions.send_message(self, msg.chat.id, output, true, msg.message_id, true)
end
return calc
