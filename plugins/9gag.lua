local ninegag = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function ninegag:init(configuration)
	ninegag.arguments = '9gag'
	ninegag.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('9gag').table
	ninegag.inlineCommands = ninegag.commands
	ninegag.help = configuration.commandPrefix .. '9gag - Returns a random result from the latest 9gag images.'
end

function ninegag:onInlineCallback(inline_query, configuration)
	local jstr = HTTP.request(configuration.apis.ninegag)
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 1
	for n in pairs(jdat) do
		local title = jdat[n].title:gsub('"', '\\"')
		results = results .. mattata.generateInlinePhoto(id, jdat[n].src, jdat[n].src, nil, nil, title, 'Read more', jdat[n].url)
		id = id + 1
		if n < #jdat then
			results = results .. ','
		end
	end
	local results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function ninegag:onMessageReceive(message, configuration)
	local url = configuration.apis.ninegag
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	local link_image = jdat[jrnd].src
	local title = jdat[jrnd].title
	local post_url = jdat[jrnd].url
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, link_image, title, false, message.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. post_url .. '"}]]}')
end

return ninegag