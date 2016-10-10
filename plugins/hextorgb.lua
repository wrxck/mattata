local hextorgb = {}
local functions = require('functions')
function hextorgb:init(configuration)
	hextorgb.command = 'hextorgb <colour hex>'
	hextorgb.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('hextorgb', true).table
	hextorgb.documentation = configuration.command_prefix .. 'hextorgb <colour hex> - Converts the given colour hex to its RGB format.'
end
function hextorgb:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, hextorgb.documentation)
		return
	else
		input = input:gsub('#', '')
	end
	local r, g, b, output
	if tonumber('0x' .. input:sub(1, 2)) ~= nil and tonumber('0x' .. input:sub(3, 4)) ~= nil and tonumber('0x' .. input:sub(5, 6)) ~= nil then
		r = tonumber('0x' .. input:sub(1, 2))
		g = tonumber('0x' .. input:sub(3, 4))
		b = tonumber('0x' .. input:sub(5, 6))
		output = '`rgb(' .. r .. ', ' .. g .. ', ' .. b .. ')`'
	else
		output = hextorgb.documentation
	end
	functions.send_reply(msg, output, true)
end
return hextorgb