local cats = {}
local HTTP = require('socket.http')
local mattata = require('mattata')

function cats:init(configuration)
	cats.arguments = 'cat'
	cats.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('cat').table
	cats.help = configuration.commandPrefix .. 'cat - A random picture of a cat!'
end

function cats:onMessageReceive(msg, configuration)
	local api = configuration.apis.cats .. '&api_key=' .. configuration.keys.cats
	local cat, res = HTTP.request(api)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	cat = cat:match('<img src="(.-)">')
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	mattata.sendPhoto(msg.chat.id, cat, 'Meow!', false, msg.message_id, nil)
end

return cats