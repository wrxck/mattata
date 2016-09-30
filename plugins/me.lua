local me = {}
local functions = require('functions')
function me:init(configuration)
	me.command = 'me'
	me.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('me', true).table
	me.documentation = configuration.command_prefix .. 'me - Returns userdata stored by mattata.'
end
function me:action(msg, configuration)
	local user
	if msg.from.id == configuration.owner_id then
		if msg.reply_to_message then
			user = msg.reply_to_message.from
		else
			local input = functions.input(msg.text)
			if input then
				if tonumber(input) then
					user = self.database.users[input]
					if not user then
						functions.send_reply(msg, 'Unrecognised ID.')
						return
					end
				elseif input:match('^@') then
					user = functions.resolve_username(self, input)
					if not user then
						functions.send_reply(msg, 'Unrecognised username.')
						return
					end
				else
					functions.send_reply(msg, 'Invalid username or ID.')
					return
				end
			end
		end
	end
	user = user or msg.from
	local userdata = self.database.userdata[tostring(user.id)] or {}
	local data = {}
	for k,v in pairs(userdata) do
		table.insert(data, string.format(
			'*%s:* `%s`\n',
			functions.md_escape(k),
			functions.md_escape(v)
		))
	end
	local output
	if #data == 0 then
		output = 'There is no data stored for this user.'
	else
		output = string.format(
			'*%s* `[%s]`*:*\n',
			functions.md_escape(functions.build_name(
				user.first_name,
				user.last_name
			)),
			user.id
		) .. table.concat(data)
	end
	functions.send_message(msg.chat.id, output, true, nil, true)
end
return me