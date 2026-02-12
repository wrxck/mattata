--[[
    mattata v2.0 - Federation: joinfed

    Joins the current chat to a federation. Requires group admin.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'joinfed'
plugin.category = 'admin'
plugin.description = 'Join this chat to a federation.'
plugin.commands = { 'joinfed' }
plugin.help = '/joinfed <federation_id> - Join this chat to the specified federation.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local fed_id = message.args
    if not fed_id or fed_id == '' then
        return api.send_message(
            message.chat.id,
            'Please specify the federation ID.\nUsage: <code>/joinfed &lt;federation_id&gt;</code>',
            'html'
        )
    end

    fed_id = fed_id:match('^(%S+)')
    local chat_id = message.chat.id

    -- Check if the chat is already in a federation
    local existing = ctx.db.execute(
        'SELECT f.id, f.name FROM federations f JOIN federation_chats fc ON f.id = fc.federation_id WHERE fc.chat_id = $1',
        { chat_id }
    )
    if existing and #existing > 0 then
        return api.send_message(
            chat_id,
            string.format(
                'This chat is already part of the federation <b>%s</b>.\nUse /leavefed to leave it first.',
                tools.escape_html(existing[1].name)
            ),
            'html'
        )
    end

    -- Check if the federation exists
    local fed = ctx.db.execute(
        'SELECT id, name FROM federations WHERE id = $1',
        { fed_id }
    )
    if not fed or #fed == 0 then
        return api.send_message(
            chat_id,
            'Federation not found. Please check the ID and try again.',
            'html'
        )
    end

    fed = fed[1]

    local result = ctx.db.execute(
        'INSERT INTO federation_chats (federation_id, chat_id, joined_by) VALUES ($1, $2, $3)',
        { fed.id, chat_id, message.from.id }
    )
    if not result then
        return api.send_message(
            chat_id,
            'Failed to join the federation. Please try again later.',
            'html'
        )
    end

    return api.send_message(
        chat_id,
        string.format(
            'This chat has joined the federation <b>%s</b>.',
            tools.escape_html(fed.name)
        ),
        'html'
    )
end

return plugin
