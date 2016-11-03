local youtube_to_mp3 = {}
local mattata = require('mattata')
local configuration = require('configuration')

function youtube_to_mp3:init(configuration)
	youtube_to_mp3.arguments = 'mp3 <YouTube URL>'
	youtube_to_mp3.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mp3').table
	youtube_to_mp3.help = configuration.commandPrefix .. 'mp3 <YouTube URL> - Sends a YouTube video in mp3 format.'
end

function convertAudio(id)
	local fileDownloadLocation = configuration.fileDownloadLocation .. '%(title)s.%(ext)s'
	local output = io.popen('youtube-dl --max-filesize 49m -o "' .. fileDownloadLocation:gsub(' ', '_') .. '" --extract-audio --audio-format mp3 https://www.youtube.com/watch/?v=' .. extractIdFromUrl(id)):read('*all')
	if string.match(output, '.* File is larger .*') then
		return false
	end
	local file = string.match(output, '%[ffmpeg%] Destination: ' .. configuration.fileDownloadLocation .. '(.*).mp3')
	if not file then
		return false
	end
	return configuration.fileDownloadLocation .. file .. '.mp3'
end

function extractIdFromUrl(url)
	return url:gsub('https?://w?w?w?m?%.?youtube.com/watch%?v=', ''):gsub('https?://w?w?w?m?%.?youtube.com/embed/', ''):gsub('https?://w?w?w?m?%.?youtu.be/', '')
end

function youtube_to_mp3:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, youtube_to_mp3.help, nil, true, false, message.message_id)
		return
	end
	local output = mattata.sendMessage(message.chat.id, 'Retrieving audio information...', nil, true, false, message.message_id)
	local file = convertAudio(input)
	if not file then
		mattata.editMessageText(message.chat.id, output.result.message_id, 'An error occured! Either that video is too long, or it doesn\'t exist!', nil, nil)
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_audio')
	local res = mattata.sendAudio(message.chat.id, file)
	if res then
		mattata.editMessageText(message.chat.id, output.result.message_id, 'You should find the requested file below.', nil, nil)
		io.popen('rm ' .. file:gsub(' ', '\\ '))
		return
	end
end

return youtube_to_mp3