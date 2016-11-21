local ai = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function ai:onInlineCallback(inline_query, configuration, language)
	local input = inline_query.query:gsub(configuration.commandPrefix .. 'ai ', '')
	local jstr, res = HTTPS.request('https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text=' .. URL.escape(input))
	if not res then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'mattata: ' .. language.aiError:gsub('NAME', inline_query.from.first_name),
				description = 'You: ' .. input,
				input_message_content = {
					message_text = '*Me:* ' .. mattata.markdownEscape(input) .. ' *| mattata:* ' .. mattata.markdownEscape(language.aiError:gsub('NAME', inline_query.from.first_name)),
					parse_mode = 'Markdown'
				}
			}
		})
	end
	local jdat = JSON.decode(jstr)
	local output = jdat.clever
	local translationJstr, translationRes = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. output)
	if translationRes == 200 then
		jdat = JSON.decode(translationJstr)
		output = jdat.text[1]
	end
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = 'mattata: ' .. output,
			description = 'You: ' .. input,
			input_message_content = {
				message_text = '*Me:* ' .. mattata.markdownEscape(input) .. ' *| mattata:* ' .. mattata.markdownEscape(output),
				parse_mode = 'Markdown'
			}
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function ai:onChannelPostReceive(channel_post, configuration)
	if not channel_post.text_lower:match('^' .. configuration.commandPrefix) then
		local input = mattata.input(channel_post.text_lower)
		local jstr, res = HTTPS.request('https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text=' .. URL.escape(input))
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, 'I dont\'t feel like talking right now...', nil, true, false, channel_post.message_id)
			return
		end
		local jdat = JSON.decode(jstr)
		mattata.sendMessage(channel_post.chat.id, jdat.clever, nil, true, false, channel_post.message_id)
		return
	end
end

function ai:onMessageReceive(message, configuration, language)
	if not message.text_lower:match('^' .. configuration.commandPrefix) then
		mattata.sendChatAction(message.chat.id, 'typing')
		local input = message.text_lower
		local jstr, res = HTTPS.request('https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text=' .. URL.escape(input))
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, language.aiError:gsub('NAME', message.from.first_name), nil, true, false, message.message_id)
			return
		end
		local jdat = JSON.decode(jstr)
		local output = jdat.clever
		local translationJstr, translationRes = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. output)
		if translationRes == 200 then
			jdat = JSON.decode(translationJstr)
			output = jdat.text[1]
		end
		mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
		return
	end
end

return ai