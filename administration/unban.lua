local unban = {}
local mattata = require('mattata')

function unban:init(configuration)
	unban.arguments = 'unban <user>'
	unban.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('unban').table
	unban.help = configuration.commandPrefix .. 'unban <user> - Unbans the given user (or the replied-to user, if no username or ID is specified) from the chat.'
end

function unban:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if message.chat.type ~= 'supergroup' or not mattata.isGroupAdmin(message.chat.id, message.from.id) then return
	elseif not message.reply_to_message and not input then
		mattata.sendMessage(message.chat.id, 'Please reply-to the user you\'d like to unban, or specify them by username/ID.', nil, true, false, message.message_id)
		return
	elseif message.reply_to_message then
		if mattata.isGroupAdmin(message.chat.id, message.reply_to_message.from.id) then
			mattata.sendMessage(message.chat.id, 'I can\'t unban that user, they\'re an administrator in this chat.', nil, true, false, message.message_id)
			return
		elseif message.reply_to_message.from.id == self.info.id then return end
		local res = mattata.unbanChatMember(message.chat.id, message.reply_to_message.from.id)
		if not res then
			mattata.sendMessage(message.chat.id, 'I couldn\'t unban ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.', nil, true, false, message.message_id)
			return
		end
		local output = message.from.first_name .. ' [' .. message.from.id .. '] has unbanned ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
		if input then output = output .. '\nReason: ' .. input end
		if configuration.logAdministrativeActions and configuration.administrationLog ~= '' then
			mattata.sendMessage(configuration.administrationLog, '<pre>' .. mattata.htmlEscape(output) .. '</pre>', 'HTML', true, false)
		end
		mattata.sendMessage(message.chat.id, '<pre>' .. mattata.htmlEscape(output) .. '</pre>', 'HTML', true, false)
		return
	else
		if tonumber(input) == nil and not input:match('^@') then input = '@' .. input end
		local resolved = mattata.request('getChat', { chat_id = tostring(input) }, nil, 'https://api.pwrtelegram.xyz/bot')
		if not resolved then
			mattata.sendMessage(message.chat.id, 'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.', nil, true, false, message.message_id)
			return
		elseif resolved.result.type ~= 'private' then
			mattata.sendMessage(message.chat.id, 'That\'s a ' .. resolved.result.type .. ', not a user!', nil, true, false, message.message_id)
			return
		end
		if mattata.isGroupAdmin(message.chat.id, resolved.result.id) then
			mattata.sendMessage(message.chat.id, 'I can\'t unban that user, they\'re an administrator in this chat.', nil, true, false, message.message_id)
			return
		elseif resolved.result.id == self.info.id then return end
		local res = mattata.unbanChatMember(message.chat.id, resolved.result.id)
		if not res then
			mattata.sendMessage(message.chat.id, 'I couldn\'t unban ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.', nil, true, false, message.message_id)
			return
		end
		local output = message.from.first_name .. ' [' .. message.from.id .. '] has unbanned ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
		if configuration.logAdministrativeActions and configuration.administrationLog ~= '' then
			mattata.sendMessage(configuration.administrationLog, '<pre>' .. mattata.htmlEscape(output) .. '</pre>', 'HTML', true, false)
		end
		mattata.sendMessage(message.chat.id, '<pre>' .. mattata.htmlEscape(output) .. '</pre>', 'HTML', true, false)
		return
	end
end

return unban