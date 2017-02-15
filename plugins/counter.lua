--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local counter = {}

local mattata = require('mattata')

function counter:init()
    counter.commands = mattata.commands(
        self.info.username
    ):command('counter')
     :command('count').table
    counter.help = [[/counter - Adds a view count to the replied-to message. Alias: /count.]]
end

function counter:on_message(message, configuration)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            counter.help
        )
    end
    local success = mattata.forward_message(
        configuration.counter_channel,
        message.chat.id,
        true,
        message.reply_to_message.message_id
    )
    if not success then
        return mattata.send_reply(
            message,
            'I couldn\'t add a counter to that message!'
        )
    end
    return mattata.forward_message(
        message.chat.id,
        configuration.counter_channel,
        false,
        success.result.message_id
    )
end

return counter