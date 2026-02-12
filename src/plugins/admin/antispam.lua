--[[
    mattata v2.0 - Antispam Plugin
]]

local plugin = {}
plugin.name = 'antispam'
plugin.category = 'admin'
plugin.description = 'Configure antispam settings'
plugin.commands = { 'antispam' }
plugin.help = '/antispam [text|sticker|photo|video|document|forward] <limit> - Set per-type message limits.'
plugin.group_only = true
plugin.admin_only = true

local VALID_TYPES = {
    text = true,
    sticker = true,
    photo = true,
    video = true,
    document = true,
    forward = true,
    audio = true,
    voice = true,
    gif = true
}

function plugin.on_message(api, message, ctx)
    if not message.args then
        -- Show current antispam settings
        local settings = ctx.db.execute(
            "SELECT key, value FROM chat_settings WHERE chat_id = $1 AND key LIKE 'antispam_%'",
            { message.chat.id }
        )
        local output = '<b>Antispam settings:</b>\n\n'
        if settings and #settings > 0 then
            for _, row in ipairs(settings) do
                local msg_type = row.key:gsub('antispam_', '')
                output = output .. string.format('- %s: %s message(s) per 5 seconds\n', msg_type, row.value)
            end
        else
            output = output .. 'No custom limits set. Default limits apply.\n'
        end
        output = output .. '\nUsage: <code>/antispam &lt;type&gt; &lt;limit&gt;</code>\nTypes: text, sticker, photo, video, document, forward, audio, voice, gif\n'
        output = output .. '<code>/antispam &lt;type&gt; off</code> - Remove limit'
        return api.send_message(message.chat.id, output, 'html')
    end

    local msg_type, limit = message.args:lower():match('^(%S+)%s+(.+)$')
    if not msg_type then
        return api.send_message(message.chat.id, 'Usage: /antispam <type> <limit|off>')
    end
    if not VALID_TYPES[msg_type] then
        return api.send_message(message.chat.id, 'Invalid type. Valid types: text, sticker, photo, video, document, forward, audio, voice, gif')
    end

    local setting_key = 'antispam_' .. msg_type
    if limit == 'off' or limit == 'disable' or limit == '0' then
        ctx.db.execute(
            "DELETE FROM chat_settings WHERE chat_id = $1 AND key = $2",
            { message.chat.id, setting_key }
        )
        return api.send_message(message.chat.id, string.format('Antispam limit for <b>%s</b> has been removed.', msg_type), 'html')
    end

    limit = tonumber(limit)
    if not limit or limit < 1 or limit > 100 then
        return api.send_message(message.chat.id, 'Limit must be a number between 1 and 100.')
    end

    ctx.db.upsert('chat_settings', {
        chat_id = message.chat.id,
        key = setting_key,
        value = tostring(limit)
    }, { 'chat_id', 'key' }, { 'value' })

    api.send_message(message.chat.id, string.format(
        'Antispam limit for <b>%s</b> set to <b>%d</b> message(s) per 5 seconds.',
        msg_type, limit
    ), 'html')
end

return plugin
