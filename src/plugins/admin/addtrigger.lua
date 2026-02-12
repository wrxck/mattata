--[[
    mattata v2.0 - Add Trigger Plugin
]]

local plugin = {}
plugin.name = 'addtrigger'
plugin.category = 'admin'
plugin.description = 'Add a trigger (auto-response pattern)'
plugin.commands = { 'addtrigger' }
plugin.help = '/addtrigger <pattern> <response> - Adds a trigger. Use /deltrigger <number> to remove.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        return api.send_message(message.chat.id, 'Usage: /addtrigger <pattern> <response>\n\nThe pattern is a Lua pattern that will be matched against incoming messages. When matched, the response is sent.')
    end

    -- If used with /deltrigger, handle deletion
    if message.command == 'deltrigger' then
        local index = tonumber(message.args)
        if not index then
            return api.send_message(message.chat.id, 'Usage: /deltrigger <number>')
        end
        local triggers = ctx.db.execute(
            'SELECT id, pattern FROM triggers WHERE chat_id = $1 ORDER BY created_at',
            { message.chat.id }
        )
        if not triggers or not triggers[index] then
            return api.send_message(message.chat.id, 'Invalid trigger number. Use /triggers to see the list.')
        end
        ctx.db.execute('DELETE FROM triggers WHERE id = $1', { triggers[index].id })
        -- Invalidate trigger cache
        require('src.core.session').invalidate_cached_list(message.chat.id, 'triggers')
        return api.send_message(message.chat.id, string.format(
            'Trigger <code>%s</code> has been removed.',
            tools.escape_html(triggers[index].pattern)
        ), 'html')
    end

    -- Parse pattern and response (split on first newline or first space after the pattern)
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

    -- Validate pattern
    local ok = pcall(string.match, '', pattern)
    if not ok then
        return api.send_message(message.chat.id, 'Invalid Lua pattern. Please check your syntax.')
    end

    -- Check for duplicate
    local existing = ctx.db.execute(
        'SELECT id FROM triggers WHERE chat_id = $1 AND pattern = $2',
        { message.chat.id, pattern }
    )
    if existing and #existing > 0 then
        ctx.db.execute(
            'UPDATE triggers SET response = $1 WHERE chat_id = $2 AND pattern = $3',
            { response, message.chat.id, pattern }
        )
        return api.send_message(message.chat.id, string.format(
            'Trigger <code>%s</code> has been updated.',
            tools.escape_html(pattern)
        ), 'html')
    end

    ctx.db.insert('triggers', {
        chat_id = message.chat.id,
        pattern = pattern,
        response = response,
        created_by = message.from.id
    })

    -- Invalidate trigger cache
    local session = require('src.core.session')
    session.invalidate_cached_list(message.chat.id, 'triggers')

    api.send_message(message.chat.id, string.format(
        'Trigger added: <code>%s</code> -> %s',
        tools.escape_html(pattern),
        tools.escape_html(response:sub(1, 100)) .. (#response > 100 and '...' or '')
    ), 'html')
end

-- Handle trigger matching on every new message
function plugin.on_new_message(api, message, ctx)
    if not ctx.is_group or not message.text or message.text == '' then return end
    -- Don't trigger on commands
    if message.text:match('^[/!#]') then return end

    -- Cache triggers per chat (5-min TTL)
    local session = require('src.core.session')
    local triggers = session.get_cached_list(message.chat.id, 'triggers', function()
        return ctx.db.execute(
            'SELECT pattern, response, is_media, file_id FROM triggers WHERE chat_id = $1',
            { message.chat.id }
        )
    end, 300)
    if not triggers or #triggers == 0 then return end

    local text = message.text:lower()
    for _, t in ipairs(triggers) do
        local ok, matched = pcall(function()
            return text:match(t.pattern:lower())
        end)
        if ok and matched then
            if t.is_media and t.file_id then
                -- Send media response
                api.send_document(message.chat.id, t.file_id, nil, nil, nil, message.message_id)
            else
                api.send_message(message.chat.id, t.response, nil, nil, nil, message.message_id)
            end
            return
        end
    end
end

return plugin
