local about = {}

local bot = require('mattata.bot')
local utilities = require('mattata.utilities')

about.command = 'about'
about.doc = 'Information about mattata.'

about.triggers = {
	''
}

function about:action(msg, config)

	if msg.forward_from then return end

	local output = config.about_text .. '\nCreated by wrxck. Based on the otouto project by topkecleon.'

	if
		(msg.new_chat_member and msg.new_chat_member.id == self.info.id)
		or msg.text_lower:match('^'..config.cmd_pat..'about$')
		or msg.text_lower:match('^'..config.cmd_pat..'about@'..self.info.username:lower()..'$')
		or msg.text_lower:match('^'..config.cmd_pat..'start$')
		or msg.text_lower:match('^'..config.cmd_pat..'start@'..self.info.username:lower()..'$')
	then
		utilities.send_message(self, msg.chat.id, output, true, nil, true)
		return
	end

	return true

end

return about
