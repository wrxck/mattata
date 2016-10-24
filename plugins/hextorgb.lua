local hextorgb = {}
local mattata = require('mattata')

function hextorgb:init(configuration)
	hextorgb.arguments = 'hextorgb <colour hex>'
	hextorgb.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('hextorgb', true).table
	hextorgb.help = configuration.commandPrefix .. 'hextorgb <colour hex> - Converts the given colour hex to its RGB format.'
end

function hextorgb:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, hextorgb.help, nil, true, false, msg.message_id, nil)
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
	mattata.sendPhoto(msg.chat.id, 'https://placeholdit.imgix.net/~text?txtsize=28&bg=' .. input .. '&w=150&h=200', output, false, msg.message_id, nil)
end

return hextorgb