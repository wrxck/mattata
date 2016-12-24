local uuid = {}
local socket = require('socket')
local uuidgen = require('uuid')
local mattata = require('mattata')

function uuid:init(configuration)
	uuid.arguments = 'uuid'
	uuid.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('uuid'):command('guid').table
	uuid.help = configuration.commandPrefix .. 'uuid - Generates a random UUID.'
end

function uuid:onMessage(message) mattata.sendMessage(message.chat.id, '<pre>' .. uuidgen() .. '</pre>', 'HTML', true, false, message.message_id) end

return uuid