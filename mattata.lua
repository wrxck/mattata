--[[

	mattata
	
	Copyright (c) 2016 Matthew Hesketh
	See LICENSE for details
	
	mattata's init function, which runs at the beginning of each instance
	This always begins with loading the required dependencies

--]]

local mattata = {}
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local JSON = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function mattata:init()
	print('mattata is initialising...')
	if configuration.botToken == '' then
		print('You need to enter your bot API key in configuration.lua!')
	end
	repeat
		self.info = mattata.getMe()
	until self.info
	self.info = self.info.result
	self.users = mattata.loadData('data/users.json')
 	if not self.users then
 		mattata.loadData('data/users.json')
 	end
 	self.groups = mattata.loadData('data/groups.json')
 	if not self.groups then
 		mattata.loadData('data/groups.json')
 	end
	self.version = '5.1'
	self.administrationPlugins = {}
	for k, v in ipairs(configuration.administrationPlugins) do
		local administrationPlugin = require('plugins.' .. v)
		self.administrationPlugins[k] = administrationPlugin
		self.administrationPlugins[k].name = v
		if administrationPlugin.init then
			administrationPlugin.init(self, configuration)
		end
		if not administrationPlugin.commands then
			administrationPlugin.commands = {}
		end
	end
	self.plugins = {}
	for k, v in ipairs(configuration.plugins) do
		local plugin = require('plugins.' .. v)
		self.plugins[k] = plugin
		self.plugins[k].name = v
		if plugin.init then
			plugin.init(self, configuration)
		end
		if not plugin.commands then
			plugin.commands = {}
		end
	end
	self.channelPlugins = {}
	for k, v in ipairs(configuration.channelPlugins) do
		local channelPlugin = require('plugins.' .. v)
		self.channelPlugins[k] = channelPlugin
		self.channelPlugins[k].name = v
		if channelPlugin.init then
			channelPlugin.init(self, configuration)
		end
		if not channelPlugin.commands then
			channelPlugin.commands = {}
		end
	end
	self.inlinePlugins = {}
	for k, v in ipairs(configuration.inlinePlugins) do
		local inlinePlugin = require('plugins.' .. v)
		self.inlinePlugins[k] = inlinePlugin
		self.inlinePlugins[k].name = v
		if inlinePlugin.init then
			inlinePlugin.init(self, configuration)
		end
		if not inlinePlugin.inlineCommands then
			inlinePlugin.commands = {}
		end
	end
	print('Successfully started @' .. self.info.username .. '!')
	self.lastUpdate = self.lastUpdate or 0
	self.lastCron = self.lastCron or os.date('%M')
	self.lastDbSave = self.lastDbSave or os.date('%H')
	self.isStarted = true
end

--[[

	Function to make POST requests to the Telegram bot API.
	A custom API can be specified, such as the PWRTelegram API,
	using the otherApi parameter.

--]]

function mattata.request(method, parameters, file, otherApi)
	local api
	if otherApi then
		api = otherApi .. configuration.botToken .. '/' .. method
	else
		api = 'https://api.telegram.org/bot' .. configuration.botToken .. '/' .. method
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
				fileName = fileName,
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
		url = api,
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

--[[

	mattata's main long-polling function which repeatedly checks
	the Telegram bot API for updates.
	The objects received in the updates are then further processed
	through object-specific functions.

--]]

function mattata:run(configuration)
	mattata.init(self, configuration)
	while self.isStarted do
		local res = mattata.getUpdates{ timeout = 20, offset = self.lastUpdate + 1 }
		if res then
			for _, v in ipairs(res.result) do
				self.lastUpdate = v.update_id
				if v.inline_query then
					mattata.onInlineQuery(self, v.inline_query, configuration)
				elseif v.callback_query then
					mattata.onCallback(self, v.callback_query, v.callback_query.message, configuration)
				elseif v.message then
					mattata.onMessage(self, v.message, configuration)
				elseif v.edited_message then
					if configuration.processMessageEdits then
						mattata.onMessage(self, v.edited_message, configuration)
					end
				elseif v.channel_post then
					mattata.onChannelPost(self, v.channel_post, configuration)
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
			mattata.saveData('data/users.json', self.users)
			mattata.saveData('data/groups.json', self.groups)
			self.last_database_save = os.date('%H')
		end
	end
	mattata.saveData('data/users.json', self.users)
	mattata.saveData('data/groups.json', self.groups)
	print('mattata is shutting down...')
