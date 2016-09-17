local nick = {}
local functions = require('functions')
function nick:init(configuration)
	nick.command = 'nick <nickname>'
	nick.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('nick', true).table
	nick.doc = configuration.command_prefix .. [[nick <nickname> Set your nickname. Use "]] .. configuration.command_prefix .. 'nick --" to delete it.'
end
function nick:action(msg, configuration)
	local id_str, name
	if msg.from.id == configuration.admin and msg.reply_to_message then
		id_str = tostring(msg.reply_to_message.from.id)
		name = functions.build_name(msg.reply_to_message.from.first_name, msg.reply_to_message.from.last_name)
	else
		id_str = tostring(msg.from.id)
		name = functions.build_name(msg.from.first_name, msg.from.last_name)
	end
	self.database.userdata[id_str] = self.database.userdata[id_str] or {}
	local output
	local input = functions.input(msg.text)
	if not input then
		if self.database.userdata[id_str].nickname then
			output = name .. '\'s nickname is "' .. self.database.userdata[id_str].nickname .. '".'
		else
			output = name .. ' currently has no nickname.'
		end
	elseif functions.utf8_len(input) > 25 then
		output = 'The character limit for nicknames is 25.'
	elseif input == '--' or input == functions.char.em_dash then
		self.database.userdata[id_str].nickname = nil
		output = name .. '\'s nickname has been deleted.'
	else
		input = input:gsub('\n', ' ')
		self.database.userdata[id_str].nickname = input
		output = name .. '\'s nickname has been set to "' .. input .. '".'
	end
	functions.send_reply(self, msg, output)
end
return nick