local nick = {}
local mattata = require('mattata')

function nick:init(configuration)
	nick.arguments = 'nick <nickname>'
	nick.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('nick').table
	nick.help = configuration.commandPrefix .. 'nick <nickname> - Set your nickname. Use \'' .. configuration.commandPrefix .. 'nick -del\' to delete it.'
end

function nick:onMessageReceive(msg, configuration)
	local id_str = tostring(msg.from.id)
	local name = mattata.buildName(msg.from.first_name, msg.from.last_name)
	self.db.userdata[id_str] = self.db.userdata[id_str] or {}
	local output
	local input = mattata.input(msg.text)
	if not input then
		if self.db.userdata[id_str].Nickname then
			output = name .. '\'s nickname is \'' .. self.db.userdata[id_str].Nickname .. '\'.'
		else
			output = name .. ' currently has no nickname.'
		end
	elseif input:len() > 32 then
		output = 'The character limit for nicknames is 32.'
	elseif input == '-del' then
		self.db.userdata[id_str].Nickname = nil
		output = name .. '\'s nickname has been deleted.'
	else
		input = input:gsub('\n', ' ')
		self.db.userdata[id_str].Nickname = input
		output = name .. '\'s nickname has been set to \'' .. input .. '\'.'
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return nick