--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local quote = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function quote:init()
    quote.commands = mattata.commands(self.info.username):command('quote').table
    quote.help = '/quote - Returns a randomly-selected, quoted message from the replied-to user. Quoted messages are stored when a user uses /save in reply to the said user\'s message(s).'
end

function quote.on_message(_, message, _, language)
    if not message.reply then
        local quotes = redis:keys('user:*:quotes')
        if #quotes == 0 then
            return false
        end
        local selected = quotes[math.random(#quotes)]
        local user = selected:match('^user:(%d+):quotes$')
        local all = redis:smembers('user:' .. user .. ':quotes')
        local random = all[math.random(#all)]
        return mattata.send_reply(message, string.format('<i>%s</i>\n– Anonymous', mattata.escape_html(random)), 'html')
    elseif redis:get('user:' .. message.reply.from.id .. ':opt_out') then
        redis:del('user:' .. message.reply.from.id .. ':quotes')
        return mattata.send_reply(message, language['quote']['1'])
    end
    local quotes = redis:smembers('user:' .. message.reply.from.id .. ':quotes')
    if #quotes == 0 then
        return mattata.send_reply(
            message, string.format(
                language['quote']['2'],
                message.reply.from.username and '@' or '',
                message.reply.from.username or message.reply.from.first_name
            )
        )
    end
    return mattata.send_reply(
        message,
        string.format(
            '<i>%s</i>\n– %s%s',
            mattata.escape_html(quotes[math.random(#quotes)]),
            mattata.escape_html(message.reply.from.name),
            message.reply.from.username and ' (@' .. message.reply.from.username .. ')' or ''
        ), 'html'
    )
end

return quote