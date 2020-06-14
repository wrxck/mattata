--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ban = {}
local mattata = require('mattata')

function ban:init()
    ban.commands = mattata.commands(self.info.username):command('ban').table
    ban.help = '/ban [user] - Bans a user from the current chat. This command can only be used by moderators and administrators of a supergroup.'
end

function ban:on_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        local output = language['errors']['supergroup']
        return mattata.send_reply(message, output)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        local output = language['errors']['admin']
        return mattata.send_reply(message, output)
    end
    local reason = false
    local user = false
    local input = mattata.input(message)
    -- check the message object for any users this command
    -- is intended to be executed on
    if message.reply then
        user = message.reply.from.id
        if input then
            reason = input
        end
    elseif input and input:match(' ') then
        user, reason = input:match('^(.-) (.-)$')
    elseif input then
        user = input
    end
    if not user then
        local output = language['ban']['1']
        local success = mattata.send_force_reply(message, output)
        if success then
            mattata.set_command_action(message.chat.id, success.result.message_id, '/ban')
        end
        return
    end
    if reason and type(reason) == 'string' and reason:match('^[Ff][Oo][Rr] ') then
        reason = reason:match('^[Ff][Oo][Rr] (.-)$')
    end
    if tonumber(user) == nil and not user:match('^%@') then
        user = '@' .. user
    end
    local user_object = mattata.get_user(user) or mattata.get_chat(user) -- resolve the username/ID to a user object
    if not user_object then
        return mattata.send_reply(message, language.errors.unknown)
    elseif user_object.result.id == self.info.id then
        return false -- don't let the bot ban itself
    end
    user_object = user_object.result
    local status = mattata.get_chat_member(message.chat.id, user_object.id)
    local is_admin = mattata.is_group_admin(message.chat.id, user_object.id)
    if not status then
        local output = language['errors']['generic']
        return mattata.send_reply(message, output)
    elseif is_admin then -- we won't try and ban moderators and administrators.
        local output = language['ban']['2']
        return mattata.send_reply(message, output)
    elseif status.result.status == 'kicked' then -- check if the user has already been kicked
        local output = language['ban']['4']
        return mattata.send_reply(message, output)
    end
    local success = mattata.ban_chat_member(message.chat.id, user_object.id) -- attempt to ban the user from the group
    if not success then -- since we've ruled everything else out, it's safe to say if it wasn't a success then the bot just isn't an administrator in the group
        local output = language['ban']['5']
        return mattata.send_reply(message, output)
    end
    mattata.increase_administrative_action(message.chat.id, user_object.id, 'bans')
    reason = reason and ', for ' .. reason or ''
    local admin_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
    local banned_username = mattata.get_formatted_user(user_object.id, user_object.first_name, 'html')
    local output
    if mattata.get_setting(message.chat.id, 'log administrative actions') then
        local log_chat = mattata.get_log_chat(message.chat.id)
        output = string.format(language['ban']['6'], admin_username, message.from.id, banned_username, user_object.id, mattata.escape_html(message.chat.title), message.chat.id, reason, '#chat' .. tostring(message.chat.id):gsub('^-100', ''), '#user' .. user_object.id)
        mattata.send_message(log_chat, output, 'html')
    else
        output = string.format(language['ban']['7'], admin_username, banned_username, reason)
        mattata.send_message(message.chat.id, output, 'html')
    end
    if message.reply and mattata.get_setting(message.chat.id, 'delete reply on action') then
        mattata.delete_message(message.chat.id, message.reply.message_id)
    end
    return mattata.delete_message(message.chat.id, message.message_id)
end

return ban