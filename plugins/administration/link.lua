--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local link = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function link:init()
    link.commands = mattata.commands(self.info.username):command('link').table
    link.help = '/link - Returns the chat\'s invite link.'
end

function link.on_message(_, message, _, language)
    if message.chat.type == 'private' then
        return mattata.send_reply(message, language.errors.supergroup)
    end
    local success = message.chat.username and {
        ['result'] = 'https://t.me/' .. message.chat.username:lower()
    } or redis:get('chat:' .. message.chat.id .. ':link') or mattata.export_chat_invite_link(message.chat.id)
    if not success then
        return mattata.send_reply(message, 'I need to be an administrator of this chat in order to retrieve the invite link.')
    elseif type(success) ~= 'table' then
        success = {
            ['result'] = success
        }
    end
    redis:set('chat:' .. message.chat.id .. ':link', success.result)
    redis:expire('chat:' .. message.chat.id .. ':link', 86400)
    success = string.format('<a href="%s">%s</a>', success.result, mattata.escape_html(message.chat.title))
    return mattata.send_message(message.chat.id, success, 'html')
end

return link