--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local currency = {}

local mattata = require('mattata')
local https = require('ssl.https')

function currency:init()
    currency.commands = mattata.commands(
        self.info.username
    ):command('currency')
     :command('convert')
     :command('cash').table
    currency.help = [[/currency <amount> <from> TO <to> - Converts exchange rates for various currencies via Google Finance. Aliases: /convert, /cash.]]
end

function currency:on_message(message, configuration)
    local input = mattata.input(message.text:upper())
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
        local str, res = https.request(url)
        if res ~= 200 then
            return mattata.send_reply(
                message,
                configuration.errors.connection
            )
        end
        str = str:match('<span class=bld>(.*) %u+</span>')
        if not str then
            return mattata.send_reply(
                message,
                configuration.errors.results
            )
        end
        result = string.format(
            '%.2f',
            str
        )
    end
    return mattata.send_message(
        message.chat.id,
        amount .. ' ' .. from .. ' = ' .. result .. ' ' .. to .. '\nvia Google Finance'
    )
end

return currency