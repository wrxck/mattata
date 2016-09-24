local translate = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function translate:init(configuration)
	translate.command = 'translate (text)'
	translate.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('translate', true):t('tl', true).table
	translate.doc = configuration.command_prefix .. 'translate (text) - Translates input or the replied-to message into mattata\'s language. Alias: ' .. configuration.command_prefix .. 'tl.'
end
function translate:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_message(msg.chat.id, translate.doc, true, msg.message_id, true)
			return
		end
	end
	local url = configuration.translate_api .. configuration.translate_key .. '&lang=' .. configuration.language .. '&text=' .. URL.escape(input)
	local str, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(str)
	if jdat.code ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	functions.send_reply(msg.reply_to_message or msg, '`' .. functions.md_escape(jdat.text[1]) .. '`', true)
end
return translate