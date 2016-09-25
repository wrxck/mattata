local functions = {}
local ltn12 = require('ltn12')
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local redis = require('redis')
local utf8 = require('lua-utf8')
local telegram_api = require('telegram_api')
function functions.send_message(chat_id, text, disable_web_page_preview, reply_to_message_id, use_markdown, reply_markup)
	local parse_mode
	if type(use_markdown) == 'string' then
		parse_mode = use_markdown
	elseif use_markdown == true then
		parse_mode = 'markdown'
	end
	return telegram_api.request('sendMessage', {
		chat_id = chat_id,
		text = text,
		disable_web_page_preview = disable_web_page_preview,
		reply_to_message_id = reply_to_message_id,
		parse_mode = parse_mode,
		reply_markup = reply_markup
	} )
end
function functions.edit_message(chat_id, message_id, text, disable_web_page_preview, use_markdown, reply_markup)
	local parse_mode
	if type(use_markdown) == 'string' then
		parse_mode = use_markdown
	elseif use_markdown == true then
		parse_mode = 'Markdown'
	end
	return telegram_api.request('editMessageText', {
		chat_id = chat_id,
		message_id = message_id,
		text = text,
		disable_web_page_preview = disable_web_page_preview,
		parse_mode = parse_mode,
		reply_markup = reply_markup
	} )
end
function functions.send_reply(msg, text, use_markdown, reply_markup)
	local parse_mode
	if type(use_markdown) == 'string' then
		parse_mode = use_markdown
	elseif use_markdown == true then
		parse_mode = 'markdown'
	end
	return telegram_api.request('sendMessage', {
		chat_id = msg.chat.id,
		text = text,
		disable_web_page_preview = true,
		reply_to_message_id = msg.message_id,
		parse_mode = parse_mode,
		reply_markup = reply_markup
	} )
end
function functions.forward_message(chat_id, from_chat_id, message_id)
	return telegram_api.request('forwardMessage', {
		chat_id = chat_id,
		from_chat_id = from_chat_id,
		message_id = message_id
	} )
end
function functions.leave_chat(chat_id)
	return telegram_api.request('leaveChat', {
		chat_id = chat_id
	} )
end
function functions.unban_chat_member(chat_id, user_id)
	return telegram_api.request('unbanChatMember', {
		chat_id = chat_id,
		user_id = user_id
	} )
end
function functions.send_photo(chat_id, file, text, reply_to_message_id, reply_markup)
	if not file then
		return false
	end
	local output = telegram_api.request('sendPhoto', {
		chat_id = chat_id,
		caption = text or nil,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		photo = file
	} )
	if string.match(file, '/tmp/') then
		os.remove(file)
		print("Deleted: " .. file)
	end
	return output
end
function functions.send_audio(chat_id, file, reply_to_message_id, duration, performer, title)
	if not file then
		return false
	end
	local output = telegram_api.request('sendAudio', {
		chat_id = chat_id,
		duration = duration or nil,
		performer = performer or nil,
		title = title or nil,
		reply_to_message_id = reply_to_message_id
	}, {
		audio = file
	} )
	if string.match(file, '/tmp/') then
		os.remove(file)
		print("Deleted " .. file)
	end
	return output
end
function functions.send_document(chat_id, file, text, reply_to_message_id, reply_markup)
	if not file then
		return false
	end
	local output = telegram_api.request('sendDocument', {
		chat_id = chat_id,
		caption = text or nil,
		reply_to_message_id = reply_to_message_id,
		reply_markup = reply_markup
	}, {
		document = file
	} )
	if string.match(file, '/tmp/') then
		os.remove(file)
		print("Deleted " .. file)
	end
	return output
end
function functions.send_video(chat_id, file, text, reply_to_message_id, duration, width, height)
	if not file then
		return false
	end
	local output = telegram_api.request('sendVideo', {
		chat_id = chat_id,
		caption = text or nil,
		duration = duration or nil,
		width = width or nil,
		height = height or nil,
		reply_to_message_id = reply_to_message_id
	}, {
		video = file
	} )
	if string.match(file, '/tmp/') then
		os.remove(file)
		print("Deleted " .. file)
	end
	return output
