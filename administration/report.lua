local report = {}
local mattata = require('mattata')

function report:init(configuration)
	report.arguments = 'report <text>'
	report.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('report'):c('ops').table
	report.help = configuration.commandPrefix .. 'report <text> - Notifies all administrators of an issue. Alias: ' .. configuration.commandPrefix .. 'ops.'
end

function report:onMessage(message, configuration)
	if message.chat.type ~= 'supergroup' then return end
	local input = mattata.input(message.text)
	local adminList = {}
	local admins = mattata.getChatAdministrators(message.chat.id)
	for n in pairs(admins.result) do if admins.result[n].user.username then table.insert(adminList, '@' .. mattata.markdownEscape(admins.result[n].user.username)) end end
	table.sort(adminList)
	local output = '*' .. message.from.first_name .. ' needs help!*\n' .. table.concat(adminList, ', ')
	if input then output = output .. '\nArguments: `' .. input:gsub('`', '\\`') .. '`' end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return report