local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
local messaging = {}
function messaging:init(configuration)
	messaging.triggers = {
		'^' .. 'mattata ' .. '',
		'^' .. 'mattata, ' .. '',
		'^' .. '' .. ''
	}
	messaging.url = configuration.messaging.url
	messaging.error = false
end
function messaging:action(msg, configuration)
	if msg.chat.type == 'private' then
		telegram_api.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' })
	end
	local input = msg.text
	local jstr = HTTPS.request(messaging.url .. URL.escape(input)):gsub('mattata', ''):gsub('mattata,','')
	local jdat = JSON.decode(jstr)
	local output = jdat.clever
	if msg.chat.type == 'private' then
		functions.send_message(self, msg.chat.id, output:gsub('?.', '?'), true, nil, true)
		return
	end
end
return messaging