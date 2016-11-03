local bandersnatch = {}
local mattata = require('mattata')

function bandersnatch:init(configuration)
	bandersnatch.arguments = 'bandersnatch'
	bandersnatch.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bandersnatch').table
	bandersnatch.inlineCommands = bandersnatch.commands
	bandersnatch.help = configuration.commandPrefix .. 'bandersnatch - Generates a fun, tongue-twisting name.'
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
	mattata.answerInlineQuery(inline_query.id, '[' .. mattata.generateInlineArticle(1, output, output, 'Markdown', false, 'bandersnatch') .. ']', 0)
end

function bandersnatch:onMessageReceive(message, configuration)
	local fullnames = configuration.bandersnatch.fullNames
	local firstnames = configuration.bandersnatch.firstNames
	local lastnames = configuration.bandersnatch.lastNames
	if math.random(10) == 10 then
		local output = fullnames[math.random(#fullnames)]
	else
		local output = firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)]
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return bandersnatch