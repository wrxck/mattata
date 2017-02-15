--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local channel = {}

local mattata = require('mattata')

function channel:init()
    channel.commands = mattata.commands(
        self.info.username
    ):command('channel')
     :command('ch').table
    channel.help = [[/channel <channel> <message> - Sends a message to a Telegram channel/group. The channel/group can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels/groups they own and/or administrate. Alias: /ch.]]
end

function channel:on_message(message, configuration)
    if message.chat.type == 'channel' then
        return
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            channel.help
        )
    end
    local target = mattata.get_word(input)
    if tonumber(target) == nil and not target:match('^@') then
        target = '@' .. target
    end
    local admin_list = mattata.get_chat_administrators(target)
    if not admin_list and not mattata.is_global_admin(message.from.id) then
        return mattata.send_reply(
            message,
            'I was unable to retrieve a list of administrators for that chat!'
        )
    elseif not mattata.is_global_admin(message.from.id) then -- Make OP users an exception
        local is_admin = false
        for _, admin in ipairs(admin_list.result) do
            if admin.user.id == message.from.id then
                is_admin = true
            end
        end
        if not is_admin then
            return mattata.send_reply(
                message,
                'You don\'t appear to be an administrator in that chat!'
            )
        end
    end
    local text = input:match('^' .. target .. '(.-)$')
    if not text then
        return mattata.send_reply(
            message,
            'Please specify the message to send using /channel <channel> <message>!'
        )
    end
    local success = mattata.send_message(
        target,
        text,
        'markdown'
    )
    if not success then
        return mattata.send_reply(
            message,
            'I was unable to send your message!'
        )
    end
    return mattata.send_reply(
        message,
        'Your message was sent successfully!'
    )
end

return channel