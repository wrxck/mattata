local apod = {}
local HTTPS = require('dependencies.ssl.https')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function apod:init(configuration)
	apod.arguments = 'apod (YYYY/MM/DD)'
	apod.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('apod', true).table
	apod.inlineCommands = apod.commands
	apod.help = configuration.commandPrefix .. 'apod (YYYY/MM/DD) - Sends the Astronomy Picture of the Day.'
end

function apod:onInlineCallback(inline_query, configuration)
	local jstr = '[' .. HTTPS.request(configuration.apis.apod .. configuration.keys.apod) .. ']'
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 1
	for n in pairs(jdat) do
		local title = jdat[n].title:gsub('"', '\\"')
		results = results .. '{"type":"photo","id":"' .. id .. '","photo_url":"' .. jdat[n].url .. '","thumb_url":"' .. jdat[n].url .. '","caption":"' .. title .. '","reply_markup":{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat[n].url .. '"}]]}}'
		id = id + 1
		if n < #jdat then
			results = results .. ','
		end
	end
	local results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function apod:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	local url = configuration.apis.apod .. configuration.keys.apod
	local date = os.date('%F')
	if input then
		if input:match('^(%d%d%d%d)%/(%d%d)%/(%d%d)$') then
			url = url .. input:gsub('/', '-')
			date = input
		end
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	local jdat = JSON.decode(jstr)
	local title = '"' .. jdat.title .. '" = ' .. jdat.date
	mattata.sendPhoto(msg.chat.id, jdat.url, title:gsub('-', '/'):gsub('=', '-'), false, msg.message_id, nil)
end

return apod