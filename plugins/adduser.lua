--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local adduser = {}

local mattata = require('mattata')

function adduser:init(configuration)
    adduser.arguments = 'adduser'
    adduser.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('adduser').table
end

function adduser:on_message(message)
    if message.chat.type ~= 'group' then
        return mattata.send_reply(
            message,
            'This command can only be used in normal groups (NOT supergroups). The user you specify must have also messaged me before.'
        )
    end
    local input = mattata.input(message.text)
    if not input or input:match('%s') then
        return mattata.send_reply(
            message,
            'Please specify the user you would like me to add, by numerical ID or username. This will only work if the user has messaged me before and has their privacy settings set to allow people to add them to groups.'
        )
    end
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    return mattata.add_chat_user_pwr(
        message.chat.id,
        input
    )
end

return adduser