local setandget = {}
local mattata = require('mattata')

function setandget:init(configuration)
	self.db.setandget = self.db.setandget or {}
	setandget.arguments = 'set <name> <value>'
	setandget.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('set', true):c('get', true).table
	setandget.help = configuration.commandPrefix .. 'set <name> <value> - Stores a value with the given name. ' .. configuration.commandPrefix .. 'get (name) - Returns the stored value or a list of stored values.'
end

function setandget:onMessageReceive(msg, configuration)
	local chat_id_str = tostring(msg.chat.id)
	local input = mattata.input(msg.text)
	self.db.setandget[chat_id_str] = self.db.setandget[chat_id_str] or {}
	if msg.text_lower:match('^' .. configuration.commandPrefix .. 'set') then
		if not input then
			mattata.sendMessage(msg.chat.id, setandget.help, nil, true, false, msg.message_id, nil)
			return
		end
		local name = mattata.getWord(input:lower(), 1)
		local value = mattata.input(input)
		if not name or not value then
			mattata.sendMessage(msg.chat.id, setandget.help)
		elseif value == '--' or value == '-del' then
			self.db.setandget[chat_id_str][name] = nil
			mattata.sendMessage(msg.chat.id, 'That value has been deleted.', nil, true, false, msg.message_id, nil)
		else
			self.db.setandget[chat_id_str][name] = value
			mattata.sendMessage(msg.chat.id, '"' .. name .. '" has been set to "' .. value .. '".', nil, true, false, msg.message_id, nil)
		end
	elseif msg.text_lower:match('^' .. configuration.commandPrefix .. 'get') then
		if not input then
			local output
				if mattata.table_size(self.db.setandget[chat_id_str]) == 0 then
					output = '`No values have been stored here.`'
				else
					output = '*List of stored values:*\n'
					for k,v in pairs(self.db.setandget[chat_id_str]) do
						output = output .. '» ' .. k .. ': `' .. v .. '`\n'
					end
				end
			mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
			return
		end
		local output
		if self.db.setandget[chat_id_str][input:lower()] then
			output = self.db.setandget[chat_id_str][input:lower()]
		else
			output = 'There is no value with that name, please try again.'
		end
		mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
	end
end

return setandget