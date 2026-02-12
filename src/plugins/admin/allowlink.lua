--[[
    mattata v2.0 - Allow Link Plugin
]]

local plugin = {}
plugin.name = 'allowlink'
plugin.category = 'admin'
plugin.description = 'Add or remove a link from the allowed links list'
plugin.commands = { 'allowlink' }
plugin.help = '/allowlink <link|@username> - Adds a link to the allowed list. /allowlink remove <link> - Removes it.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        return api.send_message(message.chat.id, 'Usage:\n/allowlink <link|@username> - Allow a link\n/allowlink remove <link|@username> - Remove from allowed list')
    end

    local args = message.args
    local is_remove = false
    if args:lower():match('^remove%s+') or args:lower():match('^del%s+') then
        is_remove = true
        args = args:gsub('^%S+%s+', '')
    end

    -- Normalise the link - extract the relevant part
    local link = args:match('^%s*(.-)%s*$')
    -- Strip protocol and domain prefixes
    link = link:gsub('^https?://', '')
    link = link:gsub('^[Tt]%.?[Mm][Ee]/', '')
    link = link:gsub('^[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.?[Mm][Ee]/', '')
    link = link:gsub('^[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.?[Dd][Oo][Gg]/', '')
    link = link:gsub('^@', '')

    if link == '' then
        return api.send_message(message.chat.id, 'Please provide a valid link or username.')
    end

    if is_remove then
        ctx.db.execute(
            'DELETE FROM allowed_links WHERE chat_id = $1 AND link = $2',
            { message.chat.id, link }
        )
        -- Also try with lowercase
        ctx.db.execute(
            'DELETE FROM allowed_links WHERE chat_id = $1 AND link = $2',
            { message.chat.id, link:lower() }
        )
        return api.send_message(message.chat.id, string.format(
            'Link <code>%s</code> has been removed from the allowed list.',
            tools.escape_html(link)
        ), 'html')
    end

    -- Check if already allowed
    local existing = ctx.db.execute(
        'SELECT 1 FROM allowed_links WHERE chat_id = $1 AND link = $2',
        { message.chat.id, link }
    )
    if existing and #existing > 0 then
        return api.send_message(message.chat.id, 'That link is already allowed.')
    end

    ctx.db.insert('allowed_links', {
        chat_id = message.chat.id,
        link = link
    })

    api.send_message(message.chat.id, string.format(
        'Link <code>%s</code> has been added to the allowed list.',
        tools.escape_html(link)
    ), 'html')
end

return plugin
