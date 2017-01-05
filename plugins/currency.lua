--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local currency = {}

local mattata = require('mattata')
local https = require('ssl.https')

function currency:init(configuration)
    currency.arguments = 'currency <amount> <from> TO <to>'
    currency.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('currency'):command('convert'):command('cash').table
    currency.help = configuration.command_prefix .. 'currency <amount> <from> TO <to> - Converts exchange rates for various currencies. Source: Google Finance. Aliases: ' .. configuration.command_prefix .. 'convert, ' .. configuration.command_prefix .. 'cash.'
end

function currency:on_message(message, configuration, language)
    local input = mattata.input(message.text_upper)
    if not input or not input:match('%a%a%a TO %a%a%a') then
        return mattata.send_reply(
            message,
            currency.help
        )
    end
    local from = input:match('(%a%a%a) TO')
    local to = input:match('TO (%a%a%a)')
    local amount = mattata.get_word(
        input,
        2
    )
    amount = tonumber(amount) or 1
    local result = 1
    local url = 'https://www.google.com/finance/converter'
    if from ~= to then
        url = url .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
        local str, res = https.request(api)
        if res ~= 200 then
            return mattata.send_reply(
                message,
                language.errors.connection
            )
        end
        str = str:match('<span class=bld>(.*) %u+</span>')
        if not str then
            return mattata.send_reply(
                message,
                language.errors.results
            )
        end
        result = string.format(
			'%.2f',
			str
		)
    end
    return mattata.send_message(
        message.chat.id,
        amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\n\n' .. os.date('!%F %T UTC') .. '\nSource: Google Finance'
    )
end

return currency