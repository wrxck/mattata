local dns = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function dns:init(configuration)
	dns.arguments = 'dns <url> <type>'
	dns.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('dns').table
	dns.help = configuration.commandPrefix .. 'dns <url> <type> - Sends DNS records of the given type for the given url. The types currently supported are AAAA, A, CERT, CNAME, DLV, IPSECKEY, MX, NS, PTR, SIG, SRV and TXT.'
end

function dns:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then mattata.sendMessage(message.chat.id, dns.help, nil, true, false, message.message_id) return end
	local jstr, res = http.request('http://dig.jsondns.org/IN/' .. url.escape(input:gsub(' ', '/')))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	if jdat.header.rcode == 'NOERROR' and not string.match(message.text_lower, 'any$') then
		local output = ''
		local rdata = ''
		if input:match(' aaaa$') or input:match(' a$') or input:match(' ns$') or input:match(' txt$') then
			for n in pairs(jdat.answer) do output = output .. '`Name: ' .. jdat.answer[n].name .. '\nType: ' .. jdat.answer[n].type .. '\nClass: ' .. jdat.answer[n].class .. '\nTTL: ' .. jdat.answer[n].ttl .. '\nRData: ' .. jdat.answer[n].rdata .. '`\n\n' end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		elseif input:match(' cert$') or input:match(' cname$') then
			for n in pairs(jdat.authority) do
				for d in pairs(jdat.authority[n].rdata) do
					rdata = rdata .. jdat.authority[n].rdata[d]
					if d < #jdat.authority[n].rdata then rdata = rdata .. ', ' end
				end
				output = output .. '`Name: ' .. jdat.authority[n].name .. '\nType: ' .. jdat.authority[n].type .. '\nClass: ' .. jdat.authority[n].class .. '\nTTL: ' .. jdat.authority[n].ttl .. '\nRData: ' .. rdata .. '`\n\n'
			end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		elseif input:match(' mx$') then
			for n in pairs(jdat.answer) do
				rdata = ''
				for d in pairs(jdat.answer[n].rdata) do
					rdata = rdata .. jdat.answer[n].rdata[d]
					if d < #jdat.answer[n].rdata then rdata = rdata .. ', ' end
				end
				output = output .. '`Name: ' .. jdat.answer[n].name .. '\nType: ' .. jdat.answer[n].type .. '\nClass: ' .. jdat.answer[n].class .. '\nTTL: ' .. jdat.answer[n].ttl .. '\nRData: ' .. rdata .. '`\n\n'
			end
			mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
			return
		elseif input:match(' srv$') or input:match(' ipseckey$') or input:match(' ptr$') or input:match(' sig$') or input:match(' dlv$') then
			for n in pairs(jdat.authority) do
				rdata = ''
				for d in pairs(jdat.authority[n].rdata) do
					rdata = rdata .. jdat.authority[n].rdata[d]
					if d < #jdat.authority[n].rdata then rdata = rdata .. ', ' end
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