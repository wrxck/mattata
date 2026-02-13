--[[
    mattata v2.0 - Auto-Delete Plugin
    Configures automatic deletion of bot responses after a delay.
    The actual deletion logic is handled by a separate middleware/handler.
]]

local plugin = {}
plugin.name = 'autodelete'
plugin.category = 'admin'
plugin.description = 'Auto-delete bot command messages after a configurable delay'
plugin.commands = { 'autodelete' }
plugin.help = '/autodelete <off|10|30|60|300> - Set the delay before bot responses are auto-deleted.'
plugin.group_only = true
plugin.admin_only = true

local session = require('src.core.session')

local VALID_DELAYS = {
    ['10'] = true,
    ['30'] = true,
    ['60'] = true,
    ['300'] = true
}

local HUMAN_LABELS = {
    ['10'] = '10 seconds',
    ['30'] = '30 seconds',
    ['60'] = '1 minute',
    ['300'] = '5 minutes'
}

function plugin.on_message(api, message, ctx)
    if not message.args then
        local current = session.get_setting(message.chat.id, 'autodelete_delay')
        local status
        if current then
            status = string.format('Auto-delete is set to <b>%s</b>.', HUMAN_LABELS[current] or (current .. ' seconds'))
        else
            status = 'Auto-delete is currently <b>disabled</b>.'
        end
        return api.send_message(message.chat.id,
            status .. '\n\n'
            .. 'Usage: <code>/autodelete &lt;delay&gt;</code>\n\n'
            .. 'Valid values:\n'
            .. '<code>off</code> - Disable auto-delete\n'
            .. '<code>10</code> - 10 seconds\n'
            .. '<code>30</code> - 30 seconds\n'
            .. '<code>60</code> - 1 minute\n'
            .. '<code>300</code> - 5 minutes',
            { parse_mode = 'html' }
        )
    end

    local arg = message.args:lower():gsub('%s+', '')

    if arg == 'off' or arg == 'disable' then
        session.invalidate_setting(message.chat.id, 'autodelete_delay')
        return api.send_message(message.chat.id, 'Auto-delete has been disabled.')
    end

    if not VALID_DELAYS[arg] then
        return api.send_message(message.chat.id,
            'Invalid delay. Valid values: off, 10, 30, 60, 300'
        )
    end

    -- Use redis.set directly for persistent storage (session.set_setting uses setex which requires TTL > 0)
    ctx.redis.set(string.format('cache:setting:%s:autodelete_delay', tostring(message.chat.id)), arg)
    return api.send_message(message.chat.id,
        string.format('Bot responses will now be auto-deleted after %s.', HUMAN_LABELS[arg] or (arg .. ' seconds'))
    )
end

return plugin
