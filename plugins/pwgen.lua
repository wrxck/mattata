local pwgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function pwgen:init(configuration)
	pwgen.command = 'pwgen <length>'
	pwgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pwgen', true).table
	pwgen.documentation = configuration.command_prefix .. 'pwgen <length> - Generates a random password of the given length.'
end
function pwgen:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, pwgen.documentation)
		return
	end
	if tonumber(input) ~= nil then
		if tonumber(input) > 30 then
			functions.send_reply(msg, '`Please enter a lower number.')
			return
		end
		if tonumber(input) < 5 then
			functions.send_reply(msg, 'Please enter a higher number.')
			return 
		end
		local jstr, res = HTTP.request(configuration.apis.pwgen .. input)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		end
		local jdat = JSON.decode(jstr)
		functions.send_reply(msg, '*Password:* `' .. functions.md_escape(jdat[1].password) .. '`\n*Phonetic:* `' .. functions.md_escape(jdat[1].phonetic) .. '`', true)
		return
	else
		functions.send_reply(msg, 'Please enter a numeric value.')
		return
	end
end
return pwgen