local pwgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function pwgen:init(configuration)
	pwgen.command = 'pwgen <length>'
	pwgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pwgen', true).table
	pwgen.doc = configuration.command_prefix .. 'pwgen <length> - Generates a random password of the given length. Please note that this is not the recommended method of generating a password and, like all online generators, it has security risks.'
end
function pwgen:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then functions.send_reply(msg, pwgen.doc, true) return end
	if tonumber(input) > 30 then functions.send_reply(msg, '`Please enter a lower number.`', true) return end
	if tonumber(input) < 5 then functions.send_reply(msg, '`Please enter a higher number.`', true) return end
	local jdat = ''
	local jstr, res = HTTP.request(configuration.pwgen_api .. input)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		jdat = JSON.decode(jstr)
		functions.send_reply(msg, '*Password:* `' .. functions.md_escape(jdat[1].password) .. '`\n*Phonetic:* `' .. functions.md_escape(jdat[1].phonetic) .. '`', true)
		return
	end
end
return pwgen
