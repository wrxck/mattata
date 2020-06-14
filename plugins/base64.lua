--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local base64 = {}
local mattata = require('mattata')
local b64 = require('base64')

function base64:init()
    base64.commands = mattata.commands(self.info.username):command('base64'):command('b64'):command('dbase64'):command('db64').table
    base64.help = '/base64 <text> - Encodes the given text in base64. Use /dbase64 or /db64 to turn base64-encoded text into plaintext.  Alias: /b64.'
end

function base64.on_message(_, message)
    local input = message.reply and message.reply.text or mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, base64.help)
    end
    local output = b64.encode(input)
    if message.command == 'dbase64' or message.command == 'db64' then
        output = b64.decode(input)
    end
    if not output then
        return mattata.send_reply(message, 'That\'s not valid base64-encoded text!')
    elseif utf8.len(output) > 4096 then
        return mattata.send_reply(message, 'That\'s too much text for me to give you. But you can have a cookie instead. ' .. utf8.char(127850))
    end
    local success = mattata.send_reply(message, output)
    if not success then
        return mattata.send_reply(message, 'That\'s not valid base64-encoded text!')
    end
    return success
end

return base64