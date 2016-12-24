local apod = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function apod:init(configuration)
	assert(configuration.keys.apod, 'apod.lua requires an API key, and you haven\'t got one configured!')
	apod.arguments = 'apod <DD/MM/YYYY>'
	apod.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('apod').table
	apod.help = configuration.commandPrefix .. 'apod <DD/MM/YYYY> - Sends the Astronomy Picture of the Day.'
end

function apod:onInlineQuery(inline_query, configuration, language)
	local jstr, res = https.request('https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod)
	if res ~= 200 then
		local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'An error occured!',
			description = language.errors.connection,
			input_message_content = { message_text = language.errors.connection }
		}})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = json.decode('[' .. jstr .. ']')
	local results = json.encode({{
		type = 'photo',
		id = '1',
		photo_url = jdat[1].url,
		thumb_url = jdat[1].url,
		caption = jdat[1].title:gsub('"', '\\"')
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function apod:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod
	local date = os.date('%Y-%m-%d')
	if input and input:match('^(%d%d)/(%d%d)/(%d%d%d%d)$') then
		local day, month, year = input:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
		url = url .. year .. '-' .. month .. '-' .. day
		date = input
	end
	local jstr, res = https.request(url)
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	local year, month, day = jdat.date:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, jdat.url, '\'' .. jdat.title .. '\' - ' .. day .. '/' .. month .. '/' .. year, false, message.message_id)
end

return apod