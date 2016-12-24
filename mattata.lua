--[[

	      			   _   _        _        
	   _ __ ___   __ _| |_| |_ __ _| |_ __ _ 
	  | '_ ` _ \ / _` | __| __/ _` | __/ _` |
	  | | | | | | (_| | |_| || (_| | || (_| |
	  |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|
										
	
	    Copyright (c) 2016 Matthew Hesketh
	    See LICENSE for details
	    

--]]

local mattata = {}
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')
local colors = require('ansicolors')

function mattata:init()
	print(colors.white .. '\n\n\n                       _   _        _        \n       _ __ ___   __ _| |_| |_ __ _| |_ __ _ \n      | \'_ ` _ \\ / _` | __| __/ _` | __/ _` |\n      | | | | | | (_| | |_| || (_| | || (_| |\n      |_| |_| |_|\\__,_|\\__|\\__\\__,_|\\__\\__,_|\n                                        \n    \n        Copyright (c) 2016 Matthew Hesketh\n        See LICENSE for details\n        \n\n\n\n[mattata]' .. colors.yellow .. ' Initialising...' .. colors.reset)
	if configuration.botToken == '' then print(colors.white .. '[mattata]' .. colors.red .. 'You need to enter your bot API key in configuration.lua!' .. colors.reset) end
	repeat self.info = mattata.request('getMe') until self.info
	self.info = self.info.result
	self.users = mattata.loadData('data/users.json')
	self.groups = mattata.loadData('data/groups.json')
	self.version = '7.0'
	self.administration = {}
	for k, v in ipairs(configuration.administration) do
		local p = require('administration.' .. v)
		self.administration[k] = p
		self.administration[k].name = v
		if p.init then p.init(self, configuration) end
		if not p.commands then p.commands = {} end
	end
	self.plugins = {}
	for k, v in ipairs(configuration.plugins) do
		local p = require('plugins.' .. v)
		self.plugins[k] = p
		self.plugins[k].name = v
		if p.init then p.init(self, configuration) end
		if not p.commands then p.commands = {} end
	end
	print(colors.white .. '[mattata]' .. colors.green .. ' Connected to the Telegram bot API!' .. colors.reset)
	self.info.name = self.info.first_name
	if self.info.last_name then self.info.name = self.info.first_name .. ' ' .. self.info.last_name end
	print ('\n          ' .. colors.white .. 'Username: @' .. self.info.username .. '\n          Name: ' .. self.info.name .. '\n          ID: ' .. self.info.id .. colors.reset .. '\n')
	self.update = self.update or 0
	self.lcron = self.lcron or os.date('%H')
	return true
end

--[[

	Function to make POST requests to the Telegram bot API.
	A custom API can be specified, such as the PWRTelegram API,
	using the 'api' parameter.

--]]

function mattata.request(method, parameters, file, api)
	parameters = parameters or {}
	api = api or 'https://api.telegram.org/bot'
	for k, v in pairs(parameters) do parameters[k] = tostring(v) end
	if file and next(file) ~= nil then
		local ftype, fname = next(file)
		if not fname then return false end
		if fname:match(configuration.fileDownloadLocation) then
			local fres = io.open(fname, 'r')
			local fdat = { filename = fname, data = fres:read('*a') }
			fres:close()
			parameters[ftype] = fdat
		else
			local ftype, fname = next(file)
			parameters[ftype] = fname
		end
	end
	if next(parameters) == nil then parameters = { '' } end
	local response = {}
	local body, boundary = multipart.encode(parameters)
	local res, code = https.request({
		url = api .. configuration.botToken .. '/' .. method,
		method = 'POST',
		headers = {
			['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
			['Content-Length'] = #body,
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	})
	if not res then
		print(colors.white .. '[mattata]' .. colors.red .. ' ' .. method .. ': Connection error: ' .. res .. colors.reset)
		return false, false
	end
	local jdat = json.decode(table.concat(response))
	if not jdat then return false, false elseif jdat.ok == true then return jdat end
	return false
end

--[[

	mattata's main long-polling function which repeatedly checks
	the Telegram bot API for updates.
	The objects received in the updates are then further processed
	through object-specific functions.

--]]

function mattata:run(configuration)
	local init = mattata.init(self, configuration); while init do; local res = mattata.getUpdates(20, self.update + 1)
	if res then; for _, update in ipairs(res.result) do
		self.update = update.update_id
		if update.message then
			mattata.onMessage(self, update.message, configuration)
			if configuration.debugMode then print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Message from ' .. colors.cyan .. update.message.from.id .. colors.green .. ' to ' .. colors.cyan .. update.message.chat.id .. colors.reset) end
		elseif update.edited_message and configuration.processEdits then
			mattata.onMessage(self, update.edited_message, configuration)
			if configuration.debugMode then print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Message edit from ' .. colors.cyan .. update.edited_message.from.id .. colors.green .. ' to ' .. colors.cyan .. update.edited_message.chat.id .. colors.reset) end
		elseif update.channel_post then
			mattata.onMessage(self, update.channel_post, configuration)
			if configuration.debugMode then print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Channel post from ' .. colors.cyan .. update.channel_post.chat.id .. colors.reset) end
		elseif update.edited_channel_post and configuration.processEdits then
			mattata.onMessage(self, update.edited_channel_post, configuration)
			if configuration.debugMode then print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Channel post edit from ' .. colors.cyan .. update.edited_channel_post.chat.id .. colors.reset) end
		elseif update.inline_query then
			mattata.onInlineQuery(self, update.inline_query, configuration)
			if configuration.debugMode then print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Inline query from ' .. colors.cyan .. update.inline_query.from.id .. colors.reset) end
		elseif update.chosen_inline_result then
			print(json.encode(update.chosen_inline_result))
		elseif update.callback_query then
			mattata.onCallbackQuery(self, update.callback_query, update.callback_query.message, configuration)
			if configuration.debugMode then print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Callback query from ' .. colors.cyan .. update.callback_query.from.id .. colors.reset) end
		end
	end; else print(colors.white .. '[mattata]' .. colors.red .. ' There was an error whilst retrieving updates from the Telegram bot API.' .. colors.reset) end
	if self.lcron ~= os.date('%H') then
		self.lcron = os.date('%H')
		for i = 1, #self.plugins do; if self.plugins[i].cron then
			local result, error = pcall(function()
				local plugin = self.plugins[i]
				plugin.cron(self, configuration)
			end)
			if not result then mattata.exception(self, error, 'CRON: ' .. i, configuration.adminGroup) end
		end; end
		mattata.saveData('data/users.json', self.users)
		mattata.saveData('data/groups.json', self.groups)
	end; end
	mattata.saveData('data/users.json', self.users)
	mattata.saveData('data/groups.json', self.groups)
	print(colors.white .. '[mattata]' .. colors.yellow .. ' Shutting down your instance of mattata (@' .. self.info.username .. ') ...' .. colors.reset)
end

--[[

	Functions to run when the Telegram bot API (successfully) returns an object.
	Each object has a designated function within each plugin.

--]]

function mattata:onMessage(message, configuration)
	if message.date < os.time() - 7 then return
	elseif not message.from then return
	elseif message.from and redis:get('blacklist:' .. message.from.id) then return end
	local language = require('languages.' .. mattata.getUserLanguage(message.from.id))
	message = mattata.processMessage(message)
	if message then
		self.users[tostring(message.from.id)] = message.from
		if message.chat.type ~= 'private' then self.groups[tostring(message.chat.id)] = message.chat
		elseif message.forward_from_chat then self.groups[tostring(message.forward_from_chat)] = message.forward_from_chat end
		message.system_date = os.time()
		message.service_message = mattata.modifyServiceMessage(message)
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
		if message.reply_to_message.chat.type ~= 'private' then self.groups[tostring(message.reply_to_message.chat.id)] = message.reply_to_message.chat
		elseif message.reply_to_message.forward_from_chat then self.groups[tostring(message.reply_to_message.forward_from_chat)] = message.reply_to_message.forward_from_chat end
		message.reply_to_message.text = message.reply_to_message.text or message.reply_to_message.caption or ''	
	end
	if message.reply_to_message and message.reply_to_message.from.id == self.info.id and message.text == 'Cancel' then
		mattata.sendMessage(message.chat.id, 'Cancelled current operation.', nil, true, false, message.message_id, json.encode({ remove_keyboard = true }))
		return
	end
	if message.chat.type == 'supergroup' and not mattata.isPluginDisabledInChat('antispam', message) then local process = require('administration.antispam').processMessage(self, message, configuration) end
	for _, plugin in ipairs(self.plugins) do
		local plugins = plugin.commands or {}
		for i = 1, #plugins do; local command = plugin.commands[i]; if message.text_lower:match(command) then
			if mattata.isPluginDisabledInChat(plugin.name, message) then return
			elseif plugin.processMessage then
				local success, result = pcall(function() plugin.processMessage(message, configuration) end)
				if not success then return end
			end
			local success, result = pcall(function() return plugin.onMessage(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id))) end)
			if not success then
				mattata.exception(self, result, message.from.id .. ': ' .. message.text, configuration.adminGroup)
				message = nil
				return
			end; end
		end
	end
	for _, plugin in ipairs(self.administration) do
		local plugins = plugin.commands or {}
		for i = 1, #plugins do; local command = plugin.commands[i]; if message.text_lower:match(command) and plugin.onMessage then
			if message.chat.type ~= 'supergroup' and plugin.name ~= 'groups' then
				mattata.sendMessage(message.chat.id, 'This command can only be used in supergroups.', nil, true, false, message.message_id)
				return
			elseif plugin.processMessage and plugin.name ~= 'antispam' then
				local success, result = pcall(function() plugin.processMessage(message, configuration) end)
				if not success then return end
			end
			local success, result = pcall(function() return plugin.onMessage(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id))) end)
			if not success then
				mattata.exception(self, result, message.from.id .. ': ' .. message.text, configuration.adminGroup)
				message = nil
				return
			end; end
		end
	end
	if message.new_chat_member and message.new_chat_member.id ~= self.info.id and not mattata.isPluginDisabledInChat('welcome', message) then 
		require('plugins.welcome').onNewChatMember(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.new_chat_member.id)))
		return
	end
	if message.photo and not mattata.isPluginDisabledInChat('captionbotai', message) then
		require('plugins.captionbotai').onPhotoReceive(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id)))
		return
	end
	if not mattata.isPluginDisabledInChat('statistics', message) then
		require('plugins.statistics').processMessage(self, message, configuration)
		if message.text_lower:match('^' .. configuration.commandPrefix .. 'statistics') or message.text_lower:match('^' .. configuration.commandPrefix .. 'stats') or message.text_lower:match('^group stats?i?s?t?i?c?s?%.?%??!?$') then 
			require('plugins.statistics').onMessage(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id)))
			return
		end
	end
	if configuration.respondToMemes and message.text_lower:match('^what the fuck did you just fucking say about me%??$') and message.chat.type ~= 'private' then
		mattata.sendChatAction(message.chat.id, 'typing')
		mattata.sendMessage(message.chat.id, 'What the fuck did you just fucking say about me, you little bitch? I\'ll have you know I graduated top of my class in the Navy Seals, and I\'ve been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. I am trained in gorilla warfare and I\'m the top sniper in the entire US armed forces. You are nothing to me but just another target. I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. You think you can get away with saying that shit to me over the Internet? Think again, fucker. As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot. The storm that wipes out the pathetic little thing you call your life. You\'re fucking dead, kid. I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that\'s just with my bare hands. Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit. If only you could have known what unholy retribution your little "clever" comment was about to bring down upon you, maybe you would have held your fucking tongue. But you couldn\'t, you didn\'t, and now you\'re paying the price, you goddamn idiot. I will shit fury all over you and you will drown in it. You\'re fucking dead, kiddo.', nil, true, false, message.message_id)
		return
	elseif configuration.respondToMemes and message.text_lower:match('^gr8 b8,? m8$') and message.chat.type ~= 'private' then
		mattata.sendChatAction(message.chat.id, 'typing')
		mattata.sendMessage(message.chat.id, 'Gr8 b8, m8. I rel8, str8 appreci8, and congratul8. I r8 this b8 an 8/8. Plz no h8, I\'m str8 ir8. Cre8 more, can\'t w8. We should convers8, I won\'t ber8, my number is 8888888, ask for N8. No calls l8 or out of st8. If on a d8, ask K8 to loc8. Even with a full pl8, I always have time to communic8 so don\'t hesit8.', nil, true, false, message.message_id)
		return
	elseif configuration.respondToMemes and message.text_lower:match('^w?h?y so salty%??!?%.?$') and message.chat.type ~= 'private' then
		mattata.sendSticker(message.chat.id, 'BQADBAADNQIAAlAYNw2gRrzQfFLv9wI')
		return
	elseif configuration.respondToMemes and message.text_lower:match('^bone? appetite?%??!?%.?$') and message.chat.type ~= 'private' then
		mattata.sendChatAction(message.chat.id, 'typing')
		local rnd = math.random(4)
		local output
		if rnd == 1 then output = 'bone apple tea'
		elseif rnd == 2 then output = 'bone app the teeth'
		elseif rnd == 3 then output = 'boney african feet'
		else output = 'bong asshole sneeze' end
		mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
		return
	elseif configuration.respondToMemes and message.text_lower:match('^y?o?u a?re? a ?p?r?o?p?e?r? fucc?k?boy?i?%??!?%.?$') and message.chat.type ~= 'private' then
		mattata.sendMessage(message.chat.id, 'Sir, I am writing to you on this fateful day to inform you of a tragic reality. While it is unfortunate that I must be the one to let you know, it is for the greater good that this knowledge is made available to you as soon as possible. m8. u r a proper fukboy.', nil, true, false, message.message_id)
		return
	elseif configuration.respondToLyrics and message.text_lower:match('^do you have the time,? to listen to me whine%??$') and message.chat.type ~= 'private' then
		mattata.sendSticker(message.chat.id, 'BQADBAADOwIAAlAYNw0I9ggFrg4HigI')
		return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'donate') then
		mattata.sendMessage(message.chat.id, '<b>Hello, ' .. mattata.htmlEscape(message.from.first_name) .. '!</b>\n\nIf you\'re feeling generous, you can contribute to the mattata project by making a monetary donation of any amount. This will go towards server costs and any time and resources used to develop mattata. This is an optional act, however it is greatly appreciated and your name will also be listed publically on mattata\'s GitHub page (and, eventually, <a href="http://mattata.pw">website</a>).\n\nIf you\'re still interested in helping me out, you can donate <a href="https://paypal.me/wrxck">here</a>. Thank you for your continued support! 😀', 'HTML', true, false, message.message_id)
		return
	elseif message.text_lower:match('^' .. self.info.first_name .. ',? babe?y?!?$') then
		mattata.sendMessage(message.chat.id, 'Oh, Daddy!', nil, true, false, message.message_id)
		return
	elseif message.text_lower:match('^hakuna matt?att?a!?%??%.?$') then
		mattata.sendMessage(message.chat.id, 'HAKUNA MATTATA BITCHES!', nil, true, false, message.message_id)
		return
	elseif message.text == 'first message' and mattata.isConfiguredAdmin(message.from.id) then
		mattata.sendMessage(message.chat.id, 'Here you go ' .. message.from.first_name, nil, true, false, 1)
	end
	if not mattata.isPluginDisabledInChat('ai', message) and not message.text:match('^Cancel$') and not message.text:match('^/?s/(.-)/(.-)/?$') and not message.photo then
		local ai = require('plugins.ai')
		if message.chat.type == 'private' and message.text ~= '' then ai.onMessage(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id)))
		elseif message.text_lower:match('^' .. self.info.first_name) or message.text_lower:match(self.info.first_name .. '$') or message.text_lower:match('^@' .. self.info.username) or message.text_lower:match('@' .. self.info.username .. '$') then
			message.text_lower = message.text_lower:gsub(self.info.first_name, ''):gsub(self.info.username, '')
			ai.onMessage(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id)))
		elseif message.reply_to_message and message.reply_to_message.from.id == self.info.id then
			message.text_lower = message.text_lower:gsub(self.info.first_name, ''):gsub(self.info.username, '')
			ai.onMessage(self, message, configuration, require('languages.' .. mattata.getUserLanguage(message.from.id)))
		end
	end
