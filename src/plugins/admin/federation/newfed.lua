--[[
    mattata v2.0 - Federation: newfed

    Creates a new federation. Any user can create up to 5 federations.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'newfed'
plugin.category = 'admin'
plugin.description = 'Create a new federation.'
plugin.commands = { 'newfed' }
plugin.help = '/newfed <name> - Create a new federation with the given name.'
plugin.group_only = false
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local name = message.args
    if not name or name == '' then
        return api.send_message(
            message.chat.id,
            'Please specify a name for the federation.\nUsage: <code>/newfed &lt;name&gt;</code>',
            { parse_mode = 'html' }
        )
    end

    if #name > 128 then
        return api.send_message(
            message.chat.id,
            'Federation name must be 128 characters or fewer.',
            { parse_mode = 'html' }
        )
    end

    local user_id = message.from.id

    local existing = ctx.db.call('sp_count_user_federations', { user_id })
    if existing and existing[1] and tonumber(existing[1].count) >= 5 then
        return api.send_message(
            message.chat.id,
            'You already own 5 federations, which is the maximum allowed.',
            { parse_mode = 'html' }
        )
    end

    local result = ctx.db.call('sp_create_federation', { name, user_id })
    if not result or #result == 0 then
        return api.send_message(
            message.chat.id,
            'Failed to create the federation. Please try again later.',
            { parse_mode = 'html' }
        )
    end

    local fed_id = result[1].id
    local output = string.format(
        'Federation <b>%s</b> created successfully!\n\nFederation ID: <code>%s</code>\n\nUse <code>/joinfed %s</code> in a group to add it to this federation.',
        tools.escape_html(name),
        tools.escape_html(fed_id),
        tools.escape_html(fed_id)
    )
    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
