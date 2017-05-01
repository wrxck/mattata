--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local msglink = {}
local mattata = require('mattata')

function msglink:init()
    msglink.commands = mattata.commands(self.info.username):command('msglink').table
    msglink.help = '/msglink - Gets the link to the replied-to message.'
end

function msglink:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    and message.chat.type ~= 'channel'
    then
        return mattata.send_reply(
            message,
            language['msglink']['1']
        )
    elseif not message.chat.username
    then
        return mattata.send_reply(
            message,
            string.format(
                language['msglink']['2'],
                message.chat.type
            )
        )
    elseif not message.reply
    then
        return mattata.send_reply(
            message,
            language['msglink']['3']
        )
    end
    return mattata.send_message(
        message.chat.id,
        'https://t.me/' .. message.chat.username .. '/' .. message.reply.message_id,
        nil,
        true,
        false,
        message.reply.message_id
    )
end

return msglink