end

function mattata:onInlineQuery(inline_query, configuration)
	if redis:get('blacklist:' .. inline_query.from.id) then
		mattata.answerInlineQuery(inline_query.id, nil, '5', true)
		return
	end	
	for _, plugin in ipairs(self.plugins) do
		local plugins = plugin.commands or {}
		for i = 1, #plugins do; local command = plugin.commands[i]; if inline_query.query:match(command) and plugin.onInlineQuery then
			local success, result = pcall(function() return plugin.onInlineQuery(self, inline_query, configuration, require('languages.' .. mattata.getUserLanguage(inline_query.from.id))) end)
			if not success then
				mattata.exception(self, result, inline_query.from.id .. ': ' .. inline_query.query, configuration.adminGroup)
				message = nil
				return
			end; end
		end
	end
	if inline_query.query ~= '' then require('plugins.ai').onInlineQuery(self, inline_query, configuration, require('languages.' .. mattata.getUserLanguage(inline_query.from.id)))
	else require('plugins.help').onInlineQuery(self, inline_query, configuration, require('languages.' .. mattata.getUserLanguage(inline_query.from.id))) end
end

function mattata:onCallbackQuery(callback_query, message, configuration)
	if redis:get('blacklist:' .. callback_query.from.id) then
		mattata.answerCallbackQuery(callback_query.id, 'You\'re not allowed to use me!', true)
		return
	elseif message.reply_to_message and message.chat.type ~= 'channel' and callback_query.from.id ~= message.reply_to_message.from.id then
		mattata.answerCallbackQuery(callback_query.id, 'Only ' .. message.reply_to_message.from.first_name .. ' can use this!')
		return
	end
	for _, plugin in ipairs(self.plugins) do
		if plugin.name == callback_query.data:match('^(%a+):') and plugin.onCallbackQuery then
			callback_query.data = callback_query.data:match('^%a+:(.-)$')
			local success, result = pcall(function() return plugin.onCallbackQuery(self, callback_query, callback_query.message, configuration, require('languages.' .. mattata.getUserLanguage(callback_query.from.id))) end)
			if not success then
				mattata.answerCallbackQuery(callback_query.id, 'An error occured!')
				mattata.exception(self, result, callback_query.from.id .. ': ' .. callback_query.data, configuration.adminGroup)
				callback_query = nil
				return
			end
		end
	end
	for _, plugin in ipairs(self.administration) do
		if plugin.name == callback_query.data:match('^(%a+):') and plugin.onCallbackQuery then
			callback_query.data = callback_query.data:match('^%a+:(.-)$')
			local success, result = pcall(function() return plugin.onCallbackQuery(self, callback_query, callback_query.message, configuration, require('languages.' .. mattata.getUserLanguage(callback_query.from.id))) end)
			if not success then
				mattata.answerCallbackQuery(callback_query.id, 'An error occured!')
				mattata.exception(self, result, callback_query.from.id .. ': ' .. callback_query.data, configuration.adminGroup)
				callback_query = nil
				return
			end
		end
	end
