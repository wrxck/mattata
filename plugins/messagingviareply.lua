local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local messaging = {}
function messaging:init(configuration)
	messaging.triggers = {
		'^' .. '' .. ''
	}
end
function messaging:action(msg, configuration)
	local input = msg.text_lower:gsub('mattata ', ''):gsub('mattata, ','')
	local jstr, code = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	local jdat = JSON.decode(jstr)
	if msg.reply_to_message then
		if msg.reply_to_message.from.id == self.id then
			if msg.chat.id == configuration.admin_group then
				if not string.match(input, configuration.command_prefix) then
					functions.send_message(msg.reply_to_message.forward_from.id, input, true, nil, true)
					return
				else
					functions.send_reply(msg, '`That message wasn\'t sent because it contained \'' .. configuration.command_prefix .. '\'`', true)
				end
			end
		end
	end
	if msg.chat.type == 'supergroup' then
		if msg.reply_to_message then
			if msg.reply_to_message.from.id == self.id then
				functions.send_action(chat_id, 'typing')
				functions.send_reply(msg, '`' .. jdat.clever .. '`', true)
				return
			end
		end
	elseif msg.chat.type == 'group' then
		if msg.reply_to_message then
			if msg.reply_to_message.from.id == self.id then
				functions.send_action(chat_id, 'typing')
				functions.send_reply(msg, '`' .. jdat.clever .. '`', true)
				return
			end
		end
	elseif msg.chat.type == 'channel' then
		if msg.reply_to_message then
			if msg.reply_to_message.from.id == self.id then
				functions.send_action(chat_id, 'typing')
				functions.send_reply(msg, '`' .. jdat.clever .. '`', true)
				return
			end
		end
	elseif msg.chat.type == 'private' then
		if string.match(input, configuration.command_prefix .. 'msg') then
			if input == configuration.command_prefix .. 'msg' then
				functions.send_reply(msg, '`Please enter a message to send to the administrators.`', true)
				return
			else
				functions.forward_message(configuration.admin_group, msg.from.id, msg.message_id)
				functions.send_reply(msg, '`Your message has been sent successfully. Make sure you don\'t delete this chat, else you won\'t be able to receive a response.`', true)
			end
		else
			functions.send_action(chat_id, 'typing')
			functions.send_reply(msg, '`' .. jdat.clever .. '`', true)
			return
		end
	end
end
return messaging