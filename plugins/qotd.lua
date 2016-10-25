local qotd = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function qotd:init(configuration)
	qotd.arguments = 'qotd'
	qotd.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('qotd', true).table
	qotd.help = configuration.commandPrefix .. 'qotd - Sends the quote of the day.'
end

function qotd:onMessageReceive(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.qotd)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if string.match(jstr, 'null') then
		output = configuration.errors.connection
	else
		output = '_' .. jdat.contents.quotes[1].quote .. '_ - *' .. jdat.contents.quotes[1].author .. '*'
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return qotd