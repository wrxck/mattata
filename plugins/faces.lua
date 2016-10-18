local faces = {}
local functions = require('functions')
function faces:init(configuration)
	faces.help = '<b>Available faces:</b>\n'
	faces.command = 'faces'
	faces.documentation = configuration.command_prefix .. 'faces - Returns a list of expressive-emoticon commands.'
	faces.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('faces').table
	local username = self.info.username:lower()
	for trigger, face in pairs(configuration.faces) do
		faces.help = faces.help .. '• ' .. configuration.command_prefix .. trigger .. ': ' .. face .. '\n'
		table.insert(faces.triggers, '^' .. configuration.command_prefix .. trigger)
		table.insert(faces.triggers, '^' .. configuration.command_prefix .. trigger .. '@' .. username)
		table.insert(faces.triggers, configuration.command_prefix .. trigger .. '$')
		table.insert(faces.triggers, configuration.command_prefix .. trigger .. '@' .. username .. '$')
		table.insert(faces.triggers, '\n' .. configuration.command_prefix .. trigger)
		table.insert(faces.triggers, '\n' .. configuration.command_prefix .. trigger .. '@' .. username)
		table.insert(faces.triggers, configuration.command_prefix .. trigger .. '\n')
		table.insert(faces.triggers, configuration.command_prefix .. trigger .. '@' .. username .. '\n')
	end
end
function faces:action(msg, configuration)
	if string.match(msg.text_lower, configuration.command_prefix .. 'faces') then
		local res = functions.send_message(msg.from.id, faces.help, true, nil, 'html')
		if not res then
			functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=faces) so I can send you a list of the available faces.', true)
			return
		elseif msg.chat.type ~= 'private' then
			functions.send_reply(msg, 'I have sent you a private message containing a list of the available faces.')
			return
		end
	end
	for trigger, face in pairs(configuration.faces) do
		if string.match(msg.text_lower, configuration.command_prefix .. trigger) then
			functions.send_message(msg.chat.id, face, true, nil, 'html')
			return
		end
	end
end
return faces