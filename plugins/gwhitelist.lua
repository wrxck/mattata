--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local gwhitelist = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function gwhitelist:init()
    gwhitelist.commands = mattata.commands(self.info.username):command('gwhitelist').table
end

function gwhitelist:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not mattata.is_global_admin(message.from.id) then
        return
    elseif not message.reply and not input then
        return mattata.send_reply(message, language['gwhitelist']['1'])
    elseif message.reply then
        input = message.reply.from.id
    end
    if tonumber(input) == nil and not input:match('^@') then
        input = '@' .. input
    end
    local resolved = mattata.get_user(input) or mattata.get_chat(input)
    local output
    if not resolved then
        output = string.format(language['gwhitelist']['2'], input)
        return mattata.send_reply(message, output)
    elseif resolved.result.type ~= 'private' then
        output = string.format(language['gwhitelist']['3'], resolved.result.type)
        return mattata.send_reply(message, output)
    end
    if resolved.result.id == self.info.id or mattata.is_global_admin(resolved.result.id) then
        return
    end
    redis:del('global_blacklist:' .. resolved.result.id)
    local bot_username = mattata.get_formatted_user(self.info.id, self.info.first_name, 'html')
    local our_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
    local whitelisted_username = mattata.get_formatted_user(resolved.result.id, resolved.result.first_name, 'html')
    output = string.format('%s <code>[%s]</code> has whitelisted %s <code>[%s]</code> to use %s <code>[%s]</code>.', our_username, message.from.id, whitelisted_username, resolved.result.id, bot_username, self.info.id)
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
        return mattata.send_message(configuration.log_channel, output, 'html')
    end
    return mattata.send_message(message.chat.id, output, 'html')
end

return gwhitelist