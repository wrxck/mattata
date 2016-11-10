local faces = {}
local mattata = require('mattata')

function faces:init(configuration)
	faces.help = '<b>Available faces:</b>\n'
	faces.arguments = 'faces'
	faces.help = configuration.commandPrefix .. 'faces - Returns a list of expressive-emoticon commands.\n'
	faces.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('faces').table
	local username = self.info.username:lower()
	for commands, face in pairs(configuration.faces) do
		faces.help = faces.help .. '• ' .. configuration.commandPrefix .. commands .. ': ' .. face .. '\n'
		table.insert(faces.commands, configuration.commandPrefix .. commands)
	end
end

function faces:onMessageReceive(message, configuration)
	if string.match(message.text_lower, configuration.commandPrefix .. 'faces') then
		local res = mattata.sendMessage(message.from.id, faces.help, 'HTML', true, false)
		if not res then
			mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=faces) so I can send you a list of the available faces.', 'Markdown', true, false, message.message_id)
			return
		elseif message.chat.type ~= 'private' then
			mattata.sendMessage(message.chat.id, 'I have sent you a private message containing a list of the available faces!', nil, true, false, message.message_id)
			return
		end
	end
	for commands, face in pairs(configuration.faces) do
		if string.match(message.text_lower, configuration.commandPrefix .. commands) then
			mattata.sendMessage(message.chat.id, face, 'HTML', true, false, message.message_id)
			return
		end
	end
end

return faces