local me = {}
local mattata = require('mattata')

function me:init(configuration)
	me.arguments = 'me'
	me.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('me').table
	me.help = configuration.commandPrefix .. 'me - Returns user-data stored by mattata.'
end

function me:onMessageReceive(msg, configuration)
	local user
	if msg.from.id == configuration.owner then
		if msg.reply_to_message then
			user = msg.reply_to_message.from
		else
			local input = mattata.input(msg.text)
			if input then
				if tonumber(input) then
					user = self.db.users[input]
					if not user then
						mattata.sendMessage(msg.chat.id, 'Unrecognised ID.', nil, true, false, msg.message_id, nil)
						return
					end
				elseif input:match('^@') then
					user = mattata.resolveUsername(self, input)
					if not user then
						mattata.sendMessage(msg.chat.id, 'Unrecognised username.', nil, true, false, msg.message_id, nil)
						return
					end
				else
					mattata.sendMessage(msg.chat.id, 'Invalid username or ID.', nil, true, false, msg.message_id, nil)
					return
				end
			end
		end
	end
	user = user or msg.from
	local userdata = self.db.userdata[tostring(user.id)] or {}
	local data = {}
	for k, v in pairs(userdata) do
		table.insert(data, string.format(
			'*%s:* `%s`\n',
			mattata.markdownEscape(k),
			mattata.markdownEscape(v)
		))
	end
	local output
	if #data == 0 then
		output = 'There is no data stored for this user.'
	else
		output = string.format(
			'*%s* `[%s]`*:*\n',
			mattata.markdownEscape(mattata.buildName(
				user.first_name,
				user.last_name
			)),
			user.id
		) .. table.concat(data)
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return me