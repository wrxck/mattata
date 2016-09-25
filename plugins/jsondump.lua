local jsondump = {}
local functions = require('functions')
local JSON = require('serpent')
function jsondump:init(configuration)
	jsondump.command = 'jsondump'
	jsondump.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('jsondump', true):t('jm', true).table
	JSON = require('dkjson')
	jsondump.serialise = function(t) return JSON.encode(t, {indent=true}) end
end
function jsondump:action(msg)
	local input = functions.input(msg.text)
	if not msg.reply_to_message then
		functions.send_reply(msg, '`Please reply to the message you would like to receive in raw JSON.`', true)
		return
	end
	local output = ''
	local s = jsondump.serialise(msg)
	if s:len() < 4000 then
		output = '`' .. tostring(s) .. '`'
	end
	local res = functions.send_message(msg.from.id, output, true, nil, true)
	if not res then
		functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the raw JSON.', true)
	elseif msg.chat.type ~= 'private' then
		functions.send_reply(msg, '`I have sent you the raw JSON via a private message.`', true)
	end
end
return jsondump