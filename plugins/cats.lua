--[[

    Based on cats.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local cats = {}
local HTTP = require('socket.http')
local mattata = require('mattata')

function cats:init(configuration)
	cats.arguments = 'cat'
	cats.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('cat').table
	cats.help = configuration.commandPrefix .. 'cat - A random picture of a cat!'
end

function cats:onMessageReceive(message, configuration)
	local api = configuration.apis.cats .. '&api_key=' .. configuration.keys.cats
	local cat, res = HTTP.request(api)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	cat = cat:match('<img src="(.-)">')
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, cat, 'Meow!', false, message.message_id, nil)
end

return cats