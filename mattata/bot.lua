local bot = {}

local bindings
local utilities

bot.version = '1.1'

function bot:init(config)
	bindings = require('mattata.bindings')
	utilities = require('mattata.utilities')

	assert(
		config.bot_api_key ~= '',
		'You did not set your bot token in the config!'
	)
	self.BASE_URL = 'https://api.telegram.org/bot' .. config.bot_api_key .. '/'

	repeat
		print('Fetching bot information...')
		self.info = bindings.getMe(self)
	until self.info
	self.info = self.info.result

	if not self.database then
		self.database = utilities.load_data(self.info.username..'.db')
	end

	self.database.users = self.database.users or {}

	self.database.userdata = self.database.userdata or {}

	self.database.version = bot.version

	self.database.users[tostring(self.info.id)] = self.info

	self.plugins = {}
	for _,v in ipairs(config.plugins) do
		local p = require('mattata.plugins.'..v)
		table.insert(self.plugins, p)
		if p.init then p.init(self, config) end
		if p.doc then p.doc = '```\n'..p.doc..'\n```' end
	end

	print('@' .. self.info.username .. ', AKA ' .. self.info.first_name ..' ('..self.info.id..')')

	self.last_update = self.last_update or 0
	self.last_cron = self.last_cron or os.date('%M')
	self.last_database_save = self.last_database_save or os.date('%H')
	self.is_started = true
end

function bot:on_msg_receive(msg, config)
	if msg.date < os.time() - 5 then return end
	self.database.users[tostring(msg.from.id)] = msg.from
	if msg.reply_to_message then
		self.database.users[tostring(msg.reply_to_message.from.id)] = msg.reply_to_message.from
	elseif msg.forward_from then
		self.database.users[tostring(msg.forward_from.id)] = msg.forward_from
	elseif msg.new_chat_member then
		self.database.users[tostring(msg.new_chat_member.id)] = msg.new_chat_member
	elseif msg.left_chat_member then
		self.database.users[tostring(msg.left_chat_member.id)] = msg.left_chat_member
	end

	msg.text = msg.text or msg.caption or ''
	msg.text_lower = msg.text:lower()

	if msg.reply_to_message then
		msg.reply_to_message.text = msg.reply_to_message.text or msg.reply_to_message.caption or ''
	end

	if msg.text:match('^'..config.cmd_pat..'start .+') then
		msg.text = config.cmd_pat .. utilities.input(msg.text)
		msg.text_lower = msg.text:lower()
	end

	for _, plugin in ipairs(self.plugins) do
		for _, trigger in ipairs(plugin.triggers or {}) do
			if string.match(msg.text_lower, trigger) then
				local success, result = pcall(function()
					return plugin.action(self, msg, config)
				end)
				if not success then

					if plugin.error then
						utilities.send_reply(self, msg, plugin.error)
					elseif plugin.error == nil then
						utilities.send_reply(self, msg, config.errors.generic)
					end
					utilities.handle_exception(self, result, msg.from.id .. ': ' .. msg.text, config)
					return
				end

				if type(result) == 'table' then
					msg = result

				elseif result ~= true then
					return
				end
			end
		end
	end

end

function bot:run(config)
	bot.init(self, config)
	while self.is_started do
		local res = bindings.getUpdates(self, { timeout=20, offset = self.last_update+1 } )
		if res then
			for _,v in ipairs(res.result) do
				self.last_update = v.update_id
				if v.message then
					bot.on_msg_receive(self, v.message, config)
				end
			end
		else
			print('Connection error while fetching updates.')
		end

		if self.last_cron ~= os.date('%M') then
			self.last_cron = os.date('%M')
			for i,v in ipairs(self.plugins) do
				if v.cron then
					local result, err = pcall(function() v.cron(self, config) end)
					if not result then
						utilities.handle_exception(self, err, 'CRON: ' .. i, config)
					end
				end
			end
		end

		if self.last_database_save ~= os.date('%H') then
			utilities.save_data(self.info.username..'.db', self.database)
			self.last_database_save = os.date('%H')
		end

	end

	utilities.save_data(self.info.username..'.db', self.database)
	print('Halted.')
end

return bot
