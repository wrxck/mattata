local messaging = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
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
	local data = JSON.decode(jstr)
	local output = data.clever
	if msg.chat.type == 'private' then
		functions.send_reply(self, msg, '`' .. output:gsub('?.', '?') .. '`', true)
		telegram_api.forwardMessage(self, {chat_id = configuration.admin_group, from_chat_id = msg.from.id, message_id = msg.message_id})
	end
	if msg.reply_to_message then
		if msg.reply_to_message.from.id == 268302625 then
			if msg.chat.id == configuration.admin_group then
				telegram_api.forwardMessage(self, {chat_id = msg.reply_to_message.forward_from.id, from_chat_id = msg.chat.id, message_id = msg.message_id})
			end
		end
	end
end
return messaging