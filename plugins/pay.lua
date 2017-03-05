--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local pay = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function pay:init()
    pay.commands = mattata.commands(
        self.info.username
    ):command('pay')
     :command('bal')
     :command('balance').table
    pay.help = [[/pay <amount> - Sends the replied-to user the given amount of mattacoins. Use /balance (or /bal) to view your current balance.]]
end

function pay.set_balance(user_id, new_balance)
    redis:set(
        'balance:' .. user_id,
        new_balance
    )
end

function pay.get_balance(user_id)
    local balance = redis:get('balance:' .. user_id)
    if not balance then
        balance = 0
    end
    return balance
end

function pay:on_message(message)
    if not message.reply then
        if message.text:match('^%/bal') then
            local balance = pay.get_balance(message.from.id)
            return mattata.send_reply(
                message,
                'You currently have ' .. balance .. ' mattacoins. Earn more by winning games of Tic-Tac-Toe, using /game - You will win 100 mattacoins for every game you win, and you will lose 50 for every game you lose.'
            )
        end
        return mattata.send_reply(
            message,
            'You must use this command in reply to the user you\'d like to send mattacoins to.'
        )
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Please specify the amount of mattacoins you\'d like to give ' .. message.reply.from.first_name .. '.'
        )
    elseif tonumber(input) == nil or tonumber(input) < 0 then
        return mattata.send_reply(
            message,
            'The amount specified should be a numerical value, of which can be no less than 0.'
        )
    elseif message.reply.from.id == message.from.id then
        return mattata.send_reply(
            message,
            'You can\'t send money to yourself!'
        )
    end
    local current_user_balance = pay.get_balance(message.from.id)
    local current_recipient_balance = pay.get_balance(message.reply.from.id)
    local new_user_balance = tonumber(current_user_balance) - tonumber(input)
    local new_recipient_balance = tonumber(current_recipient_balance) + tonumber(input)
    if new_user_balance < 0 then
        return mattata.send_reply(
            message,
            'You don\'t have enough funds to complete that transaction!'
        )
    end
    pay.set_balance(
        message.from.id,
        new_user_balance
    )
    pay.set_balance(
        message.reply.from.id,
        new_recipient_balance
    )
    return mattata.send_reply(
        message,
        input .. ' mattacoins have been sent to ' .. message.reply.from.first_name .. '. Your new balance is ' .. new_user_balance .. ' mattacoins.'
    )
end

return pay