end

--[[

	Functions to run when the Telegram bot API (successfully) returns an object.
	Each object has a designated function within each plugin.

--]]

function mattata:onMessage(message, configuration)
	if (message.date < os.time() - 50) or redis:get('blacklist:' .. message.from.id) then
		return
	end
	local language = require('languages/' .. mattata.getUserLanguage(message.from.id))
	message = mattata.processMessages(message)
	if message then
		self.users[tostring(message.from.id)] = message.from
		if message.chat.type ~= 'private' then
			self.groups[tostring(message.chat.id)] = message.chat
		end
		message.system_date = os.time()
		message.service_message = serviceModifyMessage(message)
		message.text = message.text or message.caption or ''
		message.text_lower = message.text:lower()
		message.text_upper = message.text:upper()
		if message.text:match('^' .. configuration.commandPrefix .. 'start .+') then
			message.text = configuration.commandPrefix .. mattata.input(message.text)
			message.text_lower = message.text:lower()
			message.text_upper = message.text:upper()
		end
	elseif message.reply_to_message then
		self.users[tostring(message.reply_to_message.from.id)] = message.reply_to_message.from
		if message.reply_to_message.chat.type ~= 'private' then
			self.groups[tostring(message.reply_to_message.chat.id)] = message.reply_to_message.chat
		end
		message.reply_to_message.text = message.reply_to_message.text or message.reply_to_message.caption or ''	
	end
	for _, plugin in ipairs(self.plugins) do
		mattata.processPlugins(self, message, configuration, plugin, language)
	end
	for _, administrationPlugin in ipairs(self.administrationPlugins) do
		mattata.processAdministrationPlugins(self, message, configuration, administrationPlugin, language)
	end
	if not mattata.isPluginDisabledInChat('telegram', message) then
		local telegram = require('plugins/telegram')
		if message.new_chat_member then 
			telegram.onNewChatMember(self, message, configuration, language)
		elseif message.left_chat_member then
			telegram.onLeftChatMember(self, message, configuration, language)
		end
	end
	if not mattata.isPluginDisabledInChat('captionbotai', message) then
		local captionbotai = require('plugins/captionbotai')
		if message.photo then 
			captionbotai.onPhotoReceive(self, message, configuration, language)
		end
	end
	if not mattata.isPluginDisabledInChat('statistics', message) then
		local statistics = require('plugins/statistics')
		statistics.processMessage(self, message, configuration)
		if message.text_lower:match('^' .. configuration.commandPrefix .. 'statistics') then 
			statistics.onMessage(self, message, configuration, language)
		end
	end
	if not mattata.isPluginDisabledInChat('ai', message) then
		local ai = require('plugins/ai')
		if message.chat.type == 'private' then
			if message.text_lower ~= '' then
				ai.onMessage(self, message, configuration, language)
			end
		elseif message.text_lower:match('^' .. self.info.first_name) or message.text_lower:match(self.info.first_name .. '$') or message.text_lower:match('^@' .. self.info.username) or message.text_lower:match('@' .. self.info.username .. '$') then
			message.text_lower = message.text_lower:gsub(self.info.first_name, ''):gsub(self.info.username, '')
			ai.onMessage(self, message, configuration, language)
		end
	end
	if configuration.respondToMemes then
		if message.text_lower:match('^what the fuck did you just fucking say about me%??$') then
			mattata.sendChatAction(message.chat.id, 'typing')
			mattata.sendMessage(message.chat.id, 'What the fuck did you just fucking say about me, you little bitch? I\'ll have you know I graduated top of my class in the Navy Seals, and I\'ve been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. I am trained in gorilla warfare and I\'m the top sniper in the entire US armed forces. You are nothing to me but just another target. I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. You think you can get away with saying that shit to me over the Internet? Think again, fucker. As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot. The storm that wipes out the pathetic little thing you call your life. You\'re fucking dead, kid. I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that\'s just with my bare hands. Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit. If only you could have known what unholy retribution your little "clever" comment was about to bring down upon you, maybe you would have held your fucking tongue. But you couldn\'t, you didn\'t, and now you\'re paying the price, you goddamn idiot. I will shit fury all over you and you will drown in it. You\'re fucking dead, kiddo.', nil, true, false, message.message_id)
		end
		if message.text_lower:match('^gr8 b8,? m8$') then
			mattata.sendChatAction(message.chat.id, 'typing')
			mattata.sendMessage(message.chat.id, 'Gr8 b8, m8. I rel8, str8 appreci8, and congratul8. I r8 this b8 an 8/8. Plz no h8, I\'m str8 ir8. Cre8 more, can\'t w8. We should convers8, I won\'t ber8, my number is 8888888, ask for N8. No calls l8 or out of st8. If on a d8, ask K8 to loc8. Even with a full pl8, I always have time to communic8 so don\'t hesit8.', nil, true, false, message.message_id)
		end
	end
	if configuration.respondToLyrics then
		if message.text_lower:match('^do you have the time,? to listen to me whine%??$') then
			mattata.sendChatAction(message.chat.id, 'typing')
			mattata.sendMessage(message.chat.id, 'About nothing and everything, all at once?', nil, true, false, message.message_id)
		end
	end
