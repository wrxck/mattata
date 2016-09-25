local mchistory = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
function mchistory:init(configuration)
	mchistory.command = 'mchistory <Minecraft username>'
	mchistory.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mchistory', true).table
	mchistory.doc = configuration.command_prefix .. 'mchistory <Minecraft username> - Returns the name history of a Minecraft username.'
end
function mchistory:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, mchistory.doc, true)
		return
	else
		local jstr_uuid, res_uuid = HTTPS.request(configuration.mchistory_uuid_api .. input)
		if res_uuid ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		end
		local jdat_uuid = JSON.decode(jstr_uuid)
		local jstr, res = HTTPS.request(configuration.mchistory_api .. jdat_uuid.id .. '/names')
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		end
		local jdat = JSON.decode(jstr)
		local _, count = string.gsub(jstr, "name", "")
		local output = ''
		if count == 1 then
			output = '*This player has never changed their username.*\nTheir current username is: `' .. jdat[count].name .. '`'
		elseif count == 2 then
			output = '*This player has changed their username once.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old username was: `' .. jdat[count - 1].name .. '`'
		elseif count == 3 then
			output = '*This player has changed their username twice.*\nTheir current username is: `' .. jdat[count].name .. '\nTheir old usernames were: `' .. jdat[count - 1].name .. '` and `' .. jdat[count - 2].name .. '`'
		elseif count == 4 then
			output = '*This player has changed their username three times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '` and `' .. jdat[count - 3].name .. '`'
		elseif count == 5 then
			output = '*This player has changed their username four times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '` and `' .. jdat[count - 4].name .. '`'
		elseif count == 6 then
			output = '*This player has changed their username five times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '` and `' .. jdat[count - 5].name .. '`'
		elseif count == 7 then
			output = '*This player has changed their username six times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '` and `' .. jdat[count - 6].name .. '`'
		elseif count == 8 then
			output = '*This player has changed their username seven times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '` and `' .. jdat[count - 7].name .. '`'
		elseif count == 9 then
			output = '*This player has changed their username eight times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '`, `' .. jdat[count - 7].name .. '` and `' .. jdat[count - 8].name .. '`'
		elseif count == 10 then
			output = '*This player has changed their username nine times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '`, `' .. jdat[count - 7].name .. '`, `' .. jdat[count - 8].name .. '` and `' .. jdat[count - 9].name .. '`'
		elseif count == 11 then
			output = '*This player has changed their username ten times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '`, `' .. jdat[count - 7].name .. '`, `' .. jdat[count - 8].name .. '`, `' .. jdat[count - 9].name .. '` and `' .. jdat[count - 10].name .. '`'
		elseif count == 12 then
			output = '*This player has changed their username eleven times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '`, `' .. jdat[count - 7].name .. '`, `' .. jdat[count - 8].name .. '`, `' .. jdat[count - 9].name .. '`, `' .. jdat[count - 10].name .. '` and `' .. jdat[count - 11].name .. '`'
		elseif count == 13 then
			output = '*This player has changed their username twelve times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '`, `' .. jdat[count - 7].name .. '`, `' .. jdat[count - 8].name .. '`, `' .. jdat[count - 9].name .. '`, `' .. jdat[count - 10].name .. '`, `' .. jdat[count - 11].name .. '` and `' .. jdat[count - 12].name .. '`'
		elseif count == 14 then
			output = '*This player has changed their username thirteen times.*\nTheir current username is: `' .. jdat[count].name .. '`\nTheir old usernames were: `' .. jdat[count - 1].name .. '`, `' .. jdat[count - 2].name .. '`, `' .. jdat[count - 3].name .. '`, `' .. jdat[count - 4].name .. '`, `' .. jdat[count - 5].name .. '`, `' .. jdat[count - 6].name .. '`, `' .. jdat[count - 7].name .. '`, `' .. jdat[count - 8].name .. '`, `' .. jdat[count - 9].name .. '`, `' .. jdat[count - 10].name .. '`, `' .. jdat[count - 11].name .. '`, `' .. jdat[count - 12].name .. '` and `' .. jdat[count - 13].name .. '`'
		end
		functions.send_reply(msg, output, true)
		return
	end
end
return mchistory