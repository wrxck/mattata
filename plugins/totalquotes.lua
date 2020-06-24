--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local totalquotes = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function totalquotes:init()
    totalquotes.commands = mattata.commands(self.info.username):command('totalquotes').table
    totalquotes.help = '/totalquotes - View the total number of quotes saved in the current chat.'
end

function totalquotes.on_message(_, message)
    if message.chat.type == 'private' then
        return false
    end
    local users = mattata.get_chat_members(message.chat.id)
    local total = 0
    for _, user in pairs(users) do
        local quotes = redis:smembers('user:' .. user .. ':quotes')
        total = total + #quotes
    end
    return mattata.send_reply(message, 'A total of ' .. total .. ' messages have been quoted here! To view your own quotes, send /quotes. To quote someone, use /quote in reply to one of their messages. To add a quote to the database, use /save in reply to one of their messages.')
end

return totalquotes