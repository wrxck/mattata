local istuesday = {}
local HTTP = require('dependencies.socket.http')
local functions = require('functions')
function istuesday:init(configuration)
	istuesday.command = 'istuesday'
	istuesday.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('istuesday', true):t('it', true).table
	istuesday.documentation = configuration.command_prefix .. 'istuesday - Tells you if it\'s Tuesday or not. Alias: ' .. configuration.command_prefix .. 'it.'
end
function istuesday:action(msg)
	local str, res = HTTP.request('http://www.studentology.net/tuesday')
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local output = ''
	if string.match(str, 'YES') then
		output = 'Yes!'
	else
		output = 'No.'
	end
	functions.send_reply(msg, output)
end
return istuesday