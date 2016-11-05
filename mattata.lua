-- Copyright (c) 2016 Matthew Hesketh
-- See LICENSE for details

-- Load dependencies --

local mattata = {}
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local configuration = require('configuration')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local URL = require('socket.url')
local redis = require('mattata-redis')

-- mattata's framework --

function mattata:init()
	print('mattata is initialising...')
	if configuration.botToken == '' then
		print('You need to enter your bot API key in configuration.lua!')
	end
	repeat
		self.info = mattata.getMe()
	until self.info
	self.info = self.info.result
	self.db = mattata.loadData('mattata.db')
	self.userdata = mattata.loadData(self.info.username)
	if not self.db then
		mattata.loadData('mattata.db')
	end
	if not self.userdata then
		mattata.loadData(self.info.username)
	end
	self.plugins = {}
	enabledPlugins = mattata.loadPlugins()
	for k, v in ipairs(enabledPlugins) do
		local plugin = require('plugins.' .. v)
		self.plugins[k] = plugin
		self.plugins[k].name = v
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
	self.lastUpdate = self.lastUpdate or 0
	self.lastCron = self.lastCron or os.date('%M')
	self.lastDbSave = self.lastDbSave or os.date('%H')
	self.isStarted = true
end

function mattata:onMessageReceive(message, configuration)
	if message.date < os.time() - 50 then
		return
	end
	message = mattata.processMessages(message)
	if message then
		message.system_date = os.time()
		message.service_message = serviceModifyMessage(message) 
		message.text = message.text or message.caption or ''
		message.text_lower = message.text:lower()
		message.text_upper = message.text:upper()
		message.text_trimmed = message.text:gsub(' ', '')
		if message.text:match('^' .. configuration.commandPrefix .. 'start .+') then
			message.text = configuration.commandPrefix .. mattata.input(message.text)
			message.text_lower = message.text:lower()
			message.text_upper = message.text:upper()
			message.text_trimmed = message.text:gsub(' ', '')
		end
	elseif message.reply_to_message then
		message.reply_to_message.text = message.reply_to_message.text or message.reply_to_message.caption or ''
	end
	for _, plugin in ipairs(self.plugins) do
		mattata.processPlugins(self, message, configuration, plugin)
	end
end

function mattata:onQueryReceive(callback, message, configuration)
	for _, plugin in ipairs(self.plugins) do
		if plugin.onQueryReceive then
			local success, result = pcall(function()
				plugin.onQueryReceive(self, callback, message, configuration)
			end)
			if success ~= true then
				return
			end
		end
	end
end

function mattata:processInlineQuery(inline_query, configuration)
	for _, plugin in ipairs(self.plugins) do
		for _, commands in ipairs(plugin.inlineCommands) do
			if string.match(inline_query.query, commands) then
				local success, result = pcall(function()
					plugin.onInlineCallback(self, inline_query, configuration)
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
	while self.isStarted do
		local res = mattata.getUpdates{ timeout = 20, offset = self.lastUpdate + 1 }
		if res then
			for _, v in ipairs(res.result) do
				self.lastUpdate = v.update_id
				if v.inline_query then
					mattata.processInlineQuery(self, v.inline_query, configuration)
				elseif v.callback_query then
					mattata.onQueryReceive(self, v.callback_query, v.callback_query.message, configuration)
				elseif v.message then
					mattata.onMessageReceive(self, v.message, configuration)
				end
				if configuration.processMessageEdits then
					if v.edited_message then
						mattata.onMessageReceive(self, v.edited_message, configuration)
					end
				end
			end
		else
			print('There was an error whilst retrieving updates from Telegram.')
		end
		if self.lastCron ~= os.date('%M') then
			self.lastCron = os.date('%M')
			for i = 1, #self.plugins do 
				local v = self.plugins[i]
				if v.cron then
					local result, error = pcall(function()
						v.cron(self, configuration)
					end)
					if not result then
						mattata.handleException(self, error, 'CRON: ' .. i, configuration.adminGroup)
					end
				end
			end
		end
		if self.last_database_save ~= os.date('%H') then
			mattata.saveData('mattata.db', self.db)
			mattata.saveData(self.info.username, self.userdata)
			self.last_database_save = os.date('%H')
		end
	end
	mattata.saveData('mattata.db', self.db)
	mattata.saveData(self.info.username, self.userdata)
	print('mattata is shutting down...')
end

function mattata.getRedisHash(message, var)
	return 'chat:' .. message.chat.id .. ':' .. var
end

function mattata.processPlugins(self, message, configuration, plugin)
	local plugins = plugin.commands or {}
	for i = 1, #plugins do
		local command = plugin.commands[i]
		if string.match(message.text_lower, command) then
			if mattata.isPluginDisabledInChat(plugin.name, message) then
				return
			else
				local success, result = pcall(function()
					return plugin.onMessageReceive(self, message, configuration)
				end)
				if not success then
					mattata.handleException(self, result, message.from.id .. ': ' .. message.text, configuration.adminGroup)
					message = nil
					return
				end
			end
			return
		end
	end
end

function mattata.isPluginDisabledInChat(plugin, message)
	local hash = mattata.getRedisHash(message, 'disabledPlugins')
	local disabled = redis:hget(hash, plugin)
	if disabled == 'true' then
		return true
	else
		return false
	end
end

function mattata.request(method, parameters, file, other_api)
	local api
	if other_api then
		api = other_api
	else
		api = 'https://api.telegram.org/bot'
	end
	parameters = parameters or {}
	for k, v in pairs(parameters) do
		parameters[k] = tostring(v)
	end
	if file and next(file) ~= nil then
		local fileType, fileName = next(file)
		if not fileName then
			return false
		end
		if string.match(fileName, configuration.fileDownloadLocation) then
			local fileResult = io.open(fileName, 'r')
			local fileData = {
				filename = fileName,
				data = fileResult:read('*a')
			}
			fileResult:close()
			parameters[fileType] = fileData
		else
			local fileType, fileName = next(file)
			parameters[fileType] = fileName
		end
	end
	if next(parameters) == nil then
		parameters = { '' }
	end
	local response = {}
	local body, boundary = multipart.encode(parameters)
	local success, res = HTTPS.request{
		url = api .. configuration.botToken .. '/' .. method,
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
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		photo = photo
	} )
