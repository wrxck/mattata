local lua = {}
local functions = require('functions')
local URL = require('socket.url')
local JSON = require('dkjson')
function lua:init(configuration)
	lua.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lua', true):t('exec', true).table
end
function lua:action(msg, configuration)
	if msg.from.id ~= configuration.admin then
		return true
	end
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(self, msg, 'Please enter a string of Lua to execute.')
		return
	end
	if msg.text_lower:match('^'..configuration.command_prefix..'exec') then
		input = 'exec ' .. input
	end
	local output = loadstring( [[
		local mattata = require('mattata')
		local telegram_api = require('telegram_api')
		local functions = require('functions')
		local JSON = require('dkjson')
		local URL = require('socket.url')
		local HTTP = require('socket.http')
		return function (self, msg, configuration) ]] .. input .. [[ end
	]] )()(self, msg, configuration)
	if output ~= nil then
		if type(output) == 'table' then
			local s = JSON.encode(output, {indent=true})
			if URL.escape(s):len() < 4000 then
				output = s
			end
		end
		output = '```\n' .. tostring(output) .. '\n```'
	end
	functions.send_message(self, msg.chat.id, output, true, msg.message_id, true)
end
return lua