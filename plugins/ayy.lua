local ayy = {}
local functions = require('functions')
function ayy:init(configuration)
	ayy.triggers = 'ayy'
end
function ayy:action(msg)
	local output = msg.text_lower:match('ayy') and 'lmao'
	functions.send_reply(self, msg, output)
end
return ayy