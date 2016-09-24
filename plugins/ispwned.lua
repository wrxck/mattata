local ispwned = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function ispwned:init(configuration)
	ispwned.command = 'ispwned <username/email>'
	ispwned.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ispwned', true).table
	ispwned.doc = configuration.command_prefix .. 'ispwned <username/email> - Tells you if the given username/email has been identified in any data leaks.'
end
function ispwned:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, ispwned.doc, true)
		return
	else
		local jstr = HTTPS.request(configuration.ispwned_api .. input)
		local jdat = JSON.decode(jstr)
		local _, count = string.gsub(jstr, "Title", "")
		local output = ''
		if count == 0 then
			output = 'Phew! Your account details don\'t appear to be leaked anywhere, to my knowledge.'
		elseif count == 1 then
			output = '*Found ' .. count .. ' entry:*\n\n' .. jdat[count].Title
		elseif count == 2 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
		elseif count == 3 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
		elseif count == 4 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title.. '\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
		elseif count == 5 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title.. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
		elseif count == 6 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
		elseif count == 7 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 6)].Title .. '\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
		elseif count == 8 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 7)].Title .. '\n' .. jdat[math.abs(count - 6)].Title .. '\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
		elseif count == 9 then
			output = '*Found ' .. count .. ' entries:*\n\n' .. jdat[math.abs(count - 8)].Title .. '\n' .. jdat[math.abs(count - 7)].Title .. '\n' .. jdat[math.abs(count - 6)].Title .. '\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
		end
		functions.send_reply(msg, output, true)
	end
end
return ispwned