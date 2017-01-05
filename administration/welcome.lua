--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local welcome = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function welcome:init(configuration)
    welcome.arguments = 'welcome <value>'
    welcome.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('welcome').table
    welcome.help = configuration.command_prefix .. 'welcome <value> - Sets the group\'s welcome message to the given value.\nUse $id as a placeholder for the user\'s numerical ID, $name as a placeholder for the user\'s name, $title as a placeholder for the group title, and $chatid as a placeholder for the group\'s numerical ID.\nHTML formatting is supported.'
end

function welcome.set_welcome_message(message, welcome_message)
    local hash = mattata.get_redis_hash(
        message,
        'welcome_message'
    )
    if hash then
        redis:hset(
            hash,
            'welcome_message',
            welcome_message
        )
        return 'Successfully set the new welcome message!'
    end
end

function welcome.get_welcome_message(message)
    local hash = mattata.get_redis_hash(
        message,
        'welcome_message'
    )
    if hash then
        local welcome_message = redis:hget(
            hash,
            'welcome_message'
        )
        if not welcome_message or welcome_message == 'false' then
            return false
        else
            return welcome_message
        end
    end
end

function welcome:on_new_chat_member(message, configuration, language)
    local welcome_message = welcome.get_welcome_message(message)
    if not welcome_message then
        local join_messages = language.join_messages
        local output = join_messages[math.random(#join_messages)]
        return mattata.send_message(
            message.chat.id,
            output:gsub('NAME', message.new_chat_member.first_name)
        )
    else
        local name = mattata.escape_html(message.new_chat_member.first_name)
        if message.new_chat_member.last_name then
            name = name .. ' ' .. mattata.escape_html(message.new_chat_member.last_name)
        end
        local title = mattata.escape_html(message.chat.title)
        welcome_message = welcome_message:gsub('%$id', message.new_chat_member.id):gsub('%$name', name):gsub('%$title', title):gsub('%$chatid', message.chat.id)
        return mattata.send_message(
            message.chat.id,
            welcome_message,
            'html'
        )
    end
end

function welcome:on_message(message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and not mattata.is_global_admin(message.from.id) then
        return mattata.send_reply(
            message,
            'You must be an administrator in this chat to use this command.'
        )
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            welcome.help
        )
    end
    local validate = mattata.send_message(
        message.chat.id,
        input,
        'html'
    )
    if not validate then
        return mattata.send_reply(
            message,
            'There was an error formatting your message, please check your HTML syntax and try again.'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        validate.result.message_id,
        welcome.set_welcome_message(message, input)
    )
end

return welcome