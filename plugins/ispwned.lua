local ispwned = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function ispwned:init(configuration)
	ispwned.arguments = 'ispwned <username/email>'
	ispwned.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ispwned', true).table
	ispwned.help = configuration.commandPrefix .. 'ispwned <username/email> - Tells you if the given username/email has been identified in any data leaks.'
end

function ispwned:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, ispwned.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTPS.request(configuration.apis.ispwned .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local _, count = string.gsub(jstr, "Title", "")
	local output = ''
	if count == 0 then
		output = 'Phew! Your account details don\'t appear to be leaked anywhere, to my knowledge.'
	elseif count == 1 then
		output = '*Found ' .. count .. ' entry:*\n' .. jdat[count].Title
	elseif count == 2 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
	elseif count == 3 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
	elseif count == 4 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title.. '\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
	elseif count == 5 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title.. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count - 1)].Title .. '\n' .. jdat[count].Title
	elseif count == 6 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
	elseif count == 7 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 6)].Title .. '\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
	elseif count == 8 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 7)].Title .. '\n' .. jdat[math.abs(count - 6)].Title .. '\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
	elseif count == 9 then
		output = '*Found ' .. count .. ' entries:*\n' .. jdat[math.abs(count - 8)].Title .. '\n' .. jdat[math.abs(count - 7)].Title .. '\n' .. jdat[math.abs(count - 6)].Title .. '\n' .. jdat[math.abs(count - 5)].Title .. '\n' .. jdat[math.abs(count - 4)].Title .. '\n' .. jdat[math.abs(count - 3)].Title .. '\n' .. jdat[math.abs(count - 2)].Title .. '\n' .. jdat[math.abs(count)].Title
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return ispwned