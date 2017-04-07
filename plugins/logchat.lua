--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local logchat = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function logchat:init()
    logchat.commands = mattata.commands(self.info.username):command('logchat').table
    logchat.help = '/logchat [chat] - Specify the chat that you wish to log all of this chat\'s administrative actions into.'
end

function logchat:on_message(message, configuration)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            configuration.errors.supergroup
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return mattata.send_reply(
            message,
            configuration.errors.admin
        )
    end
    local input = mattata.input(message.text)
    if not input
    then
        local success = mattata.send_force_reply(
            message,
            'Please enter the username or numerical ID of the chat you wish to log all administrative actions into.'
        )
        if success
        then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/logchat'
            )
        end
        return
    end
    local res = mattata.send_message(
        message.chat.id,
        'Checking to see whether that chat is valid...'
    )
    if not res
    then
        return
    elseif tonumber(input) == nil
    and not input:match('^@')
    then
        input = '@' .. input
    end
    local valid = mattata.get_chat(input)
    or mattata.get_user(input)
    if not valid
    or not valid.result
    then
        return mattata.edit_message_text(
            message.chat.id,
            res.result.message_id,
            'I\'m sorry, it appears you\'ve either specified an invalid chat, or you\'ve specified a chat I haven\'t been added to yet. Please rectify this and try again.'
        )
    elseif valid.result.type == 'private'
    then
        return mattata.edit_message_text(
            message.chat.id,
            res.result.message_id,
            'You can\'t set a user as your log chat!'
        )
    elseif not mattata.is_group_admin(
        valid.result.id,
        message.from.id
    )
    then
        return mattata.edit_message_text(
            message.chat.id,
            res.result.message_id,
            'You don\'t appear to be an administrator in that chat!'
        )
    elseif redis:hget(
        'chat:' .. message.chat.id .. ':settings',
        'log chat'
    ) and redis:hget(
        'chat:' .. message.chat.id .. ':settings',
        'log chat'
    ) == valid.result.id
    then
        return mattata.edit_message_text(
            message.chat.id,
            res.result.message_id,
            'It seems I\'m already logging administrative actions into that chat! Use /logchat to specify a new one.'
        )
    end
    mattata.edit_message_text(
        message.chat.id,
        res.result.message_id,
        'That chat is valid, I\'m now going to try and send a test message to it, just to ensure I have permission to post!'
    )
    local permission = mattata.send_message(
        valid.result.id,
        'Hello, World - this is a test message to check my posting permissions - if you\'re reading this, then everything went OK!'
    )
    if not permission
    then
        return mattata.edit_message_text(
            message.chat.id,
            res.result.message_id,
            'It appears I don\'t have permission to post to that chat. Please ensure it\'s still a valid chat and that I have administrative rights!'
        )
    end
    redis:hset(
        'chat:' .. message.chat.id .. ':settings',
        'log chat',
        valid.result.id
    )
    return mattata.edit_message_text(
        message.chat.id,
        res.result.message_id,
        'All done! From now on, any administrative actions in this chat will be logged into ' .. input .. ' - to change the chat you want me to log administrative actions into, just send /logchat.'
    )
end

return logchat