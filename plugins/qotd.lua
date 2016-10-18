local qotd = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
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
	if string.match(jstr, 'null') then
		output = configuration.errors.connection
	else
		output = '_' .. jdat.contents.quotes[1].quote .. '_ - *' .. jdat.contents.quotes[1].author .. '*'
	end
	functions.send_reply(msg, output, true)
end
return qotd