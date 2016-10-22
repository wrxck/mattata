local patterns = {}
local mattata = require('mattata')

function patterns:init(configuration)
	patterns.arguments = 's/<pattern>/<substitution>'
	patterns.help_word = 'sed'
	patterns.commands = { configuration.commandPrefix .. '?s/.-/.-$' }
	patterns.help = configuration.commandPrefix .. 's/<pattern>/<substitution> Replace all matches for the Lua pattern(s).'
end

function patterns:onMessageReceive(msg)
	if not msg.reply_to_message then
		return true
	end
	local output = msg.reply_to_message.text
	if msg.reply_to_message.from.id == self.info.id then
		output = output:gsub('Did you mean:\n"', '')
		output = output:gsub('"$', '')
	end
	local m1, m2 = msg.text:match('^/?s/(.-)/(.-)/?$')
	if not m2 then
		return true
	end
	local res
	res, output = pcall(
		function()
			return output:gsub(m1, m2)
		end
	)
	if res == false then
		mattata.sendMessage(msg.chat.id, 'Invalid pattern.', nil, true, false, msg.message_id, nil)
	else
		output = '*Uh... ' .. msg.reply_to_message.from.first_name .. '? Are you sure you didn\'t mean:*\n' .. mattata.trim(output:sub(1, 4000))
		mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
	end
end

return patterns