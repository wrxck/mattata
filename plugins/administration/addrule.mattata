--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local addrule = {}
local mattata = require('mattata')

function addrule:init()
    addrule.commands = mattata.commands(self.info.username):command('addrule').table
    addrule.help = '/addrule <text> - Allows you to add another group rule!'
end

function addrule.on_message(_, message, _, language)
    if message.chat.type == 'private' then return false end
    if not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, language['addrule']['1'])
    end
    local rules = mattata.get_value(message.chat.id, 'rules')
    if not rules then
        return mattata.send_reply(message, language['addrule']['2'])
    end
    local new_rules = rules .. '\n' .. input
    local success = mattata.send_message(message.chat.id, new_rules, 'markdown')
    if not success and utf8.len(new_rules) > 4096 then
        return mattata.send_reply(message, language['addrule']['3'])
    elseif not success then
        return mattata.send_reply(message, language['addrule']['4'])
    end
    mattata.set_value(message.chat.id, 'rules', new_rules)
    return mattata.edit_message_text(message.chat.id, success.result.message_id, language['addrule']['5'])
end

return addrule