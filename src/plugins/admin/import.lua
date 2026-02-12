--[[
    mattata v2.0 - Import Plugin
]]

local plugin = {}
plugin.name = 'import'
plugin.category = 'admin'
plugin.description = 'Import settings from another chat'
plugin.commands = { 'import' }
plugin.help = '/import <chat_id> - Imports settings, filters, triggers, and rules from another chat.'
plugin.group_only = true
plugin.admin_only = true
plugin.global_admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.args then
        return api.send_message(message.chat.id, 'Usage: /import <chat_id>\n\nImports settings, filters, triggers, rules, and welcome messages from another chat.')
    end

    local source_id = tonumber(message.args)
    if not source_id then
        return api.send_message(message.chat.id, 'Please provide a valid chat ID.')
    end

    if source_id == message.chat.id then
        return api.send_message(message.chat.id, 'You can\'t import from the same chat.')
    end

    local imported = {}

    -- Import chat_settings
    local settings = ctx.db.execute(
        'SELECT key, value FROM chat_settings WHERE chat_id = $1',
        { source_id }
    )
    if settings and #settings > 0 then
        for _, s in ipairs(settings) do
            ctx.db.upsert('chat_settings', {
                chat_id = message.chat.id,
                key = s.key,
                value = s.value
            }, { 'chat_id', 'key' }, { 'value' })
        end
        table.insert(imported, #settings .. ' settings')
    end

    -- Import filters
    local filters = ctx.db.execute(
        'SELECT pattern, action, response FROM filters WHERE chat_id = $1',
        { source_id }
    )
    if filters and #filters > 0 then
        for _, f in ipairs(filters) do
            local existing = ctx.db.execute(
                'SELECT 1 FROM filters WHERE chat_id = $1 AND pattern = $2',
                { message.chat.id, f.pattern }
            )
            if not existing or #existing == 0 then
                ctx.db.insert('filters', {
                    chat_id = message.chat.id,
                    pattern = f.pattern,
                    action = f.action,
                    response = f.response,
                    created_by = message.from.id
                })
            end
        end
        table.insert(imported, #filters .. ' filters')
    end

    -- Import triggers
    local triggers = ctx.db.execute(
        'SELECT pattern, response, is_media, file_id FROM triggers WHERE chat_id = $1',
        { source_id }
    )
    if triggers and #triggers > 0 then
        for _, t in ipairs(triggers) do
            local existing = ctx.db.execute(
                'SELECT 1 FROM triggers WHERE chat_id = $1 AND pattern = $2',
                { message.chat.id, t.pattern }
            )
            if not existing or #existing == 0 then
                ctx.db.insert('triggers', {
                    chat_id = message.chat.id,
                    pattern = t.pattern,
                    response = t.response,
                    is_media = t.is_media,
                    file_id = t.file_id,
                    created_by = message.from.id
                })
            end
        end
        table.insert(imported, #triggers .. ' triggers')
    end

    -- Import rules
    local rules = ctx.db.execute(
        'SELECT rules_text FROM rules WHERE chat_id = $1',
        { source_id }
    )
    if rules and #rules > 0 then
        ctx.db.upsert('rules', {
            chat_id = message.chat.id,
            rules_text = rules[1].rules_text
        }, { 'chat_id' }, { 'rules_text' })
        table.insert(imported, 'rules')
    end

    -- Import welcome message
    local welcome = ctx.db.execute(
        'SELECT message, parse_mode FROM welcome_messages WHERE chat_id = $1',
        { source_id }
    )
    if welcome and #welcome > 0 then
        ctx.db.upsert('welcome_messages', {
            chat_id = message.chat.id,
            message = welcome[1].message,
            parse_mode = welcome[1].parse_mode
        }, { 'chat_id' }, { 'message', 'parse_mode' })
        table.insert(imported, 'welcome message')
    end

    -- Import allowed links
    local links = ctx.db.execute(
        'SELECT link FROM allowed_links WHERE chat_id = $1',
        { source_id }
    )
    if links and #links > 0 then
        for _, l in ipairs(links) do
            local existing = ctx.db.execute(
                'SELECT 1 FROM allowed_links WHERE chat_id = $1 AND link = $2',
                { message.chat.id, l.link }
            )
            if not existing or #existing == 0 then
                ctx.db.insert('allowed_links', {
                    chat_id = message.chat.id,
                    link = l.link
                })
            end
        end
        table.insert(imported, #links .. ' allowed links')
    end

    if #imported == 0 then
        return api.send_message(message.chat.id, 'No settings found to import from that chat.')
    end

    api.send_message(message.chat.id, string.format(
        'Successfully imported from <code>%d</code>:\n- %s',
        source_id, table.concat(imported, '\n- ')
    ), 'html')
end

return plugin
