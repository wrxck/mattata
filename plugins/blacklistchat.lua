--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local blocklistchat = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function blocklistchat:init()
    blocklistchat.commands = mattata.commands(self.info.username):command('blocklistchat').table
end

function blocklistchat.on_message(_, message, _, language)
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
        output = string.format(language['blocklistchat']['3'], input)
    elseif res.result.type == 'private' then
        output = string.format(language['blocklistchat']['2'], input)
    else
        redis.set('blocklisted_chats:' .. input, true)
        output = string.format(language['blocklistchat']['1'], input)
    end
    return mattata.send_reply(message, output)
end

return blocklistchat