local captionbotai = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local ltn12 = require('ltn12')

function captionbotai:onPhotoReceive(message, configuration, language)
	if not message.reply_to_message or message.reply_to_message.from.id ~= self.info.id then return end
	mattata.sendChatAction(message.chat.id, 'typing')
	local getFile = mattata.getFile(message.photo[1].file_id)
	local url = 'https://api.telegram.org/file/bot' .. configuration.botToken .. '/' .. getFile.result.file_path
	local filePath = configuration.fileDownloadLocation .. os.time() .. url:match('.+/(.-)$')
	local body = {}
	local protocol = http
	local redirect = true
	if url:match('^https') then protocol = https; redirect = false end
	local _, res = protocol.request {
		url = url,
		sink = ltn12.sink.table(body),
		redirect = redirect
	}
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local file = io.open(filePath, 'w+')
	file:write(table.concat(body))
	file:close()
	local output = io.popen('./plugins/captionbotai.sh "' .. filePath .. '"'):read('*all')
	os.remove(filePath)
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return captionbotai