end

function mattata.sendAudio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendAudio', {
		chat_id = chat_id,
		caption = caption,
		duration = duration,
		performer = performer,
		title = title,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		audio = audio
	} )
end

function mattata.sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendDocument', {
		chat_id = chat_id,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		document = document
	} )
end

function mattata.sendSticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendSticker', {
		chat_id = chat_id,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		sticker = sticker
	} )
end

function mattata.sendVideo(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendVideo', {
		chat_id = chat_id,
		duration = duration,
		width = width,
		height = height,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		video = video
	} )
end

function mattata.sendVoice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendVoice', {
		chat_id = chat_id,
		caption = caption,
		duration = duration,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		voice = voice
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

function mattata.answerCallbackQuery(callback_query_id, text, show_alert, url)
	return mattata.request('answerCallbackQuery', {
		callback_query_id = callback_query_id,
		text = text,
		show_alert = show_alert,
		url = url
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

-- PWRTelegram API methods --

function mattata.getChat(chat_id)
	return mattata.request('getChat', {
		chat_id = chat_id
	}, nil, 'https://api.pwrtelegram.xyz/bot' )
end

function mattata.deleteMessage(chat_id, message_id)
	return mattata.request('deleteMessage', {
		chat_id = chat_id,
		message_id = message_id
	}, nil, 'https://api.pwrtelegram.xyz/bot' )
end

-- Custom Telegram API orientated functions

function mattata.generateInlineArticle(id, title, message_text, parse_mode, disable_web_page_preview, description, text, url)
	return JSON.encode( {
		type = 'article',
		id = tostring(id),
		title = title,
		input_message_content = {
			message_text = message_text,
			parse_mode = parse_mode,
			disable_web_page_preview = disable_web_page_preview
		},
		description = description,
		reply_markup = {
			inline_keyboard = {
				text = text,
				url = url,
				callback_data = callback_data
			}
		}
	} )
end

function mattata.generateInlinePhoto(id, photo_url, thumb_url, photo_width, photo_height, title, description, caption, text, url, message_text, parse_mode, disable_web_page_preview)
	local parameters = {
		type = 'photo',
		id = tostring(id),
		photo_url = photo_url,
		thumb_url = thumb_url,
		photo_width = photo_width,
		photo_height = photo_height,
		title = title,
		description = description,
		caption = caption,
		reply_markup = {
			inline_keyboard = {
				text = text,
				url = url
			}
		}
	}
	if message_text then
		parameters = parameters .. ',' .. {
			input_message_content = {
				message_text = message_text,
				parse_mode = parse_mode,
				disable_web_page_preview = disable_web_page_preview
			}
		}
	end
	return JSON.encode(parameters)
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

function mattata.trim(str)
	return str:gsub('^%s*(.-)%s*$', '%1')
end

function mattata.getName(message)
	local name = ''
	if message.from.last_name then
		name = message.from.first_name .. ' ' .. message.from.last_name
	else
		name = message.from.first_name
	end
	if not name then
		name = message.from.id
	end
	return name
end

function mattata:handleException(error, message, adminGroup)
	local output = string.format(
		'[%s]\n%s: %s\n%s\n',
		os.date('%F %T'),
		self.info.username,
		error or '',
		message
	)
	if adminGroup then
		output = '`' .. mattata.markdownEscape(output) .. '`'
		return mattata.sendMessage(adminGroup, output, 'Markdown', true, false)
	else
		print(output)
	end
end

function mattata.downloadToFile(url, fileName)
	if not fileName then
		fileName = configuration.fileDownloadLocation .. url:match('.+/(.-)$') or configuration.fileDownloadLocation .. os.time()
	else
		fileName = configuration.fileDownloadLocation .. fileName
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
	local file = io.open(fileName, 'w+')
	file:write(table.concat(body))
	file:close()
	return fileName
end

function mattata.loadData(fileName)
	local file = io.open(fileName)
	if file then
		local s = file:read('*all')
		file:close()
		return JSON.decode(s)
	else
		return {}
	end
end

function mattata.saveData(fileName, data)
	local s = JSON.encode(data)
	local file = io.open(fileName, 'w')
	file:write(s)
	file:close()
end

function mattata.buildName(first, last)
	if last then
		return first .. ' ' .. last
	else
		return first
	end
end

function mattata.isGroupAdmin(chat, user)
	local admin_list = mattata.getChatAdministrators(chat)
	for _, admin in ipairs(admin_list.result) do
		if admin.user.id == user then
			return true
		end
	end
	return false
end

function mattata.resolveUsername(user)
	if tonumber(user) == nil then
		if not string.match(user, '^@') then
			local user = '@' .. user
		end
	end
	local res = mattata.getChat(user)
	if res then
		if res.result.first_name then
			return res.result.first_name
		end
	end
	return false
end

function mattata.markdownEscape(text)
	return text:gsub('_', '\\_'):gsub('%[', '\\['):gsub('%]', '\\]'):gsub('%*', '\\*'):gsub('`', '\\`')
end

function mattata.htmlEscape(text)
	return text:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

mattata.commandsMeta = {}

mattata.commandsMeta.__index = mattata.commandsMeta

function mattata.commandsMeta:c(command)
	table.insert(self.table, '^' .. self.commandPrefix .. command .. '$')
	table.insert(self.table, '^' .. self.commandPrefix .. command .. '@' .. self.username:lower() .. '$')
	table.insert(self.table, '^' .. self.commandPrefix .. command .. '%s+[^%s]*')
	table.insert(self.table, '^' .. self.commandPrefix .. command .. '@' .. self.username:lower() .. '%s+[^%s]*')
	return self
end

function mattata.commands(username, commandPrefix, commandsTable)
	local self = setmetatable({}, mattata.commandsMeta)
	self.username = username
	self.commandPrefix = commandPrefix
	self.table = commandsTable or {}
	return self
end

function mattata.tableSize(t)
	local i = 0
	for _ in pairs(t) do
		i = i + 1
	end
	return i
end

function serviceModifyMessage(message)
	if message.new_chat_member then
		return 'new_chat_member'
	end
	if message.left_chat_member then
		return 'left_chat_member'
	end
	if message.new_chat_title then
		return 'new_chat_title'
	end
	if message.new_chat_photo then
		return 'new_chat_photo'
	end
	if message.group_chat_created then
		return 'group_chat_created'
	end
	if message.supergroup_chat_created then
		return 'supergroup_chat_created'
	end
	if message.channel_chat_created then
		return 'channel_chat_created'
	end
	if message.migrate_to_chat_id then
		return 'migrate_to_chat_id'
	end
	if message.migrate_from_chat_id then
		return 'migrate_from_chat_id'
	end
	return ''
end

function mattata.utf8Len(s)
	local chars = 0
	for i = 1, string.len(s) do
		local b = string.byte(s, i)
		if b < 128 or b >= 192 then
			chars = chars + 1
		end
	end
	return chars
end

function mattata.loadPlugins()
	enabledPlugins = redis:smembers('mattata:enabledPlugins')
	if enabledPlugins[1] == nil then
		mattata.loadDefaultPlugins()
	end
	return enabledPlugins
end

function mattata.loadDefaultPlugins()
	enabledPlugins = configuration.plugins
	for _, plugin in pairs(enabledPlugins) do
		redis:sadd('mattata:enabledPlugins', plugin)
	end
end

function mattata.processUsers(user)
	user.id_str = tostring(user.id)
	user.name = mattata.buildName(user.first_name, user.last_name)
	return user
end

function mattata.processMessages(message)
	if not message.text then
		message.text = message.caption or ''
	end
	message.system_date = os.time()
	message.service_message = serviceModifyMessage(message)
	message.text_lower = message.text:lower()
	message.text_upper = message.text:upper()
	message.text_trimmed = message.text:gsub(' ', '')
	message.from = mattata.processUsers(message.from)
	message.chat.id_str = tostring(message.chat.id)
	if message.reply_to_message then
		if not message.reply_to_message.text then
			message.reply_to_message.text = message.reply_to_message.caption or ''
		end
		message.reply_to_message.system_date = os.time()
		message.reply_to_message.service_message = serviceModifyMessage(message.reply_to_message)
		message.reply_to_message.text_lower = message.reply_to_message.text:lower()
		message.reply_to_message.text_upper = message.reply_to_message.text:upper()
		message.reply_to_message.text_trimmed = message.reply_to_message.text:gsub(' ', '')
		message.reply_to_message.from = mattata.processUsers(message.reply_to_message.from)
		message.reply_to_message.chat.id_str = tostring(message.reply_to_message.chat.id)
	end
	if message.forward_from then
		message.forward_from = mattata.processUsers(message.forward_from)
	end
	if message.new_chat_member then
		message.new_chat_member = mattata.processUsers(message.new_chat_member)
	end
	if message.left_chat_member then
		message.left_chat_member = mattata.processUsers(message.left_chat_member)
	end
	return message
end

return mattata