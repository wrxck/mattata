local mattata = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
mattata.version = '2.1'
function mattata:init(configuration)
	assert(configuration.bot_api_key, 'You need to enter your bot API key in to the configuration file.')
	telegram_api = require('telegram_api').init(configuration.bot_api_key)
	functions = require('functions')
	repeat
		print('Fetching mattata\'s information...')
		self.info = telegram_api.getMe()
	until self.info
	self.info = self.info.result
	self.database_name = 'mattata.db'
	self.database = functions.load_data(self.database_name)
	self.database.users = self.database.users or {}
	self.database.userdata = self.database.userdata or {}
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
		if not plugin.inline_triggers then
			plugin.inline_triggers = {}
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
	self.database.users[from_id_str] = msg.from
	if msg.reply_to_message then
		self.database.users[tostring(msg.reply_to_message.from.id)] = msg.reply_to_message.from
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
	if msg.text:match('^' .. configuration.command_prefix .. 'start .+') then
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
end
function mattata:on_callback_receive(callback, msg, configuration)
	if msg.date < os.time() - 1800 then
		functions.answer_callback_query(callback, 'WELP! That message is too old, please try again.', true)
		return
	end
	if callback.data == 'randomword' then
		functions.edit_message(msg.chat.id, msg.message_id, '*Your random word is:* `' .. HTTP.request(configuration.randomword_api) .. '`', true, true, '{"inline_keyboard":[[{"text":"Generate another!", "callback_data":"randomword"}]]}')
		return
	elseif callback.data == 'pun' then
		local puns = configuration.puns
		functions.edit_message(msg.chat.id, msg.message_id, '`' .. puns[math.random(#puns)] .. '`', true, true, '{"inline_keyboard":[[{"text":"Generate a new pun!", "callback_data":"pun"}]]}')
		return
	elseif callback.data == 'fact' then
		local jstr, res = HTTP.request(configuration.fact_api)
		local jdat = JSON.decode(jstr)
		local jrnd = math.random(#jdat)
		local output = '`' .. jdat[jrnd].nid:gsub('<p>',''):gsub('</p>',''):gsub('&amp;','&'):gsub('<em>',''):gsub('</em>',''):gsub('<strong>',''):gsub('</strong>','') .. '`'
		functions.edit_message(msg.chat.id, msg.message_id, output, true, true, '{"inline_keyboard":[[{"text":"Generate a new fact!", "callback_data":"fact"}]]}')
		return
	elseif callback.data == 'bandersnatch' then
		local output = ''
		local fullnames = configuration.bandersnatch_full_names
		local firstnames = configuration.bandersnatch_first_names
		local lastnames = configuration.bandersnatch_last_names
		if math.random(10) == 10 then
			output = '`' .. fullnames[math.random(#fullnames)] .. '`'
		else
			output = '`' .. firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)] .. '`'
		end
		functions.edit_message(msg.chat.id, msg.message, output, true, true, '{"inline_keyboard":[[{"text":"Generate a new name!", "callback_data":"bandersnatch"}]]}')
		return
	end
	callback.data = string.gsub(callback.data, '@' .. self.info.username .. ' ', "")
	local called_plugin = callback.data:match('(.*):.*')
	local param = callback.data:sub(callback.data:find(':') + 1)
	msg = functions.enrich_message(msg)
	for n=1, #self.plugins do
		local plugin = self.plugins[n]
		if plugin.name == called_plugin then
			plugin:callback(callback, msg, self, configuration, param)
		end
	end
	functions.answer_callback_query(callback, 'Invalid callback query.')
end
function mattata:process_inline_query(inline_query, configuration)
	if string.len(inline_query.query) > 200 then
		functions.abort_inline_query(inline_query)
		return
	end
	local plugint = self.plugins
	for _, plugin in ipairs(plugint) do
		for _, trigger in ipairs(plugin.inline_triggers) do
			if string.match(inline_query.query, trigger) then
				local success, result = pcall(function()
					plugin.inline_callback(self, inline_query, configuration)
				end)
				if not success then
					return
				elseif result ~= true then
					return
				end
			end
		end
	end
end
function mattata:run(configuration)
	mattata.init(self, configuration)
	while self.is_started do
		local res = telegram_api.getUpdates{timeout = 20, offset = self.last_update + 1}
		if res then
			for _,v in ipairs(res.result) do
				self.last_update = v.update_id
				if v.inline_query then
					mattata.process_inline_query(self, v.inline_query, configuration)
				elseif v.callback_query then
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
			for i,v in ipairs(self.plugins) do
				if v.cron then
					local result, err = pcall(function() v.cron(self, configuration) end)
					if not result then
						functions.handle_exception(self, err, 'CRON: ' .. i, configuration.admin_group)
					end
				end
			end
		end
		if self.last_database_save ~= os.date('%H') then
			self.last_database_save = os.date('%H')
			functions.save_data(self.info.username, self.database)
		end
	end
	functions.save_data(self.database_name, self.database)
	print('mattata is shutting down...')
end
return mattata