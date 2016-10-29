local tts = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')

function tts:init(configuration)
	tts.arguments = 'tts <text to convert>'
	tts.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('tts').table
	tts.help = configuration.commandPrefix .. 'tts <text to convert> - Converts text to speech.'
end

function tts:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text_lower)
	if not input then
		mattata.sendMessage(msg.chat.id, tts.help, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendVoice(msg.chat.id, mattata.downloadToFile('http://tts.baidu.com/text2audio?lan=' .. configuration.language .. '&ie=UTF-8&text=' .. URL.escape(input), os.time() .. '.mp3'))
end

return tts