end
function functions.send_voice(chat_id, file, reply_to_message_id, duration)
	if not file then
		return false
	end
	local output = telegram_api.request('sendVoice', {
		chat_id = chat_id,
		duration = duration or nil,
		reply_to_message_id = reply_to_message_id
	}, {
		voice = file
	} )
	if string.match(file, '/tmp/') then
		os.remove(file)
		print("Deleted " .. file)
	end
	return output
end
function functions.send_location(chat_id, latitude, longitude, reply_to_message_id)
	return telegram_api.request('sendLocation', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		reply_to_message_id = reply_to_message_id
	} )
end
function functions.send_venue(chat_id, latitude, longitude, reply_to_message_id, title, address)
	return telegram_api.request('sendVenue', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		title = title,
		address = address,
		reply_to_message_id = reply_to_message_id
	} )
end
function functions.send_action(chat_id, action)
	return telegram_api.request('sendChatAction', {
		chat_id = chat_id,
		action = action
	} )
end
function functions.get_chat(chat_id)
	return telegram_api.request('getChat', {
		chat_id = chat_id
	} )
end
function functions.answer_callback_query(callback, text, show_alert)
	return telegram_api.request('answerCallbackQuery', {
		callback_query_id = callback.id,
		text = text,
		show_alert = show_alert
	} )
end
function functions.get_chat_info(chat_id)
	return telegram_api.request('getChat', {
		chat_id = chat_id
	} )
end
function functions.get_chat_administrators(chat_id)
	return telegram_api.request('getChatAdministrators', {
		chat_id = chat_id
	} )
end
function functions.get_word(s, i)
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
function functions.input(s)
	if not s:find(' ') then
		return false
	end
	return s:sub(s:find(' ') + 1)
