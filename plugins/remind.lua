local remind = {}
local mattata = require('mattata')

function remind:init(configuration)
	self.db.reminders = self.db.reminders or {}
	remind.arguments = 'remind <duration> <message>'
	remind.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('remind').table
	remind.help = configuration.commandPrefix .. 'remind <duration> <message> - Repeats a message after a duration of time, in minutes. The maximum length of a reminder is %s characters. The maximum duration of a timer is %s minutes. The maximum number of reminders for a group is %s. The maximum number of reminders in private is %s.'
	remind.help = remind.help:format(configuration.remind.maximumLength, configuration.remind.maximumDuration, configuration.remind.maximumGroupReminders, configuration.remind.maximumPrivateReminders)
end

function remind:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, remind.help, nil, true, false, message.message_id, nil)
		return
	end
	local duration = tonumber(mattata.getWord(input, 1))
	if not duration then
		mattata.sendMessage(message.chat.id, remind.help, nil, true, false, message.message_id, nil)
		return
	end
	if duration < 1 then
		duration = 1
	elseif duration > configuration.remind.maximumDuration then
		duration = configuration.remind.maximumDuration
	end
	local message
	if message.reply_to_message and #message.reply_to_message.text > 0 then
		if message.reply_to_message.from.username then
			message = message.reply_to_message.text .. ' @' .. message.reply_to_message.from.username
		else
			message = message.reply_to_message.text
		end
	elseif mattata.input(input) then
		if message.from.username then
			message = mattata.input(input) .. ' @' .. message.from.username
		else
			message = mattata.input(input)
		end
	else
		mattata.sendMessage(message.chat.id, remind.help, nil, true, false, message.message_id, nil)
		return
	end
	if #message > configuration.remind.maximumLength then
		mattata.sendMessage(message.chat.id, 'The maximum length of reminders is ' .. configuration.remind.maximumLength .. '.', nil, true, false, message.message_id, nil)
		return
	end
	local chat_id_str = tostring(message.chat.id)
	local output
	self.db.reminders[chat_id_str] = self.db.reminders[chat_id_str] or {}
	if message.chat.type == 'private' and mattata.tableSize(self.db.reminders[chat_id_str]) >= configuration.remind.maximumPrivateReminders then
		output = 'Sorry, you already have the maximum number of reminders.'
	elseif message.chat.type ~= 'private' and mattata.tableSize(self.db.reminders[chat_id_str]) >= configuration.remind.maximumGroupReminders then
		output = 'Sorry, this group already has the maximum number of reminders.'
	else
		table.insert(self.db.reminders[chat_id_str], {
			time = os.time() + (duration * 60),
			message = message
		})
		output = string.format(
			'I will remind you in *%s* minute%s!',
			duration,
			duration == 1 and '' or 's'
		)
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
end

function remind:cron(configuration)
	local time = os.time()
	for chat_id, group in pairs(self.db.reminders) do
		for k, reminder in pairs(group) do
			if time > reminder.time then
				local output = 'Reminder: ' .. reminder.message
				local res = mattata.sendMessage(chat_id, output, 'Markdown', true, false, nil, nil)
				if res or not configuration.remind.persist then
					group[k] = nil
				end
			end
		end
	end
end

return remind