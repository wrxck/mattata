--[[
    mattata v2.0 - Add Trigger Plugin
]]

local plugin = {}
plugin.name = 'addtrigger'
plugin.category = 'admin'
plugin.description = 'Add a trigger (auto-response pattern)'
plugin.commands = { 'addtrigger', 'deltrigger' }
plugin.help = '/addtrigger <pattern> <response> - Adds a trigger. Use /deltrigger <number> to remove.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        return api.send_message(message.chat.id,
            'Usage: /addtrigger <pattern> <response>\n\n'
            .. 'The pattern is a Lua pattern that will be matched against incoming messages. '
            .. 'When matched, the response is sent.')
    end

    -- if used with /deltrigger, handle deletion
    if message.command == 'deltrigger' then
        local index = tonumber(message.args)
        if not index then
            return api.send_message(message.chat.id, 'Usage: /deltrigger <number>')
        end
        local triggers = ctx.db.call('sp_get_triggers_ordered', { message.chat.id })
        if not triggers or not triggers[index] then
            return api.send_message(message.chat.id, 'Invalid trigger number. Use /triggers to see the list.')
        end
        ctx.db.call('sp_delete_trigger_by_id', { triggers[index].id })
        -- invalidate trigger cache
        require('src.core.session').invalidate_cached_list(message.chat.id, 'triggers')
        return api.send_message(message.chat.id, string.format(
            'Trigger <code>%s</code> has been removed.',
            tools.escape_html(triggers[index].pattern)
        ), { parse_mode = 'html' })
    end

    -- parse pattern and response (split on first newline or first space after the pattern)
    local pattern, response
    if message.args:match('\n') then
        pattern, response = message.args:match('^(.-)%s*\n%s*(.+)$')
    else
        pattern, response = message.args:match('^(%S+)%s+(.+)$')
    end

    if not pattern or not response then
        return api.send_message(message.chat.id, 'Usage: /addtrigger <pattern> <response>')
    end

    pattern = pattern:match('^%s*(.-)%s*$')
    response = response:match('^%s*(.-)%s*$')

    -- validate pattern syntax
    local ok = pcall(string.match, '', pattern)
    if not ok then
        return api.send_message(message.chat.id, 'Invalid Lua pattern. Please check your syntax.')
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
    local existing = ctx.db.call('sp_check_trigger_exists', { message.chat.id, pattern })
    if existing and #existing > 0 then
        ctx.db.call('sp_update_trigger_response', { response, message.chat.id, pattern })
        return api.send_message(message.chat.id, string.format(
            'Trigger <code>%s</code> has been updated.',
            tools.escape_html(pattern)
        ), { parse_mode = 'html' })
    end

    ctx.db.call('sp_insert_trigger', { message.chat.id, pattern, response, message.from.id })

    -- invalidate trigger cache
    local session = require('src.core.session')
    session.invalidate_cached_list(message.chat.id, 'triggers')

    api.send_message(message.chat.id, string.format(
        'Trigger added: <code>%s</code> -> %s',
        tools.escape_html(pattern),
        tools.escape_html(response:sub(1, 100)) .. (#response > 100 and '...' or '')
    ), { parse_mode = 'html' })
end

-- handle trigger matching on every new message
function plugin.on_new_message(api, message, ctx)
    if not ctx.is_group or not message.text or message.text == '' then return end
    -- don't trigger on commands
    if message.text:match('^[/!#]') then return end

    -- cache triggers per chat (5-min ttl)
    local session = require('src.core.session')
    local triggers = session.get_cached_list(message.chat.id, 'triggers', function()
        return ctx.db.call('sp_get_triggers', { message.chat.id })
    end, 300)
    if not triggers or #triggers == 0 then return end

    local text = message.text:lower()
    for _, t in ipairs(triggers) do
        -- Skip patterns that could cause catastrophic backtracking
        if #t.pattern > 128 then goto continue end
        local ok, matched = pcall(function()
            return text:match(t.pattern:lower())
        end)
        if ok and matched then
            if t.is_media and t.file_id then
                -- send media response
                api.send_document(message.chat.id, t.file_id, { reply_parameters = { message_id = message.message_id } })
            else
                api.send_message(message.chat.id, t.response, { reply_parameters = { message_id = message.message_id } })
            end
            return
        end
        ::continue::
    end
end

return plugin
