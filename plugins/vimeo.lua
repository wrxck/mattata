local vimeo = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function vimeo:init(configuration)
	vimeo.arguments = 'vimeo <video ID>'
	vimeo.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('vimeo').table
	vimeo.help = configuration.commandPrefix .. 'vimeo <video ID> - Returns information about the given Vimeo video.'
end

function vimeo:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, vimeo.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://vimeo.com/api/v2/video/' .. URL.escape(input) .. '.json')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if not jdat then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local title = '<b>' .. mattata.htmlEscape(jdat[1].title) .. '</b>\n'
	local user = mattata.htmlEscape(jdat[1].user_name) .. '\n'
	local duration = 'This video is ' .. jdat[1].duration .. ' seconds long\n'
	local plays = ''
	if jdat[1].stats_number_of_plays then
		plays = 'It has been played ' .. jdat[1].stats_number_of_plays .. ' times\n'
	end
	local output = title .. user .. duration .. plays
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id)
end

return vimeo