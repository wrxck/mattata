local lua = {}
local mattata = require('mattata')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.serpent')

function lua:init(configuration)
	lua.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lua', true):c('return', true).table
	JSON = require('dependencies.dkjson')
	lua.serialise = function(t) return JSON.encode(t, {indent=true}) end
	lua.loadstring = load or loadstring
	lua.error_message = function(x)
		return 'Error:\n' .. tostring(x)
	end
end

function lua:onMessageReceive(msg, configuration)
	if msg.from.id ~= configuration.owner then
		return true
	end
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, 'Please enter a string of lua to execute', nil, true, false, msg.message_id, nil)
		return
	end
	if msg.text_lower:match('^' .. configuration.commandPrefix .. 'return') then
		input = 'return ' .. input
	end
	local output, success = loadstring( [[
		local mattata = require('mattata')
		local JSON = require('dependencies.dkjson')
		local URL = require('dependencies.socket.url')
		local HTTP = require('dependencies.socket.http')
		local HTTPS = require('dependencies.ssl.https')
		return function (msg, configuration) ]] .. input .. [[ end
	]] )
	if output == nil then
		output = success
	else
		success, output = xpcall(output(), lua.error_message, msg, configuration)
	end
	if output ~= nil then
		if type(output) == 'table' then
			local s = lua.serialise(output)
			output = s
		end
		output = '`' .. tostring(output) .. '`'
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return lua