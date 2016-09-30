local apod = {}
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local JSON = require('dkjson')
local URL = require('socket.url')
local functions = require('functions')
function apod:init(configuration)
	apod.command = 'apod (YYYY/MM/DD)'
	apod.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('apod', true).table
	apod.inline_triggers = apod.triggers
	apod.doc = configuration.command_prefix .. 'apod (YYYY/MM/DD) - Sends the Astronomy Picture of the Day.'
end
function apod:inline_callback(inline_query, configuration)
	local jstr = '[' .. HTTPS.request(configuration.apod_api .. configuration.apod_key) .. ']'
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 600
	for n in pairs(jdat) do
		local title = jdat[n].title:gsub('"', '\\"')
		results = results .. '{"type":"photo","id":"' .. id .. '","photo_url":"' .. jdat[n].url .. '","thumb_url":"' .. jdat[n].url .. '","caption":"' .. title .. '","reply_markup":{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat[n].url .. '"}]]}}'
		id = id + 1
		if n < #jdat then
			results = results .. ','
		end
	end
	local results = results .. ']'
	print('test')
	functions.answer_inline_query(inline_query, results, 1000)
end
function apod:action(msg, configuration)
	local input = functions.input(msg.text)
	local url = configuration.apod_api .. configuration.apod_key
	local date = os.date('%F')
	if input then
		if input:match('^(%d%d%d%d)%/(%d%d)%/(%d%d)$') then
			url = url .. input:gsub('/', '-')
			date = input
		end
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	end
	local jdat = JSON.decode(jstr)
	local title = '"' .. jdat.title .. '" = ' .. jdat.date
	functions.send_action(msg.chat.id, 'upload_photo')
	functions.send_photo(msg.chat.id, functions.download_to_file(jdat.url), title:gsub('-', '/'):gsub('=', '-'), msg.message_id)
end
return apod