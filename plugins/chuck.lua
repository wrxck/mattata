local chuck = {}
local JSON = require('dkjson')
local functions = require('functions')
local HTTP = require('socket.http')
function chuck:init(configuration)
	chuck.command = 'chuck'
	chuck.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('chuck', true).table
	chuck.inline_triggers = chuck.triggers
	chuck.documentation = configuration.command_prefix .. 'chuck - Generates a Chuck Norris joke!'
end
function chuck:inline_callback(inline_query, configuration)
	local jstr = HTTP.request(configuration.apis.chuck)
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"50","title":"/chuck","description":"' .. chuck.documentation .. '","input_message_content":{"message_text":"' .. jdat.value.joke .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function chuck:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.chuck)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, functions.html_escape(jdat.value.joke))
end
return chuck