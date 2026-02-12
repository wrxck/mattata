--[[
    mattata v2.0 - Set Captcha Plugin
]]

local plugin = {}
plugin.name = 'setcaptcha'
plugin.category = 'admin'
plugin.description = 'Configure captcha settings for new members'
plugin.commands = { 'setcaptcha' }
plugin.help = '/setcaptcha <on|off|timeout <seconds>> - Configure captcha settings.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.args then
        -- Show current captcha status
        local enabled = ctx.db.execute(
            "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'captcha_enabled'",
            { message.chat.id }
        )
        local timeout = ctx.db.execute(
            "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'captcha_timeout'",
            { message.chat.id }
        )
        local status = (enabled and #enabled > 0 and enabled[1].value == 'true') and 'enabled' or 'disabled'
        local timeout_val = (timeout and #timeout > 0) and timeout[1].value or '300'
        return api.send_message(message.chat.id, string.format(
            '<b>Captcha settings:</b>\nStatus: %s\nTimeout: %s seconds\n\n'
            .. 'Usage:\n<code>/setcaptcha on</code> - Enable captcha\n'
            .. '<code>/setcaptcha off</code> - Disable captcha\n'
            .. '<code>/setcaptcha timeout &lt;seconds&gt;</code> - Set timeout',
            status, timeout_val
        ), 'html')
    end

    local args = message.args:lower()
    if args == 'on' or args == 'enable' then
        ctx.db.upsert('chat_settings', {
            chat_id = message.chat.id,
            key = 'captcha_enabled',
            value = 'true'
        }, { 'chat_id', 'key' }, { 'value' })
        return api.send_message(message.chat.id, 'Captcha has been enabled for this group.')
    elseif args == 'off' or args == 'disable' then
        ctx.db.upsert('chat_settings', {
            chat_id = message.chat.id,
            key = 'captcha_enabled',
            value = 'false'
        }, { 'chat_id', 'key' }, { 'value' })
        return api.send_message(message.chat.id, 'Captcha has been disabled for this group.')
    elseif args:match('^timeout%s+(%d+)$') then
        local seconds = args:match('^timeout%s+(%d+)$')
        seconds = tonumber(seconds)
        if seconds < 30 or seconds > 3600 then
            return api.send_message(message.chat.id, 'Timeout must be between 30 and 3600 seconds.')
        end
        ctx.db.upsert('chat_settings', {
            chat_id = message.chat.id,
            key = 'captcha_timeout',
            value = tostring(seconds)
        }, { 'chat_id', 'key' }, { 'value' })
        return api.send_message(message.chat.id, string.format('Captcha timeout set to %d seconds.', seconds))
    else
        return api.send_message(message.chat.id, 'Usage: /setcaptcha <on|off|timeout <seconds>>')
    end
end

return plugin
