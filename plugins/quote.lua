--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local quote = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function quote:init()
    quote.commands = mattata.commands(self.info.username):command('quote'):command('q').table
    quote.help = '/quote - Returns a randomly-selected, quoted message from the replied-to user. Quoted messages are stored when a user uses /save in reply to the said user\'s message(s). Alias: /q.'
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
        if random:match('^%$voice:.-$') then
            mattata.send_voice(message.chat.id, random:match('^%$voice:(.-)$'))
            random = '[Voice Message]'
        end
        return mattata.send_reply(message, string.format('<i>%s</i>\n– Anonymous', mattata.escape_html(random)), 'html')
    elseif redis:get('user:' .. message.reply.from.id .. ':opt_out') then
        redis:del('user:' .. message.reply.from.id .. ':quotes')
        return mattata.send_reply(message, language['quote']['1'])
    end
    local quotes = redis:smembers('user:' .. message.reply.from.id .. ':quotes')
    local user = mattata.get_formatted_user(message.reply.from.id, message.reply.from.name, 'html')
    if #quotes == 0 then
        return mattata.send_reply(message, string.format(language['quote']['2'], user), 'html')
    end
    local random = quotes[math.random(#quotes)]
    if random:match('^%$voice:.-$') then
        mattata.send_voice(message.chat.id, random:match('^%$voice:(.-)$'))
        random = '[Voice Message]'
    end
    return mattata.send_reply(
        message, string.format(
            '<i>%s</i>\n– %s',
            mattata.escape_html(random),
            user
        ), 'html'
    )
end

return quote