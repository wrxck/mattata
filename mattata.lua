local mattata = {}
mattata.version = '1.5.1'
function mattata:init(configuration)
	assert(configuration.bot_api_key, 'You need to enter your bot API key in to the configuration file.')
	telegram_api = require('telegram_api').init(configuration.bot_api_key)
	functions = require('functions')
	repeat
		print('Fetching information about mattata...')
		self.info = telegram_api.getMe()
	until self.info
	self.info = self.info.result
	if not self.database then
		self.database = functions.load_data(self.info.username..'.db')
	end
	self.database_name = configuration.database_name or self.info.username .. '.db'
	if not self.database then
		self.database = functions.load_data(self.database_name)
	end
	self.database.users = self.database.users or {}
	self.database.userdata = self.database.userdata or {}
	self.database.blacklist = self.database.blacklist or {}
	self.database.version = mattata.version
	self.database.users[tostring(self.info.id)] = self.info
	self.plugins = {}
	for k,v in pairs(configuration.plugins) do
		local plugin = require('plugins.'..v)
		table.insert(self.plugins, plugin)
		if plugin.init then
			plugin.init(self, configuration)
		end
		if plugin.doc then
			plugin.doc = '```\n' .. plugin.doc .. '\n```'
		end
		if not plugin.triggers then
			plugin.triggers = {}
		end
	end
	print('mattata has initialised successfully!')
	self.last_update = self.last_update or 0
	self.last_cron = self.last_cron or os.date('%M')
	self.last_database_save = self.last_database_save or os.date('%H')
	self.is_started = true
end
function mattata:on_msg_receive(msg, configuration)
	if msg.date < os.time() - 5 then
		return
	end
	local plugint = self.plugins
	local from_id_str = tostring(msg.from.id)
	msg.text = msg.text or msg.caption or ''
	msg.text_lower = msg.text:lower()
	if msg.reply_to_message then
		msg.reply_to_message.text = msg.reply_to_message.text or msg.reply_to_message.caption or ''
	end
	if msg.text:match('^'..configuration.command_prefix..'start .+') then
		msg.text = configuration.command_prefix .. functions.input(msg.text)
		msg.text_lower = msg.text:lower()
	end
	if is_service_msg(msg) then
	  msg = service_modify_msg(msg)
	end
	for _, plugin in ipairs(plugint) do
		for _, trigger in ipairs(plugin.triggers) do
			if string.match(msg.text_lower, trigger) then
				local success, result = pcall(function()
					return plugin.action(self, msg, configuration)
				end)
				if not success then
					if plugin.error then
						functions.send_reply(msg, plugin.error)
					elseif plugin.error == nil then
						functions.send_reply(msg, configuration.errors.generic)
					end
					functions.handle_exception(self, result, msg.from.id .. ': ' .. msg.text, configuration.admin_group)
					msg = nil
					return
				elseif result ~= true then
					msg = nil
					return
				end
			end
		end
	end
	msg = nil
end
function mattata:on_callback_receive(callback, msg, configuration)
	if msg.date < os.time() - 1800 then
		functions.answer_callback_query(callback, 'That message is too old, please try again.', true)
		return
	end
	if not callback.data:find(':') or not callback.data:find('@'..self.info.username..' ') then
		return
	end
	callback.data = string.gsub(callback.data, '@'..self.info.username..' ', "")
	local called_plugin = callback.data:match('(.*):.*')
	local param = callback.data:sub(callback.data:find(':')+1)
	msg = functions.enrich_message(msg)
	for n=1, #self.plugins do
		local plugin = self.plugins[n]
		if plugin.name == called_plugin then
			plugin:callback(callback, msg, self, configuration, param)
		end
	end
	functions.answer_callback_query(callback, 'Invalid callback query.')
end
function mattata:run(configuration)
	mattata.init(self, configuration)
	while self.is_started do
		local res = telegram_api.getUpdates{ timeout = 20, offset = self.last_update+1 }
		if res then
			for n=1, #res.result do
				local v = res.result[n]
				self.last_update = v.update_id
				if v.callback_query then
					mattata.on_callback_receive(self, v.callback_query, v.callback_query.message, configuration)
				elseif v.message then
					mattata.on_msg_receive(self, v.message, configuration)
				end
			end
		else
			print('There was an error whilst retrieving updates from Telegram.')
		end
		if self.last_cron ~= os.date('%M') then
			self.last_cron = os.date('%M')
			for n=1, #self.plugins do 
				local v = self.plugins[n]
				if v.cron then -- Call each plugin's cron function, if it has one.
					local result, err = pcall(function() v.cron(self, configuration) end)
					if not result then
						functions.handle_exception(self, err, 'CRON: ' .. n, configuration.log_chat)
					end
				end
			end
		end
		if self.last_database_save ~= os.date('%H') then
			functions.save_data(self.info.username..'.db', self.database) -- Save the database.
			self.last_database_save = os.date('%H')
		end
	end
	functions.save_data(self.info.username..'.db', self.database)
	print('mattata is shutting down...')
end
return mattata