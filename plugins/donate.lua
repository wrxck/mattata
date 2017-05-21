--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local donate = {}
local mattata = require('mattata')

function donate:init()
    donate.commands = mattata.commands(self.info.username):command('donate').table
    donate.help = '/donate [amount] - Make an optional, monetary contribution to the mattata project. Donation amount is £1 by default, but you can specify an amount between 1 and 100. All payments are made in GBP.'
end

function donate:on_message(message, configuration)
    if configuration.stripe_live_token
    and configuration.stripe_live_token ~= ''
    then
        local input = mattata.input(message.text)
        local amount = 1
        if input
        then
            if tonumber(input) == nil
            or tonumber(input) > 1000
            or tonumber(input) < 1
            then
                return mattata.send_message(
                    message.chat.id,
                    'Please specify a number between 1 and 1000. This is the amount of GBP you would like to donate.'
                )
            elseif input:match('%.')
            then
                return mattata.send_message(
                    message.chat.id,
                    'Please refrain from using decimal numbers, use whole numbers such as 5 or 10. Thanks!'
                )
            end
            amount = tonumber(input)
        end
        local time = os.time()
        local success = mattata.send_invoice(
            message.from.id,
            'mattata Donation',
            'Donate ' .. amount .. ' GBP to help with the ongoing development of mattata! Alternatively, you can donate through PayPal by heading to https://paypal.me/wrxck/' .. amount .. ', or by sending BitCoin to 17vZxsngLkPbgai8wRFzrTw5rFEjMD2AnQ',
            message.from.id .. '_' .. time,
            configuration.stripe_live_token,
            message.from.id .. '_' .. time,
            'GBP',
            '[{"label":"£' .. amount .. ' Donation","amount":' .. amount * 100 .. '}]'
        )
        if not success
        and message.chat.type ~= 'private'
        then
            return mattata.send_message(
                message.chat.id,
                'Please message me privately in order to allow me to send you the requested information.'
            )
        end
        if message.chat.type ~= 'private'
        then
            return mattata.send_message(
                message.chat.id,
                'I have sent you the requested information via private chat!'
            )
        end
        return
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<b>Hello, %s!</b>\n\nIf you\'re feeling generous, you can contribute to the mattata project by making a monetary donation of any amount. This will go towards server costs and any time and resources used to develop mattata. This is an optional act, however it is greatly appreciated and your name will also be listed publically on mattata\'s GitHub page.\n\nIf you\'re still interested, you can donate <a href="https://paypal.me/wrxck">here</a>. Thank you for your continued support! 😀',
            mattata.escape_html(message.from.first_name)
        ),
        'html'
    )
end

return donate