--[[

    Based on nick.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local nick = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function nick:init(configuration)
	nick.arguments = 'nick <nickname>'
	nick.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('nick').table
	nick.help = configuration.commandPrefix .. 'nick <nickname> - Set your nickname to the given value. If no value is given, your current nickname is sent instead.'
end

function setNickname(user, nickname)
	local hash = mattata.getUserRedisHash(user, 'nickname')
	if hash then
		redis:hset(hash, 'nickname', nickname)
		return user.first_name .. '\'s nickname has been set to \'' .. nickname .. '\'.'
	end
end

function delNickname(user)
	local hash = mattata.getUserRedisHash(user, 'nickname')
	if redis:hexists(hash, 'nickname') == true then
		redis:hdel(hash, 'nickname')
		return 'Your nickname has successfully been deleted.'
	else
		return 'You don\'t currently have a nickname!'
	end
end

function getNickname(user)
	local hash = mattata.getUserRedisHash(user, 'nickname')
	if hash then
		local nickname = redis:hget(hash, 'nickname')
		if not nickname or nickname == 'false' then
			return 'You don\'t have a nickname set.'
		else
			return 'Your nickname is currently \'' .. nickname .. '\'.'
		end
	end
end

function nick:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	local output
	if not input then
		mattata.sendMessage(message.chat.id, getNickname(message.from), nil, true, false, message.message_id)
		return
	end
	if message.text_lower == configuration.commandPrefix .. 'nick -del' then
		mattata.sendMessage(message.chat.id, delNickname(message.from), nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, setNickname(message.from, input), nil, true, false, message.message_id)
end

return nick