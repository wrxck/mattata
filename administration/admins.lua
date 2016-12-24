local admins = {}
local mattata = require('mattata')

function admins:init(configuration)
	admins.arguments = 'admins'
	admins.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('admins').table
	admins.help = configuration.commandPrefix .. 'admins - Sends a list of the chat\'s administrators.'
end

function admins.formatAdminList(list)
	local administrators = ''
	local administrator = ''
	local creator = ''
	for k, v in pairs(list.result) do
		if v.status == 'administrator' and v.user.first_name ~= '' then
			administrator = mattata.htmlEscape(v.user.first_name)
			if v.user.username then administrator = '<a href="https://telegram.me/' .. v.user.username .. '">' .. mattata.htmlEscape(v.user.first_name) .. '</a>' end
			administrators = administrators .. '• ' .. administrator .. ' <code>[' .. v.user.id .. ']</code>\n'
		elseif v.status == 'creator' and v.user.first_name ~= '' then
			creator = mattata.htmlEscape(v.user.first_name)
			if v.user.username then creator = '<a href="https://telegram.me/' .. v.user.username .. '">' .. mattata.htmlEscape(v.user.first_name) .. '</a>' end
			creator = creator .. ' <code>[' .. v.user.id .. ']</code>'
		end
	end
	if creator == '' then creator = '-' end
	if administrators == '' then administrators = '-' end
	return creator, administrators
end

function admins:onMessage(message)
	local res = mattata.getChatAdministrators(message.chat.id)
	if not res then mattata.sendMessage(message.chat.id, 'I couldn\'t get a list of administrators in this chat.', nil, true, false, message.message_id) return end
	local creator, administrators = admins.formatAdminList(res)
	mattata.sendMessage(message.chat.id, '<b>Creator:</b> ' .. creator .. '\n<b>Administrators:</b>\n' .. administrators, 'HTML', true, false, message.message_id)
end

return admins