local cats = {}
local HTTP = require('socket.http')
local functions = require('mattata.functions')
function cats:init(configuration)
	cats.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('cat').table
	cats.command = 'cat'
	cats.doc = 'A random picture of a cat!'
end
function cats:action(msg, configuration)
	local api = configuration.cat_api .. '&api_key=' .. configuration.cat_api_key
	end
	local str, res = HTTP.request(api)
	if res ~= 200 then
		functions.send_reply(self, msg, configuration.errors.connection)
		return
	end
	str = str:match('<img src="(.-)">')
	local output = '[Meow!]('..str..')'
	functions.send_message(self, msg.chat.id, output, false, nil, true)
end
return cats
