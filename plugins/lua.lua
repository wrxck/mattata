local lua = {}
local mattata = require('mattata')
local url = require('socket.url')
local utf8 = require('lua-utf8')
local json = require('serpent')
local users, groups

function lua:init(configuration)
	lua.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('lua'):command('return'):command('broadcast'):command('gbroadcast'):command('usercount'):command('groupcount').table
	json = require('dkjson')
	lua.serialise = function(t) return json.encode(t, {indent=true}) end
	lua.loadstring = load or loadstring
	lua.error_message = function(x) return 'Error:\n' .. tostring(x) end
	users = self.users
	groups = self.groups
end

function lua:onMessage(message, configuration)
	if not mattata.isConfiguredAdmin(message.from.id) then return end
	local input = mattata.input(message.text)
	if not input and message.text_lower ~= configuration.commandPrefix .. 'usercount' and message.text_lower ~= configuration.commandPrefix .. 'groupcount' then
		mattata.sendMessage(message.chat.id, 'Please enter a string of lua to execute', nil, true, false, message.message_id)
		return
	end
	if message.text_lower:match('^' .. configuration.commandPrefix .. 'usercount$') then
		local userCount = 0
		for k, v in pairs(users) do userCount = userCount + 1 end
		mattata.sendMessage(message.chat.id, userCount, nil, true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'groupcount$') then
		local groupCount = 0
		for k, v in pairs(groups) do groupCount = groupCount + 1 end
		mattata.sendMessage(message.chat.id, groupCount, nil, true, false, message.message_id)
	elseif message.text:match('^' .. configuration.commandPrefix .. 'broadcast') then
		local text = message.text:gsub('^' .. configuration.commandPrefix .. 'broadcast ', '')
		for k, v in pairs(users) do mattata.sendMessage(v.id, text, 'Markdown', true, false) end
		mattata.sendMessage(message.chat.id, 'Done!', nil, true, false, message.message_id)
	elseif message.text:match('^' .. configuration.commandPrefix .. 'gbroadcast') then
		local text = message.text:gsub('^' .. configuration.commandPrefix .. 'gbroadcast ', '')
		for k, v in pairs(groups) do mattata.sendMessage(v.id, text, 'Markdown', true, false) end
		mattata.sendMessage(message.chat.id, 'Done!', nil, true, false, message.message_id)
	else
		if message.text_lower:match('^' .. configuration.commandPrefix .. 'return') then input = 'return ' .. input end
		local output, success = loadstring([[
			local mattata = require('mattata')
			local json = require('dkjson')
			local url = require('socket.url')
			local utf8 = require('lua-utf8')
			local http = require('socket.http')
			local https = require('ssl.https')
			return function (message, configuration, self) ]] .. input .. [[ end
		]])
		if output == nil then output = success else success, output = xpcall(output(), lua.error_message, message, configuration) end
		if output ~= nil then
			if type(output) == 'table' then local s = lua.serialise(output); output = s end
			output = '```\n' .. tostring(output) .. '\n```'
		end
		mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
	end
end

return lua