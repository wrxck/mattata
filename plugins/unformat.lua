local unformat = {}
local mattata = require('mattata')
local utf8 = require('lua-utf8')

function unformat:init(configuration)
	unformat.arguments = 'unformat'
	unformat.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('unformat').table
	unformat.help = configuration.commandPrefix .. 'unformat - Returns the raw Markdown formatting of the replied-to message. Special characters are not supported.'
end

function unformat.markdown(entity, str)
	local sub = str:sub(entity.offset + 1, entity.offset + entity.length)
	if entity.type == 'italic' then
		return '_' .. sub .. '_'
	elseif entity.type == 'bold' then
		return '*' .. sub .. '*'
	elseif entity.type =='text_link' then
		return '[' .. sub .. '](' .. entity.url ..')'
	elseif entity.type == 'pre' then
		return '```' .. sub .. '```'
	elseif entity.type == 'code' then
		return '`' .. sub .. '`'
	end
end

function unformat:onMessage(message, configuration)
	if not message.reply_to_message then
		mattata.sendMessage(message.chat.id, unformat.help, nil, true, false, message.message_id)
		return
	end
	local output = ''
	local str = message.reply_to_message.text
	if str:len() > utf8.len(str) then
		mattata.sendMessage(message.chat.id, unformat.help, nil, true, false, message.message_id)
		return
	end
	if message.reply_to_message.entities then
		local char = 0
		for k, v in pairs(message.reply_to_message.entities) do
			if v.offset ~= char then
				output = output .. str:sub(char + 1, v.offset)
				char = v.offset
			end
			output = output .. unformat.markdown(v, str)
			char = char + v.length
		end
	else
		output = message.reply_to_message.text
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return unformat