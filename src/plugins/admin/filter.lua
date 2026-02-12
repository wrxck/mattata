--[[
    mattata v2.0 - Filter Plugin
]]

local plugin = {}
plugin.name = 'filter'
plugin.category = 'admin'
plugin.description = 'Add content filters to the group'
plugin.commands = { 'filter', 'addfilter' }
plugin.help = '/filter <pattern> [action] - Adds a filter. Actions: delete (default), warn, ban, kick.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        return api.send_message(message.chat.id, 'Usage: /filter <pattern> [action]\nActions: delete (default), warn, ban, kick, mute', 'html')
    end

    local pattern, action
    if message.args:match('^(.+)%s+(delete|warn|ban|kick|mute)$') then
        pattern, action = message.args:match('^(.+)%s+(delete|warn|ban|kick|mute)$')
    else
        pattern = message.args
        action = 'delete'
    end

    pattern = pattern:match('^%s*(.-)%s*$') -- trim
    if pattern == '' then
        return api.send_message(message.chat.id, 'Please provide a pattern to filter.')
    end

    -- validate regex pattern
    local ok = pcall(string.match, '', pattern)
    if not ok then
        return api.send_message(message.chat.id, 'Invalid pattern. Please provide a valid Lua pattern.')
    end

    -- check for duplicate
    local existing = ctx.db.call('sp_get_filter', { message.chat.id, pattern })
    if existing and #existing > 0 then
        -- update the action if filter already exists
        ctx.db.call('sp_update_filter_action', { action, message.chat.id, pattern })
        require('src.core.session').invalidate_cached_list(message.chat.id, 'filters')
        return api.send_message(message.chat.id, string.format(
            'Filter <code>%s</code> updated with action: <b>%s</b>.',
            tools.escape_html(pattern), action
        ), 'html')
    end

    ctx.db.call('sp_insert_filter', { message.chat.id, pattern, action, message.from.id })

    -- invalidate filter cache
    require('src.core.session').invalidate_cached_list(message.chat.id, 'filters')

    api.send_message(message.chat.id, string.format(
        'Filter added: <code>%s</code> (action: <b>%s</b>)',
        tools.escape_html(pattern), action
    ), 'html')
end

return plugin
