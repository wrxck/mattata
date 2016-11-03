local hextorgb = {}
local mattata = require('mattata')

function hextorgb:init(configuration)
	hextorgb.arguments = 'hextorgb <colour hex>'
	hextorgb.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('hextorgb').table
	hextorgb.help = configuration.commandPrefix .. 'hextorgb <colour hex> - Converts the given colour hex to its RGB format.'
end

function hextorgb:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, hextorgb.help, nil, true, false, message.message_id, nil)
		return
	else
		input = input:gsub('#', '')
	end
	local r, g, b, output
	if tonumber('0x' .. input:sub(1, 2)) ~= nil and tonumber('0x' .. input:sub(3, 4)) ~= nil and tonumber('0x' .. input:sub(5, 6)) ~= nil then
		r = tonumber('0x' .. input:sub(1, 2))
		g = tonumber('0x' .. input:sub(3, 4))
		b = tonumber('0x' .. input:sub(5, 6))
		output = 'rgb(' .. r .. ', ' .. g .. ', ' .. b .. ')'
	else
		output = hextorgb.help
	end
	mattata.sendPhoto(message.chat.id, 'https://placeholdit.imgix.net/~text?txtsize=1&bg=' .. input .. '&w=150&h=200', output, false, message.message_id, nil)
end

return hextorgb