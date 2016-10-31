local twitch = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function twitch:init(configuration)
	twitch.arguments = 'twitch <channel>'
	twitch.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('twitch').table
	twitch.help = configuration.commandPrefix .. 'twitch <channel> - Sends information about the given Twitch channel.'
end

function twitch:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, twitch.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTPS.request('https://wind-bow.hyperdev.space/twitch-api/channels/' .. URL.escape(input))
	if res == 404 then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local title = '[' .. jdat.display_name .. '](' .. jdat.url .. ')'
	local status = '_' .. jdat.status .. '_'
	local views = jdat.views
	if views == 1 then
		views = jdat.views .. ' view'
	else
		views = jdat.views .. ' views'
	end
	local followers = jdat.followers
	if followers == 1 then
		followers = jdat.followers .. ' follower'
	else
		followers = jdat.followers .. ' followers'
	end
	local output = title .. '\n' .. status .. '\n\n' .. views .. ' *|* ' .. followers
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return twitch