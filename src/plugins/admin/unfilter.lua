--[[
    mattata v2.0 - Unfilter Plugin
]]

local plugin = {}
plugin.name = 'unfilter'
plugin.category = 'admin'
plugin.description = 'Remove a content filter from the group'
plugin.commands = { 'unfilter', 'delfilter' }
plugin.help = '/unfilter <pattern> - Removes a filter. Alias: /delfilter'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        -- list existing filters
        local filters = ctx.db.call('sp_get_filters_ordered', { message.chat.id })
        if not filters or #filters == 0 then
            return api.send_message(message.chat.id, 'There are no filters set for this group.')
        end
        local output = '<b>Active filters:</b>\n\n'
        for i, f in ipairs(filters) do
            output = output .. string.format('%d. <code>%s</code> [%s]\n', i, tools.escape_html(f.pattern), f.action)
        end
        output = output .. '\nUse /unfilter <pattern> to remove a filter.'
        return api.send_message(message.chat.id, output, { parse_mode = 'html' })
    end

    local pattern = message.args:match('^%s*(.-)%s*$')
    local result = ctx.db.call('sp_delete_filter_by_pattern', { message.chat.id, pattern })

    if result and result[1] and tonumber(result[1].count) > 0 then
        api.send_message(message.chat.id, string.format(
            'Filter <code>%s</code> has been removed.',
            tools.escape_html(pattern)
        ), { parse_mode = 'html' })
    else
        -- try by index number
        local index = tonumber(pattern)
        if index then
            local filters = ctx.db.call('sp_get_filters_ordered', { message.chat.id })
            if filters and filters[index] then
                ctx.db.call('sp_delete_filter_by_id', { filters[index].id })
                return api.send_message(message.chat.id, string.format(
                    'Filter <code>%s</code> has been removed.',
                    tools.escape_html(filters[index].pattern)
                ), { parse_mode = 'html' })
            end
        end
        api.send_message(message.chat.id, 'That filter doesn\'t exist. Use /unfilter without arguments to see all filters.')
    end
end

return plugin
