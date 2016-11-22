local set = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function set:init(configuration)
	set.arguments = 'set <variable> <value>'
	set.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('set').table
	set.help = configuration.commandPrefix .. 'set <variable> <value> - Sets the given variable to the given value. Use \'' .. configuration.commandPrefix .. 'get <variable>\' to return it.'
end

function set:setValue(message, variable, value)
	local hash = mattata.getRedisHash(message, 'variables')
	if hash then
		redis:hset(hash, variable, value)
		return '\'' .. variable .. '\' has been set to \'' .. value .. '\''
	end
end

function set:removeValue(message, variable)
	local hash = mattata.getRedisHash(message, 'variables')
	if redis:hexists(hash, variable) == true then
		redis:hdel(hash, variable)
		return '2'
	else
		return '3'
	end
end

function set:onMessage(message)
	local input = mattata.input(message.text)
	if not input or not input:match('([^%s]+) (.+)') then
		mattata.sendMessage(message.chat.id, set.help, 'Markdown', true, false, message.message_id)
		return
	end
	local variable = input:match('([^%s]+) ')
	local value = input:match(' (.+)')
	if value == 'nil' then
		output = set:removeValue(message, variable)
	else
		output = set:setValue(message, variable, value)
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return set