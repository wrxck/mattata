local dns = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function dns:init(configuration)
	dns.arguments = 'dns <URL> <type>'
	dns.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('dns').table
	dns.help = configuration.commandPrefix .. 'dns <URL> <type> - Sends DNS records of the given type for the given URL. The types currently supported are AAAA, A, CERT, CNAME, DLV, IPSECKEY, MX, NS, PTR, SIG, SRV and TXT.'
end

function dns:onMessageReceive(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then
		mattata.sendMessage(message.chat.id, dns.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://dig.jsondns.org/IN/' .. input:gsub(' ', '/'))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.header.rcode == 'NOERROR' and not string.match(message.text_lower, 'any$') then
		local output = ''
		local rdata = ''
		if string.match(input, ' aaaa$') or string.match(input, ' a$') or string.match(input, ' ns$') or string.match(input, ' txt$') then
			for n in pairs(jdat.answer) do
				output = output .. '`Name: ' .. jdat.answer[n].name .. '\nType: ' .. jdat.answer[n].type .. '\nClass: ' .. jdat.answer[n].class .. '\nTTL: ' .. jdat.answer[n].ttl .. '\nRData: ' .. jdat.answer[n].rdata .. '`\n\n'
			end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		elseif string.match(input, ' cert$') or string.match(input, ' cname$') then
			for n in pairs(jdat.authority) do
				for d in pairs(jdat.authority[n].rdata) do
					rdata = rdata .. jdat.authority[n].rdata[d]
					if d < #jdat.authority[n].rdata then
						rdata = rdata .. ', '
					end
				end
				output = output .. '`Name: ' .. jdat.authority[n].name .. '\nType: ' .. jdat.authority[n].type .. '\nClass: ' .. jdat.authority[n].class .. '\nTTL: ' .. jdat.authority[n].ttl .. '\nRData: ' .. rdata .. '`\n\n'
			end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		elseif string.match(input, ' mx$') then
			for n in pairs(jdat.answer) do
				rdata = ''
				for d in pairs(jdat.answer[n].rdata) do
					rdata = rdata .. jdat.answer[n].rdata[d]
					if d < #jdat.answer[n].rdata then
						rdata = rdata .. ', '
					end
				end
				output = output .. '`Name: ' .. jdat.answer[n].name .. '\nType: ' .. jdat.answer[n].type .. '\nClass: ' .. jdat.answer[n].class .. '\nTTL: ' .. jdat.answer[n].ttl .. '\nRData: ' .. rdata .. '`\n\n'
			end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		elseif string.match(input, ' srv$') or string.match(input, ' ipseckey$') or string.match(input, ' ptr$') or string.match(input, ' sig$') or string.match(input, ' dlv$') then
			for n in pairs(jdat.authority) do
				rdata = ''
				for d in pairs(jdat.authority[n].rdata) do
					rdata = rdata .. jdat.authority[n].rdata[d]
					if d < #jdat.authority[n].rdata then
						rdata = rdata .. ', '
					end
				end
				output = output .. '`Name: ' .. jdat.authority[n].name .. '\nType: ' .. jdat.authority[n].type .. '\nClass: ' .. jdat.authority[n].class .. '\nTTL: ' .. jdat.authority[n].ttl .. '\nRData: ' .. rdata .. '`\n\n'
			end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		end
	end
	mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
end

return dns
