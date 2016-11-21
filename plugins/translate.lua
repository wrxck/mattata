--[[

    Based on translate.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local translate = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function translate:init(configuration)
	translate.arguments = 'translate <language> <text>'
	translate.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('translate'):c('tl').table
	translate.inlineCommands = translate.commands
	translate.help = configuration.commandPrefix .. 'translate <language> <text> - Translates input into the given language (if arguments are given), else the replied-to message is translated into ' .. self.info.first_name .. '\'s language. Alias: ' .. configuration.commandPrefix .. 'tl.'
end

function translate:onInlineCallback(inline_query, configuration, language)
	local input = mattata.input(inline_query.query)
	local translationLanguage
	if not mattata.getWord(input, 1) or string.len(mattata.getWord(input, 1)) > 2 then
		translationLanguage = language.locale
	else
		translationLanguage = mattata.getWord(input, 1)
	end
	local jstr, res = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. translationLanguage .. '&text=' .. URL.escape(input:gsub(translationLanguage .. ' ', '')))
	if res ~= 200 then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = {
					message_text = language.errors.connection
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = JSON.decode(jstr)
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = jdat.text[1],
			description = 'Click to send your translation.',
			input_message_content = {
				message_text = jdat.text[1]
			}
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function translate:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		if channel_post.reply_to_message then
			local jstr, res = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text=' .. URL.escape(channel_post.reply_to_message.text))
			if res ~= 200 then
				mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendMessage(channel_post.chat.id, '*Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '): *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, translate.help, nil, true, false, channel_post.message_id)
		return
	end
	local translationLanguage
	if not mattata.getWord(input, 1) or string.len(mattata.getWord(input, 1)) > 2 then
		translationLanguage = configuration.language
	else
		translationLanguage = mattata.getWord(input, 1)
	end
	local jstr, res = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. translationLanguage .. '&text=' .. URL.escape(input:gsub(translationLanguage .. ' ', '')))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, '*Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '): *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, channel_post.message_id)
end

function translate:onMessageReceive(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		if message.reply_to_message then
			local jstr, res = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. URL.escape(message.reply_to_message.text))
			if res ~= 200 then
				mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendMessage(message.chat.id, '*Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '): *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, translate.help, nil, true, false, message.message_id)
		return
	end
	local translationLanguage
	if not mattata.getWord(input, 1) or string.len(mattata.getWord(input, 1)) > 2 then
		translationLanguage = language.locale
	else
		translationLanguage = mattata.getWord(input, 1)
	end
	local jstr, res = HTTPS.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. translationLanguage .. '&text=' .. URL.escape(input:gsub(translationLanguage .. ' ', '')))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, '*Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '): *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, message.message_id)
end

return translate