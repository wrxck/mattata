local warn = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local JSON = require('dkjson')

function warn:init(configuration)
	warn.arguments = 'warn'
	warn.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('warn').table
	warn.help = configuration.commandPrefix .. 'warn - Warn the replied-to user.'
end

function warn:onCallbackQuery(callback_query, message, configuration)
	if not mattata.isGroupAdmin(message.chat.id, callback_query.from.id) then return
	elseif callback_query.data:match('^reset:(.-)$') then
		redis:hdel('chat:' .. message.chat.id .. ':warnings', callback_query.data:match('^reset:(.-)$'))
		mattata.editMessageText(message.chat.id, message.message_id, 'Warnings reset by ' .. callback_query.from.first_name, nil, true)
		return
	elseif callback_query.data:match('^remove:(.-)$') then
		local amount = redis:hincrby('chat:' .. message.chat.id .. ':warnings', callback_query.data:match('^remove:(.-)$'), -1)
		local text, maximum, difference
		if tonumber(amount) < 0 then
			text = 'The number of warnings received by this user is already zero!'
			redis:hincrby('chat:' .. message.chat.id .. ':warnings', callback_query.data:match('^remove:(.-)$'), 1)
		else
			maximum = 3
			difference = maximum - amount
			text = 'Warning removed! (%d/%d)'
			text = text:format(tonumber(amount), tonumber(maximum))
		end
		mattata.editMessageText(message.chat.id, message.message_id, text, nil, true)
		return
	end
end

function warn:onMessage(message, configuration)
	if message.chat.type ~= 'private' and mattata.isGroupAdmin(message.chat.id, message.from.id) then return
	elseif not message.reply_to_message or mattata.isGroupAdmin(message.chat.id, message.reply_to_message.from.id) then
		mattata.sendMessage(message.chat.id, 'Either the targeted user is a group administrator, or you haven\'t send this message as a reply.', nil, true, false, message.message_id)
		return
	end
	local name = message.reply_to_message.from.first_name
	local hash = 'chat:' .. message.chat.id .. ':warnings'
	local amount = redis:hincrby(hash, message.reply_to_message.from.id, 1)
	local maximum = 3
	local text, res
	amount, maximum = tonumber(amount), tonumber(maximum)
	if amount >= maximum then
		text = message.reply_to_message.from.first_name .. ' was banned for reaching the maximum number of allowed warnings (' .. maximum .. ').'
		res = mattata.kickChatMember(message.chat.id, message.reply_to_message.from.id)
		if not res then
			mattata.sendMessage(message.chat.id, 'I couldn\'t ban that user. Please ensure that I\'m an administrator and that the targeted user isn\'t.', nil, true, false, message.message_id)
			return
		end
		redis:hdel('chat:' .. message.chat.id .. ':warnings', message.reply_to_message.from.id)
		mattata.sendMessage(message.chat.id, text, nil, true, false, message.message_id)
		return
	end
	local difference = maximum - amount
	text = '*%s* has been warned `[`%d/%d`]`'
	if message.text_lower ~= configuration.commandPrefix .. 'warn' then text = text .. '\n*Reason:* ' .. mattata.markdownEscape(message.text_lower:gsub('^' .. configuration.commandPrefix .. 'warn ', '')) end
	text = text:format(mattata.markdownEscape(name), amount, maximum)
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = 'Remove Warning', callback_data = 'warn:remove:' .. message.reply_to_message.from.id },
		{ text = 'Reset Warnings', callback_data = 'warn:reset:' .. message.reply_to_message.from.id }
	}}
	mattata.sendMessage(message.chat.id, text, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
	return
end

return warn