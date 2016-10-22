local ninegag = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function ninegag:init(configuration)
	ninegag.arguments = '9gag'
	ninegag.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('9gag', true).table
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
		results = results .. '{"type":"photo","id":"' .. id .. '","photo_url":"' .. jdat[n].src .. '","thumb_url":"' .. jdat[n].src .. '","caption":"' .. title .. '","reply_markup":{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat[n].url .. '"}]]}}'
		id = id + 1
		if n < #jdat then
			results = results .. ','
		end
	end
	local results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function ninegag:onMessageReceive(msg, configuration)
	local url = configuration.apis.ninegag
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	local link_image = jdat[jrnd].src
	local title = jdat[jrnd].title
	local post_url = jdat[jrnd].url
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	mattata.sendPhoto(msg.chat.id, link_image, title, false, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. post_url .. '"}]]}')
end

return ninegag