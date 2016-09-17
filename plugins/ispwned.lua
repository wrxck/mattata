local ispwned = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function ispwned:init(configuration)
	ispwned.command = 'ispwned <email>'
	ispwned.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ispwned', true).table
	ispwned.doc = configuration.command_prefix .. 'ispwned <email> - Tells you if your account has been identified in any data leaks.'
end
function ispwned:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(self, msg, '/ispwned <email>') return
	else
		local jstr = HTTPS.request(configuration.ispwned_api .. input)
		local jdat = JSON.decode(jstr)
		local _, count = string.gsub(jstr, "Title", "")
		local output = ''
		if count == 0 then
			output = 'Phew! Your account details don\'t appear to be leaked anywhere.'
		elseif count == 1 then
			output = '*Found ' .. count .. ' entry:*\n' .. jdat[count].Title
		elseif count == 2 then
			output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count-1)].Title .. '\n' .. jdat[count].Title
		elseif count == 3 then
			output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count-2)].Title .. '\n' .. jdat[math.abs(count-1)].Title .. '\n' .. jdat[count].Title
		elseif count == 4 then
			output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count-3)].Title .. '\n' .. jdat[math.abs(count-2)].Title.. '\n' .. jdat[math.abs(count-1)].Title .. '\n' .. jdat[count].Title
		elseif count == 5 then
			output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count-4)].Title .. '\n' .. jdat[math.abs(count-3)].Title.. '\n' .. jdat[math.abs(count-2)].Title .. '\n' .. jdat[math.abs(count-1)].Title .. '\n' .. jdat[count].Title
		end
		functions.send_reply(self, msg, output, true)
	end
end
return ispwned