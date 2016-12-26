local sed = {}
local mattata = require('mattata')
local json = require('dkjson')

function sed:init(configuration)
	sed.arguments = 's/<pattern>/<substitution>'
	sed.commands = { configuration.commandPrefix .. '?s/.-/.-$' }
	sed.help = 's/<pattern>/<substitution> - Replaces all matches for the given Lua pattern.'
end

function sed:onCallbackQuery(callback_query, message, configuration)
	if callback_query.data:match('^yes$') then
		mattata.editMessageText(message.chat.id, message.message_id, message.text .. '\n\n<i>' .. mattata.htmlEscape(callback_query.from.first_name) .. ' is confident they didn\'t mean this!</i>', 'HTML', true)
		return
	elseif callback_query.data:match('^no$') then
		mattata.editMessageText(message.chat.id, message.message_id, message.text .. '\n\n<i>WELP! ' .. mattata.htmlEscape(callback_query.from.first_name) .. ' admitted defeat...</i>', 'HTML', true)
		return
	end
end

function sed:onMessage(message)
	if not message.reply_to_message then return end
	local matches, substitution = message.text:match('^/?s/(.-)/(.-)/?g?$')
	substitution = substitution:gsub('\\n', '\n'):gsub('\\/', '/')
	if not substitution then return
	elseif message.reply_to_message.from.id == self.info.id then
		mattata.sendMessage(message.chat.id, 'Screw you, I\'m always right.', nil, true, false, message.message_id)
		return
	end
	local res, output = pcall(function() return message.reply_to_message.text:gsub(matches, substitution) end)
	if not res then
		mattata.sendMessage(message.chat.id, 'Invalid Lua pattern!', nil, true, false, message.message_id)
	end
	output = mattata.trim(output:sub(1, 4096))
	if output == message.reply_to_message.text then mattata.sendMessage(message.chat.id, 'You\'re retarded... There\'s literally no difference after applying that substitution.', nil, true, false, message.reply_to_message.id) return end
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = 'I\'m sure', callback_data = 'sed:yes' },
		{ text = '😭', callback_data = 'sed:no' }
	}}
	mattata.sendMessage(message.chat.id, 'Hi, ' .. mattata.htmlEscape(message.reply_to_message.from.first_name) .. ', are you sure you didn\'t mean:\n' .. mattata.htmlEscape(output), 'HTML', true, false, message.reply_to_message.message_id, json.encode(keyboard))
end

return sed