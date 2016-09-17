local mcuuid = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function mcuuid:init(configuration)
	mcuuid.command = 'mcuuid <Minecraft username>'
	mcuuid.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mcuuid', true).table
	mcuuid.doc = configuration.command_prefix .. 'mcuuid <Minecraft username> - Tells you the UUID of a Minecraft username.'
end
function mcuuid:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_reply(self, msg, mcuuid.doc, true)
			return
		end
	end
	local url = configuration.mcuuid_api .. input
	local jstr = HTTP.request(url)
	local jdat = JSON.decode(jstr)
	functions.send_reply(self, msg, '`' .. jdat[1].uuid_formatted .. '`', true)
end
return mcuuid