local baconipsum = {}
local functions = require('functions')
local HTTPS = require('ssl.https')
function baconipsum:init(configuration)
	baconipsum.command = 'baconipsum'
	baconipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('baconipsum', true).table
	baconipsum.inline_triggers = baconipsum.triggers
	baconipsum.documentation = configuration.command_prefix .. 'baconipsum - Generate a few meaty Lorem Ipsum sentences!'
end
function baconipsum:inline_callback(inline_query, configuration)
    local str, res = HTTPS.request(configuration.apis.baconipsum)
    local output = '`' .. str .. '`'
	local results = '[{"type":"article","id":"50","title":"/baconipsum","description":"' .. output:gsub('`', '') .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function baconipsum:action(msg, configuration)
    local output, res = HTTPS.request(configuration.apis.baconipsum)
    if res ~= 200 then
    	functions.send_reply(msg, configuration.errors.connection)
    	return
    end
    functions.send_reply(msg, output)
end
return baconipsum