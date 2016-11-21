local captionbotai = {}
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local ltn12 = require('ltn12')
local mattata = require('mattata')

function captionbotai:onPhotoReceive(message, configuration, language)
	if message.reply_to_message then
		if message.reply_to_message.from.id == self.info.id then
			mattata.sendChatAction(message.chat.id, 'typing')
			local getFile = mattata.getFile(message.photo[1].file_id)
			local url = 'https://api.telegram.org/file/bot' .. configuration.botToken .. '/' .. getFile.result.file_path
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
				mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
				return
			end
			local file = io.open(filePath, 'w+')
			file:write(table.concat(body))
			file:close()
			local output = io.popen('./plugins/captionbotai.sh "' .. filePath .. '"'):read('*all')
			os.remove(filePath)
			mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
			return
		end
	end
end

return captionbotai
