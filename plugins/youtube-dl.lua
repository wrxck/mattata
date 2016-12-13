-- Credit to @MazenK for the original idea

local youtube_dl = {}
local mattata = require('mattata')

function youtube_dl:init(configuration)
	youtube_dl.arguments = 'mp3 <YouTube URL>'
	youtube_dl.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mp3').table
	youtube_dl.help = configuration.commandPrefix .. 'mp3 <YouTube URL> - Sends a YouTube video in mp3 format.'
end

function convertAudio(id)
	id = mattata.bashEscape(id) -- Just for extra precautionary measures
	local configuration = require('configuration')
	local fileDownloadLocation = configuration.fileDownloadLocation .. '%(title)s.%(ext)s'
	local output = io.popen('youtube-dl --max-filesize 49m -o "' .. fileDownloadLocation:gsub(' ', '_') .. '" --extract-audio --audio-format mp3 https://www.youtube.com/watch/?v=' .. extractUrl(id)):read('*all')
	if string.match(output, '.* File is larger .*') then
		return false
	end
	local file = string.match(output, '%[ffmpeg%] Destination: ' .. configuration.fileDownloadLocation .. '(.*).mp3')
	if not file then
		return false
	end
	return configuration.fileDownloadLocation .. file .. '.mp3'
end

function extractUrl(url)
	return url:gsub('https?://w?w?w?m?%.?youtube.com/watch%?v=', ''):gsub('https?://w?w?w?m?%.?youtube.com/embed/', ''):gsub('https?://w?w?w?m?%.?youtu.be/', '')
end

function youtube_dl:onChannelPost(channel_post)
	local input = channel_post.text:match('^' .. configuration.commandPrefix .. '(mp3) ([^%s]+)$')
	if not input then
		mattata.sendMessage(channel_post.chat.id, youtube_dl.help, nil, true, false, channel_post.message_id)
		return
	end
	local output = mattata.sendMessage(channel_post.chat.id, 'Retrieving audio information...', nil, true, false, channel_post.message_id)
	local file = convertAudio(input)
	if not file then
		mattata.editMessageText(channel_post.chat.id, output.result.message_id, 'An error occured! Either that video is too long, or it doesn\'t exist!')
		return
	end
	local res = mattata.sendAudio(channel_post.chat.id, file)
	if res then
		mattata.editMessageText(channel_post.chat.id, output.result.message_id, 'You should find the requested file below.')
		return
	end
end

function youtube_dl:onMessage(message)
	local input = message.text:match('^' .. configuration.commandPrefix .. '(mp3) ([^%s]+)$')
	if not input then
		mattata.sendMessage(message.chat.id, youtube_dl.help, nil, true, false, message.message_id)
		return
	end
	local output = mattata.sendMessage(message.chat.id, 'Retrieving audio information...', nil, true, false, message.message_id)
	local file = convertAudio(input)
	if not file then
		mattata.editMessageText(message.chat.id, output.result.message_id, 'An error occured! Either that video is too long, or it doesn\'t exist!')
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_audio')
	local res = mattata.sendAudio(message.chat.id, file)
	if res then
		mattata.editMessageText(message.chat.id, output.result.message_id, 'You should find the requested file below.')
		return
	end
end

return youtube_dl