--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local whitelistlink = {}
local mattata = require('mattata')

function whitelistlink:init()
    whitelistlink.commands = mattata.commands(self.info.username):command('whitelistlink'):command('wl').table
    whitelistlink.help = '/whitelistlink <links> - Whitelists the given links in the current chat. Requires administrative privileges. Use /whitelistlink -del <links> to Alias: /wl.'
end

function whitelistlink:on_message(message)
    if not mattata.is_group_admin(message.chat.id, message.from.id) then
        return false
    end
    local input = mattata.input(message.text)
    local delete = false
    if not input then
        return mattata.send_reply(message, 'Please specify the URLs or @usernames you\'d like to whitelist.')
    elseif input:match('^%-del .-$') then
        input = input:match('^%-del (.-)$')
        delete = true
    end
    local output = mattata.check_links(message, false, false, true, false, delete)
    return mattata.send_reply(message, output)
end

return whitelistlink