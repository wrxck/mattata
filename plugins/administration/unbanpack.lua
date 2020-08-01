--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local unbanpack = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function unbanpack:init()
    unbanpack.commands = mattata.commands(self.info.username):command('unbanpack'):command('ubp').table
    unbanpack.help = '/unbanpack - Unbans the replied-to sticker\'s pack. This command can only be used by moderators and administrators of a supergroup. Alias: /ubp.'
end


function unbanpack:on_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    elseif not message.reply then
        return mattata.send_reply(message, 'Please reply to a sticker from the sticker set you\'d like to unban.')
    elseif not message.reply.sticker then
        return mattata.send_reply(message, 'You must use this command in reply to a sticker!')
    elseif not message.reply.sticker.set_name then
        return mattata.send_reply(message, 'That sticker isn\'t from a set, it\'s just a file - I\'m afraid I can\'t unban that!')
    end
    local set_name = message.reply.sticker.set_name
    if not redis:sismember('banned_sticker_packs:' .. message.chat.id, set_name) then
        mattata.send_reply(message, 'That [sticker pack](https://t.me/addstickers/' .. set_name .. ') isn\'t currently banned in this chat! To ban it, send /banpack in reply to one of the stickers from it!', true, true)
    end
    redis:srem('banned_sticker_packs:' .. message.chat.id, set_name)
    if mattata.get_setting(message.chat.id, 'log administrative actions') then
        local log_chat = mattata.get_log_chat(message.chat.id)
        local output = '%s <code>[%s]</code> has unbanned the sticker pack <a href="https://t.me/addstickers/%s">%s</a> in %s <code>[%s]</code>.\n#chat%s #user%s'
        local admin = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
        output = string.format(output, admin, message.from.id, set_name, set_name, mattata.escape_html(message.chat.title), message.chat.id, tostring(message.chat.id):gsub('^%-100', ''), message.from.id)
        mattata.send_message(log_chat, output, 'html')
    end
    return mattata.send_reply(message, 'I\'ve successfully unbanned [that sticker pack](https://t.me/addstickers/' .. set_name .. ') in this chat!', true, true)
end

return unbanpack