-- Copyright (c) 2016 wrxck
-- See LICENSE for details

-- Load dependencies --

local mattata = {}
local HTTP = require('dependencies.socket.http')
local HTTPS = require('dependencies.ssl.https')
local JSON = require('dependencies.dkjson')
local configuration = require('configuration')
local ltn12 = require('dependencies.ltn12')
local mp_encode = require('dependencies.multipart-post').encode
local URL = require('dependencies.socket.url')

-- mattata's framework --

function mattata:init()
	if not configuration.botToken then
		print('You need to enter your bot API key in configuration.lua!')
		return
	end
	print('mattata is initialising...')
	repeat
		self.info = mattata.getMe()
	until self.info
	self.info = self.info.result
	self.db = mattata.load_data(self.info.username)
	if not self.db then
		mattata.load_data(self.info.username)
	end
	self.db.users = self.db.users or {}
	self.db.userdata = self.db.userdata or {}
	self.db.reminders = self.db.reminders or {}
	self.db.version = '3.0'
	self.db.users[tostring(self.info.id)] = self.info
	self.plugins = {}
	for k, v in pairs(configuration.plugins) do
		local plugin = require('plugins.' .. v)
		table.insert(self.plugins, plugin)
		if plugin.init then
			plugin.init(self, configuration)
		end
		if plugin.help then
			plugin.help = '\n' .. plugin.help .. '\n'
		end
		if not plugin.commands then
			plugin.commands = {}
		end
		if not plugin.inlineCommands then
			plugin.inlineCommands = {}
		end
	end
	print('Successfully started @' .. self.info.username .. '!')
	self.last_update = self.last_update or 0
	self.last_cron = self.last_cron or os.date('%M')
	self.last_db_save = self.last_db_save or os.date('%H')
	self.is_started = true
end

function mattata:onMessageReceive(msg, configuration)
	if msg.date < os.time() - 100 then
		return
	end
	local plugincommands = self.plugins
	local from_id_str = tostring(msg.from.id)
	self.db.users[from_id_str] = msg.from
	if msg then
		self.db.users[tostring(msg.from.id)] = msg.from
	elseif msg.new_chat_member then
		self.db.users[tostring(msg.new_chat_member.id)] = msg.new_chat_member
	elseif msg.left_chat_member then
		self.db.users[tostring(msg.left_chat_member.id)] = msg.left_chat_member
	end 
	msg.text = msg.text or msg.caption or ''
	msg.text_lower = msg.text:lower()
	if msg.reply_to_message then
		msg.reply_to_message.text = msg.reply_to_message.text or msg.reply_to_message.caption or ''
	end
	if msg.text:match('^' .. configuration.commandPrefix .. 'start .+') then
		msg.text = configuration.commandPrefix .. mattata.input(msg.text)
		msg.text_lower = msg.text:lower()
	end
	if is_service_msg(msg) then
	  msg = service_modify_msg(msg)
	end
	for _, plugin in ipairs(plugincommands) do
		for _, commands in ipairs(plugin.commands) do
			if string.match(msg.text_lower, commands) then
				local success, result = pcall(function()
					return plugin.onMessageReceive(self, msg, configuration)
				end)
				if not success then
					if plugin.error then
						print(plugin.error)
					elseif plugin.error == nil then
						print(configuration.errors.generic)
					end
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

function mattata:onCallbackReceive(callback, msg, configuration)
	for _, plugin in ipairs(self.plugins) do
		if plugin.query_callback then
			local success, result = pcall(function()
				plugin.query_callback(self, callback, msg, configuration)
			end)
			if not success then
				return
			elseif result ~= true then
				return
			end
		end
	end
end

