local skateipsum = {}
local utilities = require('mattata.utilities')
local JSON = require('dkjson')
local HTTP = require('socket.http')
function skateipsum:init(config)
	skateipsum.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('skateipsum', true).table
skateipsum.command = 'skateipsum'
skateipsum.doc = 'Generates a few skateboard-themed Lorem Ipsum sentences!'
end
function skateipsum:action(msg, config)
 local url = HTTP.request('http://skateipsum.com/get/1/1/JSON')
 local jstr = JSON.decode(url)
 local jdat = jstr[1]
	utilities.send_message(self, msg.chat.id, jdat, nil, true)
end
return skateipsum