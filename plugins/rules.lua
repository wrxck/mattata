local rules = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function rules:init(configuration)
	rules.arguments = 'rules | ' .. configuration.commandPrefix .. 'delrules | ' .. configuration.commandPrefix .. 'setrules <value>'
	rules.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('rules'):c('setrules'):c('delrules').table
	rules.help = configuration.commandPrefix .. 'rules - Returns the group rules. ' .. configuration.commandPrefix .. 'setrules <value> - Sets the group rules to the given value. Markdown is supported, and only group administrators can use this command. Use ' .. configuration.commandPrefix .. 'delrules to delete the current rules - this command may also only be used by group administrators.'
end

function setRules(message, rules)
	local hash = mattata.getRedisHash(message, 'rules')
	if hash then
		redis:hset(hash, 'rules', rules)
		return 'Successfully set the new rules.'
	end
end

function delRules(message)
	local hash = mattata.getRedisHash(message, 'rules')
	if redis:hexists(hash, 'rules') == true then
		redis:hdel(hash, 'rules')
		return 'Your rules have successfully been deleted.'
	else
		return 'There aren\'t any rules set for this group.'
	end
end

function getRules(message)
	local hash = mattata.getRedisHash(message, 'rules')
	if hash then
		local rules = redis:hget(hash, 'rules')
		if not rules or rules == 'false' then
			return 'There aren\'t any rules set for this group.'
		else
			return rules
		end
	end
end

function rules:onMessageReceive(message, configuration)
	if message.chat.type ~= 'private' then
		if mattata.isGroupAdmin(message.chat.id, message.from.id) then
			local input = mattata.input(message.text)
			if message.text_lower:match('^' .. configuration.commandPrefix .. 'rules$') then
				mattata.sendMessage(message.chat.id, getRules(message), 'Markdown', true, false)
				return
			end
			if message.text_lower:match('^' .. configuration.commandPrefix .. 'delrules') then
				mattata.sendMessage(message.chat.id, delRules(message), nil, true, false, message.message_id)
				return
			end
			if message.text_lower:match('^' .. configuration.commandPrefix .. 'setrules') then
				if message.text_lower:match('^' .. configuration.commandPrefix .. 'setrules$') then
					mattata.sendMessage(message.chat.id, 'Please specify the rules to set for this group.', nil, true, false, message.message_id)
					return
				end
				mattata.sendMessage(message.chat.id, setRules(message, input), nil, true, false, message.message_id)
				return
			end
		elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'rules') then
			mattata.sendMessage(message.chat.id, getRules(message), 'Markdown', true, false)
			return
		end
	end
end

return rules