local lua = {}
local functions = require('functions')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.serpent')
function lua:init(configuration)
	lua.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lua', true):t('return', true).table
	JSON = require('dependencies.dkjson')
	lua.serialise = function(t) return JSON.encode(t, {indent=true}) end
	lua.loadstring = load or loadstring
	lua.error_message = function(x)
		return 'Error:\n' .. tostring(x)
	end
end
function lua:action(msg, configuration)
	if msg.from.id ~= configuration.owner_id then
		return true
	end
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, 'Please enter a string of lua to execute')
		return
	end
	if msg.text_lower:match('^' .. configuration.command_prefix .. 'return') then
		input = 'return ' .. input
	end
	local output, success = loadstring( [[
		local mattata = require('mattata')
		local telegram_api = require('telegram_api')
		local functions = require('functions')
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
	functions.send_message(msg.chat.id, output, true, msg.message_id, true)
end
return lua