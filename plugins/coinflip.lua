--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local coinflip = {}

local mattata = require('mattata')

function coinflip:init(configuration)
    coinflip.arguments = 'coinflip <guess>'
    coinflip.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('coinflip'):command('cf').table
    coinflip.help = configuration.command_prefix .. 'coinflip <guess> - Flips a coin and returns the result! If no arguments are given, the result of a random coin flip is returned; if, however, an argument is given, the result of the random coin flip tests against your guess and returns the result and whether your guess was correct. Alias: ' .. configuration.command_prefix .. 'cf.'
end

function coinflip:on_message(message)
    local input = mattata.input(message.text_lower)
    local result = 'Heads.'
    local flip = math.random(2)
    if not input then
        if flip ~= 1 then
            result = 'Tails.'
        end
        return mattata.send_reply(
            message,
            '<b>The coin landed on:</b> ' .. result,
            'html'
        )
    else
        input = input:gsub('heads', '1'):gsub('tails', '2')
    end
    if tonumber(input) == 1 or tonumber(input) == 2 then
        input = tonumber(input)
        if flip ~= 1 then
            result = 'Tails.'
        end
        if input == flip then
            return mattata.send_reply(
                message,
                '<b>The coin landed on:</b> ' .. result .. '\n<i>You were correct!</i>',
                'html'
            )
        end
        return mattata.send_reply(
            message,
            '<b>The coin landed on:</b> ' .. result .. '\n<i>You weren\'t correct, try again...</i>',
            'html'
        )
    else
        return mattata.send_reply(
            message,
            'Invalid arguments were given. You must specify your guess, it should be either \'heads\' or \'tails\'.'
        )
    end
end

return coinflip