--[[
    mattata v2.0 - No Delete Plugin
]]

local plugin = {}
plugin.name = 'nodelete'
plugin.category = 'admin'
plugin.description = 'Toggle whether a plugin\'s commands are auto-deleted'
plugin.commands = { 'nodelete' }
plugin.help = '/nodelete <plugin> - Toggle whether a plugin\'s command messages are auto-deleted.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        -- List current no-delete plugins
        local no_delete = ctx.redis.smembers('chat:' .. message.chat.id .. ':no_delete')
        if not no_delete or #no_delete == 0 then
            return api.send_message(message.chat.id, 'No plugins are exempt from auto-deletion.\nUsage: /nodelete <plugin_name>')
        end
        local output = '<b>Plugins exempt from auto-deletion:</b>\n\n'
        for _, name in ipairs(no_delete) do
            output = output .. '- <code>' .. tools.escape_html(name) .. '</code>\n'
        end
        return api.send_message(message.chat.id, output, 'html')
    end

    local plugin_name = message.args:lower():match('^(%S+)$')
    if not plugin_name then
        return api.send_message(message.chat.id, 'Usage: /nodelete <plugin_name>')
    end

    local key = 'chat:' .. message.chat.id .. ':no_delete'
    local is_set = ctx.redis.sismember(key, plugin_name)
    if is_set and is_set ~= false and is_set ~= 0 then
        ctx.redis.srem(key, plugin_name)
        api.send_message(message.chat.id, string.format(
            'Commands from <code>%s</code> will now be auto-deleted.',
            tools.escape_html(plugin_name)
        ), 'html')
    else
        ctx.redis.sadd(key, plugin_name)
        api.send_message(message.chat.id, string.format(
            'Commands from <code>%s</code> will no longer be auto-deleted.',
            tools.escape_html(plugin_name)
        ), 'html')
    end
end

return plugin