end
function functions.input_from_msg(msg)
	return functions.input(msg.text) or (msg.reply_to_message and #msg.reply_to_message.text > 0 and msg.reply_to_message.text) or false
end
function functions.trim(str)
	local s = str:gsub('^%s*(.-)%s*$', '%1')
	return s
end
function string:isempty()
	self = functions.trim(self)
	return self == nil or self == ''
end
function get_name(msg)
	 local name = msg.from.first_name
	 if not name then
	 	name = msg.from.id
	 end
	 return name
end
function run_command(str)
	local cmd = io.popen(str)
	local result = cmd:read('*all')
	cmd:close()
	return result
end
function convert_timestamp(timestamp, date_format)
	return os.date(date_format, timestamp)
end
function functions.download_to_file(url, file_name)
	print('Downloading ' .. url)
	if not file_name then
		file_name = '/tmp/' .. url:match('.+/(.-)$') or '/tmp/' .. os.time()
	else
		file_name = '/tmp/' .. file_name
	end
	local body = {}
	local doer = HTTP
	local do_redir = true
	if url:match('^https') then
		doer = HTTPS
		do_redir = false
	end
	local _, res = doer.request {
		url = url,
		sink = ltn12.sink.table(body),
		redirect = do_redir
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
function functions.load_data(filename)
	local f = io.open(filename)
	if f then
		local s = f:read('*all')
		f:close()
		return JSON.decode(s)
	else
		return {}
	end
end
function functions.save_data(filename, data)
	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()
end
function get_file_size(file)
	local current = file:seek()
	local size = file:seek("end")
	file:seek("set", current)
	return tonumber(size)
end
function functions.get_coords(input, configuration)
	local url = 'https://maps.googleapis.com/maps/api/geocode/JSON?address=' .. URL.escape(input) .. '&language=' .. configuration.language
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		return configuration.errors.connection
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		return configuration.errors.results
	end
	return {
		lat = jdat.results[1].geometry.location.lat,
		lon = jdat.results[1].geometry.location.lng,
		addr = jdat.results[1].formatted_address
	}
end
function functions.table_size(tab)
	local i = 0
	for _,_ in pairs(tab) do
		i = i + 1
	end
	return i
end
function functions.build_name(first, last)
	if last then
		return first .. ' ' .. last
	else
		return first
	end
end
function functions:handle_exception(err, message, admin_group)
	local output = string.format(
		'[%s]\n%s: %s\n%s\n',
		os.date('%F %T'),
		self.info.username,
		err or '',
		message
	)
	if admin_group then
		output = '<code>' .. functions.html_escape(output) .. '</code>'
		return functions.send_message(admin_group, output, true, nil, 'html')
	else
		print(output)
	end
end
function functions.md_escape(text)
	return text:gsub('_', '\\_'):gsub('%[', '\\['):gsub('%]', '\\]'):gsub('%*', '\\*'):gsub('`', '\\`')
end
function functions.html_escape(text)
	return text:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end
function functions:resolve_username(input)
	input = input:gsub('^@', '')
	for _, user in pairs(self.database.users) do
		if user.username and user.username:lower() == input:lower() then
			local t = {}
			for key, val in pairs(user) do
				t[key] = val
			end
			return t
		end
	end
end
functions.triggers_meta = {}
functions.triggers_meta.__index = functions.triggers_meta
function functions.triggers_meta:t(pattern, has_args)
	local username = self.username:lower()
	table.insert(self.table, '^'..self.command_prefix..pattern..'$')
	table.insert(self.table, '^'..self.command_prefix..pattern..'@'..username..'$')
	if has_args then
		table.insert(self.table, '^'..self.command_prefix..pattern..'%s+[^%s]*')
		table.insert(self.table, '^'..self.command_prefix..pattern..'@'..username..'%s+[^%s]*')
	end
	return self
end
function functions.triggers(username, command_prefix, trigger_table)
	local self = setmetatable({}, functions.triggers_meta)
	self.username = username
	self.command_prefix = command_prefix
	self.table = trigger_table or {}
	return self
end
function functions.enrich_user(user)
	user.id_str = tostring(user.id)
	user.name = functions.build_name(user.first_name, user.last_name)
	return user
end
function functions.enrich_message(msg)
	if not msg.text then
		msg.text = msg.caption or ''
	end
	msg.text_lower = msg.text:lower()
	msg.from = functions.enrich_user(msg.from)
	msg.chat.id_str = tostring(msg.chat.id)
	if msg.reply_to_message then
		if not msg.reply_to_message.text then
			msg.reply_to_message.text = msg.reply_to_message.caption or ''
		end
		msg.reply_to_message.text_lower = msg.reply_to_message.text:lower()
		msg.reply_to_message.from = functions.enrich_user(msg.reply_to_message.from)
		msg.reply_to_message.chat.id_str = tostring(msg.reply_to_message.chat.id)
	end
	if msg.forward_from then
		msg.forward_from = functions.enrich_user(msg.forward_from)
	end
	if msg.new_chat_member then
		msg.new_chat_member = functions.enrich_user(msg.new_chat_member)
	end
	if msg.left_chat_member then
		msg.left_chat_member = functions.enrich_user(msg.left_chat_member)
	end
	return msg
end
function functions.pretty_float(x)
	if x % 1 == 0 then
		return tostring(math.floor(x))
	else
		return tostring(x)
	end
end
functions.char = {
	zwnj = '‌',
	arabic = '[\216-\219][\128-\191]',
	rtl_override = '‮',
	rtl_mark = '‏',
	em_dash = '—',
	utf_8 = '[%z\1-\127\194-\244][\128-\191]',
}
function scandir(directory)
	local i, t, popen = 0, {}, io.popen
	for filename in popen('ls -a "'..directory..'"'):lines() do
		i = i + 1
		t[i] = filename
	end
	return t
end
function match_pattern(pattern, text)
	if text then
		local matches = { string.match(text, pattern) }
		if next(matches) then
			return matches
		end
	end
end
function is_sudo(msg, configuration)
	local var = false
	if configuration.owner == msg.from.id then
		var = true
	end
	return var
end
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
	local var = false
	if msg.new_chat_member then
		var = true
	elseif msg.left_chat_member then
		var = true
	elseif msg.new_chat_title then
		var = true
	elseif msg.new_chat_photo then
		var = true
	elseif msg.group_chat_created then
		var = true
	elseif msg.supergroup_chat_created then
		var = true
	elseif msg.channel_chat_created then
		var = true
	elseif msg.migrate_to_chat_id then
		var = true
	elseif msg.migrate_from_chat_id then
		var = true
	end
	return var
end
function post_petition(url, arguments, headers)
	local url, h = string.gsub(url, "HTTP://", "")
	local url, hs = string.gsub(url, "HTTPS://", "")
	local post_prot = "HTTP"
	if hs == 1 then
		post_prot = "HTTPS"
	end
	local response_body = {}
	local request_constructor = {
		url = post_prot..'://'..url,
		method = "POST",
		sink = ltn12.sink.table(response_body),
		headers = headers or {},
		redirect = false
	}
	local source = arguments
	if type(arguments) == "table" then
		source = helpers.url_encode_arguments(arguments)
	end
	if not headers then
		request_constructor.headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF8"
		request_constructor.headers["X-Accept"] = "application/JSON"
		request_constructor.headers["Accept"] = "application/JSON"
	end
	if type(arguments) == 'userdata' then
		request_constructor.headers["Content-Length"] = get_file_size(source)
		request_constructor.source = ltn12.source.file(source)
	else 
		request_constructor.headers["Content-Length"] = tostring(#source)
		request_constructor.source = ltn12.source.string(source)
	end
	if post_prot == "HTTP" then
		ok, response_code, response_headers, response_status_line = HTTP.request(request_constructor)
	else
		ok, response_code, response_headers, response_status_line = HTTPS.request(request_constructor)
	end
	if not ok then
		return nil
	end
	response_body = JSON.decode(table.concat(response_body))
	return response_body, response_headers
end
function get_redis_hash(msg, var)
	if msg.chat.type == 'group' or msg.chat.type == 'supergroup' then
		return 'chat:'..msg.chat.id..':'..var
	end
	if msg.chat.type == 'private' then
		return 'user:'..msg.from.id..':'..var
	end
end
function functions.utf8_len(s)
    local chars = 0
    for i = 1, string.len(s) do
        local b = string.byte(s, i)
        if b < 128 or b >= 192 then
            chars = chars + 1
        end
    end
    return chars
end
function round(num, idp)
	if idp and idp > 0 then
		local mult = 10^idp
		return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end
function comma_value(amount)
	local formatted = amount
	while true do	
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if (k == 0) then
			break
		end
	end
	return formatted
end
function string.starts(String,Start)
	 return string.sub(String,1,string.len(Start))==Start
end
function string.ends(str, fin)
	return fin == '' or string.sub(str, -string.len(fin)) == fin
end
function get_location(user_id)
	local hash = 'user:'..user_id
	local set_location = redis:hget(hash, 'location')
	if set_location == 'false' or set_location == nil then
		return false
	else
		return set_location
	end
end
function get_HTTP_header(url)
	local doer = HTTP
	local do_redir = true
	if url:match('^HTTPS') then
		doer = HTTPS
		do_redir = false
	end
	local _, code, header = doer.request {
		method = "HEAD",
		url = url,
		redirect = do_redir
	}
	if not header then
		return
	end
	return header, code
end
function was_modified_since(url, last_modified)
	local doer = HTTP
	local do_redir = true
	if url:match('^HTTPS') then
		doer = HTTPS
		do_redir = false
	end
	local _, code, header = doer.request {
		url = url,
		method = "HEAD",
		redirect = do_redir,
		headers = {
			["If-Modified-Since"] = last_modified
		}
	}
	if code == 304 then
		return false, nil, code
	else
		if header["last-modified"] then
			new_last_modified = header["last-modified"]
		elseif header["Last-Modified"] then
			new_last_modified = header["Last-Modified"]
		end
		return true, new_last_modified, code
	end
end
function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end
function functions.fix_utf8(str)
	return string.char(utf8.codepoint(str, 1, -1))
end
functions.set_meta = {}
functions.set_meta.__index = functions.set_meta
function functions.new_set()
	return setmetatable({__count = 0}, functions.set_meta)
end
function functions.set_meta:add(x)
	if x == "__count" then
		return false
	else
		if not self[x] then
			self[x] = true
			self.__count = self.__count + 1
		end
		return true
	end
end
function functions.set_meta:remove(x)
	if x == "__count" then
		return false
	else
		if self[x] then
			self[x] = nil
			self.__count = self.__count - 1
		end
		return true
	end
end
function functions.set_meta:__len()
	return self.__count
end
function functions.answer_inline_query(inline_query, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter)
	return telegram_api.request('answerInlineQuery', {
		inline_query_id = inline_query.id,
		results = results,
		cache_time = cache_time,
		is_personal = is_personal,
		next_offset = next_offset,
		switch_pm_text = switch_pm_text,
		switch_pm_parameter = switch_pm_parameter
	} )
end
function functions.abort_inline_query(inline_query)
	return telegram_api.request('answerInlineQuery', {
		inline_query_id = inline_query.id,
		cache_time = 5,
		is_personal = true
	} )
end
return functions