--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local nick = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function nick:init(configuration)
    nick.commands = mattata.commands(self.info.username):command('nick'):command('nickname'):command('nn'):command('setnick').table
    nick.help = '/nick <text> - Sets your nickname to the given text. Your nickname can\'t be longer than ' .. configuration.limits.nick .. ' characters in length. Aliases: /nickname, /nn, /setnick.'
end

function nick.on_message(_, message, configuration)
    local input = mattata.input(message.text)
    if not input then
        local current = redis:hget('user:' .. message.from.id .. ':info', 'nickname')
        local output, parse_mode = nick.help
        if current then
            current = mattata.get_formatted_user(message.from.id, current, 'html')
            output = 'You are currently known as ' .. current .. '! To change this, send <code>/nick &lt;text&gt;</code>'
            parse_mode = 'html'
        end
        return mattata.send_reply(message, output, parse_mode)
    elseif input:len() > configuration.limits.nick then
        return mattata.send_reply(message, 'Your nickname can\'t be longer than ' .. configuration.limits.nick .. ' characters in length!')
    end
    redis:hset('user:' .. message.from.id .. ':info', 'nickname', input)
    local user = mattata.get_formatted_user(message.from.id, input, 'html')
    return mattata.send_message(message.chat.id, string.format('You\'ll now be known as %s!', user), 'html')
end

return nick