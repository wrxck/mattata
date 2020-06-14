--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local blacklistchat = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function blacklistchat:init()
    blacklistchat.commands = mattata.commands(self.info.username):command('blacklistchat').table
end

function blacklistchat.on_message(_, message, _, language)
    if not mattata.is_global_admin(message.from.id) then
        return false
    end
    local input = mattata.input(message.text)
    if not input then
        return false
    end
    input = input:match('^@(.-)$') or input
    local res = mattata.get_chat(input)
    local output
    if not res then
        output = string.format(language['blacklistchat']['3'], input)
    elseif res.result.type == 'private' then
        output = string.format(language['blacklistchat']['2'], input)
    else
        redis.set('blacklisted_chats:' .. input, true)
        output = string.format(language['blacklistchat']['1'], input)
    end
    return mattata.send_reply(message, output)
end

return blacklistchat