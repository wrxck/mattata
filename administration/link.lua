local link = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function link:init(configuration)
	link.arguments = 'link'
	link.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('link').table
	link.help = configuration.commandPrefix .. 'link - Get the group link.'
end

function link.setLink(message, link)
	local hash = mattata.getRedisHash(message, 'link')
	if hash then redis:hset(hash, 'link', link); return 'Successfully set the new link.' end
end

function link.getLink(message)
	local hash = mattata.getRedisHash(message, 'link')
	if hash then
		local link = redis:hget(hash, 'link')
		if not link or link == 'false' then return 'There isn\'t a link set for this group.'
		return link
	end
end

function link:onMessage(message, configuration)
	if not mattata.isGroupAdmin(message.chat.id, message.from.id) or not mattata.isConfiguredAdmin(message.from.id) then return end
	local input = mattata.input(message.text)
	local output
	if not input then
		output = link.getLink(message)
		if not output then
			output = 'There isn\'t a link set for this group.'
			if mattata.isGroupAdmin(message.chat.id, message.from.id) then output = output ..  '\nYou can set one with \'' .. configuration.commandPrefix .. 'link <value>\'.' end
		else output = '<a href="' .. output .. '">' .. mattata.htmlEscape(message.chat.title) .. '</a>' end
	end
	if message.entities[2] and message.entities[2].type == 'url' and message.entities[2].offset == message.entities[1].offset + message.entities[1].length + 1 and message.entities[2].length == input:len() then output = link.setLink(message, input) else output = 'That\'s not a valid url.' end
	local res = mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id)
	if not res then mattata.sendMessage(message.chat.id, 'There was an error sending the group link, it\'s probably not valid.', nil, true, false, message.message_id) end
end

return link