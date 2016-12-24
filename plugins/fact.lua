local fact = {}
local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function fact:init(configuration)
	fact.arguments = 'fact'
	fact.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('fact').table
	fact.help = configuration.commandPrefix .. 'fact - Returns a random fact!'
end

function fact:onMessage(message, configuration, language)
	local jstr, res = http.request('http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat[math.random(#jdat)].nid:gsub('&lt;', '<'):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, false, message.message_id)
end

return fact