local speechToText = {} -- Credit to @Brawl for the original plugin
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local ltn12 = require('ltn12')
local JSON = require('dkjson')
local helpers = require('OAuth.helpers')
local lfs = require('lfs')

function speechToText:init(configuration)
	speechToText.arguments = 'stt'
	speechToText.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('stt').table
	speechToText.help = configuration.commandPrefix .. 'stt - Transcribes the replied-to voice message.'
end

function downloadVoice(message)
	local configuration = require('configuration')
	local request = mattata.getFile(message.reply_to_message.voice.file_id)
	local body = {}
	local _, res = HTTPS.request {
		url = 'https://api.telegram.org/file/bot' .. configuration.botToken .. '/' .. request.result.file_path,
		sink = ltn12.sink.table(body),
		redirect = false
	}
	if res ~= 200 then
		return false
	end
	local file = io.open(configuration.fileDownloadLocation .. request.result.file_path:match('.+/(.-)$'), 'w+')
	file:write(table.concat(body))
	file:close()
	io.popen('ffmpeg -loglevel panic -i ' .. tostring(configuration.fileDownloadLocation .. request.result.file_path:match('.+/(.-)$')) .. ' -ac 1 -y ' .. tostring(configuration.fileDownloadLocation .. request.result.file_path:match('.+/(.-)%.oga$') .. '.mp3'))
	return configuration.fileDownloadLocation .. request.result.file_path:match('.+/(.-)%.oga$') .. '.mp3'
end

function speechToText:onMessage(message, configuration, language)
	mattata.sendChatAction(message.chat.id, 'typing')
	if not message.reply_to_message then
		mattata.sendMessage(message.chat.id, speechToText.help, nil, true, false, message.message_id)
		return
	elseif not message.reply_to_message.voice then
		mattata.sendMessage(message.chat.id, 'The replied-to message must be a voice message!', nil, true, false, message.message_id)
		return
	elseif message.reply_to_message.voice.mime_type ~= 'audio/ogg' then
		mattata.sendMessage(message.chat.id, 'That voice message is not in a valid format!', nil, true, false, message.message_id)
		return
	elseif message.reply_to_message.voice.duration > 90 then
		mattata.sendMessage(message.chat.id, 'The replied-to voice message must be less than 90 seconds long!', nil, true, false, message.message_id)
		return
	elseif message.reply_to_message.voice.file_size > 20971520 then
		mattata.sendMessage(message.chat.id, 'The replied-to voice message must be smaller than 20 MB!', nil, true, false, message.message_id)
		return
	end
	local file = downloadVoice(message)
	if not file then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local body = {}
	local jstr, res = HTTPS.request({
		url = 'https://api.wit.ai/speech?v=20161128',
		method = 'POST',
		sink = ltn12.sink.table(body),
		headers = {
			['Content-Length'] = lfs.attributes(file, 'size'),
			['Content-Type'] = 'audio/mpeg3',
			Authorization = 'Bearer ' .. configuration.keys.witai
		},
		source = ltn12.source.file(io.open(file, 'r')),
		redirect = false
	})
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(table.concat(body))
	if not jdat then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	elseif not jdat._text or jdat._text == '' then
		mattata.sendMessage(message.chat.id, 'There were no transcribable voices detected.', nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, 'Speech to text: ' .. jdat._text, nil, true, false, message.message_id)
end

return speechToText