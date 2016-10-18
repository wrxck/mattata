local leavechat = {}
local functions = require('functions')
function leavechat:init(configuration)
	leavechat.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('leavechat', true).table
end
function leavechat:action(msg, configuration)
	local input = functions.input(msg.text)
	local admin_list, t = functions.get_chat_administrators(msg.chat.id)
	if admin_list then
		local is_admin = false
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == msg.from.id then
				is_admin = true
			elseif msg.from.id == configuration.owner_id then
				is_admin = true
			end
		end
		if is_admin then
			functions.send_message(msg.chat.id, 'Well, fuck you then, ' .. msg.from.first_name .. '...', true, nil, true)
			functions.leave_chat(msg.chat.id)
			return
		else
			functions.send_message(msg.chat.id, 'Sorry, you do not appear to be an administrator for this group.', true, nil, true)
			return
		end
	end
end
return leavechat