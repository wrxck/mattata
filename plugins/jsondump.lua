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

function jsondump:onMessageReceive(msg)
	local input = mattata.input(msg.text)
	local output = ''
	local s = jsondump.serialise(msg)
	if s:len() < 4000 then
		output = '`' .. tostring(s) .. '`'
	end
	local res = mattata.sendMessage(msg.from.id, output, 'Markdown', true, false, msg.message_id, nil)
	if not res then
		mattata.sendMessage(msg.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the raw JSON.', 'Markdown', true, false, msg.message_id, nil)
	elseif msg.chat.type ~= 'private' then
		mattata.sendMessage(msg.chat.id, 'I have sent you the raw JSON via a private message.', nil, true, false, msg.message_id, nil)
	end
end

return jsondump