end


function mattata.isPluginDisabledInChat(plugin, message)
	if redis:hget(mattata.getRedisHash(message, 'disabledPlugins'), plugin) == 'true' then return true end
	return false
end

--[[

	Functions which compliment the mattata API by providing Lua
	bindings to the Telegram bot API.
	
--]]

function mattata.getUpdates(timeout, offset) return mattata.request('getUpdates', { timeout = timeout, offset = offset }) end

function mattata.sendMessage(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendMessage', {
		chat_id = chat_id,
		text = text,
		parse_mode = parse_mode or nil,
		disable_web_page_preview = disable_web_page_preview or false,
		disable_notification = disable_notification or false,
		reply_to_message_id = reply_to_message_id or nil,
		reply_markup = reply_markup or nil
	})
end

function mattata.sendReply(message, text, parse_mode, reply_markup)
	return mattata.request('sendMessage', {
		chat_id = message.chat.id,
		text = text,
		parse_mode = parse_mode or nil,
		disable_web_page_preview = true,
		disable_notification = false,
		reply_to_message_id = message.message_id,
		reply_markup = reply_markup or nil
	})
end

function mattata.sendForceReplyMessage(message, text, parse_mode, selective)
	return mattata.request('sendMessage', {
		chat_id = message.chat.id,
		text = text,
		parse_mode = parse_mode or nil,
		disable_web_page_preview = true,
		disable_notification = false,
		reply_to_message_id = message.message_id,
		reply_markup = json.encode({ force_reply = true, selective = selective or false })
	})
