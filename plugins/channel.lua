--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local channel = {}

local mattata = require('mattata')

function channel:init(configuration)
    channel.arguments = 'ch <channel> <message>'
    channel.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('ch').table
    channel.help = '/ch <channel> <message> - Sends a message to a Telegram channel/group. The channel/group can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels/groups they own and/or administrate.'
end

function channel:on_message(message, configuration, language)
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
            language.unable_to_retrieve_channel_admins
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
                language.not_channel_admin
            )
        end
    end
    local text = input:match('^' .. target .. '(.-)$')
    if not text then
        return mattata.send_reply(
            message,
            language.enter_message_to_send_to_channel
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
            language.unable_to_send_to_channel
        )
    end
    return mattata.send_reply(
        message,
        language.message_sent_to_channel
    )
end

return channel