function mattata:processInlineQuery(inline_query, configuration)
	local plugincommands = self.plugins
	for _, plugin in ipairs(plugincommands) do
		for _, commands in ipairs(plugin.inlineCommands) do
			if string.match(inline_query.query, commands) then
				local success, result = pcall(function()
					plugin.inlineCallback(self, inline_query, configuration)
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
		local res = mattata.getUpdates{ timeout = 20, offset = self.last_update + 1 }
		if res then
			for _, v in ipairs(res.result) do
				self.last_update = v.update_id
				if v.inline_query then
					mattata.processInlineQuery(self, v.inline_query, configuration)
				elseif v.callback_query then
					mattata.onCallbackReceive(self, v.callback_query, configuration)
				elseif v.message then
					mattata.onMessageReceive(self, v.message, configuration)
				elseif v.edited_message then
					mattata.onMessageReceive(self, v.edited_message, configuration)
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
						print('CRON: ' .. i)
					end
				end
			end
		end
		if self.last_db_save ~= os.date('%H') then
			self.last_db_save = os.date('%H')
			mattata.save_data(self.info.username, self.db)
		end
	end
	mattata.save_data(self.info.username, self.db)
	print('mattata is shutting down...')
end

function mattata.request(method, parameters, file)
	parameters = parameters or {}
	for k, v in pairs(parameters) do
		parameters[k] = tostring(v)
	end
	if file and next(file) ~= nil then
		local file_type, file_name = next(file)
		if not file_name then
			return false
		end
		if string.match(file_name, configuration.fileDownloadLocation) then
			local file_result = io.open(file_name, 'r')
			local file_data = {
				filename = file_name,
				data = file_result:read('*a')
			}
			file_result:close()
			parameters[file_type] = file_data
		else
			local file_type, file_name = next(file)
			parameters[file_type] = file_name
		end
	end
	if next(parameters) == nil then
		parameters = { '' }
	end
	local response = {}
	local body, boundary = mp_encode(parameters)
	local success, res = HTTPS.request{
		url = 'https://api.telegram.org/bot' .. configuration.botToken .. '/' .. method,
		method = 'POST',
		headers = {
			['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
			['Content-Length'] = #body,
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	}
	local data = table.concat(response)
	if not success then
		print(method .. ': Connection error. [' .. res	.. ']')
		return false, false
	else
		local result = JSON.decode(data)
		if not result then
			return false, false
		elseif result.ok then
			return result
		else
			print(JSON.encode(result))
			return false
		end
	end
end

function mattata.gen(_, key)
	return function(parameters, file)
		return mattata.request(key, parameters, file)
	end
end

setmetatable(mattata, { __index = mattata.gen })

-- Telegram API methods --

function mattata.sendMessage(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendMessage', {
		chat_id = chat_id,
		text = text,
		parse_mode = parse_mode,
		disable_web_page_preview = disable_web_page_preview,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.forwardMessage(chat_id, from_chat_id, disable_notification, message_id)
	return mattata.request('forwardMessage', {
		chat_id = chat_id,
		from_chat_id = from_chat_id,
		disable_notification = disable_notification,
		message_id = message_id
	} )
end

function mattata.sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendPhoto', {
		chat_id = chat_id,
		photo = photo,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendAudio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendAudio', {
		chat_id = chat_id,
		audio = audio,
		caption = caption,
		duration = duration,
		performer = performer,
		title = title,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendDocument', {
		chat_id = chat_id,
		document = document,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendSticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendSticker', {
		chat_id = chat_id,
		sticker = sticker,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendVideo(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendVideo', {
		chat_id = chat_id,
		video = video,
		duration = duration,
		width = width,
		height = height,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendVoice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendVoice', {
		chat_id = chat_id,
		voice = voice,
		caption = caption,
		duration = duration,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendLocation(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendLocation', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendVenue(chat_id, latitude, longitude, title, address, foursquare_id, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendVenue', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		title = title,
		address = address,
		foursquare_id = foursquare_id,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendContact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendContact', {
		chat_id = chat_id,
		phone_number = phone_number,
		first_name = first_name,
		last_name = last_name,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.sendChatAction(chat_id, action)
	return mattata.request('sendChatAction', {
		chat_id = chat_id,
		action = action
	} )
end

function mattata.getUserProfilePhotos(user_id, offset, limit)
	return mattata.request('getUserProfilePhotos', {
		user_id = user_id,
		offset = offset,
		limit = limit
	} )
end

function mattata.getFile(file_id)
	return mattata.request('getFile', {
		file_id = file_id
	} )
end

function mattata.kickChatMember(chat_id, user_id)
	return mattata.request('kickChatMember', {
		chat_id = chat_id,
		user_id = user_id
	} )
end

function mattata.leaveChat(chat_id)
	return mattata.request('leaveChat', {
		chat_id = chat_id
	} )
end

function mattata.unbanChatMember(chat_id, user_id)
	return mattata.request('unbanChatMember', {
		chat_id = chat_id,
		user_id = user_id
	} )
end

function mattata.getChat(chat_id)
	return mattata.request('getChat', {
		chat_id = chat_id
	} )
end

function mattata.getChatAdministrators(chat_id)
	return mattata.request('getChatAdministrators', {
		chat_id = chat_id
	} )
end

function mattata.getChatMembersCount(chat_id)
	return mattata.request('getChatMembersCount', {
		chat_id = chat_id
	} )
end

function mattata.getChatMember(chat_id, user_id)
	return mattata.request('getChatMember', {
		chat_id = chat_id,
		user_id = user_id
	} )
end

function mattata.answerCallbackQuery(callback_query_id, text, show_alert)
	return mattata.request('answerCallbackQuery', {
		callback_query_id = callback_query_id,
		text = text,
		show_alert = show_alert
	} )
end

function mattata.editMessageText(chat_id, message_id, text, parse_mode, disable_web_page_preview, reply_markup)
	return mattata.request('editMessageText', {
		chat_id = chat_id,
		message_id = message_id,
		text = text,
		parse_mode = parse_mode,
		disable_web_page_preview = disable_web_page_preview,
		reply_markup = reply_markup
	} )
end

function mattata.editMessageCaption(chat_id, message_id, inline_message_id, caption, reply_markup)
	return mattata.request('editMessageCaption', {
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id,
		caption = caption,
		reply_markup = reply_markup
	} )
end

function mattata.editMessageReplyMarkup(chat_id, message_id, inline_message_id, reply_markup)
	return mattata.request('editMessageReplyMarkup', {
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.answerInlineQuery(inline_query_id, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter)
	return mattata.request('answerInlineQuery', {
		inline_query_id = inline_query_id,
		results = results,
		cache_time = cache_time,
		is_personal = is_personal,
		next_offset = next_offset,
		switch_pm_text = switch_pm_text,
		switch_pm_parameter = switch_pm_parameter
	} )
end

function mattata.sendGame(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendGame', {
		chat_id = chat_id,
		game_short_name = game_short_name,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	} )
end

function mattata.setGameScore(user_id, score, chat_id, message_id, inline_message_id, editMessageText)
	return mattata.request('setGameScore', {
		user_id = user_id,
		score = score,
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id,
		editMessageText = editMessageText
	} )
end

function mattata.getGameHighScores(user_id, chat_id, message_id, inline_message_id)
	return mattata.request('getGameHighScores', {
		user_id = user_id,
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id
	} )
end

-- General functions --

function mattata.getWord(s, i)
	s = s or ''
	i = i or 1
	local n = 0
	for w in s:gmatch('%g+') do
		n = n + 1
		if n == i then
			return w
		end
	end
	return false
end

function mattata.input(s)
	if not s:find(' ') then
		return false
	end
	return s:sub(s:find(' ') + 1)
end

function mattata.input_from_msg(msg)
	return mattata.input(msg.text) or (msg.reply_to_message and #msg.reply_to_message.text > 0 and msg.reply_to_message.text) or false
end

function mattata.trim(str)
	return str:gsub('^%s*(.-)%s*$', '%1')
end

function mattata.get_name(msg)
	local name = ''
	if msg.from.last_name then
		name = msg.from.first_name .. ' ' .. msg.from.last_name
	else
		name = msg.from.first_name
	end
	if not name then
		name = msg.from.id
	end
	return name
end

function mattata.download_to_file(url, file_name)
	print('Downloading ' .. url)
	if not file_name then
		file_name = configuration.fileDownloadLocation .. os.time()
	else
		file_name = configuration.fileDownloadLocation .. file_name
	end
	local body = {}
	local protocol = HTTP
	local redirect = true
	if url:match('^https') then
		protocol = HTTPS
		redirect = false
	end
	local _, res = protocol.request {
		url = url,
		sink = ltn12.sink.table(body),
		redirect = redirect
	}
	if res ~= 200 then
		return false
	end
	local file = io.open(file_name, 'w+')
	file:write(table.concat(body))
	file:close()
	print('Saved to: '..file_name)
	return file_name
end

function mattata.load_data(filename)
	local file = io.open(filename)
	if file then
		local s = file:read('*all')
		file:close()
		return JSON.decode(s)
	else
		return {}
	end
end

function mattata.save_data(filename, data)
	local s = JSON.encode(data)
	local file = io.open(filename, 'w')
	file:write(s)
	file:close()
end

function mattata.build_name(first, last)
	if last then
		return first .. ' ' .. last
	else
		return first
	end
end

function mattata.markdownEscape(text)
	return text:gsub('_', '\\_'):gsub('%[', '\\['):gsub('%]', '\\]'):gsub('%*', '\\*'):gsub('`', '\\`')
end

function mattata.htmlEscape(text)
	return text:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

function mattata:resUsername(input)
	input = input:gsub('^@', '')
	for _, user in pairs(self.db.users) do
		if user.username and user.username:lower() == input:lower() then
			local t = {}
			for key, val in pairs(user) do
				t[key] = val
			end
			return t
		end
	end
end

mattata.commands_meta = {}

mattata.commands_meta.__index = mattata.commands_meta

function mattata.commands_meta:c(pattern, has_args)
	local username = self.username:lower()
	table.insert(self.table, '^' .. self.commandPrefix .. pattern .. '$')
	table.insert(self.table, '^' .. self.commandPrefix .. pattern .. '@' .. username .. '$')
	if has_args then
		table.insert(self.table, '^' .. self.commandPrefix .. pattern .. '%s+[^%s]*')
		table.insert(self.table, '^' .. self.commandPrefix .. pattern .. '@' .. username .. '%s+[^%s]*')
	end
	return self
end

function mattata.commands(username, commandPrefix, commands_table)
	local self = setmetatable({}, mattata.commands_meta)
	self.username = username
	self.commandPrefix = commandPrefix
	self.table = commands_table or {}
	return self
end

function mattata.pretty_float(x)
	if x % 1 == 0 then
		return tostring(math.floor(x))
	else
		return tostring(x)
	end
end

mattata.char = {
	zwnj = '‌',
	arabic = '[\216-\219][\128-\191]',
	rtl_override = '‮',
	rtl_mark = '‏',
	em_dash = '—',
	utf_8 = '[%z\1-\127\194-\244][\128-\191]',
}

function service_modify_msg(msg)
	if msg.new_chat_member then
		msg.text = '//tgservice new_chat_member'
		msg.text_lower = msg.text
	elseif msg.left_chat_member then
		msg.text = '//tgservice left_chat_member'
		msg.text_lower = msg.text
	elseif msg.new_chat_title then
		msg.text = '//tgservice new_chat_title'
		msg.text_lower = msg.text
	elseif msg.new_chat_photo then
		msg.text = '//tgservice new_chat_photo'
		msg.text_lower = msg.text
	elseif msg.group_chat_created then
		msg.text = '//tgservice group_chat_created'
		msg.text_lower = msg.text
	elseif msg.supergroup_chat_created then
		msg.text = '//tgservice supergroup_chat_created'
		msg.text_lower = msg.text
	elseif msg.channel_chat_created then
		msg.text = '//tgservice channel_chat_created'
		msg.text_lower = msg.text
	elseif msg.migrate_to_chat_id then
		msg.text = '//tgservice migrate_to_chat_id'
		msg.text_lower = msg.text
	elseif msg.migrate_from_chat_id then
		msg.text = '//tgservice migrate_from_chat_id'
		msg.text_lower = msg.text
	end
	return msg
end

function is_service_msg(msg)
	local res = false
	if msg.new_chat_member then
		res = true
	elseif msg.left_chat_member then
		res = true
	elseif msg.new_chat_title then
		res = true
	elseif msg.new_chat_photo then
		res = true
	elseif msg.group_chat_created then
		res = true
	elseif msg.supergroup_chat_created then
		res = true
	elseif msg.channel_chat_created then
		res = true
	elseif msg.migrate_to_chat_id then
		res = true
	elseif msg.migrate_from_chat_id then
		res = true
	end
	return res
end

function mattata.utf8_len(s)
	local chars = 0
	for i = 1, string.len(s) do
		local b = string.byte(s, i)
		if b < 128 or b >= 192 then
			chars = chars + 1
		end
	end
	return chars
end

mattata.set_meta = {}

mattata.set_meta.__index = mattata.set_meta

function mattata.new_set()
	return setmetatable({__count = 0}, mattata.set_meta)
end

function mattata.set_meta:add(x)
	if x == '__count' then
		return false
	else
		if not self[x] then
			self[x] = true
			self.__count = self.__count + 1
		end
		return true
	end
end

function mattata.set_meta:remove(x)
	if x == '__count' then
		return false
	else
		if self[x] then
			self[x] = nil
			self.__count = self.__count - 1
		end
		return true
	end
end

function mattata.set_meta:__len()
	return self.__count
end

return mattata