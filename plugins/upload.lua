local upload = {}
local mattata = require('mattata')

function upload:init(configuration) upload.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('upload').table end

function upload:onMessage(message, configuration)
	if not mattata.isConfiguredAdmin(message.from.id) then
		return
	elseif not message.reply_to_message or not message.reply_to_message.document then
		mattata.sendMessage(message.chat.id, 'Please reply to the file you\'d like to download to the server. It must be <= 20 MB.', nil, true, false, message.message_id)
		return
	elseif message.reply_to_message.document.file_size > 20971520 then
		mattata.sendMessage(message.chat.id, 'That file is too large. It must be <= 20 MB.', nil, true, false, message.message_id)
		return
	end
	local file = mattata.getFile(message.reply_to_message.document.file_id)
	if not file then
		mattata.sendMessage(message.chat.id, 'I couldn\'t get this file, it\'s probably too old.', nil, true, false, message.message_id)
		return
	end
	local res = mattata.downloadToFile('https://api.telegram.org/file/bot' .. configuration.botToken .. '/' .. file.result.file_path:gsub('//', '/'):gsub('/$', ''), message.reply_to_message.document.file_name)
	if not res then
		mattata.sendMessage(message.chat.id, 'There was an error whilst retrieving this file.', nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, 'Successfully downloaded the file to the server - it can be found at <code>' .. mattata.htmlEscape(configuration.fileDownloadLocation .. message.reply_to_message.document.file_name) .. '</code>!', 'HTML', true, false, message.message_id)
end

return upload