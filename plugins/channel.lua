--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local channel = {}

local mattata = require('mattata')
local socket = require('socket')
local json = require('dkjson')
local redis = require('mattata-redis')

function channel:init()
    channel.commands = mattata.commands(
        self.info.username
    ):command('channel')
     :command('ch')
     :command('msg').table
    channel.help = [[/channel <channel> <message> - Sends a message to a Telegram channel/group. The channel/group can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels/groups they own/administrate. Aliases: /ch, /msg.]]
end

function channel:on_callback_query(callback_query, message)
    local request = json.decode(
        redis:hget(
            'temp:channel',
            callback_query.data
        )
    )
    if request.from ~= callback_query.from.id then
        return mattata.answer_callback_query(
            callback_query.id,
            'You are not allowed to use this!'
        )
    elseif not mattata.is_group_admin(
        request.target,
        request.from
    ) then
        return mattata.answer_callback_query(
            callback_query.id,
            'You don\'t appear to be an administrator in that chat anymore!'
        )
    end
    local success = mattata.send_message(
        request.target,
        request.text,
        'markdown'
    )
    if not success then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'I couldn\'t send your message, are you sure I still have permission to send messages in that chat?'
        )
    end
    redis:hdel(
        'temp:channel',
        callback_query.data
    )
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        'Your message has been sent!'
    )
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
    target = mattata.get_chat_id(target) or target
    local admin_list = mattata.get_chat_administrators(target)
    if not admin_list and not mattata.is_global_admin(message.from.id) then
        return mattata.send_reply(
            message,
            'I was unable to retrieve a list of administrators for that chat!'
        )
    elseif not mattata.is_global_admin(message.from.id) then -- Make configured owners an exception.
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
    local text = input:match(' (.-)$')
    if not text then
        return mattata.send_reply(
            message,
            'Please specify the message to send, using the syntax /channel <channel> <message>.'
        )
    end
    local request_id = tostring(socket.gettime()):gsub('%D', '')
    local success = mattata.send_message(
        message.chat.id,
        '*Are you sure you want to send this message? This is how it will look:*\n\n' .. text,
        'markdown',
        true,
        false,
        nil,
        json.encode(
            {
                ['inline_keyboard'] = {
                    {
                        {
                            ['text'] = 'Yes, I\'m sure!',
                            ['callback_data'] = string.format(
                                'channel:%s',
                                request_id
                            )
                        }
                    }
                }
            }
        )
    )
    if not success then
        return mattata.send_reply(
            message,
            'That message contains invalid Markdown formatting! Please correct your syntax and try again.'
        )
    end
    redis:hset(
        'temp:channel',
        request_id,
        json.encode(
            {
                ['target'] = target,
                ['text'] = text,
                ['from'] = message.from.id
            }
        )
    )
    return
end

return channel