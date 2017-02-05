--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local prime = {}

local mattata = require('mattata')

function prime:init(configuration)
    prime.arguments = 'prime <number>'
    prime.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('prime').table
    prime.help = '/prime <number> - Tells you if a number is prime or not.'
end

function prime.is_prime(n)
    n = tonumber(n)
    if not n or n < 2 or n % 1 ~= 0 then 
        return n .. ' is NOT a prime number!'
    elseif n > 2 and n % 2 == 0 then 
        return n .. ' is NOT a prime number!'
    elseif n > 5 and n % 5 == 0 then 
        return n .. ' is NOT a prime number!'
    else
        for i = 3, math.sqrt(n), 2 do
            if n % i == 0 then
                return n .. ' is NOT a prime number!'
            end
        end
        return n .. ' is a prime number!'
    end
end

function prime:on_message(message)
    local input = mattata.input(message.text)
    if not input or tonumber(input) == nil then
        return mattata.send_reply(
            message,
            prime.help
        )
    elseif tonumber(input) > 99999 or tonumber(input) < 1 then
        return mattata.send_reply(
            message,
            'Please enter a number between 1 and 99999.'
        )
    end
    return mattata.send_message(
        message.chat.id,
        prime.is_prime(input)
    )
end

return prime