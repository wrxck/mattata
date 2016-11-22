local hextorgb = {}
local mattata = require('mattata')

function hextorgb:init(configuration)
	hextorgb.arguments = 'hextorgb <colour hex>'
	hextorgb.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('hextorgb').table
	hextorgb.help = configuration.commandPrefix .. 'hextorgb <colour hex> - Converts the given colour hex to its RGB format.'
end

function hextorgb:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, hextorgb.help, nil, true, false, channel_post.message_id)
		return
	end
	input = input:gsub('#', '')
	if tonumber('0x' .. input:sub(1, 2)) == nil and tonumber('0x' .. input:sub(3, 4)) == nil and tonumber('0x' .. input:sub(5, 6)) == nil then
		mattata.sendMessage(channel_post.chat.id, hextorgb.help, nil, true, false, channel_post.message_id)
		return
	end
	local r = tonumber('0x' .. input:sub(1, 2))
	local g = tonumber('0x' .. input:sub(3, 4))
	local b = tonumber('0x' .. input:sub(5, 6))
	mattata.sendPhoto(channel_post.chat.id, 'https://placeholdit.imgix.net/~text?txtsize=1&bg=' .. input .. '&w=150&h=200', 'rgb(' .. r .. ', ' .. g .. ', ' .. b .. ')', false, channel_post.message_id)
end

function hextorgb:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, hextorgb.help, nil, true, false, message.message_id)
		return
	end
	input = input:gsub('#', '')
	if tonumber('0x' .. input:sub(1, 2)) == nil and tonumber('0x' .. input:sub(3, 4)) == nil and tonumber('0x' .. input:sub(5, 6)) == nil then
		mattata.sendMessage(message.chat.id, hextorgb.help, nil, true, false, message.message_id)
		return
	end
	local r = tonumber('0x' .. input:sub(1, 2))
	local g = tonumber('0x' .. input:sub(3, 4))
	local b = tonumber('0x' .. input:sub(5, 6))
	mattata.sendPhoto(message.chat.id, 'https://placeholdit.imgix.net/~text?txtsize=1&bg=' .. input .. '&w=150&h=200', 'rgb(' .. r .. ', ' .. g .. ', ' .. b .. ')', false, message.message_id)
end

return hextorgb