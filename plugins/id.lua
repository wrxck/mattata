local functions = require('functions')
local id = {}
function id:init(configuration)
	id.command = 'id <username/id>'
	id.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('id', true).table
	id.doc = configuration.command_prefix .. [[id <username/id> ... Displays detailed information about a user.]]
end
function id.format(t)
	if t.username then
		return string.format(
			'@%s, who is also known as *%s* ```[%s]```.\n',
			t.username,
			functions.build_name(t.first_name, t.last_name),
			t.id
		)
	else
		return string.format(
			'*%s* ```[%s]```.\n',
			functions.build_name(t.first_name, t.last_name),
			t.id
		)
	end
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
					output = output .. 'I\'m sorry, but don\'t recognise that ID (' .. user .. ').\n'
				end
			elseif user:match('^@') then
				local t = functions.resolve_username(self, user)
				if t then
					output = output .. id.format(t)
				else
					output = output .. 'I\'m sorry, but I don\'t recognise that username (' .. user .. ').\n'
				end
			else
				output = output .. 'Invalid username or ID (' .. user .. ').\n'
			end
		end
	else
		output = id.format(msg.from)
	end
	functions.send_reply(self, msg, output, true)
end
return id