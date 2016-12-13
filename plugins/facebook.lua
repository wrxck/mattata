local facebook = {}
local mattata = require('mattata')
local JSON = require('dkjson')

function facebook:init(configuration)
	facebook.arguments = 'facebook <username>'
	facebook.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('facebook'):c('fb').table
	facebook.help = configuration.commandPrefix .. 'facebook <username> - Sends the profile picture of the given Facebook user. Alias: ' .. configuration.commandPrefix .. 'fb.'
end

function getAvatar(user)
	HTTPS = require('ssl.https')
	URL = require('socket.url')
	profile, res = HTTPS.request('https://www.facebook.com/' .. URL.escape(user))
	if profile == nil then
		return false
	elseif not profile:match(',"entity_id":"(.-)"}') then
		return false
	end
	jstr, code, res = HTTPS.request({
		url = 'https://graph.facebook.com/' .. profile:match(',"entity_id":"(.-)"}') .. '/picture?type=large&width=5000&height=5000',
		redirect = false
	})
	if not res or not res.location then
		return false
	end
	return res.location
end

function facebook:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, facebook.help, nil, true, false, channel_post.message_id)
		return
	end
	local output = getAvatar(input)
	if not output then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'View @' .. input .. ' on Facebook',
				url = 'https://www.facebook.com/' .. input
			}
		}
	}
	mattata.sendPhoto(channel_post.chat.id, output, nil, false, channel_post.message_id, JSON.encode(keyboard))
end

function facebook:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, facebook.help, nil, true, false, message.message_id)
		return
	end
	local output = getAvatar(input)
	if not output then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'View @' .. input .. ' on Facebook',
				url = 'https://www.facebook.com/' .. input
			}
		}
	}
	mattata.sendPhoto(message.chat.id, output, nil, false, message.message_id, JSON.encode(keyboard))
end

return facebook