local bible = {}
local HTTP = require('dependencies.socket.http')
local URL = require('dependencies.socket.url')
local functions = require('functions')
function bible:init(configuration)
	bible.command = 'bible <reference>'
	bible.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('bible', true).table
	bible.inline_triggers = bible.triggers
	bible.documentation = configuration.command_prefix .. 'bible <reference> - Returns a verse from the American Standard Version of the Bible. Results from biblia.com.'
end
function bible:inline_callback(inline_query, configuration)
	local url = configuration.apis.bible .. configuration.keys.bible .. '&passage=' .. URL.escape(inline_query.query)
    local output = HTTP.request(url)
	if output:len() > 4000 then
		output = 'The requested passage is too long to post here. Please, try and be more specific.'
	end
	local results = '[{"type":"article","id":"50","title":"/bible","description":"' .. bible.documentation .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function bible:action(msg, configuration)
	local input = functions.input_from_msg(msg)
	if not input then
		functions.send_reply(msg, bible.documentation)
		return
	end
	local url = configuration.apis.bible .. configuration.keys.bible .. '&passage=' .. URL.escape(input)
	local output, res = HTTP.request(url)
	if not output or res ~= 200 or output:len() == 0 then
		output = configuration.errors.results
	end
	if output:len() > 4000 then
		output = 'The requested passage is too long to post here. Please, try and be more specific.'
	end
	functions.send_reply(msg, output)
end
return bible