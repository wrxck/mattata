local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
local groupmessaging = {}
function groupmessaging:init(configuration)
	groupmessaging.triggers = {
		'^' .. 'mattata ' .. '',
		'^' .. 'mattata, ' .. '',
	}
	groupmessaging.url = configuration.messaging.url
	groupmessaging.error = false
end
function groupmessaging:action(msg, configuration)
	if msg.chat.type == 'supergroup' then
		telegram_api.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' })
	end
	local input = msg.text_lower:gsub('mattata', ''):gsub('mattata,','')
	local jstr, code = HTTPS.request(groupmessaging.url .. URL.escape(input))
	local data = JSON.decode(jstr)
	if msg.chat.type == 'supergroup' then
		functions.send_reply(self, msg, data.clever)
		return
	end
end
return groupmessaging