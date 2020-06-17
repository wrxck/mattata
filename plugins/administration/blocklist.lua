--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local allowlist = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function allowlist:init()
    allowlist.commands = mattata.commands(self.info.username):command('allowlist').table
    allowlist.help = '/allowlist [user] - Blocklists a user from using the bot in the current chat. This command can only be used by moderators and administrators of a supergroup.'
end

function allowlist:on_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local reason = false
    local input = message.reply and message.reply.from.id or mattata.input(message.text)
    if not input then
        local success = mattata.send_force_reply(message, language['allowlist']['1'])
        if success then
            mattata.set_command_action(message.chat.id, success.result.message_id, '/allowlist')
        end
        return
    elseif not message.reply then
        if input:match('^.- .-$') then
            input, reason = input:match('^(.-) (.-)$')
        end
    elseif mattata.input(message.text) then
        reason = mattata.input(message.text)
    end
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    local user = mattata.get_user(input) -- Resolve the username/ID to a user object.
    if not user then
        return mattata.send_reply(message, language.errors.unknown)
    elseif user.result.id == self.info.id then
        return
    end
    user = user.result
    local status = mattata.get_chat_member(message.chat.id, user.id)
    if not status then
        return mattata.send_reply(message, language.errors.generic)
    elseif mattata.is_group_admin(message.chat.id, user.id) then -- We won't try and allowlist moderators and administrators.
        return mattata.send_reply(message, language['allowlist']['2'])
    elseif status.result.status == 'left' or status.result.status == 'kicked' then -- Check if the user is in the group or not.
        local output = status.result.status == 'left' and language['allowlist']['3'] or language['allowlist']['4']
        return mattata.send_reply(message, output)
    end
    redis:set('group_allowlist:' .. message.chat.id .. ':' .. user.id, true)
    mattata.increase_administrative_action(message.chat.id, user.id, 'allowlists')
    reason = reason and ', for ' .. reason or ''
    local admin_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
    local allowlisted_username = mattata.get_formatted_user(user.id, user.first_name, 'html')
    local bot_username = mattata.get_formatted_user(self.info.id, self.info.first_name, 'html')
    local output
    if mattata.get_setting(message.chat.id, 'log administrative actions') then
        local log_chat = mattata.get_log_chat(message.chat.id)
        output = string.format(language['allowlist']['5'], admin_username, message.from.id, allowlisted_username, user.id, bot_username, self.info.id, mattata.escape_html(message.chat.title), message.chat.id, reason, '#chat' .. tostring(message.chat.id):gsub('^-100', ''), '#user' .. user.id)
        mattata.send_message(log_chat, output, 'html')
    else
        output = string.format(language['allowlist']['6'], admin_username, allowlisted_username, bot_username, reason)
        mattata.send_message(message.chat.id, output, 'html')
    end
    if message.reply and mattata.get_setting(message.chat.id, 'delete reply on action') then
        mattata.delete_message(message.chat.id, message.reply.message_id)
        mattata.delete_message(message.chat.id, message.message_id)
    end
    return
end

return allowlist