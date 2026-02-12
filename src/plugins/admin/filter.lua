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

local VALID_ACTIONS = {
    delete = true,
    warn = true,
    ban = true,
    kick = true,
    mute = true
}

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

    -- Validate regex pattern
    local ok = pcall(string.match, '', pattern)
    if not ok then
        return api.send_message(message.chat.id, 'Invalid pattern. Please provide a valid Lua pattern.')
    end

    -- Check for duplicate
    local existing = ctx.db.execute(
        'SELECT id FROM filters WHERE chat_id = $1 AND pattern = $2',
        { message.chat.id, pattern }
    )
    if existing and #existing > 0 then
        -- Update the action if filter already exists
        ctx.db.execute(
            'UPDATE filters SET action = $1 WHERE chat_id = $2 AND pattern = $3',
            { action, message.chat.id, pattern }
        )
        require('src.core.session').invalidate_cached_list(message.chat.id, 'filters')
        return api.send_message(message.chat.id, string.format(
            'Filter <code>%s</code> updated with action: <b>%s</b>.',
            tools.escape_html(pattern), action
        ), 'html')
    end

    ctx.db.insert('filters', {
        chat_id = message.chat.id,
        pattern = pattern,
        action = action,
        created_by = message.from.id
    })

    -- Invalidate filter cache
    require('src.core.session').invalidate_cached_list(message.chat.id, 'filters')

    api.send_message(message.chat.id, string.format(
        'Filter added: <code>%s</code> (action: <b>%s</b>)',
        tools.escape_html(pattern), action
    ), 'html')
end

return plugin
