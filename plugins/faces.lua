local faces = {}
local functions = require('functions')
function faces:init(configuration)
	faces.help = 'faces:\n'
	faces.command = 'faces'
	faces.doc = configuration.command_prefix .. 'faces - Returns a list of expressive-emoticon commands.'
	faces.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('faces').table
	local username = self.info.username:lower()
	for trigger, reaction in pairs(configuration.faces) do
		faces.help = faces.help .. '• ' .. configuration.command_prefix .. trigger .. ': ' .. reaction .. '\n'
		table.insert(faces.triggers, '^'..configuration.command_prefix..trigger)
		table.insert(faces.triggers, '^'..configuration.command_prefix..trigger..'@'..username)
		table.insert(faces.triggers, configuration.command_prefix..trigger..'$')
		table.insert(faces.triggers, configuration.command_prefix..trigger..'@'..username..'$')
		table.insert(faces.triggers, '\n'..configuration.command_prefix..trigger)
		table.insert(faces.triggers, '\n'..configuration.command_prefix..trigger..'@'..username)
		table.insert(faces.triggers, configuration.command_prefix..trigger..'\n')
		table.insert(faces.triggers, configuration.command_prefix..trigger..'@'..username..'\n')
	end
end
function faces:action(msg, configuration)
	if string.match(msg.text_lower, configuration.command_prefix .. 'faces') then
		functions.send_message(msg.chat.id, faces.help, true, nil, 'html')
		return
	end
	for trigger,reaction in pairs(configuration.faces) do
		if string.match(msg.text_lower, configuration.command_prefix .. trigger) then
			functions.send_message(msg.chat.id, reaction, true, nil, 'html')
			return
		end
	end
end
return faces