--[[
    mattata v2.0 - Federation: fpromote

    Promotes a user to federation admin. Only the federation owner can promote.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'fpromote'
plugin.category = 'admin'
plugin.description = 'Promote a user to federation admin.'
plugin.commands = { 'fpromote' }
plugin.help = '/fpromote [user] - Promote a user to federation admin.'
plugin.group_only = true
plugin.admin_only = false

local function resolve_user(message, ctx)
    if message.reply and message.reply.from then
        return message.reply.from.id, message.reply.from.first_name
    end
    if message.args and message.args ~= '' then
        local input = message.args:match('^(%S+)')
        if tonumber(input) then
            return tonumber(input), input
        end
        local username = input:gsub('^@', ''):lower()
        local user_id = ctx.redis.get('username:' .. username)
        if user_id then
            return tonumber(user_id), '@' .. username
        end
    end
    return nil, nil
end

local function get_chat_federation(db, chat_id)
    local result = db.execute(
        'SELECT f.id, f.name, f.owner_id FROM federations f JOIN federation_chats fc ON f.id = fc.federation_id WHERE fc.chat_id = $1',
        { chat_id }
    )
    if result and #result > 0 then return result[1] end
    return nil
end

function plugin.on_message(api, message, ctx)
    local fed = get_chat_federation(ctx.db, message.chat.id)
    if not fed then
        return api.send_message(
            message.chat.id,
            'This chat is not part of any federation.',
            'html'
        )
    end

    if fed.owner_id ~= message.from.id then
        return api.send_message(
            message.chat.id,
            'Only the federation owner can promote admins.',
            'html'
        )
    end

    local target_id, target_name = resolve_user(message, ctx)
    if not target_id then
        return api.send_message(
            message.chat.id,
            'Please specify a user to promote by replying to their message or providing a user ID/username.\nUsage: <code>/fpromote [user]</code>',
            'html'
        )
    end

    if target_id == fed.owner_id then
        return api.send_message(
            message.chat.id,
            'The federation owner cannot be promoted as an admin.',
            'html'
        )
    end

    -- Check if already an admin
    local existing = ctx.db.execute(
        'SELECT 1 FROM federation_admins WHERE federation_id = $1 AND user_id = $2',
        { fed.id, target_id }
    )
    if existing and #existing > 0 then
        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> is already a federation admin.',
                tools.escape_html(target_name)
            ),
            'html'
        )
    end

    ctx.db.execute(
        'INSERT INTO federation_admins (federation_id, user_id, promoted_by) VALUES ($1, $2, $3)',
        { fed.id, target_id, message.from.id }
    )

    return api.send_message(
        message.chat.id,
        string.format(
            '<b>%s</b> has been promoted to federation admin in <b>%s</b>.',
            tools.escape_html(target_name),
            tools.escape_html(fed.name)
        ),
        'html'
    )
end

return plugin