end

function mattata.forwardMessage(chat_id, from_chat_id, disable_notification, message_id)
	return mattata.request('forwardMessage', {
		chat_id = chat_id,
		from_chat_id = from_chat_id,
		disable_notification = disable_notification,
		message_id = message_id
	})
end

function mattata.sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendPhoto', {
		chat_id = chat_id,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, { photo = photo })
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
	}, { audio = audio })
end

function mattata.sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendDocument', {
		chat_id = chat_id,
		caption = caption,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, { document = document })
end

function mattata.sendSticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendSticker', {
		chat_id = chat_id,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, { sticker = sticker })
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
	}, { video = video })
end

function mattata.sendVoice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendVoice', {
		chat_id = chat_id,
		caption = caption,
		duration = duration,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, { voice = voice })
end

function mattata.sendLocation(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendLocation', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	})
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
	})
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
	})
end

function mattata.sendChatAction(chat_id, action) return mattata.request('sendChatAction', { chat_id = chat_id, action = action }) end

function mattata.getUserProfilePhotos(user_id, offset, limit) return mattata.request('getUserProfilePhotos', { user_id = user_id, offset = offset, limit = limit }) end

function mattata.getFile(file_id) return mattata.request('getFile', { file_id = file_id }) end

function mattata.kickChatMember(chat_id, user_id) return mattata.request('kickChatMember', { chat_id = chat_id, user_id = user_id }) end

