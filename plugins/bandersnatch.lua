local bandersnatch = {}
local functions = require('functions')
function bandersnatch:init(configuration)
	bandersnatch.command = 'bandersnatch'
	bandersnatch.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('bandersnatch', true).table
	bandersnatch.inline_triggers = bandersnatch.triggers
	bandersnatch.documentation = configuration.command_prefix .. 'bandersnatch - Shun the frumious Bandersnatch (whatever THAT means...) Alias: ' .. configuration.command_prefix .. 'bs.'
end
function bandersnatch:inline_callback(inline_query, configuration)
    local output = ''
	local fullnames = configuration.bandersnatch.full_names
	local firstnames = configuration.bandersnatch.first_names
	local lastnames = configuration.bandersnatch.last_names
	if math.random(10) == 10 then
		output = fullnames[math.random(#fullnames)]
	else
		output = firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)]
	end
	local results = '[{"type":"article","id":"50","title":"/bandersnatch","description":"' .. output .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 50)
end
function bandersnatch:action(msg, configuration)
	local output = ''
	local fullnames = configuration.bandersnatch.full_names
	local firstnames = configuration.bandersnatch.first_names
	local lastnames = configuration.bandersnatch.last_names
	if math.random(10) == 10 then
		output = fullnames[math.random(#fullnames)]
	else
		output = firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)]
	end
	functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Generate a new name!", "callback_data":"bandersnatch"}]]}')
end
return bandersnatch