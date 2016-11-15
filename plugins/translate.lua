--[[

    Based on translate.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local translate = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function translate:init(configuration)
	translate.arguments = 'translate <text>'
	translate.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('translate'):c('tl').table
	translate.inlineCommands = translate.commands
	translate.help = configuration.commandPrefix .. 'translate <language> <text> - Translates input or the replied-to message into ' .. self.info.first_name .. '\'s language. Alias: ' .. configuration.commandPrefix .. 'tl.'
end

function translate:onInlineCallback(inline_query, configuration)
	local input = inline_query.query:gsub(configuration.commandPrefix .. 'translate ', ''):gsub(configuration.commandPrefix .. 'tl ', '')
	local language = mattata.getWord(input, 1)
	local jstr = HTTPS.request(configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. language .. '&text=' .. URL.escape(input:gsub(language .. ' ', '')))
	local jdat = JSON.decode(jstr)
	mattata.answerInlineQuery(inline_query.id, '[' .. mattata.generateInlineArticle(1, jdat.text[1], jdat.text[1], nil, true, 'Click to send your translation') .. ']', 0)
end

function translate:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	local url
	if message.reply_to_message then
		if not input then
			url = configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text=' .. URL.escape(message.reply_to_message.text)
			local jstr, res = HTTPS.request(url)
			if res ~= 200 then
				mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendMessage(message.chat.id, '*Translation: *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, message.message_id, nil)
			return
		end
	end
	if not input then
		mattata.sendMessage(message.chat.id, translate.help, nil, true, false, message.message_id, nil)
		return
	end
	local language = mattata.getWord(input, 1)
	url = configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. language .. '&text=' .. URL.escape(input:gsub(language .. ' ', ''))
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, '*Translation: *' .. mattata.markdownEscape(jdat.text[1]), 'Markdown', true, false, message.message_id, nil)
end

return translate
