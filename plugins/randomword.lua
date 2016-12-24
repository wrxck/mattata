local randomword = {}
local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function randomword:init(configuration)
	randomword.arguments = 'randomword'
	randomword.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('randomword'):command('rw').table
	randomword.help = configuration.commandPrefix .. 'randomword - Generates a random word. Alias: ' .. configuration.commandPrefix .. 'rw.'
end

function randomword:onCallbackQuery(callback_query, message, language)
	local str, res = http.request('http://www.setgetgo.com/randomword/get.php')
	if res ~= 200 then mattata.editMessageText(message.chat.id, message.message_id, language.errors.connection, nil, true) return end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Generate Another', callback_data = 'randomword' }}}
	mattata.editMessageText(message.chat.id, message.message_id, 'Your random word is <b>' .. str .. '</b>!', 'HTML', true, json.encode(keyboard))
end

function randomword:onMessage(message, language)
	local str, res = http.request('http://www.setgetgo.com/randomword/get.php')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Generate Another', callback_data = 'randomword' }}}
	mattata.sendMessage(message.chat.id, 'Your random word is <b>' .. str .. '</b>!', 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return randomword