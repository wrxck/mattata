--[[

    Based on patterns.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local sed = {}
local mattata = require('mattata')

function sed:init(configuration)
	sed.arguments = 's/<pattern>/<substitution>'
	sed.commands = { configuration.commandPrefix .. '?s/.-/.-$' }
	sed.help = 's/<pattern>/<substitution> - Replaces all matches for the given Lua pattern.'
end

function sed:onMessage(message)
	if not message.reply_to_message then
		return true
	end
	local matches, substitution = message.text:match('^/?s/(.-)/(.-)/?$')
	if not substitution or message.reply_to_message.from.id == self.info.id then
		return true
	end
	local res, output = pcall(
		function()
			return message.reply_to_message.text:gsub(matches, substitution)
		end
	)
	if res == false then
		mattata.sendMessage(message.chat.id, 'Invalid Lua pattern!', nil, true, false, message.message_id)
	end
	output = mattata.trim(output:sub(1, 4000))
	mattata.sendMessage(message.chat.id, '*Hi, ' .. message.reply_to_message.from.first_name .. ', are you sure you didn\'t mean:*\n' .. mattata.markdownEscape(output), 'Markdown', true, false, message.reply_to_message.message_id)
end

return sed