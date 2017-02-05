--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local msglink = {}

local mattata = require('mattata')

function msglink:init(configuration)
    msglink.arguments = 'msglink'
    msglink.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('msglink').table
    msglink.help = '/msglink - Gets the link to the replied-to message.'
end

function msglink:on_message(message)
    if message.chat.type ~= 'supergroup' and message.chat.type ~= 'channel' then
        return mattata.send_reply(
            message,
            'You can only use this command in supergroups and channels.'
        )
    elseif not message.chat.username then
        return mattata.send_reply(
            message,
            'This ' .. message.chat.type .. ' must be public, with a @username.'
        )
    elseif not message.reply_to_message then
        return mattata.send_reply(
            message,
            'Please reply to the message you\'d like to get a link for.'
        )
    end
    return mattata.send_message(
        message.chat.id,
        't.me/' .. message.chat.username .. '/' .. message.reply_to_message.message_id,
        nil,
        true,
        false,
        message.reply_to_message.message_id
    )
end

return msglink