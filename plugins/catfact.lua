local catfact = {}
local JSON = require('dkjson')
local functions = require('functions')
local HTTP = require('socket.http')
function catfact:init(configuration)
	catfact.command = 'catfact'
	catfact.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('catfact', true).table
	catfact.inline_triggers = catfact.triggers
	catfact.documentation = configuration.command_prefix .. 'catfact - A random cat-related fact!'
end
function catfact:inline_callback(inline_query, configuration)
	local jstr = HTTP.request(configuration.apis.catfact)
	local jdat = JSON.decode(jstr)
	local results = '[{"type":"article","id":"50","title":"/catfact","description":"' .. catfact.documentation .. '","input_message_content":{"message_text":"' .. jdat.facts[1] .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function catfact:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.catfact)
	local jdat = JSON.decode(jstr)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	functions.send_reply(msg, jdat.facts[1]:gsub('â', ' '))
end
return catfact