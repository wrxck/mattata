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

function faces:onMessageReceive(msg, configuration)
	if string.match(msg.text_lower, configuration.commandPrefix .. 'faces') then
		local res = mattata.sendMessage(msg.from.id, faces.help, 'HTML', true, false, nil, nil)
		if not res then
			mattata.sendMessage(msg.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=faces) so I can send you a list of the available faces.', 'Markdown', true, false, msg.message_id, nil)
			return
		elseif msg.chat.type ~= 'private' then
			mattata.sendMessage(msg.chat.id, 'I have sent you a private message containing a list of the available faces!', nil, true, false, msg.message_id, nil)
			return
		end
	end
	for commands, face in pairs(configuration.faces) do
		if string.match(msg.text_lower, configuration.commandPrefix .. commands) then
			mattata.sendMessage(msg.chat.id, face, 'HTML', true, false, msg.message_id, nil)
			return
		end
	end
end

return faces