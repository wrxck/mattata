--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local doge = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function doge:init()
    doge.commands = mattata.commands(self.info.username):command('doge').table
    doge.help = '/doge <text> - Doge-ifies the given text. Sentences should be separated using slashes or new lines. Example: /doge hello world/this is a test sentence/make sure you type like this/else it won\'t work!'
end

function doge.on_message(_, message, _, language)
    local input = message.reply and message.reply.text or mattata.input(message.text)
    if not input then
        local success = mattata.send_force_reply(message, language['doge']['1'])
        if success then
            redis:set('action:' .. message.chat.id .. ':' .. success.result.message_id, '/doge')
        end
        return
    elseif message.reply then
        input = input:gsub(' ', '\n')
    end
    local url = 'http://dogr.io/' .. input:gsub(' ', '%%20'):gsub('\n', '/') .. '.png?split=false&.png'
    if not url:match('https?://[%%%w-_%.%?%.:/%+=&]+') == url then -- Validate the URL.
        return mattata.send_reply(message, language['errors']['results'])
    end
    return mattata.send_photo(message.chat.id, url)
end

return doge