function mattata.leaveChat(chat_id) return mattata.request('leaveChat', { chat_id = chat_id }) end

function mattata.unbanChatMember(chat_id, user_id) return mattata.request('unbanChatMember', { chat_id = chat_id, user_id = user_id }) end

function mattata.getChatAdministrators(chat_id) return mattata.request('getChatAdministrators', { chat_id = chat_id }) end

function mattata.getChatMembersCount(chat_id) return mattata.request('getChatMembersCount', { chat_id = chat_id }) end

function mattata.getChatMember(chat_id, user_id) return mattata.request('getChatMember', { chat_id = chat_id, user_id = user_id }) end

function mattata.answerCallbackQuery(callback_query_id, text, show_alert, url)
	return mattata.request('answerCallbackQuery', {
		callback_query_id = callback_query_id,
		text = text,
		show_alert = show_alert,
		url = url
	})
end

function mattata.editMessageText(chat_id, message_id, text, parse_mode, disable_web_page_preview, reply_markup)
	return mattata.request('editMessageText', {
		chat_id = chat_id,
		message_id = message_id,
		text = text,
		parse_mode = parse_mode,
		disable_web_page_preview = disable_web_page_preview,
		reply_markup = reply_markup
	})
end

function mattata.editMessageCaption(chat_id, message_id, inline_message_id, caption, reply_markup)
	return mattata.request('editMessageCaption', {
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id,
		caption = caption,
		reply_markup = reply_markup
	})
