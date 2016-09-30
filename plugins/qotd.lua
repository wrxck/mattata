local qotd = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function qotd:init(configuration)
	qotd.command = 'qotd'
	qotd.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('qotd', true).table
	qotd.documentation = configuration.command_prefix .. 'qotd - Sends the quote of the day.'
end
function qotd:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.qotd)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, '_' .. jdat.contents.quotes[1].quote .. '_ - *' .. jdat.contents.quotes[1].author .. '*', true)
end
return qotd