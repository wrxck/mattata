--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local cancel = {}

local mattata = require('mattata')

function cancel:init()
    cancel.commands = mattata.commands(
        self.info.username
    ):command('cancel').table
    cancel.help = [[/cancel - Removes any intrusive keyboards, that are appearing in the current chat, on your client.]]
end

function cancel:on_message(message)
    return mattata.send_message(
        message.chat.id,
        'Cancelled current operation!',
        nil,
        true,
        false,
        message.message_id,
        json.encode(
            {
                ['remove_keyboard'] = true
            }
        )
    )
end

return cancel