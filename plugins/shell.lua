--[[

    Based on shell.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local shell = {}
local mattata = require('mattata')

function shell:init(configuration)
	shell.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bash').table
end

function shell:onMessage(message)
	if not mattata.isConfiguredAdmin(message.from.id) then
		return
	end
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, 'Please specify a command to run.', nil, true, false, message.message_id)
		return
	end
	input = input:gsub('—', '--')
	local output = io.popen(input):read('*all')
	io.popen(input):close()
	if output:len() == 0 then
		output = 'Success!'
	else
		output = '```\n' .. output .. '\n```'
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return shell