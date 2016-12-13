local instagram = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function instagram:init(configuration)
	instagram.arguments = 'instagram <user>'
	instagram.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('instagram'):c('ig').table
	instagram.help = configuration.commandPrefix .. 'instagram <user> - Sends the profile picture of the given Instagram user. Alias: ' .. configuration.commandPrefix .. 'ig.'
end

function instagram:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, instagram.help, nil, true, false, channel_post.message_id)
		return
	end
	local str, res = HTTP.request('http://igdp.co/' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	elseif str:match('No Instagram Account found%.') or not str:match('<img src="https://(.-)" class="img%-responsive">') then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'View @' .. input .. ' on Instagram',
				url = 'https://www.instagram.com/' .. input
			}
		}
	}
	mattata.sendPhoto(channel_post.chat.id, str:match('<img src="https://(.-)" class="img%-responsive">'), nil, false, channel_post.message_id, JSON.encode(keyboard))
end

function instagram:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, instagram.help, nil, true, false, message.message_id)
		return
	end
	local str, res = HTTP.request('http://igdp.co/' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	elseif str:match('No Instagram Account found%.') or not str:match('<img src="https://(.-)" class="img%-responsive">') then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'View @' .. input .. ' on Instagram',
				url = 'https://www.instagram.com/' .. input
			}
		}
	}
	mattata.sendPhoto(message.chat.id, str:match('<img src="https://(.-)" class="img%-responsive">'), nil, false, message.message_id, JSON.encode(keyboard))
end

return instagram