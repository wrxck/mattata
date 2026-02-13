--[[
    mattata v2.0 - Warn Plugin
    Warning system with configurable max warnings and auto-ban.
]]

local plugin = {}
plugin.name = 'warn'
plugin.category = 'admin'
plugin.description = 'Warn users with auto-ban threshold'
plugin.commands = { 'warn' }
plugin.help = '/warn [user] [reason] - Warns a user. After reaching max warnings, user is banned.'
plugin.group_only = true
plugin.admin_only = true

local DEFAULT_MAX_WARNINGS = 3

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Ban Users" admin permission to use this command.')
    end

    local user_id, reason
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
        reason = message.args
    elseif message.args then
        local input = message.args
        if input:match('^(%S+)%s+(.+)$') then
            user_id, reason = input:match('^(%S+)%s+(.+)$')
        else
            user_id = input
        end
    end
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to warn.')
    end
    if tonumber(user_id) == nil then
        local name = user_id:match('^@?(.+)$')
        user_id = ctx.redis.get('username:' .. name:lower())
    end
    user_id = tonumber(user_id)
    if not user_id or user_id == api.info.id then return end
    if permissions.is_group_admin(api, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'I can\'t warn an admin or moderator.')
    end

    -- increment warning count
    local hash = string.format('chat:%s:%s', message.chat.id, user_id)
    local amount = ctx.redis.hincrby(hash, 'warnings', 1)
    local max_warnings = tonumber(ctx.session.get_setting(message.chat.id, 'max warnings')) or DEFAULT_MAX_WARNINGS

    -- auto-ban if threshold reached
    if tonumber(amount) >= max_warnings then
        api.ban_chat_member(message.chat.id, user_id)
    end

    -- log to database
    pcall(function()
        ctx.db.call('sp_insert_warning', table.pack(message.chat.id, user_id, message.from.id, reason))
        ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, user_id, 'warn', reason))
    end)

    if reason and reason:lower():match('^for ') then reason = reason:sub(5) end
    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    local reason_text = reason and (', for ' .. tools.escape_html(reason)) or ''

    local output
    if tonumber(amount) >= max_warnings then
        output = string.format(
            '<a href="tg://user?id=%d">%s</a> has warned <a href="tg://user?id=%d">%s</a>%s.\n<b>%d/%d warnings reached - user has been banned.</b>',
            message.from.id, admin_name, user_id, target_name, reason_text, amount, max_warnings
        )
    else
        output = string.format(
            '<a href="tg://user?id=%d">%s</a> has warned <a href="tg://user?id=%d">%s</a>%s. [%d/%d]',
            message.from.id, admin_name, user_id, target_name, reason_text, amount, max_warnings
        )
    end

    local keyboard = api.inline_keyboard():row(
        api.row():callback_data_button(
            'Reset Warnings', string.format('warn:reset:%s:%s', message.chat.id, user_id)
        ):callback_data_button(
            'Remove 1', string.format('warn:remove:%s:%s', message.chat.id, user_id)
        )
    )
    api.send_message(message.chat.id, output, { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard })
    if message.reply then
        pcall(function() api.delete_message(message.chat.id, message.reply.message_id) end)
    end
    pcall(function() api.delete_message(message.chat.id, message.message_id) end)
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if callback_query.data:match('^reset:%-?%d+:%d+$') then
        local chat_id, user_id = callback_query.data:match('^reset:(%-?%d+):(%d+)$')
        if not permissions.is_group_admin(api, tonumber(chat_id), callback_query.from.id) then
            return api.answer_callback_query(callback_query.id, { text = 'You need to be an admin.' })
        end
        ctx.redis.hdel(string.format('chat:%s:%s', chat_id, user_id), 'warnings')
        local name = callback_query.from.username and ('@' .. callback_query.from.username) or tools.escape_html(callback_query.from.first_name)
        return api.edit_message_text(message.chat.id, message.message_id,
            '<pre>Warnings reset by ' .. name .. '!</pre>', { parse_mode = 'html' })

    elseif callback_query.data:match('^remove:%-?%d+:%d+$') then
        local chat_id, user_id = callback_query.data:match('^remove:(%-?%d+):(%d+)$')
        if not permissions.is_group_admin(api, tonumber(chat_id), callback_query.from.id) then
            return api.answer_callback_query(callback_query.id, { text = 'You need to be an admin.' })
        end
        local hash = string.format('chat:%s:%s', chat_id, user_id)
        local amount = ctx.redis.hincrby(hash, 'warnings', -1)
        if tonumber(amount) < 0 then
            ctx.redis.hincrby(hash, 'warnings', 1)
            return api.answer_callback_query(callback_query.id, { text = 'No warnings to remove!' })
        end
        local max_warnings = tonumber(ctx.session.get_setting(tonumber(chat_id), 'max warnings')) or DEFAULT_MAX_WARNINGS
        local name = callback_query.from.username and ('@' .. callback_query.from.username) or tools.escape_html(callback_query.from.first_name)
        return api.edit_message_text(message.chat.id, message.message_id,
            string.format('<pre>Warning removed by %s! [%s/%s]</pre>', name, amount, max_warnings), { parse_mode = 'html' })
    end
end

return plugin
