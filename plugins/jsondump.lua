local jsondump = {}
local mattata = require('mattata')
local JSON = require('serpent')

function jsondump:init(configuration)
	jsondump.arguments = 'jsondump'
	jsondump.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('jsondump').table
	JSON = require('dkjson')
	jsondump.serialise = function(t)
		return JSON.encode(t, { indent = true } )
	end
end

function jsondump:onMessageReceive(message)
	local input = mattata.input(message.text)
	local output = ''
	local s = jsondump.serialise(message)
	if s:len() < 4000 then
		output = '`' .. tostring(s) .. '`'
	end
	local res = mattata.sendMessage(message.from.id, output, 'Markdown', true, false, message.message_id, nil)
	if not res then
		mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the raw JSON.', 'Markdown', true, false, message.message_id, nil)
	elseif message.chat.type ~= 'private' then
		mattata.sendMessage(message.chat.id, 'I have sent you the raw JSON via a private message.', nil, true, false, message.message_id, nil)
	end
end

return jsondump