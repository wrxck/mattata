--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local save = {}

local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function save:init()
    save.commands = mattata.commands(
        self.info.username
    ):command('save').table
    save.help = [[/save - Stores the replied-to message in mattata's database - of which a randomly-selected, saved message from the said user can be retrieved using /quote.]]
end

function save:on_message(message)
    if not message.reply or #message.reply.text < 1 then
        return mattata.send_reply(
            message,
            save.help
        )
    elseif message.reply.forward_from then
        message.reply.from = message.reply.forward_from
    end
    if redis:get('user:' .. message.reply.from.id .. ':opt_out') then
        redis:del('quotes:' .. message.reply.from.id)
        return mattata.send_reply(
            message,
            'This user has opted out of data-storing functionality.'
        )
    end
    local quotes = redis:get('quotes:' .. message.reply.from.id)
    if not quotes then
        quotes = {}
    else
        quotes = json.decode(quotes)
    end
    table.insert(
        quotes,
        message.reply.text
    )
    redis:set(
        'quotes:' .. message.reply.from.id,
        json.encode(quotes)
    )
    return mattata.send_reply(
        message,
        string.format(
            'That message has been saved in my database, and added to the list of possible responses for when /quote is used in reply to %s%s!',
            message.reply.from.username and '@' or '',
            message.reply.from.username or message.reply.from.first_name
        )
    )
end

return save