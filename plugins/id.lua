local id = {}
local functions = require('functions')
function id:init(configuration)
	id.command = 'id <user>'
	id.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('id', true).table
	id.inline_triggers = id.triggers
	id.doc = configuration.command_prefix .. 'id <user> - Sends the name, ID, and username for the given users. Arguments must be usernames and/or IDs. Input is also accepted via reply. If no input is given, info about you is sent.'
end
function id.format(t)
	if t.username then
		return string.format(
			'@%s, AKA %s `[%s]`.\n',
			t.username,
			functions.build_name(t.first_name, t.last_name),
			t.id
		)
	else
		return string.format(
			'%s `[%s]`.\n',
			functions.build_name(t.first_name, t.last_name),
			t.id
		)
	end
end
function id:inline_callback(inline_query, configuration, matches)
	local output = inline_query.from.id
	local results = '[{"type":"article","id":"9","title":"/id","description":"Get your numerical ID","input_message_content":{"message_text":"Your ID is: '..inline_query.from.id..'","parse_mode":"Markdown"}}]'
	functions.answer_inline_query(inline_query, results, 600, nil, nil, inline_query.from.id)
end
function id:action(msg)
	local output
	local input = functions.input(msg.text)
	if msg.reply_to_message then
		output = id.format(msg.reply_to_message.from)
	elseif input then
		output = ''
		for user in input:gmatch('%g+') do
			if tonumber(user) then
				if self.database.users[user] then
					output = output .. id.format(self.database.users[user])
				else
					output = output .. 'I don\'t recognise that ID (' .. user .. ').\n'
				end
			elseif user:match('^@') then
				local t = functions.resolve_username(self, user)
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
	functions.send_reply(msg, output, true)
end
return id