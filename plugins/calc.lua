local calc = {}
local URL = require('socket.url')
local HTTP = require('socket.http')
local functions = require('functions')
function calc:init(configuration)
 calc.command = 'calc <expression>'
 calc.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('calc', true).table
 calc.doc = configuration.command_prefix .. [[calc <expression>
Calculates solutions to, well, mathematical expressions. The results are provided by mathjs.org.]]
end
function calc:action(msg, configuration)
 local input = functions.input(msg.text):gsub("π", "3.14159265359"):gsub("pi", "3.14159265359"):gsub("phi", "1.61803398875"):gsub("the golden ratio", "1.61803398875"):gsub("φ", "1.61803398875")
 if not input then
  functions.send_message(self, msg.chat.id, calc.doc, true, msg.message_id, true)
  return
 end
 local url = configuration.calc_api .. URL.escape(input)
 local output = HTTP.request(url)
 if not output then
  functions.send_reply(self, msg, configuration.errors.connection_error)
  return
 end
 output = '`' .. output .. '`'
 functions.send_message(self, msg.chat.id, output, true, msg.message_id, true)
end
return calc