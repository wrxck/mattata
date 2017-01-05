--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local antispam = {}

local mattata = require('mattata')
local redis = require('mattata-redis')
local configuration = require('configuration')

function antispam:init(configuration)
    antispam.arguments = 'antispam'
    antispam.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('antispam'):command('antiflood').table
    antispam.help = configuration.command_prefix .. 'antispam - Toggles the anti-spam plugin in the chat. Alias: ' .. configuration.command_prefix .. 'antiflood.'
end

function antispam.set_message_limit(message, limit)
    if tonumber(limit) == nil or tonumber(limit) < 2 or tonumber(limit) > 100 or limit:match('%.') then
        return 'You must specify the number of messages a user can send every second. This value must be a whole number between 2 and 100. The value used will be interpreted as twice the amount you specify if the spammed messages are forwarded. Users will be kicked immediately if they send Arabic/RTL characters.'
    end
    local hash = mattata.get_redis_hash(
        message,
        'antispam'
    )
    redis:hset(
        hash,
        'antispam',
        tonumber(limit)
    )
    return 'Users will now be kicked if they send ' .. tonumber(limit) .. ' or more messages in 5 seconds, or if they forward ' .. tonumber(limit) * 2 .. ' or more messages in 5 seconds.'
end

function antispam.get_message_limit(message)
    local hash = mattata.get_redis_hash(
        message,
        'antispam'
    )
    local limit = redis:hget(
        hash,
        'antispam'
    )
    if not limit or limit == 'false' or tonumber(limit) == nil then
        return 5
    end
    return tonumber(limit)
end

function antispam.is_user_spamming(message) -- Checks if a user is spamming and returns two boolean values
    local messages = redis:get('spam:' .. message.chat.id .. ':' .. message.from.id)
    local forwarded = redis:get('forwarded-spam:' .. message.chat.id .. ':' .. message.from.id)
    local limit = antispam.get_message_limit(message)
    if message.forward_from or message.forward_from_chat then
        if tonumber(forwarded) == nil then
            forwarded = 1
        end
        redis:setex(
            'forwarded-spam:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(forwarded) + 1
        )
        if tonumber(forwarded) == (tonumber(limit) * 2) then
            return true, false
        end
    else
        if tonumber(messages) == nil then
            messages = 1
        end
        redis:setex(
            'spam:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(messages) + 1
        )
        if tonumber(messages) == tonumber(limit) then
            return true, false
        end
    end
    if message.text:match('[\216-\219][\128-\191]') then -- Matches Arabic and RTL characters.
        return false, true
    end
    return false, false
end

function antispam:enable_antispam(message)
    local hash = 'chat:' .. message.chat.id .. ':disabled_plugins'
    if redis:hget(
        hash,
        'antispam'
    ) == 'true' then
        return false
    end
    redis:hset(
        hash,
        'antispam',
        true
    )
    return 'The plugin \'antispam\' has been enabled in this chat. Users will be kicked if they send ' .. tonumber(antispam.get_message_limit(message)) .. ' messages in 5 seconds, or if the forward ' .. tonumber(antispam.get_message_limit(message)) * 2 .. ' messages in 5 seconds. To change this, use \'' .. configuration.command_prefix .. 'antispam <limit>\'. Users will be kicked immediately if they send Arabic/RTL characters.'
end

function antispam:disable_antispam(message)
    local hash = 'chat:' .. message.chat.id .. ':disabled_plugins'
    if redis:hget(
        hash,
        'antispam'
    ) ~= 'true' then
        return false
    end
    redis:hset(
        hash,
        'antispam',
        false
    )
    return 'The plugin \'antispam\' has been disabled in this chat.'
end

function antispam.process_message(self, message, configuration)
    if mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then -- Don't iterate over the user's messages if they're an administrator in the group.
        return
    end
    local flooding, arabic = antispam.is_user_spamming(message)
    if not flooding and not arabic then
        return
    end
    local name = message.from.first_name
    if message.from.last_name then
        name = name .. ' ' .. message.from.last_name
    end
    local success = mattata.kick_chat_member(
        message.chat.id,
        message.from.id
    )
    if not success then
        return
    end
    mattata.unban_chat_member(
        message.chat.id,
        message.from.id
    )
    local output
    if flooding then
        output = mattata.escape_html(self.info.first_name) .. ' [' .. self.info.id .. '] has kicked ' .. mattata.escape_html(message.from.first_name) .. ' [' .. message.from.id .. '] from ' .. mattata.escape_html(message.chat.title) .. ' [' .. message.chat.id .. '] for flooding the chat.'
    elseif arabic then
        output = mattata.escape_html(self.info.first_name) .. ' [' .. self.info.id .. '] has kicked ' .. mattata.escape_html(message.from.first_name) .. ' [' .. message.from.id .. '] from ' .. mattata.escape_html(message.chat.title) .. ' [' .. message.chat.id .. '] for sending Arabic/RTL characters.'
    end
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
        mattata.send_message(
            configuration.log_channel,
            '<pre>' .. output .. '</pre>',
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. output .. '</pre>',
        'html'
    )
end

function antispam:on_message(message)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return -- Ignore all requests from users who aren't administrators in the group.
    end
    local input = mattata.input(message.text)
    local output
    if not input then -- Toggle the plugin
        output = antispam:disable_antispam(message)
        if not output then
            output = antispam:enable_antispam(message)
        end
    else
        output = antispam.set_message_limit(
            message,
            input
        )
    end
    return mattata.send_message(
        message.chat.id,
        output
    )
end

return antispam