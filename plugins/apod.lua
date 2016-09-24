local apod = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local URL = require('socket.url')
local functions = require('functions')
function apod:init(configuration)
	apod.command = 'apod (YYYY/MM/DD)'
	apod.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('apod', true).table
	apod.doc = configuration.command_prefix .. 'apod (YYYY/MM/DD) - Sends the Astronomy Picture of the Day.'
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
	local data = JSON.decode(jstr)
	local output = '"' .. data.title .. '" = ' .. data.date
	functions.send_action(msg.chat.id, 'upload_photo')
	functions.send_photo(msg.chat.id, functions.download_to_file(data.url), output:gsub('-', '/'):gsub('=', '-'), msg.message_id)
end
return apod