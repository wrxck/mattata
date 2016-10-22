local messaging = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function messaging:init(configuration)
	messaging.commands = { '^' .. 'mattata' .. '' }
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
	local input = msg.text_lower:gsub(self.info.first_name, ' ')
	local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	if res ~= 200 then
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendChatAction(msg.chat.id, 'typing')
	mattata.sendMessage(msg.chat.id, jdat.clever, nil, true, false, msg.message_id, nil)
end

return messaging