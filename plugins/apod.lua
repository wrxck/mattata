--[[

    Based on apod.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local apod = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local mattata = require('mattata')

function apod:init(configuration)
	apod.arguments = 'apod <YYYY/MM/DD>'
	apod.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('apod').table
	apod.inlineCommands = apod.commands
	apod.help = configuration.commandPrefix .. 'apod <YYYY/MM/DD> - Sends the Astronomy Picture of the Day.'
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

function apod:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
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
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local title = '\'' .. jdat.title .. '\' = ' .. jdat.date
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, jdat.url, title:gsub('-', '/'):gsub('=', '-'), false, message.message_id)
end

return apod