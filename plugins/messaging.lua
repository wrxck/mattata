local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local messaging = {}
function messaging:init(configuration)
	messaging.triggers = {
		'^' .. '' .. ''
	}
	messaging.inline_triggers = messaging.triggers
end
function messaging:inline_callback(inline_query, configuration, matches)
	local input = inline_query.query
	local jstr, code = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"9","title":"Talk with mattata, inline!","description":"Start typing to see the response","input_message_content":{"message_text":"Me: ' .. input .. ' | mattata: ' .. jdat.clever..'"}}]'
	functions.answer_inline_query(inline_query, results, 600, nil, nil, 'Me: ' .. input .. ' | ' .. self.info.first_name .. ': ' .. jdat.clever)
end
function messaging:action(msg, configuration)
	local input = msg.text_lower:gsub(self.info.first_name .. ' ', ''):gsub(self.info.first_name .. ', ','')
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
		if string.match(msg.text, self.info.first_name) then
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, '`' .. jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!') .. '`', true)
			return		
		elseif msg.reply_to_message then
			if msg.reply_to_message.from.id == self.id then
				functions.send_action(msg.chat.id, 'typing')
				functions.send_reply(msg, '`' .. jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!') .. '`', true)
				return
			end
		end
	elseif msg.chat.type == 'group' then
		if string.match(msg.text, self.info.first_name) then
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, '`' .. jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!') .. '`', true)
			return		
		elseif msg.reply_to_message then
			if msg.reply_to_message.from.id == self.id then
				functions.send_action(msg.chat.id, 'typing')
				functions.send_reply(msg, '`' .. jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!') .. '`', true)
				return
			end
		end
	elseif msg.chat.type == 'channel' then
		if string.match(msg.text, self.info.first_name) then
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, '`' .. jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!') .. '`', true)
			return		
		elseif msg.reply_to_message then
			if msg.reply_to_message.from.id == self.id then
				functions.send_action(msg.chat.id, 'typing')
				functions.send_reply(msg, '`' .. jdat.clever:gsub('Hakuna Matata.', 'I\'m mattata!'):gsub('Hakuna.', 'I\'m mattata!') .. '`', true)
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
			functions.send_action(msg.chat.id, 'typing')
			functions.send_reply(msg, '`' .. jdat.clever .. '`', true)
			return
		end
	end
end
return messaging