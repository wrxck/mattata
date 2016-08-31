local loremipsum = {}
local functions = require('mattata.functions')
local HTTP = require('socket.http')
function loremipsum:init(configuration)
	loremipsum.command = 'loremipsum'
	loremipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('loremipsum', true).table
	loremipsum.doc = 'Generates a few Lorem Ipsum sentences!'
end
function loremipsum:action(msg, configuration)
	local api = configuration.loremipsum_api
	local output = HTTP.request(api)
	functions.send_message(self, msg.chat.id, output, nil, true)
end
return loremipsum
