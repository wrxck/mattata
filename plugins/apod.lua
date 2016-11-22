--[[

    Based on apod.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local apod = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local JSON = require('dkjson')

function apod:init(configuration)
	apod.arguments = 'apod <YYYY/MM/DD>'
	apod.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('apod').table
	apod.inlineCommands = apod.commands
	apod.help = configuration.commandPrefix .. 'apod <YYYY/MM/DD> - Sends the Astronomy Picture of the Day.'
end

function apod:onInlineQuery(inline_query, configuration)
	local jstr, res =  HTTPS.request('https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod)
	if res ~= 200 then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = {
					message_text = language.errors.connection
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = JSON.decode('[' .. jstr .. ']')
	local results = JSON.encode({
		{
			type = 'photo',
			id = '1',
			photo_url = jdat[1].url,
			thumb_url = jdat[1].url,
			caption = jdat[1].title:gsub('"', '\\"')
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function apod:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod
	local date = os.date('%Y-%m-%d')
	if input then
		if input:match('^(%d%d%d%d)%/(%d%d)%/(%d%d)$') then
			url = url .. input:gsub('/', '-')
			date = input
		end
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local title = '\'' .. jdat.title .. '\' = ' .. jdat.date
	mattata.sendPhoto(channel_post.chat.id, jdat.url, title:gsub('-', '/'):gsub('=', '-'), false, channel_post.message_id)
end

function apod:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod
	local date = os.date('%Y-%m-%d')
	if input then
		if input:match('^(%d%d%d%d)%/(%d%d)%/(%d%d)$') then
			url = url .. input:gsub('/', '-')
			date = input
		end
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local title = '\'' .. jdat.title .. '\' = ' .. jdat.date
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, jdat.url, title:gsub('-', '/'):gsub('=', '-'), false, message.message_id)
end

return apod