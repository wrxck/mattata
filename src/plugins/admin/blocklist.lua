--[[
    mattata v2.0 - Blocklist Plugin
]]

local plugin = {}
plugin.name = 'blocklist'
plugin.category = 'admin'
plugin.description = 'Manage the group blocklist'
plugin.commands = { 'blocklist', 'block', 'unblock' }
plugin.help = '/blocklist - List blocked users. /block <user> [reason] - Block a user. /unblock <user> - Unblock a user.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    -- /blocklist with no args: list blocked users
    if message.command == 'blocklist' and not message.args then
        local result = ctx.db.execute(
            'SELECT user_id, reason, created_at FROM group_blocklist WHERE chat_id = $1 ORDER BY created_at DESC',
            { message.chat.id }
        )
        if not result or #result == 0 then
            return api.send_message(message.chat.id, 'No users are blocklisted in this group.')
        end
        local output = '<b>Blocklisted users:</b>\n\n'
        for _, row in ipairs(result) do
            local info = api.get_chat(row.user_id)
            local name = info and info.result and tools.escape_html(info.result.first_name) or tostring(row.user_id)
            local reason_text = row.reason and (' - ' .. tools.escape_html(row.reason)) or ''
            output = output .. string.format('- <a href="tg://user?id=%s">%s</a> [%s]%s\n', row.user_id, name, row.user_id, reason_text)
        end
        return api.send_message(message.chat.id, output, 'html')
    end

    -- /block or /blocklist add
    if message.command == 'block' or (message.command == 'blocklist' and message.args and message.args:match('^add')) then
        local user_id, reason
        if message.reply and message.reply.from then
            user_id = message.reply.from.id
            reason = message.args
        elseif message.args then
            local input = message.command == 'blocklist' and message.args:gsub('^add%s*', '') or message.args
            if input:match('^(%S+)%s+(.+)$') then
                user_id, reason = input:match('^(%S+)%s+(.+)$')
            else
                user_id = input:match('^(%S+)')
            end
        end
        if not user_id then
            return api.send_message(message.chat.id, 'Please specify the user to block.')
        end
        if tonumber(user_id) == nil then
            user_id = user_id:match('^@?(.+)$')
            user_id = ctx.redis.get('username:' .. user_id:lower())
        end
        user_id = tonumber(user_id)
        if not user_id then
            return api.send_message(message.chat.id, 'I couldn\'t find that user.')
        end
        if user_id == api.info.id then return end
        if permissions.is_group_admin(api, message.chat.id, user_id) then
            return api.send_message(message.chat.id, 'You can\'t blocklist an admin.')
        end

        ctx.db.upsert('group_blocklist', {
            chat_id = message.chat.id,
            user_id = user_id,
            reason = reason
        }, { 'chat_id', 'user_id' }, { 'reason' })

        -- Also set Redis key for fast lookup
        ctx.redis.set('group_blocklist:' .. message.chat.id .. ':' .. user_id, '1')

        local target_info = api.get_chat(user_id)
        local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
        return api.send_message(message.chat.id, string.format(
            '<a href="tg://user?id=%d">%s</a> has been added to the blocklist.',
            user_id, target_name
        ), 'html')
    end

    -- /unblock or /blocklist remove
    if message.command == 'unblock' or (message.command == 'blocklist' and message.args and message.args:match('^remove')) then
        local user_id
        if message.reply and message.reply.from then
            user_id = message.reply.from.id
        elseif message.args then
            local input = message.command == 'blocklist' and message.args:gsub('^remove%s*', '') or message.args
            user_id = input:match('^@?(%S+)')
            if tonumber(user_id) == nil then
                user_id = ctx.redis.get('username:' .. user_id:lower())
            end
        end
        user_id = tonumber(user_id)
        if not user_id then
            return api.send_message(message.chat.id, 'Please specify the user to unblock.')
        end

        ctx.db.execute(
            'DELETE FROM group_blocklist WHERE chat_id = $1 AND user_id = $2',
            { message.chat.id, user_id }
        )
        ctx.redis.del('group_blocklist:' .. message.chat.id .. ':' .. user_id)

        local target_info = api.get_chat(user_id)
        local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
        return api.send_message(message.chat.id, string.format(
            '<a href="tg://user?id=%d">%s</a> has been removed from the blocklist.',
            user_id, target_name
        ), 'html')
    end

    api.send_message(message.chat.id, 'Usage: /block <user> [reason] | /unblock <user> | /blocklist')
end

return plugin
