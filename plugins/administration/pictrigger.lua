--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local pictriggers = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function pictriggers:init()
    pictriggers.commands = mattata.commands(self.info.username):command('pictriggers'):command('addpictrigger'):command('delpictrigger').table
    pictriggers.help = '/pictriggers - Allows admins to view existing picture triggers. Use /addpictrigger <trigger> <URL> to add one, and /delpictrigger <trigger> to delete one. Each chat is allowed 8 picture triggers, with a maximum of 16 characters per word trigger. Trigger words can be alpha-numerical.'
end

function pictriggers:on_new_message(message)
    if message.command or message.is_media or self.is_ai then
        return false
    end
    local matches = redis:hgetall('pictriggers:' .. message.chat.id)
    if not next(matches) == 0 then
        return false
    end
    for trigger, value in pairs(matches) do
        if message.text:match(trigger) then
            return mattata.send_photo(message.chat.id, value)
        end
    end
    return
end

function pictriggers:on_message(message, configuration)
    self.is_done = true
    if message.chat.type == 'private' or not mattata.is_group_admin(message.chat.id, message.from.id) then
        return false
    elseif message.command == 'pictriggers' then
        local matches = redis:hgetall('pictriggers:' .. message.chat.id)
        if not next(matches) then
            return mattata.send_reply(message, 'This chat doesn\'t have any picture triggers set up. To add one, use /addpictrigger <trigger> <URL>.')
        end
        local output = 'Picture triggers for <b>%s</b>\n\n%s'
        local all = {}
        for trigger, value in pairs(matches) do
            local line = '<code>%s</code>: %s'
            line = string.format(line, mattata.escape_html(trigger), mattata.escape_html(value))
            table.insert(all, line)
        end
        all = table.concat(all, '\n')
        output = string.format(output, mattata.escape_html(message.chat.title), all)
        return mattata.send_reply(message, output, 'html')
    elseif message.command == 'addpictrigger' then
        local input = mattata.input(message.text)
        if not input or not input:match('^%w+ .-$') then
            return mattata.send_reply(message, pictriggers.help)
        end
        local count = 0
        local all = redis:hgetall('pictriggers:' .. message.chat.id)
        for _, v in pairs(all) do
            count = count + 1
        end
        if count >= 8 then
            return mattata.send_reply(message, 'You can\'t have more than 8 picture triggers! Please delete one using /delpictrigger <trigger>. To view a list of this chat\'t picture triggers, use /pictriggers.')
        end
        local trigger, value = input:match('^(%w+) (.-)$')
        if trigger:len() > 16 then
            return mattata.send_reply(message, 'The trigger needs to be 1-16 characters long, and alpha-numerical.')
        end
        local success = mattata.send_photo(configuration.log_chat, value)
        if not success then
            return mattata.send_reply(message, 'That appears to be an invalid URL, because I couldn\'t send it! Please make sure it\'s a format Telegram bot API supports.')
        end
        mattata.delete_message(configuration.log_chat, success.result.message_id)
        redis:hset('pictriggers:' .. message.chat.id, trigger, value)
        return mattata.send_reply(message, 'Successfully added that picture trigger! To view a list of picture triggers, send /pictriggers.')
    elseif message.command == 'delpictrigger' then
        local input = mattata.input(message.text)
        if not input or not input:match('^%w+$') then
            return mattata.send_reply(message, 'Please specify the picture trigger you\'d like to delete! To view your existing picture triggers, send /pictriggers.')
        end
        local deleted = redis:hdel('pictriggers:' .. message.chat.id, input)
        if deleted == 0 then
            return mattata.send_reply(message, 'That trigger does not exist! Use /pictriggers to view a list of existing picture triggers for this chat.')
        end
        return mattata.send_reply(message, 'Successfully deleted that picture trigger!')
    end
    return false
end

return pictriggers