--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local hextorgb = {}

local mattata = require('mattata')

function hextorgb:init()
    hextorgb.commands = mattata.commands(
        self.info.username
    ):command('hextorgb')
     :command('hrgb').table
    hextorgb.help = [[/hextorgb <hex code> - Converts the given hex colour code into its RGB format. Alias: /hrgb.]]
end

function hextorgb:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            hextorgb.help
        )
    end
    input = input:gsub('#', '')
    if tonumber('0x' .. input:sub(1, 2)) == nil or tonumber('0x' .. input:sub(3, 4)) == nil or tonumber('0x' .. input:sub(5, 6)) == nil then
        return mattata.send_reply(
            message,
            hextorgb.help
        )
    end
    local success = mattata.send_photo(
        message.chat.id,
        'https://placeholdit.imgix.net/~text?txtsize=1&bg=' .. input .. '&w=150&h=200', 'rgb(' .. tonumber('0x' .. input:sub(1, 2)) .. ', ' .. tonumber('0x' .. input:sub(3, 4)) .. ', ' .. tonumber('0x' .. input:sub(5, 6)) .. ')',
        false,
        message.message_id
    )
    if not success then
        return mattata.send_message(
            message.chat.id,
            hextorgb.help
        )
    end
end

return hextorgb