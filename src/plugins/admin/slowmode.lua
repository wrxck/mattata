--[[
    mattata v2.1 - Slow Mode Plugin
    Control slow mode delay in groups.
]]

local plugin = {}
plugin.name = 'slowmode'
plugin.category = 'admin'
plugin.description = 'Set slow mode delay'
plugin.commands = { 'slowmode', 'slow' }
plugin.help = '/slowmode <off|10s|30s|1m|5m|15m|1h> - Set slow mode delay for the chat.'
plugin.group_only = true
plugin.admin_only = true

local DELAYS = {
    ['off'] = 0, ['0'] = 0, ['disable'] = 0,
    ['10s'] = 10, ['10'] = 10,
    ['30s'] = 30, ['30'] = 30,
    ['1m'] = 60, ['60'] = 60, ['60s'] = 60,
    ['5m'] = 300, ['300'] = 300, ['300s'] = 300,
    ['15m'] = 900, ['900'] = 900, ['900s'] = 900,
    ['1h'] = 3600, ['3600'] = 3600, ['3600s'] = 3600,
}

local function format_delay(seconds)
    if seconds == 0 then return 'disabled' end
    if seconds < 60 then return seconds .. ' seconds' end
    if seconds < 3600 then return (seconds / 60) .. ' minutes' end
    return (seconds / 3600) .. ' hour'
end

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Usage: /slowmode <off|10s|30s|1m|5m|15m|1h>')
    end

    local delay = DELAYS[message.args:lower()]
    if not delay then
        return api.send_message(message.chat.id, 'Invalid delay. Options: off, 10s, 30s, 1m, 5m, 15m, 1h')
    end

    local result = api.set_chat_slow_mode_delay(message.chat.id, delay)
    if result then
        local label = format_delay(delay)
        return api.send_message(message.chat.id, string.format('Slow mode set to <b>%s</b>.', label), 'html')
    end
    return api.send_message(message.chat.id, 'Failed to set slow mode. Make sure I have the correct permissions.')
end

return plugin
