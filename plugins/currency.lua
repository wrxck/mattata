local currency = {}
local mattata = require('mattata')
local https = require('ssl.https')

function currency:init(configuration)
	currency.arguments = 'currency <amount> <from> TO <to>'
	currency.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('currency'):command('convert'):command('cash').table
	currency.help = configuration.commandPrefix .. 'currency <amount> <from> TO <to> - Converts exchange rates for various currencies. Source: Google Finance. Aliases: ' .. configuration.commandPrefix .. 'convert, ' .. configuration.commandPrefix .. 'cash.'
end

function currency:onMessage(message, configuration, language)
	local input = mattata.input(message.text_upper)
	if not input:match('%a%a%a TO %a%a%a') then mattata.sendMessage(message.chat.id, currency.help, nil, true, false, message.message_id) return end
	local from = input:match('(%a%a%a) TO')
	local to = input:match('TO (%a%a%a)')
	local amount = mattata.getWord(input, 2)
	amount = tonumber(amount) or 1
	local result = 1
	local api = 'https://www.google.com/finance/converter'
	if from ~= to then
		api = api .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
		local str, res = https.request(api)
		if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
		str = str:match('<span class=bld>(.*) %u+</span>')
		if not str then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
		result = string.format('%.2f', str)
	end
	local output = amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\n\n'
	output = output .. os.date('!%F %T UTC') .. '\nSource: Google Finance'
	output = '\n' .. output .. '\n'
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return currency