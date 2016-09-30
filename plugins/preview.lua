local preview = {}
local HTTP = require('socket.http')
local functions = require('functions')
function preview:init(configuration)
	preview.command = 'preview <url>'
	preview.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('preview', true).table
	preview.documentation = configuration.command_prefix .. 'preview <link> - Sends an "unlinked" preview of the given URL.'
end
function preview:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, preview.documentation)
		return
	else
		input = functions.get_word(input, 1)
	end
	if not input:match('^https?://.+') then
		input = 'http://' .. input
	end
	local res = HTTP.request(input)
	if not res then
		functions.send_reply(msg, 'Please provide a valid URL.')
	return
	end
	if res:len() == 0 then
		functions.send_reply(msg, 'Sorry, the URL you provided is not letting me generate a preview. Please check it\'s valid.')
		return
	end
	local output = '[​](' .. input .. ')'
	functions.send_message(msg.chat.id, output, false, nil, true)
end
return preview