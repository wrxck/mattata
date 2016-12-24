local facebook = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function facebook:init(configuration)
	facebook.arguments = 'facebook <username>'
	facebook.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('facebook'):command('fb').table
	facebook.help = configuration.commandPrefix .. 'facebook <username> - Sends the profile picture of the given Facebook user. Alias: ' .. configuration.commandPrefix .. 'fb.'
end

function facebook.getAvatar(user)
	local profile, res = https.request('https://www.facebook.com/' .. url.escape(user))
	if profile == nil then return false elseif not profile:match(',"entity_id":"(.-)"}') then return false end
	local jstr, code, res = https.request({ url = 'https://graph.facebook.com/' .. profile:match(',"entity_id":"(.-)"}') .. '/picture?type=large&width=5000&height=5000', redirect = false })
	if not res or not res.location then return false end
	return res.location
end

function facebook:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, facebook.help, nil, true, false, message.message_id) return end
	local output = facebook.getAvatar(input)
	if not output then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'View @' .. input .. ' on Facebook', url = 'https://www.facebook.com/' .. url.escape(input) }}}
	mattata.sendPhoto(message.chat.id, output, nil, false, message.message_id, json.encode(keyboard))
end

return facebook