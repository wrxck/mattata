local skateipsum = {}
local functions = require('mattata.functions')
local JSON = require('dkjson')
local HTTP = require('socket.http')
function skateipsum:init(configuration)
    skateipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('skateipsum', true).table
    skateipsum.command = 'skateipsum'
    skateipsum.doc = 'Generates a few skateboard-themed Lorem Ipsum sentences!'
end
function skateipsum:action(msg, configuration)
    local url = HTTP.request('http://skateipsum.com/get/1/1/JSON')
    local jstr = JSON.decode(url)
    local jdat = jstr[1]
    functions.send_message(self, msg.chat.id, jdat, nil, true)
end
return skateipsum
