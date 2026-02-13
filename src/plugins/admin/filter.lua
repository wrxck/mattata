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
        return api.send_message(message.chat.id, 'Usage: /filter <pattern> [action]\nActions: delete (default), warn, ban, kick, mute', { parse_mode = 'html' })
    end

    local VALID_ACTIONS = { delete = true, warn = true, ban = true, kick = true, mute = true }

    local pattern, action
    local last_word = message.args:match('(%S+)$')
    if last_word and VALID_ACTIONS[last_word:lower()] and message.args:match('^(.+)%s+%S+$') then
        pattern, action = message.args:match('^(.+)%s+(%S+)$')
        action = action:lower()
    else
        pattern = message.args
        action = 'delete'
    end

    pattern = pattern:match('^%s*(.-)%s*$') -- trim
    if pattern == '' then
        return api.send_message(message.chat.id, 'Please provide a pattern to filter.')
    end

    -- validate pattern syntax
    local ok = pcall(string.match, '', pattern)
    if not ok then
        return api.send_message(message.chat.id, 'Invalid pattern. Please provide a valid Lua pattern.')
    end

    -- reject patterns that could cause catastrophic backtracking
    if #pattern > 128 then
        return api.send_message(message.chat.id, 'Pattern too long (max 128 characters).')
    end
    local wq_count = 0
    do
        local i = 1
        while i <= #pattern do
            if pattern:sub(i, i) == '%' then
                i = i + 2
            elseif pattern:sub(i, i) == '.' and i < #pattern then
                local nc = pattern:sub(i + 1, i + 1)
                if nc == '+' or nc == '*' or nc == '-' then wq_count = wq_count + 1 end
                i = i + 1
            else
                i = i + 1
            end
        end
    end
    if wq_count > 3 then
        return api.send_message(message.chat.id, 'Pattern too complex (too many wildcard repetitions).')
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
        ), { parse_mode = 'html' })
    end

    ctx.db.call('sp_insert_filter', { message.chat.id, pattern, action, message.from.id })

    -- invalidate filter cache
    require('src.core.session').invalidate_cached_list(message.chat.id, 'filters')

    api.send_message(message.chat.id, string.format(
        'Filter added: <code>%s</code> (action: <b>%s</b>)',
        tools.escape_html(pattern), action
    ), { parse_mode = 'html' })
end

return plugin
