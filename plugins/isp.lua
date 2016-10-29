local isp = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function isp:init(configuration)
	isp.arguments = 'isp <URL>'
	isp.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('isp').table
	isp.help = configuration.commandPrefix .. 'isp <URL> - Sends information about the given URL\'s ISP.'
end

function isp:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, isp.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTP.request('http://ip-api.com/json/' .. input .. '?lang=' .. configuration.language .. '&fields=country,regionName,city,zip,isp,org,as,status,message,query')
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'fail' then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	else
		local isp, zip, city, regionName, country
		if jdat.isp ~= '' then
			output = '*' .. jdat.isp .. '*\n'
		end
		if jdat.zip ~= '' then
			output = output .. jdat.zip .. '\n'
		end
		if jdat.city ~= '' then
			output = output .. jdat.city .. '\n'
		end
		if jdat.regionName ~= '' then
			output = output .. jdat.regionName .. '\n'
		end
		if jdat.country ~= '' then
			output = output .. jdat.country .. '\n'
		end
		local output = '`' .. input .. ':`\n' .. output
		mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
		return
	end
end

return isp