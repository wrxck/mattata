--[[

    Based on currency.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local currency = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')

function currency:init(configuration)
	currency.arguments = 'currency <amount> <from> TO <to>'
	currency.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('currency').table
	currency.help = configuration.commandPrefix .. 'currency <amount> <from> TO <to> - Converts exchange rates for various currencies. Source: Google Finance.'
end

function currency:onChannelPostReceive(channel_post, configuration)
	local input = channel_post.text_upper
	if not input:match('%a%a%a TO %a%a%a') then
		mattata.sendMessage(channel_post.chat.id, currency.help, nil, true, false, channel_post.message_id)
		return
	end
	local from = input:match('(%a%a%a) TO')
	local to = input:match('TO (%a%a%a)')
	local amount = mattata.getWord(input, 2)
	amount = tonumber(amount) or 1
	local result = 1
	local api = 'https://www.google.com/finance/converter'
	if from ~= to then
		api = api .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
		local str, res = HTTPS.request(api)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		str = str:match('<span class=bld>(.*) %u+</span>')
		if not str then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
			return
		end
		result = string.format('%.2f', str)
	end
	local output = amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\n\n'
	output = output .. os.date('!%F %T UTC') .. '\nSource: Google Finance'
	output = '\n' .. output .. '\n'
	mattata.sendMessage(channel_post.chat.id, output, nil, true, false, channel_post.message_id)
end

function currency:onMessageReceive(message, language)
	local input = message.text_upper
	if not input:match('%a%a%a TO %a%a%a') then
		mattata.sendMessage(message.chat.id, currency.help, nil, true, false, message.message_id)
		return
	end
	local from = input:match('(%a%a%a) TO')
	local to = input:match('TO (%a%a%a)')
	local amount = mattata.getWord(input, 2)
	amount = tonumber(amount) or 1
	local result = 1
	local api = 'https://www.google.com/finance/converter'
	if from ~= to then
		api = api .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
		local str, res = HTTPS.request(api)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
			return
		end
		str = str:match('<span class=bld>(.*) %u+</span>')
		if not str then
			mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
			return
		end
		result = string.format('%.2f', str)
	end
	local output = amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\n\n'
	output = output .. os.date('!%F %T UTC') .. '\nSource: Google Finance'
	output = '\n' .. output .. '\n'
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return currency