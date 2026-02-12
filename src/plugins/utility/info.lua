--[[
    mattata v2.0 - Info Plugin
    System information (admin only).
]]

local plugin = {}
plugin.name = 'info'
plugin.category = 'utility'
plugin.description = 'View system information'
plugin.commands = { 'info' }
plugin.help = '/info - View system and bot statistics.'
plugin.global_admin_only = true

function plugin.on_message(api, message, ctx)
    local loader = require('src.core.loader')
    local lines = {
        '<b>mattata v' .. ctx.config.VERSION .. '</b>',
        '',
        'Plugins loaded: <code>' .. loader.count() .. '</code>',
        'Lua version: <code>' .. _VERSION .. '</code>',
        'Uptime: <code>' .. os.date('!%H:%M:%S', os.clock()) .. '</code>'
    }

    -- Database stats
    local user_count = ctx.db.call('sp_count_users', {})
    local chat_count = ctx.db.call('sp_count_chats', {})
    if user_count and user_count[1] then
        table.insert(lines, 'Users tracked: <code>' .. user_count[1].count .. '</code>')
    end
    if chat_count and chat_count[1] then
        table.insert(lines, 'Groups tracked: <code>' .. chat_count[1].count .. '</code>')
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
