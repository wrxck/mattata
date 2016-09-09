local setandget = {}
local functions = require('functions')
function setandget:init(configuration)
	self.database.setandget = self.database.setandget or {}
	setandget.command = 'set <name> <value>'
	setandget.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('set', true):t('get', true).table
	setandget.doc = configuration.command_prefix .. [[set <name> <value> Stores a value with the given name. Use "]] .. configuration.command_prefix .. [[set <name> --" to delete the stored value.]] .. configuration.command_prefix .. [[get [name] Returns the stored value or a list of stored values.]]
end
function setandget:action(msg, configuration)
	local chat_id_str = tostring(msg.chat.id)
	local input = functions.input(msg.text)
	self.database.setandget[chat_id_str] = self.database.setandget[chat_id_str] or {}
	if msg.text_lower:match('^'..configuration.command_prefix..'set') then
		if not input then
			functions.send_message(self, msg.chat.id, setandget.doc, true, nil, true)
			return
		end
		local name = functions.get_word(input:lower(), 1)
		local value = functions.input(input)
		if not name or not value then
			functions.send_message(self, msg.chat.id, setandget.doc, true, nil, true)
		elseif value == '--' or value == '—' then
			self.database.setandget[chat_id_str][name] = nil
			functions.send_message(self, msg.chat.id, 'That value has been deleted.')
		else
			self.database.setandget[chat_id_str][name] = value
			functions.send_message(self, msg.chat.id, '"' .. name .. '" has been set to "' .. value .. '".', true)
		end
	elseif msg.text_lower:match('^'..configuration.command_prefix..'get') then
		if not input then
			local output
			if functions.table_size(self.database.setandget[chat_id_str]) == 0 then
				output = 'No values have been stored here.'
			else
				output = '*List of stored values:*\n'
				for k,v in pairs(self.database.setandget[chat_id_str]) do
					output = output .. '» ' .. k .. ': `' .. v .. '`\n'
				end
			end
			functions.send_message(self, msg.chat.id, output, true, nil, true)
			return
		end
		local output
		if self.database.setandget[chat_id_str][input:lower()] then
			output = '`' .. self.database.setandget[chat_id_str][input:lower()] .. '`'
		else
			output = 'There is no value with that name, please try again.'
		end
		functions.send_message(self, msg.chat.id, output, true, nil, true)
	end
end
return setandget