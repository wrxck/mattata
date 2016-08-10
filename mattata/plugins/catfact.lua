local catfact = {}
local JSON = require('dkjson')
local utilities = require('mattata.utilities')
local URL = require('socket.url')
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')

function catfact:init(config)
	catfact.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('catfact', true).table
catfact.command = 'catfact'
catfact.doc = 'Returns a cat fact!'
end

function catfact:action(msg, config)
 
 local url = 'http://catfacts-api.appspot.com/api/facts'

 local jstr = HTTP.request(url)

	local jdat = JSON.decode(jstr)

	if jdat.error then
		utilities.send_reply(self, msg, config.errors.results)
		return
	end

local output = jdat.facts[1]

	utilities.send_message(self, msg.chat.id, output, nil, true)

end

return catfact
