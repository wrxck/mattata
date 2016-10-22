local currency = {}
local HTTPS = require('dependencies.ssl.https')
local mattata = require('mattata')

function currency:init(configuration)
	currency.arguments = 'currency (amount) <from> TO <to>'
	currency.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('currency', true).table
	currency.help = configuration.commandPrefix .. 'currency (amount) <from> TO <to> - Returns exchange rates for various currencies. Source: Google Finance.'
end

function currency:onMessageReceive(msg, configuration)
	local input = msg.text:upper()
	if not input:match('%a%a%a TO %a%a%a') then
		mattata.sendMessage(msg.chat.id, currency.help, nil, true, false, msg.message_id, nil)
		return
	end
	local from = input:match('(%a%a%a) TO')
	local to = input:match('TO (%a%a%a)')
	local amount = mattata.getWord(input, 2)
	amount = tonumber(amount) or 1
	local result = 1
	local api = configuration.apis.currency
	if from ~= to then
		api = api .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
		local str, res = HTTPS.request(api)
		if res ~= 200 then
			mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
			return
		end
		str = str:match('<span class=bld>(.*) %u+</span>')
		if not str then
			mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
			return
		end
		result = string.format('%.2f', str)
	end
	local output = amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\n\n'
	output = output .. os.date('!%F %T UTC') .. '\nSource: Google Finance'
	output = '\n' .. output .. '\n'
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return currency