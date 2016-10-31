local mchistory = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local mattata = require('mattata')

function mchistory:init(configuration)
	mchistory.arguments = 'mchistory <Minecraft username>'
	mchistory.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mchistory').table
	mchistory.help = configuration.commandPrefix .. 'mchistory <Minecraft username> - Returns the name history of a Minecraft username.'
end

function mchistory:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, mchistory.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr_uuid, res_uuid = HTTPS.request(configuration.apis.mchistory.uuid .. input)
	if res_uuid ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat_uuid = JSON.decode(jstr_uuid)
	local jstr, res = HTTPS.request(configuration.apis.mchistory.history .. jdat_uuid.id .. '/names')
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local output, summary
	for n in pairs(jdat) do
		if n == 1 then
			summary = '*This player has changed their username 1 time:*\n'
			output = mattata.markdownEscape(jdat[n].name)
		else
			summary = '*This player has changed their username ' .. #jdat .. ' times:*\n'
			output = output .. mattata.markdownEscape(jdat[n].name)
		end
		if n < #jdat then
			output = output .. ', '
		end
	end
	mattata.sendMessage(msg.chat.id, summary .. output, 'Markdown', true, false, msg.message_id, nil)
end

return mchistory