--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local rules = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function rules:init(configuration)
    rules.arguments = 'rules | ' .. configuration.command_prefix .. 'delrules | ' .. configuration.command_prefix .. 'setrules <value>'
    rules.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('rules'):command('setrules'):command('delrules').table
    rules.help = configuration.command_prefix .. 'rules - Returns the group rules. ' .. configuration.command_prefix .. 'setrules <value> - Sets the group rules to the given value. Markdown is supported, and only group administrators can use this command. Use ' .. configuration.command_prefix .. 'delrules to delete the current rules - this command may also only be used by group administrators.'
end

function rules.set_rules(message, rules)
    local hash = mattata.get_redis_hash(
        message,
        'rules'
    )
    if hash then
        redis:hset(
            hash,
            'rules',
            rules
        )
        return 'Successfully set the new rules.'
    end
end

function rules.del_rules(message)
    local hash = mattata.get_redis_hash(
        message,
        'rules'
    )
    if redis:hexists(
        hash,
        'rules'
    ) == true then
        redis:hdel(
            hash,
            'rules'
        )
        return 'Your rules have successfully been deleted.'
    else
        return 'There aren\'t any rules set for this group.'
    end
end

function rules.get_rules(message)
    local hash = mattata.get_redis_hash(
        message,
        'rules'
    )
    if hash then
        local rules = redis:hget(
            hash,
            'rules'
        )
        if not rules or rules == 'false' then
            return 'There aren\'t any rules set for this group.'
        else
            return rules
        end
    end
end

function rules:on_message(message, configuration)
    if mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        local input = mattata.input(message.text)
        if message.text_lower:match('^' .. configuration.command_prefix .. 'rules$') then
            return mattata.send_message(
                message.chat.id,
                rules.get_rules(message),
                'markdown'
            )
        end
        if message.text_lower:match('^' .. configuration.command_prefix .. 'delrules') then
            return mattata.send_message(
                message.chat.id,
                rules.del_rules(message)
            )
        end
        if message.text_lower:match('^' .. configuration.command_prefix .. 'setrules') then
            if message.text_lower:match('^' .. configuration.command_prefix .. 'setrules$') then
                return mattata.send_message(
                    message.chat.id,
                    'Please specify the rules to set for this group.'
                )
            else
                return mattata.send_message(
                    message.chat.id,
                    rules.set_rules(message, input)
                )
            end
        end
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'rules') then
        return mattata.send_message(
            message.chat.id,
            rules.get_rules(message),
            'markdown'
        )
    end
end

return rules