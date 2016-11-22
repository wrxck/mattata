--[[

    Based on ping.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local ping = {}
local mattata = require('mattata')

function ping:init(configuration)
	ping.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ping'):c('pong').table
end

function ping:onChannelPost(channel_post)
	mattata.sendMessage(channel_post.chat.id, 'Pong!', nil, true, false, channel_post.message_id)
end

function ping:onMessage(message)
	mattata.sendMessage(message.chat.id, 'Pong!', nil, true, false, message.message_id)
end

return ping