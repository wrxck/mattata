local pwgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function pwgen:init(configuration)
	pwgen.command = 'pwgen'
	pwgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pwgen', true).table
	pwgen.doc = configuration.command_prefix .. 'pwgen \nGenerates a random password.'
end
function pwgen:action(msg, configuration)
	local pw = HTTP.request(configuration.pwgen_api)
	local jstr = JSON.decode(pw)
	functions.send_reply(self, msg, '`' .. jstr.char[1] .. '`', true)
end
return pwgen