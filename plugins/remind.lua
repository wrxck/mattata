local remind = {}
local mattata = require('mattata')

function remind:init(configuration)
	self.db.reminders = self.db.reminders or {}
	remind.arguments = 'remind <duration> <message>'
	remind.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('remind', true).table
	remind.help = configuration.commandPrefix .. 'remind <duration> <message> - Repeats a message after a duration of time, in minutes. The maximum length of a reminder is %s characters. The maximum duration of a timer is %s minutes. The maximum number of reminders for a group is %s. The maximum number of reminders in private is %s.'
	remind.help = remind.help:format(configuration.remind.maximumLength, configuration.remind.maximumDuration, configuration.remind.maximumGroupReminders, configuration.remind.maximumPrivateReminders)
end

function remind:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, remind.help, nil, true, false, msg.message_id, nil)
		return
	end
	local duration = tonumber(mattata.getWord(input, 1))
	if not duration then
		mattata.sendMessage(msg.chat.id, remind.help, nil, true, false, msg.message_id, nil)
		return
	end
	if duration < 1 then
		duration = 1
	elseif duration > configuration.remind.maximumDuration then
		duration = configuration.remind.maximumDuration
	end
	local message
	if msg.reply_to_message and #msg.reply_to_message.text > 0 then
		if msg.reply_to_message.from.username then
			message = msg.reply_to_message.text .. ' @' .. msg.reply_to_message.from.username
		else
			message = msg.reply_to_message.text
		end
	elseif mattata.input(input) then
		if msg.from.username then
			message = mattata.input(input) .. ' @' .. msg.from.username
		else
			message = mattata.input(input)
		end
	else
		mattata.sendMessage(msg.chat.id, remind.help, nil, true, false, msg.message_id, nil)
		return
	end
	if #message > configuration.remind.maximumLength then
		mattata.sendMessage(msg.chat.id, 'The maximum length of reminders is ' .. configuration.remind.maximumLength .. '.', nil, true, false, msg.message_id, nil)
		return
	end
	local chat_id_str = tostring(msg.chat.id)
	local output
	self.db.reminders[chat_id_str] = self.db.reminders[chat_id_str] or {}
	if msg.chat.type == 'private' and mattata.table_size(self.db.reminders[chat_id_str]) >= configuration.remind.maximumPrivateReminders then
		output = 'Sorry, you already have the maximum number of reminders.'
	elseif msg.chat.type ~= 'private' and mattata.table_size(self.db.reminders[chat_id_str]) >= configuration.remind.maximumGroupReminders then
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
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

function remind:cron(configuration)
	local time = os.time()
	for chat_id, group in pairs(self.db.reminders) do
		for k, reminder in pairs(group) do
			if time > reminder.time then
				local output = 'Reminder: ' .. reminder.message
				local res = mattata.sendMessage(chat_id, output, 'Markdown', true, false, msg.message_id, nil)
				if res or not configuration.remind.persist then
					group[k] = nil
				end
			end
		end
	end
end

return remind