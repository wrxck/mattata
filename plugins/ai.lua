local ai = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local cleverbot = require('mattata-ai')

function ai:onInlineQuery(inline_query, configuration, language)
	local input = inline_query.query:gsub('^' .. configuration.commandPrefix .. 'ai ', '')
	local output = cleverbot.init():talk(inline_query.query)
	if not output then return false end
	local results
	if language ~= 'en' then
		local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. url.escape(output))
		if res == 200 then local jdat = json.decode(jstr); output = jdat.text[1] end
		results = json.encode({{
			type = 'article',
			id = '1',
			title = 'mattata: ' .. output,
			description = 'You: ' .. input,
			input_message_content = { message_text = '*Me:* ' .. mattata.markdownEscape(input) .. ' *| mattata:* ' .. mattata.markdownEscape(output), parse_mode = 'Markdown' }
		}})
	else
		results = json.encode({{
			type = 'article',
			id = '1',
			title = 'mattata: ' .. language.aiError:gsub('NAME', inline_query.from.first_name),
			description = 'You: ' .. input,
			input_message_content = { message_text = '*Me:* ' .. mattata.markdownEscape(input) .. ' *| mattata:* ' .. mattata.markdownEscape(language.aiError:gsub('NAME', inline_query.from.first_name)), parse_mode = 'Markdown' }
		}})
	end
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function ai:onMessage(message, configuration, language)
	if message.text_lower:match('^' .. configuration.commandPrefix) then return end
	mattata.sendChatAction(message.chat.id, 'typing')
	local output = cleverbot.init():talk(message.text_lower)
	if not output then return end
	if language.locale ~= 'en' then
		local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. url.escape(output))
		if res == 200 then local jdat = json.decode(jstr); output = jdat.text[1] end
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return ai