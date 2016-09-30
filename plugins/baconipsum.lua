local baconipsum = {}
local functions = require('functions')
local HTTPS = require('ssl.https')
function baconipsum:init(configuration)
	baconipsum.command = 'baconipsum'
	baconipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('baconipsum', true).table
	baconipsum.inline_triggers = baconipsum.triggers
	baconipsum.doc = configuration.command_prefix .. 'baconipsum - Generate a few meaty Lorem Ipsum sentences!'
end
function baconipsum:inline_callback(inline_query, configuration)
    local str, res = HTTPS.request(configuration.baconipsum_api)
    local output = '`' .. str .. '`'
	local results = '[{"type":"article","id":"10","title":"/baconipsum","description":"Generate a few meaty Lorem Ipsum sentences!","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 900)
end
function baconipsum:action(msg, configuration)
    local str, res = HTTPS.request(configuration.baconipsum_api)
    if res ~= 200 then
    	functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
    	return
    else
    	local output = '`' .. str .. '`'
    	functions.send_reply(msg, output, true)
    	return
    end
end
return baconipsum