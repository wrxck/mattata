local captionbotai = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local ltn12 = require('ltn12')
local json = require('dkjson')

function captionbotai.getConversationId()
	local str, res = https.request('https://www.captionbot.ai/api/init')
	if res ~= 200 then return false end
	if not str:match('%"(.-)%"') then return false else return str:match('%"(.-)%"') end
end

function captionbotai.makeRequest(url, id)
	local body = '{"conversationId":"' .. id .. '","waterMark":"","userMessage":"' .. url .. '"}'
	local response = {}
	local res, code, headers, status = https.request({
		url = 'https://www.captionbot.ai/api/message',
		method = 'POST',
		headers = {
			['Host'] = 'www.captionbot.ai',
			['Accept'] = '*/*',
			['Content-Type'] = 'application/json; charset=utf-8',
			['Content-Length'] = body:len(),
			['Referer'] = 'https://www.captionbot.ai/',
			['X-Requested-With'] = 'XMLHttpRequest'
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	})
	print(json.encode(headers))
	print(table.concat(response))
	if res ~= 200 then return false end
	print(table.concat(response))
	return false
end

function captionbotai:onPhotoReceive(message, configuration, language)
	if not message.reply_to_message or message.reply_to_message.from.id ~= self.info.id then return end
	local file = mattata.getFile(message.photo[1].file_id)
	if not file then mattata.sendMessage(message.chat.id, 'An error occured.', nil, true, false, message.message_id) return end
	mattata.sendChatAction(message.chat.id, 'typing')
	local init = captionbotai.getConversationId()
	if not init then mattata.sendMessage(message.chat.id, 'An error occured.', nil, true, false, message.message_id) return end
	local output = captionbotai.makeRequest('https://api.telegram.org/file/bot' .. configuration.botToken .. '/' .. file.result.file_path, init)
	if not output then mattata.sendMessage(message.chat.id, 'An error occured.', nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return captionbotai