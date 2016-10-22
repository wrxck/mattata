local about = {}
local mattata = require('mattata')
local mattata = require('mattata')

about.arguments = 'about'
about.help = 'Information about mattata.'
about.commands = { '' }

function about:onMessageReceive(msg, configuration)
	if msg.forward_from then
		return
	end
	local output = configuration.aboutText .. '\nCreated by @wrxck.'
	if (msg.new_chat_member and msg.new_chat_member.id == self.info.id) or msg.text_lower:match('^' .. configuration.commandPrefix .. 'about$') or msg.text_lower:match('^' .. configuration.commandPrefix .. 'about@' .. self.info.username:lower() .. '$') or msg.text_lower:match('^' .. configuration.commandPrefix .. 'start$') or msg.text_lower:match('^' .. configuration.commandPrefix .. 'start@' .. self.info.username:lower() .. '$') then
		mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id)
		return
	end
	return true
end

return about