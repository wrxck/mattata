local translate = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function translate:init(configuration)
	translate.command = 'translate (text)'
	translate.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('translate', true):t('tl', true).table
	translate.inline_triggers = translate.triggers
	translate.documentation = configuration.command_prefix .. 'translate (text) - Translates input or the replied-to message into mattata\'s language. Alias: ' .. configuration.command_prefix .. 'tl.'
end
function translate:inline_callback(inline_query, configuration)
	local url = configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text=' .. URL.escape(inline_query.query)
	local jstr = HTTPS.request(url)
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"50","title":"/translate","description":"' .. functions.md_escape(jdat.text[1]):gsub('/translate ', '') .. '","input_message_content":{"message_text":"' .. functions.md_escape(jdat.text[1]) .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function translate:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, translate.documentation)
		return
	end
	local url = configuration.apis.translate .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text=' .. URL.escape(input)
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, functions.md_escape(jdat.text[1]))
end
return translate