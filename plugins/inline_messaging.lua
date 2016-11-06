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
	mattata.answerInlineQuery(inline_query.id, '[' .. mattata.generateInlineArticle(1, 'mattata: ' .. jdat.clever, '*Me:* ' .. mattata.markdownEscape(input) .. ' *| mattata:* ' .. mattata.markdownEscape(jdat.clever), 'Markdown', false, 'You: ' .. input) .. ']', 0)
end

return inline_messaging