end

function mattata.editMessageReplyMarkup(chat_id, message_id, inline_message_id, reply_markup)
	return mattata.request('editMessageReplyMarkup', {
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id,
		reply_markup = reply_markup
	})
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
	})
end

function mattata.sendGame(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup)
	return mattata.request('sendGame', {
		chat_id = chat_id,
		game_short_name = game_short_name,
		disable_notification = disable_notification,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	})
end

function mattata.setGameScore(user_id, score, force, disable_edit_message, chat_id, message_id, inline_message_id)
	return mattata.request('setGameScore', {
		user_id = user_id,
		score = score,
		force = force,
		disable_edit_message = disable_edit_message,
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id
	})
end

function mattata.getGameHighScores(user_id, chat_id, message_id, inline_message_id)
	return mattata.request('getGameHighScores', {
		user_id = user_id,
		chat_id = chat_id,
		message_id = message_id,
		inline_message_id = inline_message_id
	})
end

function mattata.getChat(chat_id) return mattata.request('getChat', { chat_id = chat_id }) end

--[[

	General functions for general use throughout mattata's
	framework and plugins.

--]]

function mattata.getRedisHash(message, variable) return 'chat:' .. message.chat.id .. ':' .. variable end

function mattata.getUserRedisHash(user, variable) return 'user:' .. user.id .. ':' .. variable end

