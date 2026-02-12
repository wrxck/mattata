--[[
    mattata v2.0 - Anti-Link Plugin
]]

local plugin = {}
plugin.name = 'antilink'
plugin.category = 'admin'
plugin.description = 'Toggle anti-link mode to delete Telegram invite links from non-admins'
plugin.commands = { 'antilink' }
plugin.help = '/antilink <on|off> - Toggle anti-link mode.'
plugin.group_only = true
plugin.admin_only = true

local INVITE_PATTERNS = {
    '[Tt]%.?[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_%-]+',
    '[Tt]%.?[Mm][Ee]/[%+][%w_%-]+',
    '[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.?[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_%-]+',
    '[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.?[Dd][Oo][Gg]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_%-]+',
    '[Tt][Gg]://[Jj][Oo][Ii][Nn]%?[Ii][Nn][Vv][Ii][Tt][Ee]=[%w_%-]+'
}

function plugin.on_message(api, message, ctx)
    if not message.args then
        local enabled = ctx.db.call('sp_get_chat_setting', { message.chat.id, 'antilink_enabled' })
        local status = (enabled and #enabled > 0 and enabled[1].value == 'true') and 'enabled' or 'disabled'
        return api.send_message(message.chat.id, string.format(
            'Anti-link is currently <b>%s</b>.\nUsage: /antilink <on|off>', status
        ), 'html')
    end

    local arg = message.args:lower()
    if arg == 'on' or arg == 'enable' then
        ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'antilink_enabled', 'true' })
        require('src.core.session').invalidate_setting(message.chat.id, 'antilink_enabled')
        return api.send_message(message.chat.id, 'Anti-link has been enabled. Telegram invite links from non-admins will be deleted.')
    elseif arg == 'off' or arg == 'disable' then
        ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'antilink_enabled', 'false' })
        require('src.core.session').invalidate_setting(message.chat.id, 'antilink_enabled')
        return api.send_message(message.chat.id, 'Anti-link has been disabled.')
    else
        return api.send_message(message.chat.id, 'Usage: /antilink <on|off>')
    end
end

function plugin.on_new_message(api, message, ctx)
    if not ctx.is_group or not message.text or message.text == '' then return end
    if ctx.is_admin or ctx.is_global_admin then return end
    if not require('src.core.permissions').can_delete(api, message.chat.id) then return end

    -- check if antilink is enabled (cached)
    local session = require('src.core.session')
    local enabled = session.get_cached_setting(message.chat.id, 'antilink_enabled', function()
        local result = ctx.db.call('sp_get_chat_setting', { message.chat.id, 'antilink_enabled' })
        if result and #result > 0 then return result[1].value end
        return nil
    end, 300)
    if enabled ~= 'true' then
        return
    end

    -- check if user is trusted
    local permissions = require('src.core.permissions')
    if permissions.is_trusted(ctx.db, message.chat.id, message.from.id) then
        return
    end

    -- build full text including entity urls
    local text = message.text
    if message.entities then
        for _, entity in ipairs(message.entities) do
            if entity.type == 'text_link' and entity.url then
                text = text .. ' ' .. entity.url
            end
        end
    end

    -- check for allowed links
    for _, pattern in ipairs(INVITE_PATTERNS) do
        if text:match(pattern) then
            -- check if link is allowed
            local link = text:match(pattern)
            local allowed = ctx.db.call('sp_check_allowed_link', { message.chat.id, link })
            if not allowed or #allowed == 0 then
                api.delete_message(message.chat.id, message.message_id)
                local tools = require('telegram-bot-lua.tools')
                api.send_message(message.chat.id, string.format(
                    '<a href="tg://user?id=%d">%s</a>, invite links are not allowed in this group.',
                    message.from.id, tools.escape_html(message.from.first_name)
                ), 'html')
                return
            end
        end
    end
end

return plugin
