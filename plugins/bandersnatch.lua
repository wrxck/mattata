local bandersnatch = {}
local mattata = require('mattata')

function bandersnatch:init(configuration)
	bandersnatch.arguments = 'bandersnatch'
	bandersnatch.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bandersnatch', true).table
	bandersnatch.inlineCommands = bandersnatch.commands
	bandersnatch.help = configuration.commandPrefix .. 'bandersnatch - Shun the frumious Bandersnatch (whatever THAT means...) Alias: ' .. configuration.commandPrefix .. 'bs.'
end

function bandersnatch:onInlineCallback(inline_query, configuration)
    local output
	local fullnames = configuration.bandersnatch.fullNames
	local firstnames = configuration.bandersnatch.firstNames
	local lastnames = configuration.bandersnatch.lastNames
	if math.random(10) == 10 then
		output = fullnames[math.random(#fullnames)]
	else
		output = firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)]
	end
	local results = '[{"type":"article","id":"1","title":"/bandersnatch","description":"' .. output .. '","input_message_content":{"message_text":"' .. output .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function bandersnatch:onMessageReceive(msg, configuration)
	local output = ''
	local fullnames = configuration.bandersnatch.fullNames
	local firstnames = configuration.bandersnatch.firstNames
	local lastnames = configuration.bandersnatch.lastNames
	if math.random(10) == 10 then
		output = fullnames[math.random(#fullnames)]
	else
		output = firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)]
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, '{"inline_keyboard":[[{"text":"Generate a new name!", "callback_data":"bandersnatch"}]]}')
end

return bandersnatch