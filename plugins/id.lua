local id = {}
local mattata = require('mattata')

function id:init(configuration)
	id.arguments = 'id <user>'
	id.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('id', true).table
	id.inlineCommands = id.commands
	id.help = configuration.commandPrefix .. 'id <user> - Sends the name, ID, and username for the given users. Arguments must be usernames and/or IDs. Input is also accepted via reply. If no input is given, info about you is sent.'
end

function id.format(t)
	if t.username then
		return string.format(
			'@%s, AKA %s `[%s]`.\n',
			t.username,
			mattata.build_name(t.first_name, t.last_name),
			t.id
		)
	else
		return string.format(
			'%s `[%s]`.\n',
			mattata.build_name(t.first_name, t.last_name),
			t.id
		)
	end
end

function id:onInlineCallback(inline_query, configuration)
	local results = '[{"type":"article","id":"1","title":"/id","description":"Your ID is: ' .. inline_query.from.id .. '","input_message_content":{"message_text":"' .. inline_query.from.id .. '","parse_mode":"Markdown"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function id:onMessageReceive(msg)
	local output
	local input = mattata.input(msg.text)
	if msg.reply_to_message then
		output = id.format(msg.reply_to_message.from)
	elseif input then
		output = ''
		for user in input:gmatch('%g+') do
			if tonumber(user) then
				if self.db.users[user] then
					output = output .. id.format(self.db.users[user])
				else
					output = output .. 'I don\'t recognise that ID (' .. user .. ').\n'
				end
			elseif user:match('^@') then
				local t = mattata.resUsername(self, user)
				if t then
					output = output .. id.format(t)
				else
					output = output .. 'I don\'t recognise that username (' .. user .. ').\n'
				end
			else
				output = output .. 'Invalid username or ID (' .. user .. ').\n'
			end
		end
	else
		output = id.format(msg.from)
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return id