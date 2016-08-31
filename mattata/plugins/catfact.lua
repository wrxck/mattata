local catfact = {}
local JSON = require('dkjson')
local functions = require('mattata.functions')
local URL = require('socket.url')
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
function catfact:init(configuration)
	catfact.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('catfact', true).table
	catfact.command = 'catfact'
	catfact.doc = 'A random cat-related fact!'
end
function catfact:action(msg, configuration)
	local api = configuration.catfact_api
	local jstr = HTTP.request(api)
	local jdat = JSON.decode(jstr)
	if jdat.error then
		functions.send_reply(self, msg, configuration.errors.results)
		return
	end
local output = jdat.facts[1]
	functions.send_message(self, msg.chat.id, output, nil, true)
end
return catfact
