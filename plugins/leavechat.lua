local leavechat = {}
local mattata = require('mattata')

function leavechat:init(configuration)
	leavechat.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('leavechat', true).table
end

function leavechat:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	local admin_list, t = mattata.getChatAdministrators(msg.chat.id)
	if admin_list then
		local is_admin = false
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == msg.from.id then
				is_admin = true
			elseif msg.from.id == configuration.owner then
				is_admin = true
			end
		end
		if is_admin then
			mattata.sendMessage(msg.chat.id, 'Well, fuck you then, ' .. msg.from.first_name .. '...', nil, true, false, msg.message_id, nil)
			mattata.leaveChat(msg.chat.id)
			return
		else
			mattata.sendMessage(msg.chat.id, 'Sorry, you do not appear to be an administrator for this group.', nil, true, false, msg.message_id, nil)
			return
		end
	end
end

return leavechat