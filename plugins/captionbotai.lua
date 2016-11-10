local captionbotai = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local ltn12 = require('ltn12')

function captionbotai:init(configuration)
	-- captionbotai.arguments = 'captionbotai <text>'
	captionbotai.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('captionbotai').table
	-- captionbotai.help = configuration.commandPrefix .. 'captionbotai <text> - Repeats a string of text.'
end

function captionbotai:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, 'meep', nil, true, false, message.message_id)
		return
	end
	local url = input
	local filePath = configuration.fileDownloadLocation .. os.time() .. url:match('.+/(.-)$')
	local body = {}
	local protocol = HTTP
	local redirect = true
	if url:match('^https') then
		protocol = HTTPS
		redirect = false
	end
	local _, res = protocol.request {
		url = url,
		sink = ltn12.sink.table(body),
		redirect = redirect
	}
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local file = io.open(filePath, 'w+')
	file:write(table.concat(body))
	file:close()
	print('Saved to: ' .. filePath)
	local output = io.popen('./plugins/captionbotai.sh "' .. filePath .. '"'):read('*all')
	print(output)
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return captionbotai