local isp = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function isp:init(configuration)
	isp.arguments = 'isp <url>'
	isp.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('isp').table
	isp.help = configuration.commandPrefix .. 'isp <url> - Sends information about the given url\'s ISP.'
end

function isp:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, isp.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = http.request('http://ip-api.com/json/' .. url.escape(input) .. '?lang=' .. configuration.language .. '&fields=country,regionName,city,zip,isp,org,as,status,message,query')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	if jdat.status == 'fail' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local output = ''
	if jdat.isp ~= '' then output = '<b>' .. jdat.isp .. '</b>\n' end
	if jdat.zip ~= '' then output = output .. jdat.zip .. '\n' end
	if jdat.city ~= '' then output = output .. jdat.city .. '\n' end
	if jdat.regionName ~= '' then output = output .. jdat.regionName .. '\n' end
	if jdat.country ~= '' then output = output .. jdat.country .. '\n' end
	mattata.sendMessage(message.chat.id, '<pre>' .. mattata.htmlEscape(input) .. ':</pre>\n' .. output, 'HTML', true, false, message.message_id)
end

return isp