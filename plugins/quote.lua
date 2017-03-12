--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local quote = {}

local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function quote:init()
    quote.commands = mattata.commands(
        self.info.username
    ):command('quote').table
    quote.help = [[/quote - Returns a randomly-selected, quoted message from the replied-to user. Quoted messages are stored when a user uses /save in reply to the said user's message(s).]]
end

function quote:on_message(message)
    if not message.reply then
        local quotes = redis:keys('quotes:*')
        local user, quote
        repeat
            quote = quotes[math.random(#quotes)]
            user = quote:match(':(%d+)$')
        until mattata.get_chat(user)
        user = mattata.get_chat(user).result
        quote = json.decode(
            redis:get(quote)
        )
        return mattata.send_reply(
            message,
            string.format(
                '<i>%s</i>\n– %s%s',
                mattata.escape_html(quote[math.random(#quote)]),
                mattata.escape_html(user.name),
                user.username and ' (@' .. user.username .. ')' or ''
            ),
            'html'
        )
    elseif redis:get('user:' .. message.reply.from.id .. ':opt_out') then
        redis:del('quotes:' .. message.reply.from.id)
        return mattata.send_reply(
            message,
            'This user has opted out of data-storing functionality.'
        )
    end
    local quotes = redis:get('quotes:' .. message.reply.from.id)
    if not quotes then
        return mattata.send_reply(
            message,
            string.format(
                'There are no saved quotes for %s%s! You can save one by using /save in reply to a message they send.',
                message.reply.from.username and '@' or '',
                message.reply.from.username or message.reply.from.first_name
            )
        )
    end
    quotes = json.decode(quotes)
    return mattata.send_reply(
        message,
        string.format(
            '<i>%s</i>\n– %s%s',
            mattata.escape_html(quotes[math.random(#quotes)]),
            mattata.escape_html(message.reply.from.name),
            message.reply.from.username and ' (@' .. message.reply.from.username .. ')' or ''
        ),
        'html'
    )
end

return quote