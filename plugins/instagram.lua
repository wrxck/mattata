local instagram = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function instagram:init(configuration)
	instagram.arguments = 'instagram <user>'
	instagram.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('instagram'):command('ig').table
	instagram.help = configuration.commandPrefix .. 'instagram <user> - Sends the profile picture of the given Instagram user. Alias: ' .. configuration.commandPrefix .. 'ig.'
end

function instagram:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, instagram.help, nil, true, false, message.message_id); return end
	local str, res = http.request('http://igdp.co/' .. url.escape(input))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return
	elseif str:match('No Instagram Account found%.') or not str:match('<img src="https://(.-)" class="img%-responsive">') then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'View @' .. input .. ' on Instagram', url = 'https://www.instagram.com/' .. input }}}
	mattata.sendPhoto(message.chat.id, str:match('<img src="https://(.-)" class="img%-responsive">'), nil, false, message.message_id, json.encode(keyboard))
end

return instagram