end

function mattata:onChannelPost(channel_post, configuration)
	if channel_post.date < os.time() - 50 then
		return
	end
	channel_post = mattata.processChannelPosts(channel_post)
	if channel_post then
		self.groups[tostring(channel_post.chat.id)] = channel_post.chat
		channel_post.system_date = os.time()
		channel_post.text = channel_post.text or channel_post.caption or ''
		channel_post.text_lower = channel_post.text:lower()
		channel_post.text_upper = channel_post.text:upper()
		if channel_post.text:match('^' .. configuration.commandPrefix .. 'start .+') then
			channel_post.text = configuration.commandPrefix .. mattata.input(channel_post.text)
			channel_post.text_lower = channel_post.text:lower()
			channel_post.text_upper = channel_post.text:upper()
		end
	elseif channel_post.reply_to_message then
		self.groups[tostring(channel_post.reply_to_message.chat.id)] = channel_post.reply_to_message.chat
		channel_post.reply_to_message.text = channel_post.reply_to_message.text or channel_post.reply_to_message.caption or ''	
	end
	for _, channelPlugin in ipairs(self.channelPlugins) do
		mattata.processChannelPlugins(self, channel_post, configuration, channelPlugin)
	end
	local ai = require('plugins/ai')
	if channel_post.text_lower:match('^' .. self.info.first_name) or channel_post.text_lower:match(self.info.first_name .. '$') or channel_post.text_lower:match('^@' .. self.info.username) or channel_post.text_lower:match('@' .. self.info.username .. '$') then
		channel_post.text_lower = channel_post.text_lower:gsub(self.info.first_name, ''):gsub(self.info.username, '')
		ai.onChannelPost(self, channel_post, configuration)
	end
end

function mattata:onInlineQuery(inline_query, configuration)
	if redis:get('blacklist:' .. inline_query.from.id) then
		mattata.answerInlineQuery(inline_query.id, nil, '5', true)
		return
	end
	local language = require('languages/' .. mattata.getUserLanguage(inline_query.from.id))
	if inline_query.query:match('^' .. configuration.commandPrefix) then
		for _, inlinePlugin in ipairs(self.inlinePlugins) do
			for _, commands in ipairs(inlinePlugin.inlineCommands) do
				if inline_query.query:match(commands) then
					local success, result = pcall(function()
						inlinePlugin.onInlineQuery(self, inline_query, configuration, language)
					end)
					if not success then
						return
					elseif result ~= true then
						return
					end
				end
			end
		end
	elseif inline_query.query:gsub(' ', '') ~= '' then
		local ai = require('plugins/ai')
		ai.onInlineQuery(self, inline_query, configuration, language)
	else
		local help = require('plugins/help')
		help.onInlineQuery(self, inline_query, configuration, language)
	end
end

function mattata:onCallback(callback, message, configuration)
	if redis:get('blacklist:' .. callback.from.id) then
		mattata.answerCallbackQuery(callback.id, 'You\'re not allowed to use me!', true)
		return
	end
	local language = require('languages/' .. mattata.getUserLanguage(callback.from.id))
	for _, plugin in ipairs(self.plugins) do
		if plugin.onCallback then
			local success, result = pcall(function()
				plugin.onCallback(self, callback, message, configuration, language)
			end)
			if success ~= true then
				return
			end
		end
	end
	for _, administrationPlugin in ipairs(self.administrationPlugins) do
		if administrationPlugin.onCallback then
			local success, result = pcall(function()
				administrationPlugin.onCallback(self, callback, message, configuration, language)
			end)
			if success ~= true then
				return
			end
		end
	end
