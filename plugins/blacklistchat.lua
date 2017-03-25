--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local blacklistchat = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function blacklistchat:init()
    blacklistchat.commands = mattata.commands(
        self.info.username
    ):command('blacklistchat').table
end

function blacklistchat:on_message(message)
    if not mattata.is_global_admin(message.from.id) then
        return
    end
    local input = mattata.input(message.text)
    if not input then
        return
    end
    input = input:match('^@(.-)$') or input
    if mattata.get_chat(input) and mattata.get_chat(input).result.type ~= 'private' then
        redis:set(
            'blacklisted_chats:' .. input,
            true
        )
        return mattata.send_reply(
            message,
            input .. ' has now been blacklisted, and I will leave whenever I am added there!'
        )
    elseif mattata.get_chat(input) then
        return mattata.send_reply(
            message,
            input .. ' is a user, this command is only for blacklisting chats such as groups and channels!'
        )
    end
    return mattata.send_reply(
        message,
        input .. ' doesn\'t appear to be a valid chat!'
    )
end

return blacklistchat