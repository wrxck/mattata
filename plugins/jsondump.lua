local jsondump = {}
local mattata = require('mattata')
local json = require('serpent')

function jsondump:init(configuration)
	jsondump.arguments = 'jsondump'
	jsondump.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('jsondump').table
	jsondump.help = configuration.commandPrefix .. 'jsondump - Returns the raw json of your message.'
	json = require('dkjson')
	jsondump.serialise = function(t) return json.encode(t, { indent = true } ) end
end

function jsondump:onMessage(message)
	local s = jsondump.serialise(message)
	if s:len() < 4096 then output = '<pre>' .. mattata.htmlEscape(tostring(s)) .. '</pre>' end
	local res = mattata.sendMessage(message.from.id, output, 'HTML', true, false)
	if not res then mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the raw json.', 'Markdown', true, false, message.message_id)
	elseif message.chat.type ~= 'private' then mattata.sendMessage(message.chat.id, 'I have sent you the raw json via a private message.', nil, true, false, message.message_id) end
end

return jsondump