local apod = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function apod:init(configuration)
	apod.command = 'apod (YYYY/MM/DD)'
	apod.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('apod', true).table
	apod.inline_triggers = apod.triggers
	apod.documentation = configuration.command_prefix .. 'apod (YYYY/MM/DD) - Sends the Astronomy Picture of the Day.'
end
function apod:inline_callback(inline_query, configuration)
	local jstr = '[' .. HTTPS.request(configuration.apis.apod .. configuration.keys.apod) .. ']'
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 50
	for n in pairs(jdat) do
		local title = jdat[n].title:gsub('"', '\\"')
		results = results .. '{"type":"photo","id":"' .. id .. '","photo_url":"' .. jdat[n].url .. '","thumb_url":"' .. jdat[n].url .. '","caption":"' .. title .. '","reply_markup":{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat[n].url .. '"}]]}}'
		id = id + 1
		if n < #jdat then
			results = results .. ','
		end
	end
	local results = results .. ']'
	functions.answer_inline_query(inline_query, results, 50)
end
function apod:action(msg, configuration)
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
	local input = functions.input(msg.text)
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
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local title = '"' .. jdat.title .. '" = ' .. jdat.date
	functions.send_photo(msg.chat.id, functions.download_to_file(jdat.url), title:gsub('-', '/'):gsub('=', '-'), msg.message_id)
end
return apod
