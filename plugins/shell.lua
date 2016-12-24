local shell = {}
local mattata = require('mattata')

function shell:init(configuration) shell.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('bash').table end

function shell:onMessage(message)
	if not mattata.isConfiguredAdmin(message.from.id) then return end
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, 'Please specify a command to run.', nil, true, false, message.message_id)
		return
	end
	local output = io.popen(input):read('*all')
	io.popen(input):close()
	if output:len() == 0 then output = 'Success!' else output = '<pre>' .. mattata.htmlEscape(output) .. '</pre>' end
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id)
end

return shell