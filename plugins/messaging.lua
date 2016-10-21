local messaging = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local functions = require('functions')
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
		return
	end
	local jdat = JSON.decode(jstr)
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
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!'):gsub('?%.', '?'))
			return
		end
	else
		if string.match(msg.text, '😐😐😐') or string.match(msg.text, '😑😑😑') or string.match(msg.text, ':|:|:|') or string.match(msg.text, '🙁🙁🙁') or string.match(msg.text, '☹☹☹️') or string.match(msg.text, '🌹🌹🌹') or string.match(msg.text, '😒😒😒') or string.match(msg.text, '😭😭😭') or string.match(msg.text, '💋💋💋') then -- Idea by @aRandomStranger
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, '*⚠️ WEEDOW WEEDOW ⚠️*\n_Random iranian spammer detected._', true)
		end
		if string.match(msg.text_lower, 'ayy') then
			functions.send_reply(msg, 'lmao')
			return
		end
		if string.match(msg.text_lower, 'lmao') then
			functions.send_reply(msg, 'ayy')
			return
		end
		if string.match(msg.text, self.info.first_name) or string.match(msg.text, 'Mattata') then
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!'):gsub('?%.', '?'))
			return
		end
		if string.match(msg.text, '%^%?') then
			functions.send_reply(msg, 'Since this user used the trigger `^?`, any messages sent in reply will be forwarded to them.', true)
			return
		end
		if msg.reply_to_message then
			if msg.reply_to_message.from.id ~= msg.from.id then
				if msg.reply_to_message.from.username then
					if string.match(msg.reply_to_message.text, '%^%?') then
						functions.forward_message(msg.reply_to_message.from.id, msg.chat.id, msg.message_id)
					end
				end
			end
			if msg.reply_to_message.from.id == self.info.id then
				if msg.chat.id == configuration.admin_group then
					if string.match(input, configuration.command_prefix) then
						functions.send_reply(msg, 'That message wasn\'t sent because it contained \'' .. configuration.command_prefix .. '\'')
						return
					else
						if msg.reply_to_message.forward_from then
							local admin_res = functions.send_message(msg.reply_to_message.forward_from.id, input, true, nil, true)
							if admin_res then
								functions.send_reply(msg, 'Your message was sent successfully!')
							else
								functions.send_reply(msg, 'Your message failed to send - this probably means the user blocked me.')
							end
							return
						end
					end
				else
					functions.send_action(msg.chat.id, 'typing')
					functions.send_reply(msg, jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!'):gsub('?%.', '?'))
					return
				end
			end
		end
	end
end
return messaging
