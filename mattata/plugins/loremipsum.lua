local loremipsum = {}
local utilities = require('mattata.utilities')
local HTTP = require('socket.http')
function loremipsum:init(config)
	loremipsum.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('loremipsum', true).table
loremipsum.command = 'loremipsum'
loremipsum.doc = 'Generates a few Lorem Ipsum sentences!'
end
function loremipsum:action(msg, config)
 local url = 'http://loripsum.net/api/1/medium/plaintext'
 local output = HTTP.request(url)
	utilities.send_message(self, msg.chat.id, output, nil, true)
end
return loremipsum