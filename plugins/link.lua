local link = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function link:init(configuration)
	link.arguments = 'link | ' .. configuration.commandPrefix .. 'dellink | ' .. configuration.commandPrefix .. 'setlink <value>'
	link.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('link'):c('setlink'):c('dellink').table
	link.help = configuration.commandPrefix .. 'link - Returns the group link. ' .. configuration.commandPrefix .. 'setlink <value> - Sets the group link to the given value. Only group administrators can use this command. Use ' .. configuration.commandPrefix .. 'dellink to delete the current link - this command may also only be used by group administrators.'
end

function setLink(message, link)
	local hash = mattata.getRedisHash(message, 'link')
	if hash then
		redis:hset(hash, 'link', link)
		return 'Successfully set the new link.'
	end
end

function delLink(message)
	local hash = mattata.getRedisHash(message, 'link')
	if redis:hexists(hash, 'link') == true then
		redis:hdel(hash, 'link')
		return 'The group link has successfully been deleted.'
	else
		return 'There isn\'t a link set for this group.'
	end
end

function getLink(message)
	local hash = mattata.getRedisHash(message, 'link')
	if hash then
		local link = redis:hget(hash, 'link')
		if not link or link == 'false' then
			return 'There isn\'t a link set for this group.'
		else
			return link
		end
	end
end

function link:onMessageReceive(message, configuration)
	if message.chat.type ~= 'private' then
		if mattata.isGroupAdmin(message.chat.id, message.from.id) then
			local input = mattata.input(message.text)
			if message.text_lower:match('^' .. configuration.commandPrefix .. 'link$') then
				if getLink(message) ~= 'There isn\'t a link set for this group.' then
					mattata.sendMessage(message.chat.id, '<a href=\'' .. getLink(message) .. '\'>' .. mattata.htmlEscape(message.chat.title) .. '</a>', 'HTML', true, false, message.message_id)
					return
				end
				mattata.sendMessage(message.chat.id, getLink(message), 'Markdown', true, false)
				return
			end
			if message.text_lower:match('^' .. configuration.commandPrefix .. 'dellink') then
				mattata.sendMessage(message.chat.id, delLink(message), nil, true, false, message.message_id)
				return
			end
			if message.text_lower:match('^' .. configuration.commandPrefix .. 'setlink') then
				if message.text_lower:match('^' .. configuration.commandPrefix .. 'setlink$') then
					mattata.sendMessage(message.chat.id, 'Please specify the link to set for this group.', nil, true, false, message.message_id)
					return
				end
				if (not message.entities[2]) or (message.entities[2].type ~= 'url') then
					mattata.sendMessage(message.chat.id, 'That\'s not a valid URL.', nil, true, false, message.message_id)
					return
				end
				mattata.sendMessage(message.chat.id, setLink(message, input), nil, true, false, message.message_id)
				return
			end
		elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'link') then
			if getLink(message) ~= 'There isn\'t a link set for this group.' then
				mattata.sendMessage(message.chat.id, '<a href=\'' .. getLink(message) .. '\'>' .. mattata.htmlEscape(message.chat.title) .. '</a>', 'HTML', true, false, message.message_id)
				return
			end
			mattata.sendMessage(message.chat.id, getLink(message), nil, true, false, message.message_id)
			return
		end
	end
end

return link