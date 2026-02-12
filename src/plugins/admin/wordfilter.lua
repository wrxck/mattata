--[[
    mattata v2.0 - Word Filter Plugin
]]

local plugin = {}
plugin.name = 'wordfilter'
plugin.category = 'admin'
plugin.description = 'Toggle word filter and process filtered messages'
plugin.commands = { 'wordfilter' }
plugin.help = '/wordfilter <on|off> - Toggle word filtering. Filtered words are managed with /filter and /unfilter.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.args then
        local enabled = ctx.db.execute(
            "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'wordfilter_enabled'",
            { message.chat.id }
        )
        local status = (enabled and #enabled > 0 and enabled[1].value == 'true') and 'enabled' or 'disabled'
        return api.send_message(message.chat.id, string.format(
            'Word filter is currently <b>%s</b>.\nUsage: /wordfilter <on|off>', status
        ), 'html')
    end

    local arg = message.args:lower()
    if arg == 'on' or arg == 'enable' then
        ctx.db.upsert('chat_settings', {
            chat_id = message.chat.id,
            key = 'wordfilter_enabled',
            value = 'true'
        }, { 'chat_id', 'key' }, { 'value' })
        require('src.core.session').invalidate_setting(message.chat.id, 'wordfilter_enabled')
        return api.send_message(message.chat.id, 'Word filter has been enabled.')
    elseif arg == 'off' or arg == 'disable' then
        ctx.db.upsert('chat_settings', {
            chat_id = message.chat.id,
            key = 'wordfilter_enabled',
            value = 'false'
        }, { 'chat_id', 'key' }, { 'value' })
        require('src.core.session').invalidate_setting(message.chat.id, 'wordfilter_enabled')
        return api.send_message(message.chat.id, 'Word filter has been disabled.')
    else
        return api.send_message(message.chat.id, 'Usage: /wordfilter <on|off>')
    end
end

function plugin.on_new_message(api, message, ctx)
    if not ctx.is_group or not message.text or message.text == '' then return end
    if ctx.is_admin or ctx.is_global_admin then return end
    if not require('src.core.permissions').can_delete(api, message.chat.id) then return end

    -- Check if wordfilter is enabled (cached)
    local session = require('src.core.session')
    local enabled = session.get_cached_setting(message.chat.id, 'wordfilter_enabled', function()
        local result = ctx.db.execute(
            "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'wordfilter_enabled'",
            { message.chat.id }
        )
        if result and #result > 0 then return result[1].value end
        return nil
    end, 300)
    if enabled ~= 'true' then
        return
    end

    -- Get filters for this chat (cached)
    local filters = session.get_cached_list(message.chat.id, 'filters', function()
        return ctx.db.execute(
            'SELECT pattern, action FROM filters WHERE chat_id = $1',
            { message.chat.id }
        )
    end, 300)
    if not filters or #filters == 0 then return end

    local text = message.text:lower()
    for _, f in ipairs(filters) do
        local match = pcall(function()
            return text:match(f.pattern:lower())
        end)
        if match and text:match(f.pattern:lower()) then
            -- Execute action
            if f.action == 'delete' then
                api.delete_message(message.chat.id, message.message_id)
            elseif f.action == 'warn' then
                api.delete_message(message.chat.id, message.message_id)
                local hash = string.format('chat:%s:%s', message.chat.id, message.from.id)
                ctx.redis.hincrby(hash, 'warnings', 1)
                api.send_message(message.chat.id, string.format(
                    '<a href="tg://user?id=%d">%s</a> has been warned for using a filtered word.',
                    message.from.id, require('telegram-bot-lua.tools').escape_html(message.from.first_name)
                ), 'html')
            elseif f.action == 'ban' then
                api.delete_message(message.chat.id, message.message_id)
                api.ban_chat_member(message.chat.id, message.from.id)
            elseif f.action == 'kick' then
                api.delete_message(message.chat.id, message.message_id)
                api.ban_chat_member(message.chat.id, message.from.id)
                api.unban_chat_member(message.chat.id, message.from.id)
            elseif f.action == 'mute' then
                api.delete_message(message.chat.id, message.message_id)
                api.restrict_chat_member(message.chat.id, message.from.id, os.time() + 3600, {
                    can_send_messages = false
                })
            end
            return
        end
    end
end

return plugin
