--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local unfilter = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function unfilter:init()
    unfilter.commands = mattata.commands(self.info.username):command('unfilter').table
    unfilter.help = '/unfilter <words> - Remove words from this chat\'s word filter.'
end

function unfilter:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    end
    local input = mattata.input(message.text)
    if not input
    or not input:match('.+')
    then
        return mattata.send_reply(
            message,
            unfilter.help
        )
    end
    local words = {}
    for word in input:gmatch('.+')
    do
        table.insert(
            words,
            word
        )
    end
    local total = redis:smembers('word_filter:' .. message.chat.id)
    local removed = {}
    for n, word in pairs(words)
    do
        if redis:sismember(
            'word_filter:' .. message.chat.id,
            word
        )
        then
            local success = redis:srem(
                'word_filter:' .. message.chat.id,
                word
            )
            if success == 1
            then
                table.insert(
                    removed,
                    word
                )
            end
        end
    end
    local new_total = #total - #removed
    return mattata.send_message(
        message.chat.id,
        tostring(#removed) .. ' word(s) have been removed from this chat\'s word filter. There is now a total of ' .. tostring(new_total) .. ' word(s) filtered in this chat. Use /filter <words> to add words to this filter.'
    )
end

return unfilter
