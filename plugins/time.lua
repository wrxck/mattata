local time = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
function time:init(configuration)
	time.command = 'time <location>'
	time.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('time', true).table
	time.doc = configuration.command_prefix .. 'time <location> - Displays the time, date, and time-zone for the given location.'
end
function time:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_message(self, msg.chat.id, time.doc, true, msg.message_id, true)
			return
		end
	end
	local coords = functions.get_coords(input, configuration)
	if type(coords) == 'string' then
		functions.send_reply(self, msg, coords)
		return
	end
	local now = os.time()
	local utc = os.time(os.date("!*t", now))
	local url = 'https://maps.googleapis.com/maps/api/timezone/json?location=' .. coords.lat ..','.. coords.lon .. '&timestamp='..utc
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(self, msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local timestamp = now + jdat.rawOffset + jdat.dstOffset
	local utcoff = (jdat.rawOffset + jdat.dstOffset) / 3600
	if utcoff == math.abs(utcoff) then
		utcoff = '+'.. functions.pretty_float(utcoff)
	else
		utcoff = functions.pretty_float(utcoff)
	end
	local output = os.date('!%I:%M %p\n', timestamp) .. os.date('!%A, %B %d, %Y\n', timestamp) .. jdat.timeZoneName .. ' (UTC' .. utcoff .. ')'
	output = '```\n' .. output .. '\n```'
	functions.send_reply(self, msg, output, true)
end
return time