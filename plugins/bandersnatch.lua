--[[

    Based on bandersnatch.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

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
	local fullNames = configuration.bandersnatch.fullNames
	local firstNames = configuration.bandersnatch.firstNames
	local lastNames = configuration.bandersnatch.lastNames
	if math.random(10) == 10 then
		output = fullNames[math.random(#fullNames)]
	else
		output = firstNames[math.random(#firstNames)] .. ' ' .. lastNames[math.random(#lastNames)]
	end
	mattata.answerInlineQuery(inline_query.id, '[' .. mattata.generateInlineArticle(1, output, output, 'Markdown', false, 'Click to send your new name!') .. ']', 0)
end

function bandersnatch:onMessageReceive(message, configuration)
	local fullNames = configuration.bandersnatch.fullNames
	local firstNames = configuration.bandersnatch.firstNames
	local lastNames = configuration.bandersnatch.lastNames
	if math.random(10) == 10 then
		local output = fullNames[math.random(#fullNames)]
	else
		local output = firstNames[math.random(#firstNames)] .. ' ' .. lastNames[math.random(#lastNames)]
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return bandersnatch
