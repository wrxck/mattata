--[[
    mattata v2.0 - Slowmode Plugin
]]

local plugin = {}
plugin.name = 'slowmode'
plugin.category = 'admin'
plugin.description = 'Set the group slow mode delay'
plugin.commands = { 'slowmode' }
plugin.help = '/slowmode <off|10s|30s|1m|5m|15m|1h> - Set slow mode delay for the group.'
plugin.group_only = true
plugin.admin_only = true

local VALID_DELAYS = {
    ['0'] = 0,
    ['off'] = 0,
    ['10'] = 10,
    ['10s'] = 10,
    ['30'] = 30,
    ['30s'] = 30,
    ['60'] = 60,
    ['1m'] = 60,
    ['300'] = 300,
    ['5m'] = 300,
    ['900'] = 900,
    ['15m'] = 900,
    ['3600'] = 3600,
    ['1h'] = 3600
}

local HUMAN_LABELS = {
    [0] = 'disabled',
    [10] = '10 seconds',
    [30] = '30 seconds',
    [60] = '1 minute',
    [300] = '5 minutes',
    [900] = '15 minutes',
    [3600] = '1 hour'
}

function plugin.on_message(api, message, ctx)
    if not message.args then
        return api.send_message(message.chat.id,
            '<b>Slow mode</b>\n\n'
            .. 'Usage: <code>/slowmode &lt;delay&gt;</code>\n\n'
            .. 'Valid values:\n'
            .. '<code>off</code> - Disable slow mode\n'
            .. '<code>10s</code> - 10 seconds\n'
            .. '<code>30s</code> - 30 seconds\n'
            .. '<code>1m</code> - 1 minute\n'
            .. '<code>5m</code> - 5 minutes\n'
            .. '<code>15m</code> - 15 minutes\n'
            .. '<code>1h</code> - 1 hour',
            { parse_mode = 'html' }
        )
    end

    local arg = message.args:lower():gsub('%s+', '')
    local delay = VALID_DELAYS[arg]
    if not delay then
        return api.send_message(message.chat.id,
            'Invalid delay. Valid values: off, 10s, 30s, 1m, 5m, 15m, 1h'
        )
    end

    local config = require('telegram-bot-lua.config')
    local result = api.request(config.endpoint .. api.token .. '/setChatSlowModeDelay', {
        chat_id = message.chat.id,
        slow_mode_delay = delay
    })
    if not result or not result.result then
        return api.send_message(message.chat.id,
            'I couldn\'t set slow mode. Make sure I have the right permissions.'
        )
    end

    pcall(function()
        ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, nil, 'slowmode', 'Set to ' .. delay .. 's'))
    end)

    if delay == 0 then
        return api.send_message(message.chat.id, 'Slow mode disabled.')
    end

    return api.send_message(message.chat.id,
        string.format('Slow mode set to %s.', HUMAN_LABELS[delay] or (delay .. ' seconds'))
    )
end

return plugin
