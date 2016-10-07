local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
local messaging = {}
function messaging:init(configuration)
	messaging.triggers = {
		'^' .. '' .. ''
	}
	messaging.inline_triggers = messaging.triggers
end
function messaging:inline_callback(inline_query, configuration)
	local input = inline_query.query
	local jstr = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"50","title":"Talk with mattata, inline!","description":"Start typing to see the response","input_message_content":{"message_text":"Me: ' .. input .. ' | mattata: ' .. jdat.clever..'"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function messaging:action(msg, configuration)
	local input = msg.text_lower:gsub(self.info.first_name .. ' ', ''):gsub(self.info.first_name .. ', ',''):gsub('Mattata, ',''):gsub('Mattata ','')
	local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	if msg.reply_to_message then
		if msg.reply_to_message.from.id == self.id then
			if msg.chat.id == configuration.admin_group then
				if not string.match(input, configuration.command_prefix) then
					functions.send_message(msg.reply_to_message.forward_from.id, input, true, nil, true)
					return
				else
					functions.send_reply(msg, 'That message wasn\'t sent because it contained \'' .. configuration.command_prefix .. '\'')
				end
			end
		end
	end
	if msg.chat.type == 'private' then
		if string.match(input, configuration.command_prefix .. 'msg') then
			if input == configuration.command_prefix .. 'msg' then
				functions.send_reply(msg, 'Please enter a message to send to the administrators.')
				return
			else
				functions.forward_message(configuration.admin_group, msg.from.id, msg.message_id)
				functions.send_reply(msg, 'Your message has been sent successfully. Make sure you don\'t delete this chat, else you won\'t be able to receive a response.')
			end
		else
			telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
			functions.send_reply(msg, jdat.clever)
			return
		end
	else
		if string.match(msg.text, 'trick or treat') then
			telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
			functions.send_reply(msg, 'Trick, motherfucker!')
			return
		elseif string.match(msg.text, 'nigger') then
			telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
			functions.send_reply(msg, 'You racist bastard!')
			return
		elseif string.match(msg.text, self.info.first_name) or string.match(msg.text, 'Mattata') then
			telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
			functions.send_reply(msg, jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!'))
			return
		end	
		if msg.reply_to_message then
			if msg.reply_to_message.from.id == self.info.id then
				telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
				functions.send_reply(msg, jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!'))
				return
			end
		end
	end
end
return messaging