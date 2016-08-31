local chuck = {}
local JSON = require('dkjson')
local functions = require('mattata.functions')
local URL = require('socket.url')
local HTTP = require('socket.http')
function chuck:init(configuration)
	chuck.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('chuck', true):t('cn', true):t('chucknorris', true).table
	chuck.command = 'chuck'
	chuck.doc = 'Generates a Chuck Norris joke!'
end
function chuck:action(msg, configuration)
	local api = configuration.chuck_api
	local raw_joke = HTTP.request(api)
	local decoded_joke = JSON.decode(raw_joke)
	if decoded_joke.error then
		functions.send_reply(self, msg, configuration.errors.results)
		return
	end
	local output = decoded_joke.value.joke
	functions.send_message(self, msg.chat.id, output, nil, true)
end
return chuck
