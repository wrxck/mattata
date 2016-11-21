local guidgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function guidgen:init(configuration)
	guidgen.arguments = 'guidgen'
	guidgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('guidgen').table
	guidgen.help = configuration.commandPrefix .. 'guidgen - Generates a random GUID.'
end

function guidgen:onMessageReceive(message, language)
	local str, res = HTTP.request('http://www.passwordrandom.com/query?command=guid&format=text&count=1')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '```\n' .. str .. '\n```', 'Markdown', true, false, message.message_id)
end

return guidgen