function mattata.getWord(s, i)
	s = s or ''
	i = i or 1
	local n = 0
	for w in s:gmatch('%g+') do n = n + 1; if n == i then return w end; end
	return false
end

function mattata.input(s)
	if not s:find(' ') then return false end
	return s:sub(s:find(' ') + 1)
end

function mattata.trim(str) return str:gsub('^%s*(.-)%s*$', '%1') end

function mattata:exception(error, message, adminGroup)
	local output = string.format('[%s]\n%s: %s\n%s\n', os.date('%X'), self.info.username, mattata.htmlEscape(error) or '', mattata.htmlEscape(message))
	if adminGroup then return mattata.sendMessage(adminGroup, '<pre>' .. output .. '</pre>', 'HTML') end
	print(output)
end

function mattata.downloadToFile(url, name)
	name = name or os.time() .. '.' .. url:match('.+/%.(.-)$')
	local body = {}
	local protocol = http
	local redirect = true
	if url:match('^https') then protocol = https; redirect = false end
	local _, res = protocol.request { url = url, sink = ltn12.sink.table(body), redirect = redirect }
	if res ~= 200 then return false end
	local file = io.open(configuration.fileDownloadLocation .. name, 'w+')
	file:write(table.concat(body))
	file:close()
	return configuration.fileDownloadLocation .. name
end

function mattata.loadData(fileName)
	local file = io.open(fileName)
	if file then local s = file:read('*all'); file:close(); return json.decode(s) end
	return {}
end

function mattata.saveData(fileName, data)
	local s = json.encode(data)
	local file = io.open(fileName, 'w')
	file:write(s)
	file:close()
end

function mattata.isGroupAdmin(chat, user)
	local admins = mattata.getChatAdministrators(chat)
	if not admins then return false end
	for _, admin in ipairs(admins.result) do if admin.user.id == user then return true end; end
	return false
end

function mattata.resolveUsername(input)
	local res = mattata.request('getChat', { chat_id = tostring(input) }, nil, 'https://api.pwrtelegram.xyz/bot')
	if not res then return input elseif res.result.type ~= 'private' then return input end
	return tonumber(res.result.id)
end

function mattata.markdownEscape(text) return text:gsub('_', '\\_'):gsub('%[', '\\['):gsub('%]', '\\]'):gsub('%*', '\\*'):gsub('`', '\\`') end

function mattata.htmlEscape(text) return text:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;') end

mattata.commandsMeta = {}

mattata.commandsMeta.__index = mattata.commandsMeta

function mattata.commandsMeta:command(command)
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
	for _ in pairs(t) do i = i + 1 end
	return i
end

function mattata.modifyServiceMessage(message)
	if message.new_chat_member then return 'new_chat_member'
	elseif message.left_chat_member then return 'left_chat_member'
	elseif message.new_chat_title then return 'new_chat_title'
	elseif message.new_chat_photo then return 'new_chat_photo'
	elseif message.delete_chat_photo then return 'delete_chat_photo'
	elseif message.group_chat_created then return 'group_chat_created'
	elseif message.supergroup_chat_created then return 'supergroup_chat_created'
	elseif message.channel_chat_created then return 'channel_chat_created'
	elseif message.migrate_to_chat_id then return 'migrate_to_chat_id'
	elseif message.migrate_from_chat_id then return 'migrate_from_chat_id'
	elseif message.pinned_message then return 'pinned_message'
	else return '' end
