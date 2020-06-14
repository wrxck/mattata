--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local afk = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function afk:init()
    afk.commands = mattata.commands(self.info.username):command('afk').table
    afk.help = '/afk [note] - Mark yourself as away from keyboard, with an optional note that will be displayed to users who mention you whilst you\'re away. You must have an @username for this feature to work.'
end

function afk.on_message(_, message, _, language)
    if not message.from.username then
        return mattata.send_reply(message, language['afk']['1']) -- Since this feature relies on detecting username
        -- mentions, this feature is currently only available to users who have a public @username.
    elseif redis:hget('afk:' .. message.from.id, 'since') then -- Check if the user is
    -- already marked as AFK.
        local since = redis:hget('afk:' .. message.from.id, 'since')
        -- Un-mark the user as AFK in the database.
        redis:hdel('afk:' .. message.from.id, 'since')
        redis:hdel('afk:' .. message.from.id, 'note')
        local keys = redis:keys('afk:' .. message.from.id .. ':replied:*')
        if #keys > 0 then
            for _, key in pairs(keys) do
                redis:del(key)
            end
        end
        local time = mattata.format_time(os.time() - tonumber(since))
        local output = string.format(language['afk']['2'], message.from.first_name, time)
        output = output:gsub('AFK', '/AFK') -- temporary solution until i update language strings
        mattata.delete_message(message.chat.id, message.message_id) -- attempt to delete their message to reduce chat clutter
        return mattata.send_message(message.chat.id, output) -- Inform the chat of the user's return, and include the
        -- time they spent marked as AFK.
    end
    local input = mattata.input(message.text) and '\n' .. language['afk']['3'] .. ': ' .. mattata.input(message.text) or ''
    redis:hset('afk:' .. message.from.id, 'since', os.time())
    redis:hset('afk:' .. message.from.id, 'note', input)
    local output = string.format(language['afk']['4'], message.from.first_name, input)
    local success = mattata.send_message(message.chat.id, output)
    if success then -- if the afk message sent, we'll attempt to delete their original message to clear up the chat a bit
        return mattata.delete_message(message.chat.id, message.message_id)
    end
    return false
end

return afk