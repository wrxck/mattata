local currency = {}
local HTTPS = require('ssl.https')
local functions = require('functions')
function currency:init(configuration)
	currency.command = 'currency [amount] <from> <to>'
	currency.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('currency', true).table
	currency.doc = configuration.command_prefix .. 'currency [amount] <from> <to> - Returns exchange rates for various currencies. Source: Google Finance.'
end
function currency:action(msg, configuration)
	local input = msg.text:upper()
	if not input:match('%a%a%a TO %a%a%a') then
		functions.send_reply(self, msg, currency.doc, true)
		return
	end
	local from = input:match('(%a%a%a) TO')
	local to = input:match('TO (%a%a%a)')
	local amount = functions.get_word(input, 2)
	amount = tonumber(amount) or 1
	local result = 1
	local api = configuration.currency_api
	if from ~= to then
		api = api .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
		local str, res = HTTPS.request(api)
		if res ~= 200 then
			functions.send_reply(self, msg, configuration.errors.connection)
			return
		end
		str = str:match('<span class=bld>(.*) %u+</span>')
		if not str then
			functions.send_reply(self, msg, configuration.errors.results)
			return
		end
		result = string.format('%.2f', str)
	end
	local output = amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\n\n'
	output = output .. os.date('!%F %T UTC') .. '\nSource: Google Finance`'
	output = '```\n' .. output .. '\n```'
	functions.send_reply(self, msg, output, true)
end
return currency