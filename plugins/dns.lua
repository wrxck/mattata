local dns = {}
local functions = require('functions')
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
function dns:init(configuration)
	dns.command = 'dns <URL> <type>'
	dns.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('dns', true).table
	dns.documentation = configuration.command_prefix .. 'dns <URL> <type> - Sends DNS records of the given type for the given URL. The types currently supported are A, CNAME, MX, NS and SRV. Returns a maximum of 5 records for the given type. This plugin is currently in development so may be buggy at times.'
end
function dns:action(msg, configuration)
	local input = functions.input(msg.text_lower)
	if not input or not string.match(input, ' ') then
		functions.send_reply(msg, dns.documentation)
		return
	end
	local jstr, res = HTTP.request('http://dig.jsondns.org/IN/' .. input:gsub('/ ', ' '):gsub(' ', '/'))
	local jdat = JSON.decode(jstr)
	if jdat.header.rcode == 'NOERROR' then
		local output
		if string.match(input, 'ns') or string.match(input, ' a') and not string.match(input, ' aaaa') then
			if jdat.answer[1] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '`'
			end
			if jdat.answer[2] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '`'
			end
			if jdat.answer[3] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata .. '`'
			end
			if jdat.answer[4] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata .. '\n\nName: ' .. jdat.answer[4].name .. '\nType: ' .. jdat.answer[4].type .. '\nClass: ' .. jdat.answer[4].class .. '\nTTL: ' .. jdat.answer[4].ttl .. '\nRData: ' .. jdat.answer[4].rdata .. '`'
			end
			if jdat.answer[5] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata .. '\n\nName: ' .. jdat.answer[4].name .. '\nType: ' .. jdat.answer[4].type .. '\nClass: ' .. jdat.answer[4].class .. '\nTTL: ' .. jdat.answer[4].ttl .. '\nRData: ' .. jdat.answer[4].rdata .. '\n\nName: ' .. jdat.answer[5].name .. '\nType: ' .. jdat.answer[5].type .. '\nClass: ' .. jdat.answer[5].class .. '\nTTL: ' .. jdat.answer[5].ttl .. '\nRData: ' .. jdat.answer[5].rdata .. '`'
			end
			functions.send_reply(msg, output, true)
			return
		end
		--[[ if string.match(input, ' aaaa') then
			if jdat.answer[1] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '`'
			end
			if jdat.answer[2] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '`'
			end
			if jdat.answer[3] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata .. '`'
			end
			if jdat.answer[4] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata .. '\n\nName: ' .. jdat.answer[4].name .. '\nType: ' .. jdat.answer[4].type .. '\nClass: ' .. jdat.answer[4].class .. '\nTTL: ' .. jdat.answer[4].ttl .. '\nRData: ' .. jdat.answer[4].rdata .. '`'
			end
			functions.send_reply(msg, output, true)
			return
		end ]]--
		if string.match(input, ' cname') then
			if jdat.authority[1] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. '`'
			end
			if jdat.authority[2] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. '`'
			end
			if jdat.authority[3] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. '\n\nName: ' .. jdat.authority[3].name .. '\nType: ' .. jdat.authority[3].type .. '\nClass: ' .. jdat.authority[3].class .. '\nTTL: ' .. jdat.authority[3].ttl .. '\nRData: ' .. jdat.authority[3].rdata[1] .. ', ' .. jdat.authority[3].rdata[2] .. ', ' .. jdat.authority[3].rdata[3] .. ', ' .. jdat.authority[3].rdata[4] .. ', ' .. jdat.authority[3].rdata[5] .. ', ' .. jdat.authority[3].rdata[6] .. '`'
			end
			if jdat.authority[4] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. '\n\nName: ' .. jdat.authority[3].name .. '\nType: ' .. jdat.authority[3].type .. '\nClass: ' .. jdat.authority[3].class .. '\nTTL: ' .. jdat.authority[3].ttl .. '\nRData: ' .. jdat.authority[3].rdata[1] .. ', ' .. jdat.authority[3].rdata[2] .. ', ' .. jdat.authority[3].rdata[3] .. ', ' .. jdat.authority[3].rdata[4] .. ', ' .. jdat.authority[3].rdata[5] .. ', ' .. jdat.authority[3].rdata[6] .. '\n\nName: ' .. jdat.authority[4].name .. '\nType: ' .. jdat.authority[4].type .. '\nClass: ' .. jdat.authority[4].class .. '\nTTL: ' .. jdat.authority[4].ttl .. '\nRData: ' .. jdat.authority[4].rdata[1] .. ', ' .. jdat.authority[4].rdata[2] .. ', ' .. jdat.authority[4].rdata[3] .. ', ' .. jdat.authority[4].rdata[4] .. ', ' .. jdat.authority[4].rdata[5] .. ', ' .. jdat.authority[4].rdata[6] .. '`'
			end
			if jdat.authority[5] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. '\n\nName: ' .. jdat.authority[3].name .. '\nType: ' .. jdat.authority[3].type .. '\nClass: ' .. jdat.authority[3].class .. '\nTTL: ' .. jdat.authority[3].ttl .. '\nRData: ' .. jdat.authority[3].rdata[1] .. ', ' .. jdat.authority[3].rdata[2] .. ', ' .. jdat.authority[3].rdata[3] .. ', ' .. jdat.authority[3].rdata[4] .. ', ' .. jdat.authority[3].rdata[5] .. ', ' .. jdat.authority[3].rdata[6] .. '\n\nName: ' .. jdat.authority[4].name .. '\nType: ' .. jdat.authority[4].type .. '\nClass: ' .. jdat.authority[4].class .. '\nTTL: ' .. jdat.authority[4].ttl .. '\nRData: ' .. jdat.authority[4].rdata[1] .. ', ' .. jdat.authority[4].rdata[2] .. ', ' .. jdat.authority[4].rdata[3] .. ', ' .. jdat.authority[4].rdata[4] .. ', ' .. jdat.authority[4].rdata[5] .. ', ' .. jdat.authority[4].rdata[6] .. '\n\nName: ' .. jdat.authority[5].name .. '\nType: ' .. jdat.authority[5].type .. '\nClass: ' .. jdat.authority[5].class .. '\nTTL: ' .. jdat.authority[5].ttl .. '\nRData: ' .. jdat.authority[5].rdata[1] .. ', ' .. jdat.authority[5].rdata[2] .. ', ' .. jdat.authority[5].rdata[3] .. ', ' .. jdat.authority[5].rdata[4] .. ', ' .. jdat.authority[5].rdata[5] .. ', ' .. jdat.authority[5].rdata[6] .. '`'
			end
			functions.send_reply(msg, output, true)
			return
		end
		if string.match(input, ' mx') then
			if jdat.answer[1] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata[1] .. ', ' .. jdat.answer[1].rdata[2] .. '`'
			end
			if jdat.answer[2] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata[1] .. ', ' .. jdat.answer[1].rdata[2] .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata[1] .. ', ' .. jdat.answer[2].rdata[2] .. '`'
			end
			if jdat.answer[3] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata[1] .. ', ' .. jdat.answer[1].rdata[2] .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata[1] .. ', ' .. jdat.answer[2].rdata[2] .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata[1] .. ', ' .. jdat.answer[3].rdata[2] .. '`'
			end
			if jdat.answer[4] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata[1] .. ', ' .. jdat.answer[1].rdata[2] .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata[1] .. ', ' .. jdat.answer[2].rdata[2] .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata[1] .. ', ' .. jdat.answer[3].rdata[2] .. '\n\nName: ' .. jdat.answer[4].name .. '\nType: ' .. jdat.answer[4].type .. '\nClass: ' .. jdat.answer[4].class .. '\nTTL: ' .. jdat.answer[4].ttl .. '\nRData: ' .. jdat.answer[4].rdata[1] .. ', ' .. jdat.answer[4].rdata[2] .. '`'
			end
			if jdat.answer[5] then
				output = '`Name: ' .. jdat.answer[1].name .. '\nType: ' .. jdat.answer[1].type .. '\nClass: ' .. jdat.answer[1].class .. '\nTTL: ' .. jdat.answer[1].ttl .. '\nRData: ' .. jdat.answer[1].rdata[1] .. ', ' .. jdat.answer[1].rdata[2] .. '\n\nName: ' .. jdat.answer[2].name .. '\nType: ' .. jdat.answer[2].type .. '\nClass: ' .. jdat.answer[2].class .. '\nTTL: ' .. jdat.answer[2].ttl .. '\nRData: ' .. jdat.answer[2].rdata[1] .. ', ' .. jdat.answer[2].rdata[2] .. '\n\nName: ' .. jdat.answer[3].name .. '\nType: ' .. jdat.answer[3].type .. '\nClass: ' .. jdat.answer[3].class .. '\nTTL: ' .. jdat.answer[3].ttl .. '\nRData: ' .. jdat.answer[3].rdata[1] .. ', ' .. jdat.answer[3].rdata[2] .. '\n\nName: ' .. jdat.answer[4].name .. '\nType: ' .. jdat.answer[4].type .. '\nClass: ' .. jdat.answer[4].class .. '\nTTL: ' .. jdat.answer[4].ttl .. '\nRData: ' .. jdat.answer[4].rdata[1] .. ', ' .. jdat.answer[4].rdata[2] .. '\n\nName: ' .. jdat.answer[5].name .. '\nType: ' .. jdat.answer[5].type .. '\nClass: ' .. jdat.answer[5].class .. '\nTTL: ' .. jdat.answer[5].ttl .. '\nRData: ' .. jdat.answer[5].rdata[1] .. ', ' .. jdat.answer[5].rdata[2] .. '`'
			end
			functions.send_reply(msg, output, true)
			return
		end
		if string.match(input, ' srv') then
			if jdat.authority[1] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. ', ' .. jdat.authority[1].rdata[7] .. '`'
			end
			if jdat.authority[2] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. ', ' .. jdat.authority[1].rdata[7] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. ', ' .. jdat.authority[2].rdata[7] .. '`'
			end
			if jdat.authority[3] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. ', ' .. jdat.authority[1].rdata[7] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. ', ' .. jdat.authority[2].rdata[7] .. '\n\nName: ' .. jdat.authority[3].name .. '\nType: ' .. jdat.authority[3].type .. '\nClass: ' .. jdat.authority[3].class .. '\nTTL: ' .. jdat.authority[3].ttl .. '\nRData: ' .. jdat.authority[3].rdata[1] .. ', ' .. jdat.authority[3].rdata[2] .. ', ' .. jdat.authority[3].rdata[3] .. ', ' .. jdat.authority[3].rdata[4] .. ', ' .. jdat.authority[3].rdata[5] .. ', ' .. jdat.authority[3].rdata[6] .. ', ' .. jdat.authority[3].rdata[7] .. '`'
			end
			if jdat.authority[4] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. ', ' .. jdat.authority[1].rdata[7] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. ', ' .. jdat.authority[2].rdata[7] .. '\n\nName: ' .. jdat.authority[3].name .. '\nType: ' .. jdat.authority[3].type .. '\nClass: ' .. jdat.authority[3].class .. '\nTTL: ' .. jdat.authority[3].ttl .. '\nRData: ' .. jdat.authority[3].rdata[1] .. ', ' .. jdat.authority[3].rdata[2] .. ', ' .. jdat.authority[3].rdata[3] .. ', ' .. jdat.authority[3].rdata[4] .. ', ' .. jdat.authority[3].rdata[5] .. ', ' .. jdat.authority[3].rdata[6] .. ', ' .. jdat.authority[3].rdata[7] .. '\n\nName: ' .. jdat.authority[4].name .. '\nType: ' .. jdat.authority[4].type .. '\nClass: ' .. jdat.authority[4].class .. '\nTTL: ' .. jdat.authority[4].ttl .. '\nRData: ' .. jdat.authority[4].rdata[1] .. ', ' .. jdat.authority[4].rdata[2] .. ', ' .. jdat.authority[4].rdata[3] .. ', ' .. jdat.authority[4].rdata[4] .. ', ' .. jdat.authority[4].rdata[5] .. ', ' .. jdat.authority[4].rdata[6] .. ', ' .. jdat.authority[4].rdata[7] .. '`'
			end
			if jdat.authority[5] then
				output = '`Name: ' .. jdat.authority[1].name .. '\nType: ' .. jdat.authority[1].type .. '\nClass: ' .. jdat.authority[1].class .. '\nTTL: ' .. jdat.authority[1].ttl .. '\nRData: ' .. jdat.authority[1].rdata[1] .. ', ' .. jdat.authority[1].rdata[2] .. ', ' .. jdat.authority[1].rdata[3] .. ', ' .. jdat.authority[1].rdata[4] .. ', ' .. jdat.authority[1].rdata[5] .. ', ' .. jdat.authority[1].rdata[6] .. ', ' .. jdat.authority[1].rdata[7] .. '\n\nName: ' .. jdat.authority[2].name .. '\nType: ' .. jdat.authority[2].type .. '\nClass: ' .. jdat.authority[2].class .. '\nTTL: ' .. jdat.authority[2].ttl .. '\nRData: ' .. jdat.authority[2].rdata[1] .. ', ' .. jdat.authority[2].rdata[2] .. ', ' .. jdat.authority[2].rdata[3] .. ', ' .. jdat.authority[2].rdata[4] .. ', ' .. jdat.authority[2].rdata[5] .. ', ' .. jdat.authority[2].rdata[6] .. ', ' .. jdat.authority[2].rdata[7] .. '\n\nName: ' .. jdat.authority[3].name .. '\nType: ' .. jdat.authority[3].type .. '\nClass: ' .. jdat.authority[3].class .. '\nTTL: ' .. jdat.authority[3].ttl .. '\nRData: ' .. jdat.authority[3].rdata[1] .. ', ' .. jdat.authority[3].rdata[2] .. ', ' .. jdat.authority[3].rdata[3] .. ', ' .. jdat.authority[3].rdata[4] .. ', ' .. jdat.authority[3].rdata[5] .. ', ' .. jdat.authority[3].rdata[6] .. ', ' .. jdat.authority[3].rdata[7] .. '\n\nName: ' .. jdat.authority[4].name .. '\nType: ' .. jdat.authority[4].type .. '\nClass: ' .. jdat.authority[4].class .. '\nTTL: ' .. jdat.authority[4].ttl .. '\nRData: ' .. jdat.authority[4].rdata[1] .. ', ' .. jdat.authority[4].rdata[2] .. ', ' .. jdat.authority[4].rdata[3] .. ', ' .. jdat.authority[4].rdata[4] .. ', ' .. jdat.authority[4].rdata[5] .. ', ' .. jdat.authority[4].rdata[6] .. ', ' .. jdat.authority[4].rdata[7] .. '\n\nName: ' .. jdat.authority[5].name .. '\nType: ' .. jdat.authority[5].type .. '\nClass: ' .. jdat.authority[5].class .. '\nTTL: ' .. jdat.authority[5].ttl .. '\nRData: ' .. jdat.authority[5].rdata[1] .. ', ' .. jdat.authority[5].rdata[2] .. ', ' .. jdat.authority[5].rdata[3] .. ', ' .. jdat.authority[5].rdata[4] .. ', ' .. jdat.authority[5].rdata[5] .. ', ' .. jdat.authority[5].rdata[6] .. ', ' .. jdat.authority[5].rdata[7] .. '`'
			end
			functions.send_reply(msg, output, true)
			return
		end
		--[[ if string.match(input, ' txt') then
			name = jdat.answer[1].name
			type = jdat.answer[1].type
			class = jdat.answer[1].class
			ttl = jdat.answer[1].ttl
			rdata = jdat.answer[1].rdata
			output = '```Name: ' .. name .. '\nType: ' .. type .. '\nClass: ' .. class .. '\nTTL: ' .. ttl .. '\nRData: ' .. rdata .. '```'
			functions.send_reply(msg, output, true)
			return
		end ]]--
	else
		functions.send_reply(msg, configuration.errors.results)
		return
	end
end
return dns