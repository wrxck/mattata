--[[

    Based on luarun.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local lua = {}
local mattata = require('mattata')
local URL = require('socket.url')
local JSON = require('serpent')

function lua:init(configuration)
	lua.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lua'):c('return').table
	JSON = require('dkjson')
	lua.serialise = function(t) return JSON.encode(t, {indent=true}) end
	lua.loadstring = load or loadstring
	lua.error_message = function(x)
		return 'Error:\n' .. tostring(x)
	end
end

function lua:onMessageReceive(message, configuration)
	if message.from.id ~= configuration.owner then
		return true
	end
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, 'Please enter a string of lua to execute', nil, true, false, message.message_id, nil)
		return
	end
	if message.text_lower:match('^' .. configuration.commandPrefix .. 'return') then
		input = 'return ' .. input
	end
	local output, success = loadstring( [[
		local mattata = require('mattata')
		local JSON = require('dkjson')
		local URL = require('socket.url')
		local HTTP = require('socket.http')
		local HTTPS = require('ssl.https')
		return function (message, configuration) ]] .. input .. [[ end
	]] )
	if output == nil then
		output = success
	else
		success, output = xpcall(output(), lua.error_message, message, configuration)
	end
	if output ~= nil then
		if type(output) == 'table' then
			local s = lua.serialise(output)
			output = s
		end
		output = '`' .. tostring(output) .. '`'
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
end

return lua