--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local dice = {}

local mattata = require('mattata')

function dice:init(configuration)
    dice.arguments = 'dice <number of dice> <range of numbers>'
    dice.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('dice').table
    dice.help = '/dice <number of dice to roll> <range of numbers on the dice> - Rolls a die a given amount of times, with a given range.'
end

function dice:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            dice.help
        )
    end
    local count, range
    if input:match('^(%d*) (%d*)$') then
        count, range = input:match('^(%d*) (%d*)$')
    end
    if not count or not range then
        return mattata.send_reply(
            message,
            dice.help
        )
    end
    if tonumber(range) < configuration.dice.min_range then
        return mattata.send_reply(
            message,
            'The minimum range is ' .. configuration.dice.min_range .. '.'
        )
    elseif tonumber(range) > configuration.dice.max_range or tonumber(count) > configuration.dice.max_count then
        if configuration.dice.max_range == configuration.dice.max_count then
            return mattata.send_reply(
                message,
                'The maximum range and count are both ' .. configuration.dice.max_range .. '.'
            )
        end
        return mattata.send_reply(
            message,
            'The maximum range is ' .. configuration.dice.max_range .. ', and the maximum count is ' .. configuration.dice.max_count .. '.'
        )
    end
    local output = '<b>' .. count .. '</b> rolls with a range of <b>' .. range .. '</b>:\n'
    local results = {}
    for i = 1, tonumber(count) do
        table.insert(
            results,
            math.random(tonumber(range))
        )
    end
    return mattata.send_message(
        message.chat.id,
        output .. '<pre>' .. table.concat(
            results,
            ', '
        ) .. '</pre>',
        'html'
    )
end

return dice