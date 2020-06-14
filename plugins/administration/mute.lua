--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local mute = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function mute:init()
    mute.commands = mattata.commands(self.info.username):command('mute').table
    mute.help = '/mute [user] - Mutes a user in the current chat. This command can only be used by group admins.'
end

function mute:on_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        local output = language['errors']['supergroup']
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
        local output = 'You need to specify the user you\'d like to mute, either by username/ID or in reply.'
        local success = mattata.send_force_reply(message, output)
        if success then
            mattata.set_command_action(message.chat.id, success.result.message_id, '/mute')
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
        local output = language['errors']['unknown']
        return mattata.send_reply(message, output)
    elseif user_object.result.id == self.info.id then
        return false -- don't let the bot mute itself
    end
    local bot_status = mattata.get_chat_member(message.chat.id, self.info.id)
    if not bot_status then
        return false
    elseif not bot_status.result.can_restrict_members then
        return mattata.send_reply(message, 'It appears I don\'t have the required permissions required in order to mute that user. Please amend this and try again!')
    end
    user_object = user_object.result
    local status = mattata.get_chat_member(message.chat.id, user_object.id)
    local is_admin = mattata.is_group_admin(message.chat.id, user_object.id)
    if not status then
        return mattata.send_reply(message, 'I couldn\'t retrieve any information about that user!')
    elseif is_admin then -- we won't try and mute moderators and administrators.
        return mattata.send_reply(message, 'I can\'t mute that user because they\'re an admin in this chat!')
    end
    local success = mattata.restrict_chat_member(message.chat.id, user_object.id, os.time(), false, false, false, false, false, false, false, false) -- attempt to mute the user in the group
    if not success then
        return mattata.send_reply(message, 'I couldn\'t mute that user in this group, because it appears I don\'t have permission to!')
    end
    reason = reason and ', for ' .. reason or ''
    local admin_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
    local muted_username = mattata.get_formatted_user(user_object.id, user_object.first_name, 'html')
    redis:hincrby('chat:' .. message.chat.id .. ':' .. user_object.id, 'mutes', 1)
    if mattata.get_setting(message.chat.id, 'log administrative actions') then
        local log_chat = mattata.get_log_chat(message.chat.id)
        local output = '%s <code>[%s]</code> has muted %s <code>[%s]</code> in %s <code>[%s]</code>%s.\n%s %s'
        output = string.format(output, admin_username, message.from.id, muted_username, user_object.id, mattata.escape_html(message.chat.title), message.chat.id, reason, '#chat' .. tostring(message.chat.id):gsub('^-100', ''), '#user' .. user_object.id)
        mattata.send_message(log_chat, output, 'html')
    end
    if message.reply and mattata.get_setting(message.chat.id, 'delete reply on action') then
        mattata.delete_message(message.chat.id, message.reply.message_id)
    end
    local output = '%s has muted %s%s.'
    output = string.format(output, admin_username, muted_username, reason)
    return mattata.send_message(message.chat.id, output, 'html')
end

return mute