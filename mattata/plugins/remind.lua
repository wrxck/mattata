local remind = {}

local utilities = require('mattata.utilities')

remind.command = 'remind <duration> <message>'

function remind:init(config)
	self.database.reminders = self.database.reminders or {}

	remind.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('remind', true).table
	remind.doc = config.cmd_pat .. 'remind <duration> <message> \nRepeats a message after a duration of time, in minutes.'
end

function remind:action(msg)

	local input = utilities.input(msg.text)
	if not input then
		utilities.send_message(self, msg.chat.id, remind.doc, true, msg.message_id, true)
		return
	end

	local duration = utilities.get_word(input, 1)
	if not tonumber(duration) then
		utilities.send_message(self, msg.chat.id, remind.doc, true, msg.message_id, true)
		return
	end

	duration = tonumber(duration)
	if duration < 1 then
		duration = 1
	elseif duration > 526000 then
		duration = 526000
	end

	local message = utilities.input(input)
	if not message then
		utilities.send_message(self, msg.chat.id, remind.doc, true, msg.message_id, true)
		return
	end
	local chat_id_str = tostring(msg.chat.id)

	self.database.reminders[chat_id_str] = self.database.reminders[chat_id_str] or {}

	if msg.chat.type ~= 'private' and utilities.table_size(self.database.reminders[chat_id_str]) > 9 then
		utilities.send_reply(self, msg, 'Sorry, this group already has ten reminders.')
		return
	elseif msg.chat.type == 'private' and utilities.table_size(self.database.reminders[chat_id_str]) > 49 then
		utilities.send_reply(msg, 'Sorry, you already have fifty reminders.')
		return
	end

	local reminder = {
		time = os.time() + duration * 60,
		message = message
	}
	table.insert(self.database.reminders[chat_id_str], reminder)
	local output = 'I will remind you in ' .. duration
	if duration == 1 then
		output = output .. ' minute!'
	else
		output = output .. ' minutes!'
	end
	utilities.send_reply(self, msg, output)
end

function remind:cron()
	local time = os.time()

	for chat_id, group in pairs(self.database.reminders) do
		local new_group = {}

		for _, reminder in ipairs(group) do

			if time > reminder.time then
				local output = '*Reminder:*\n"' .. utilities.md_escape(reminder.message) .. '"'
				local res = utilities.send_message(self, chat_id, output, true, nil, true)

				if not res then
					table.insert(new_group, reminder)
				end
			else
				table.insert(new_group, reminder)
			end
		end

		self.database.reminders[chat_id] = new_group

		if #new_group == 0 then
			self.database.reminders[chat_id] = nil
		end
	end
end

return remind
