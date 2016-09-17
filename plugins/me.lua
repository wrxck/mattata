local me = {}
local functions = require('functions')
function me:init(configuration)
	me.command = 'me'
	me.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('me', true).table
	me.doc = 'Prints any userdata stored by mattata which is related to the specified user.'
end
function me:action(msg, configuration)
	local userdata = self.database.userdata[tostring(msg.from.id)] or {}
	if msg.from.id == configuration.admin then
		if msg.reply_to_message then
			userdata = self.database.userdata[tostring(msg.reply_to_message.from.id)]
		else
			local input = functions.input(msg.text)
			if input then
				local user_id = functions.id_from_username(self, input)
				if user_id then
					userdata = self.database.userdata[tostring(user_id)] or {}
				end
			end
		end
	end
	local output = ''
	for k,v in pairs(userdata) do
		output = output .. '*' .. k .. ':* `' .. tostring(v) .. '`\n'
	end
	if output == '' then
		output = 'Sorry, but there is no data stored for this user.'
	end
	functions.send_reply(self, msg, output, true)
end
return me