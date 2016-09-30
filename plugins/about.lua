local about = {}
local mattata = require('mattata')
local functions = require('functions')
about.command = 'about'
about.doc = 'Information about mattata.'
about.triggers = { '' }
function about:action(msg, configuration)
	if msg.forward_from then
		return
	end
	local output = configuration.about_text .. '\nCreated by wrxck. Originally based on otouto by topkecleon.'
	if (msg.new_chat_member and msg.new_chat_member.id == self.info.id) or msg.text_lower:match('^' .. configuration.command_prefix .. 'about$') or msg.text_lower:match('^' .. configuration.command_prefix .. 'about@' .. self.info.username:lower() .. '$') or msg.text_lower:match('^' .. configuration.command_prefix .. 'start$') or msg.text_lower:match('^' .. configuration.command_prefix .. 'start@' .. self.info.username:lower() .. '$') then
		functions.send_reply(msg, '`' .. output .. '`', true)
		return
	end
	return true
end
return about