end

function mattata.utf8Len(s)
	local chars = 0
	for i = 1, string.len(s) do local b = string.byte(s, i); if b < 128 or b >= 192 then chars = chars + 1 end; end
	return chars
end

function mattata.processUser(user)
	user.id_str = tostring(user.id)
	user.name = user.first_name
	if user.last_name then user.name = user.name .. ' ' .. user.last_name end
	return user
end

function mattata.processMessage(message)
	if not message.text then message.text = message.caption or '' end
	message.is_media = true
	if message.audio then message.media_type = 'audio'
	elseif message.document then message.media_type = 'document'
	elseif message.sticker then message.media_type = 'sticker'
	elseif message.video then message.media_type = 'video'
	elseif message.voice then message.media_type = 'voice'
	elseif message.contact then message.media_type = 'contact'
	elseif message.location then message.media_type = 'location'
	elseif message.venue then message.media_type = 'venue'
	else message.media_type = ''; message.is_media = false end
	message.system_date = os.time()
	message.service_message = mattata.modifyServiceMessage(message)
	message.text_lower = message.text:lower()
	message.text_upper = message.text:upper()
	message.from = mattata.processUser(message.from)
	message.chat.id_str = tostring(message.chat.id)
	if message.reply_to_message then
		message.reply_to_message.is_media = true
		if message.reply_to_message.audio then message.reply_to_message.media_type = 'audio'
		elseif message.reply_to_message.document then message.reply_to_message.media_type = 'document'
		elseif message.reply_to_message.sticker then message.reply_to_message.media_type = 'sticker'
		elseif message.reply_to_message.video then message.reply_to_message.media_type = 'video'
		elseif message.reply_to_message.voice then message.reply_to_message.media_type = 'voice'
		elseif message.reply_to_message.contact then message.reply_to_message.media_type = 'contact'
		elseif message.reply_to_message.location then message.reply_to_message.media_type = 'location'
		elseif message.reply_to_message.venue then message.reply_to_message.media_type = 'venue'
		else message.reply_to_message.media_type = ''; message.reply_to_message.is_media = false end
		if not message.reply_to_message.text then message.reply_to_message.text = message.reply_to_message.caption or '' end
		message.reply_to_message.system_date = os.time()
		message.reply_to_message.service_message = mattata.modifyServiceMessage(message.reply_to_message)
		message.reply_to_message.text_lower = message.reply_to_message.text:lower()
		message.reply_to_message.text_upper = message.reply_to_message.text:upper()
		message.reply_to_message.from = mattata.processUser(message.reply_to_message.from)
		message.reply_to_message.chat.id_str = tostring(message.reply_to_message.chat.id)
	elseif message.forward_from then message.forward_from = mattata.processUser(message.forward_from)
	elseif message.new_chat_member then message.new_chat_member = mattata.processUser(message.new_chat_member)
	elseif message.left_chat_member then message.left_chat_member = mattata.processUser(message.left_chat_member) end
	return message
end

function mattata.isConfiguredAdmin(id)
	for k, v in pairs(configuration.admins) do if id == v then return true end; end
	return false
end

function mattata.getUserLanguage(id)
	local language = redis:hget('user:' .. id .. ':language', 'language')
	if language == nil then return 'en' else return language end
end

function mattata.commaValue(amount)
	while true do amount, k = amount:gsub('^(-?%d+)(%d%d%d)', '%1,%2'); if (k == 0) then break; end; end
	return amount
end

function mattata.bashEscape(str) return str:gsub('$', ''):gsub('%^', ''):gsub('&', ''):gsub('|', ''):gsub(';', '') end

function mattata.formatMilliseconds(milliseconds)
	local totalSeconds = math.floor(milliseconds / 1000)
	local seconds = totalSeconds % 60
	local minutes = math.floor(totalSeconds / 60)
	local hours = math.floor(minutes / 60)
	minutes = minutes % 60
	return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end

function mattata.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

return mattata