local isp = {}
local functions = require('functions')
local HTTP = require('dependencies.socket.http')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
function isp:init(configuration)
	isp.command = 'isp <URL>'
	isp.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('isp', true).table
	isp.documentation = configuration.command_prefix .. 'isp <URL> - Sends information about the given URL\'s ISP.'
end
function isp:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, isp.documentation)
		return
	end
	local jstr, res = HTTP.request('http://ip-api.com/json/' .. input .. '?lang=' .. configuration.language .. '&fields=country,regionName,city,zip,isp,org,as,status,message,query')
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'fail' then
		functions.send_reply(msg, configuration.errors.connection)
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
		functions.send_reply(msg, output, true)
		return
	end
end
return isp