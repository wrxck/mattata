local synonym = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function synonym:init(configuration)
	synonym.command = 'synonym <word>'
	synonym.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('synonym', true).table
	synonym.doc = configuration.command_prefix .. 'synonym <word> - sends a synonym of the given word.'
end
function synonym:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, synonym.doc, true)
		return
	else
		local url = configuration.synonym_api .. configuration.synonym_key .. '&lang=' .. configuration.language .. '-' .. configuration.language .. '&text=' .. URL.escape(input)
		local jstr, res = HTTPS.request(url)
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		end
		local jdat = JSON.decode(jstr)
		if jstr ~= '{"head":{},"def":[]}' then
			functions.send_reply(msg, '`' .. jdat.def[1].tr[1].text .. '`', true)
			return
		else
			functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
			return
		end
	end
end
return synonym