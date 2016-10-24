local messaging = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function messaging:init(configuration)
	messaging.commands = { '^' .. '' .. '' }
	messaging.inlineCommands = { '^' .. '' .. '' }
end

function messaging:onInlineCallback(inline_query, configuration)
	local input = inline_query.query
	local jstr = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"1","title":"Talk with mattata, inline!","description":"Start typing to see the response","input_message_content":{"message_text":"Me: ' .. input .. ' | mattata: ' .. jdat.clever..'"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function messaging:onMessageReceive(msg, configuration)
	if string.match(msg.text_lower, 'mattata') then
		local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(msg.text_lower))
		if res ~= 200 then
			return
		end
		local jdat = JSON.decode(jstr)
		mattata.sendChatAction(msg.chat.id, 'typing')
		mattata.sendMessage(msg.chat.id, jdat.clever, nil, true, false, msg.message_id, nil)
		return
	elseif string.match(msg.text_lower, '@appledog') then
		mattata.sendPhoto(msg.chat.id, 'https://www.pixilart.net/images/art/d69775a2f30926e.gif', nil, false, msg.message_id, nil)
		return
	elseif msg.reply_to_message then
		if msg.reply_to_message.from.id == self.info.id then
			local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(msg.text_lower))
			if res ~= 200 then
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendChatAction(msg.chat.id, 'typing')
			mattata.sendMessage(msg.chat.id, jdat.clever, nil, true, false, msg.message_id, nil)
		end
	end
end

return messaging