local about = {}

local bot = require('mattata.bot')
local functions = require('mattata.functions')

about.command = 'about'
about.doc = 'Information about mattata.'
about.triggers = {
	''
}

function about:action(msg, configuration)
	if msg.forward_from then return end
	local output = configuration.about_text .. '\nCreated by wrxck. Based on the otouto project by topkecleon.'
	if
		(msg.new_chat_member and msg.new_chat_member.id == self.info.id)
		or msg.text_lower:match('^'..configuration.command_prefix..'about$')
		or msg.text_lower:match('^'..configuration.command_prefix..'about@'..self.info.username:lower()..'$')
		or msg.text_lower:match('^'..configuration.command_prefix..'start$')
		or msg.text_lower:match('^'..configuration.command_prefix..'start@'..self.info.username:lower()..'$')
	then
		functions.send_message(self, msg.chat.id, output, true, nil, true)
		return
	end
	return true
end

return about
