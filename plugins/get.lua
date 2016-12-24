local get = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function get:init(configuration)
	get.arguments = 'get <variable>'
	get.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('get').table
	get.help = configuration.commandPrefix .. 'get <variable> - Returns the stored value of the given variable.'
end

function get.getValue(message, variable)
	local hash = mattata.getRedisHash(message, 'variables')
	if hash then
		local value = redis:hget(hash, variable)
		if not value then return 'There is currently no saved value for \'' .. variable .. '\'.' else return '\'' .. variable .. '\' = \'' .. value .. '\'' end
	end
end

function get.listVariables(message)
	local hash = mattata.getRedisHash(message, 'variables')
	if hash then
		local variables = redis:hkeys(hash)
		local text = ''
		for i = 1, #variables do
			get.getValue(message, variables[i])
			text = text .. variables[i] .. '\n'
		end
		if text == '' or text == nil then return 'No variables have been given values in this chat!' else return text end
	end
end

function get:onMessage(message)
	local input = mattata.input(message.text)
	local output
	if input then output = get.getValue(message, input:match('(.+)')) else output = get.listVariables(message) end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return get