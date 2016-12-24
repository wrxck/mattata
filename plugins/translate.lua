local translate = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function translate:init(configuration)
	translate.arguments = 'translate <language> <text>'
	translate.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('translate'):command('tl').table
	translate.help = configuration.commandPrefix .. 'translate <language> <text> - Translates input into the given language (if arguments are given), else the replied-to message is translated into ' .. self.info.first_name .. '\'s language. Alias: ' .. configuration.commandPrefix .. 'tl.'
end

function translate:onInlineQuery(inline_query, configuration, language)
	local input = mattata.input(inline_query.query)
	local translationLanguage = ''
	if not mattata.getWord(input, 1) or mattata.getWord(input, 1):len() > 2 then
		translationLanguage = language.locale
	else
		translationLanguage = mattata.getWord(input, 1)
	end
	local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. translationLanguage .. '&text=' .. url.escape(input:gsub(translationLanguage .. ' ', '')))
	if res ~= 200 then
		local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'An error occured!',
			description = language.errors.connection,
			input_message_content = { message_text = language.errors.connection }
		}})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = json.decode(jstr)
	local results = json.encode({{
		type = 'article',
		id = '1',
		title = jdat.text[1],
		description = 'Click to send your translation.',
		input_message_content = { message_text = jdat.text[1] }
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
	return
end

function translate:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		if not message.reply_to_message then
			mattata.sendMessage(message.chat.id, translate.help, nil, true, false, message.message_id)
			return
		end
		local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. url.escape(message.reply_to_message.text))
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
			return
		end
		local jdat = json.decode(jstr)
		mattata.sendMessage(message.chat.id, '<b>Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '):</b>\n' .. mattata.htmlEscape(jdat.text[1]), 'HTML', true, false, message.message_id)
		return
	end
	local translationLanguage
	if not mattata.getWord(input, 1) or mattata.getWord(input, 1):len() > 2 then
		translationLanguage = language.locale
	else
		translationLanguage = mattata.getWord(input, 1)
	end
	local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. translationLanguage .. '&text=' .. url.escape(input:gsub(translationLanguage .. ' ', '')))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	mattata.sendMessage(message.chat.id, '<b>Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '):</b>\n' .. mattata.htmlEscape(jdat.text[1]), 'HTML', true, false, message.message_id)
end

return translate