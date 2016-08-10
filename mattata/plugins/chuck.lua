local chuck = {}
local JSON = require('dkjson')
local utilities = require('mattata.utilities')
local URL = require('socket.url')
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')

function chuck:init(config)
	chuck.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('chuck', true):t('cn', true):t('chucknorris', true).table
chuck.command = 'chuck'
chuck.doc = 'Returns a Chuck Norris joke!'
end

function chuck:action(msg, config)
 
 local url = 'http://api.icndb.com/jokes/random'

 local jstr = HTTP.request(url)

	local jdat = JSON.decode(jstr)

	if jdat.error then
		utilities.send_reply(self, msg, config.errors.results)
		return
	end

local output = jdat.value.joke

	utilities.send_message(self, msg.chat.id, output, nil, true)

end

return chuck