end

--[[

	A small set of functions to process plugins.
	This allows plugins to be effectively toggled in chats.
	Note: Channel plugins currently can't be toggled

--]]

function mattata.processPlugins(self, message, configuration, plugin, language)
	local plugins = plugin.commands or {}
	for i = 1, #plugins do
		local command = plugin.commands[i]
		if string.match(message.text_lower, command) then
			if not mattata.isPluginDisabledInChat(plugin.name, message) then
				local success, result = pcall(function()
					return plugin.onMessage(self, message, configuration, language)
				end)
				if not success then
					mattata.handleException(self, result, message.from.id .. ': ' .. message.text, configuration.adminGroup)
					message = nil
					return
				end
			end
		end
	end
end

function mattata.processChannelPlugins(self, channel_post, configuration, channelPlugin)
	local channelPlugins = channelPlugin.commands or {}
	for i = 1, #channelPlugins do
		local command = channelPlugin.commands[i]
		if string.match(channel_post.text_lower, command) then
			local success, result = pcall(function()
				return channelPlugin.onChannelPost(self, channel_post, configuration)
			end)
			if not success then
				mattata.handleException(self, result, channel_post.chat.id .. ': ' .. channel_post.text, configuration.adminGroup)
				channel_post = nil
				return
			end
		end
	end
end

function mattata.processAdministrationPlugins(self, message, configuration, administrationPlugin, language)
	local administrationPlugins = administrationPlugin.commands or {}
	for i = 1, #administrationPlugins do
		local command = administrationPlugin.commands[i]
		if string.match(message.text_lower, command) then
			local success, result = pcall(function()
				return administrationPlugin.onMessage(self, message, configuration, language)
			end)
			if not success then
				mattata.handleException(self, result, message.from.id .. ': ' .. message.text, configuration.adminGroup)
				message = nil
				return
			end
		end
	end
end

function mattata.isPluginDisabledInChat(plugin, message)
	if redis:hget(mattata.getRedisHash(message, 'disabledPlugins'), plugin) == 'true' then
		return true
	end
	return false
end

--[[

	Functions which compliment the mattata API by providing Lua
	bindings to the Telegram bot API.
	
--]]

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

-- PWRTelegram bot API methods

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

--[[

	General functions for general use throughout mattata's
	framework and plugins.

--]]

function mattata.getRedisHash(message, variable)
	return 'chat:' .. message.chat.id .. ':' .. variable
end

function mattata.getUserRedisHash(user, variable)
	return 'user:' .. user.id .. ':' .. variable
end

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
		os.date('%X'),
		mattata.markdownEscape(self.info.username),
		mattata.markdownEscape(error) or '',
		mattata.markdownEscape(message)
	)
	if adminGroup then
		return mattata.sendMessage(adminGroup, '`' .. output .. '`', 'Markdown', true, false)
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
	local admins = mattata.getChatAdministrators(chat)
	for _, admin in ipairs(admins.result) do
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

function mattata.processChannelPosts(channel_post)
	if not channel_post.text then
		channel_post.text = channel_post.caption or ''
	end
	channel_post.system_date = os.time()
	channel_post.text_lower = channel_post.text:lower()
	channel_post.text_upper = channel_post.text:upper()
	channel_post.chat.id_str = tostring(channel_post.chat.id)
	if channel_post.reply_to_message then
		if not channel_post.reply_to_message.text then
			channel_post.reply_to_message.text = channel_post.reply_to_message.caption or ''
		end
		channel_post.reply_to_message.system_date = os.time()
		channel_post.reply_to_message.text_lower = channel_post.reply_to_message.text:lower()
		channel_post.reply_to_message.text_upper = channel_post.reply_to_message.text:upper()
		channel_post.reply_to_message.chat.id_str = tostring(channel_post.reply_to_message.chat.id)
	end
	if channel_post.forward_from then
		channel_post.forward_from = mattata.processUsers(channel_post.forward_from)
	end
	return channel_post
end

function mattata.isConfiguredAdmin(id)
	for k, v in pairs(configuration.admins) do
		if id == v then
			return true
		end
	end
	return false
end

function mattata.getUserLanguage(user)
	local hash = 'user:' .. user .. ':language'
	if hash then
		local language = redis:hget(hash, 'language')
		if not language or language == 'false' then
			return 'en'
		else
			return language
		end
	end
end

return mattata