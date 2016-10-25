local ass = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function ass:init(configuration)
	ass.arguments = 'ass (id)'
	ass.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ass', true).table
	ass.help = configuration.commandPrefix .. 'ass (id) - If no arguments are given, returns a random picture of some ass. If an ID is specified as an argument, returns the specific ass that matches the inputted ID.'
end

function ass:onMessageReceive(msg, configuration)
	if msg.chat.type == 'private' then
		local jstr, res = HTTP.request(configuration.apis.ass.noise)
		local input = tonumber(mattata.input(msg.text))
		if res ~= 200 then
			mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
			return
		end
		local jdat = ''
		if not input then
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			mattata.sendChatAction(msg.chat.id, 'upload_photo')
			mattata.sendPhoto(msg.chat.id, output, 'Image #' .. tonumber(jdat[1].id), false, msg.message_id, nil)
			return
		elseif 7 < input < 3990 or tonumber(input) == nil then
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			mattata.sendChatAction(msg.chat.id, 'upload_photo')
			mattata.sendPhoto(msg.chat.id, output, 'That ID doesn\'t belong to an image, so here is: Image #' .. tonumber(jdat[1].id), false, msg.message_id, nil)
			return
		else
			local input = tonumber(mattata.input(msg.text))
			local jstr, res = HTTP.request(configuration.apis.ass.get .. input)
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			if res ~= 200 then
				mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
				return
			end
			mattata.sendChatAction(msg.chat.id, 'upload_photo')
			mattata.sendPhoto(msg.chat.id, output, 'Image #' .. tonumber(jdat[1].id), false, msg.message_id, nil)
			return
		end
	else
		mattata.sendMessage(msg.chat.id, 'Since this is NSFW, please execute this arguments in a private chat with me.', nil, true, false, '{"inline_keyboard":[[{"text":"Take me there!", "url":"http://telegram.me/' .. self.info.username .. '?start=ass"}]]}')
		return
	end
end

return ass