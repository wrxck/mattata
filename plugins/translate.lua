local translate = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function translate:init(configuration)
	translate.arguments = 'translate (text)'
	translate.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('translate', true):c('tl', true).table
	translate.inlineCommands = translate.commands
	translate.help = configuration.commandPrefix .. 'translate (text) - Translates input or the replied-to message into ' .. self.info.first_name .. '\'s language. Alias: ' .. configuration.commandPrefix .. 'tl.'
end

function translate:onInlineCallback(inline_query, configuration)
	local url = configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text=' .. URL.escape(inline_query.query)
	local jstr = HTTPS.request(url)
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"1","title":"/translate","description":"' .. mattata.markdownEscape(jdat.text[1]):gsub('/translate ', '') .. '","input_message_content":{"message_text":"' .. mattata.markdownEscape(jdat.text[1]) .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function translate:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	local url = configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text='
	if msg.reply_to_message then
		if not input then
			url = url .. URL.escape(msg.reply_to_message.text)
			local jstr, res = HTTPS.request(url)
			if res ~= 200 then
				mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendMessage(msg.chat.id, '*Translation: *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, msg.message_id, nil)
			return
		end
	else
		if not input then
			mattata.sendMessage(msg.chat.id, translate.help, nil, true, false, msg.message_id, nil)
			return
		end
		url = url .. URL.escape(input)
		local jstr, res = HTTPS.request(url)
		if res ~= 200 then
			mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
			return
		end
		local jdat = JSON.decode(jstr)
		mattata.sendMessage(msg.chat.id, '*Translation: *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, msg.message_id, nil)
		return
	end
end

return translate