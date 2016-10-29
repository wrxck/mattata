local inline_messaging = {}
local mattata = require('mattata')
local JSON = require('dkjson')
local HTTPS = require('ssl.https')
local URL = require('socket.url')

function inline_messaging:init(configuration)
	inline_messaging.inlineCommands = { '^' .. configuration.commandPrefix .. 'ai' }
end

function inline_messaging:onInlineCallback(inline_query, configuration)
	local input = inline_query.query:gsub(configuration.commandPrefix .. 'ai ', '')
	local jstr = HTTPS.request(configuration.messaging.url .. URL.escape(input))
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"1","title":"mattata: ' .. jdat.clever .. '","description":"You: ' .. input .. '","input_message_content":{"message_text":"Me: ' .. input .. ' | mattata: ' .. jdat.clever..'"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

return inline_messaging