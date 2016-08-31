local autoresponses = {}
local functions = require('mattata.functions')
function autoresponses:init(configuration)
	autoresponses = configuration.autoresponses
	autoresponses.triggers = {
		self.info.first_name:lower() .. '%p*$'
	}
end
function autoresponses:action(msg, configuration)
	local nick = functions.build_name(msg.from.first_name, msg.from.last_name)
	if self.database.userdata[tostring(msg.from.id)] then
		nick = self.database.userdata[tostring(msg.from.id)].nickname or nick
	end
	for trigger,responses in pairs(configuration.autoresponses) do
		for _,response in pairs(responses) do
			if msg.text_lower:match(response..',? '..self.info.first_name:lower()) then
				local output = functions.char.zwnj .. trigger:gsub('#NAME', nick)
				functions.send_message(self, msg.chat.id, output)
				return
			end
		end
	end
	return true
end
