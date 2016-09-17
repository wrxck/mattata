local functions = {}
local HTTP = require('socket.http')
local ltn12 = require('ltn12')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local telegram_api = require('telegram_api')
function functions:send_message(chat_id, text, disable_web_page_preview, reply_to_message_id, use_markdown)
	return telegram_api.request(self, 'sendMessage', {
		chat_id = chat_id,
		text = text,
		disable_web_page_preview = disable_web_page_preview,
		reply_to_message_id = reply_to_message_id,
		parse_mode = use_markdown and 'Markdown' or nil
	} )
end
function functions:send_reply(old_msg, text, use_markdown)
	return telegram_api.request(self, 'sendMessage', {
		chat_id = old_msg.chat.id,
		text = text,
		disable_web_page_preview = true,
		reply_to_message_id = old_msg.message_id,
		parse_mode = use_markdown and 'Markdown' or nil
	} )
end
function functions.get_word(s, i)
	s = s or ''
	i = i or 1
	local t = {}
	for w in s:gmatch('%g+') do
		table.insert(t, w)
	end
	return t[i] or false
end
function functions.index(s)
	local t = {}
	for w in s:gmatch('%g+') do
		table.insert(t, w)
	end
	return t
end

function functions.input(s)
	if not s:find(' ') then
		return false
	end
	return s:sub(s:find(' ')+1)
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
function functions.trim(str)
	local s = str:gsub('^%s*(.-)%s*$', '%1')
	return s
end
function functions.load_data(filename)
	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)
	return data
end
function functions.save_data(filename, data)
	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()
end
function functions.get_coords(input, configuration)
	local url = 'http://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		return configuration.errors.connection
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		return configuration.errors.results
	end
	return {
		lat = jdat.results[1].geometry.location.lat,
		lon = jdat.results[1].geometry.location.lng
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
function functions:id_from_username(input)
	input = input:gsub('^@', '')
	for _, user in pairs(self.database.users) do
		if user.username and user.username:lower() == input:lower() then
			return user.id
		end
	end
end
function functions:id_from_message(msg)
	if msg.reply_to_message then
		return msg.reply_to_message.from.id
	else
		local input = functions.input(msg.text)
		if input then
			if tonumber(input) then
				return tonumber(input)
			elseif input:match('^@') then
				return functions.id_from_username(self, input)
			end
		end
	end
end
function functions:user_from_message(msg, no_extra)
	local input = functions.input(msg.text_lower)
	local target = {}
	if msg.reply_to_message then
		for k,v in pairs(self.database.users[msg.reply_to_message.from.id_str]) do
			target[k] = v
		end
	elseif input and tonumber(input) then
		target.id = tonumber(input)
		if self.database.users[input] then
			for k,v in pairs(self.database.users[input]) do
				target[k] = v
			end
		end
	elseif input and input:match('^@') then
		local uname = input:gsub('^@', '')
		for _,v in pairs(self.database.users) do
			if v.username and uname == v.username:lower() then
				for key, val in pairs(v) do
					target[key] = val
				end
			end
		end
		if not target.id then
			target.err = 'Sorry, but I don\'t recognise that username.'
		end
	else
		target.err = 'Please specify a user by replying to a message they\'ve sent, or by using their username (or numerical ID) as a command argument.'
	end
	if not no_extra then
		if target.id then
			target.id_str = tostring(target.id)
		end
		if not target.first_name then
			target.first_name = 'User'
		end
		target.name = functions.build_name(target.first_name, target.last_name)
	end
	return target
end
function functions:handle_exception(err, message, configuration)
	if not err then err = '' end
	local output = '\n[' .. os.date('%F %T', os.time()) .. ']\n' .. self.info.username .. ': ' .. err .. '\n' .. message .. '\n'
	if configuration.console_chat then
		output = '```' .. output .. '```'
		functions.send_message(self, configuration.console_chat, output, true, nil, true)
	else
		print(output)
	end
end
function functions.download_file(url, filename)
	if not filename then
		filename = url:match('.+/(.-)$') or os.time()
		filename = '/tmp/' .. filename
	end
	local body = {}
	local doer = HTTP
	local do_redir = true
	if url:match('^https') then
		doer = HTTPS
		do_redir = false
	end
	local _, res = doer.request{
		url = url,
		sink = ltn12.sink.table(body),
		redirect = do_redir
	}
	if res ~= 200 then return false end
	local file = io.open(filename, 'w+')
	file:write(table.concat(body))
	file:close()
	return filename
end
function functions.markdown_escape(text)
	text = text:gsub('_', '\\_')
	text = text:gsub('%[', '\\[')
	text = text:gsub('%]', '\\]')
	text = text:gsub('%*', '\\*')
	text = text:gsub('`', '\\`')
	return text
end
functions.md_escape = functions.markdown_escape
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
function functions.with_http_timeout(timeout, fun)
	local original = HTTP.TIMEOUT
	HTTP.TIMEOUT = timeout
	fun()
	HTTP.TIMEOUT = original
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
	utf_8 = '([%z\1-\127\194-\244][\128-\191]*)',
}
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
local function create_folder(name)
	local cmd = io.popen('sudo mkdir '..name)
	cmd:read('*all')
	cmd = io.popen('sudo chmod -R 777 '..name)
	cmd:read('*all')
	cmd:close()
end
function functions.create_file(path, text, mode)
	if not mode then
		mode = "w"
	end
	file = io.open(path, mode)
	if not file then
		create_folder('files')
		file = io.open(path, mode)
		if not file then
			return false
		end
	end
	file:write(text)
	file:close()
	return true
end
function functions.set_meta:__len()
	return self.__count
end
return functions