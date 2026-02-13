--[[
    mattata v2.0 - Federation: delfed

    Deletes a federation. Only the federation owner can delete it.
    Requires confirmation via inline callback.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'delfed'
plugin.category = 'admin'
plugin.description = 'Delete a federation you own.'
plugin.commands = { 'delfed' }
plugin.help = '/delfed <federation_id> - Delete a federation you own.'
plugin.group_only = false
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local fed_id = message.args
    if not fed_id or fed_id == '' then
        return api.send_message(
            message.chat.id,
            'Please specify the federation ID.\nUsage: <code>/delfed &lt;federation_id&gt;</code>',
            { parse_mode = 'html' }
        )
    end

    fed_id = fed_id:match('^(%S+)')

    local fed = ctx.db.call('sp_get_federation', { fed_id })
    if not fed or #fed == 0 then
        return api.send_message(
            message.chat.id,
            'Federation not found. Please check the ID and try again.'
        )
    end

    fed = fed[1]

    if fed.owner_id ~= message.from.id then
        return api.send_message(
            message.chat.id,
            'Only the federation owner can delete it.'
        )
    end

    local keyboard = {
        inline_keyboard = { {
            { text = 'Yes, delete it', callback_data = 'delfed:confirm:' .. fed.id },
            { text = 'No, cancel', callback_data = 'delfed:cancel' }
        } }
    }

    return api.send_message(
        message.chat.id,
        string.format(
            'Are you sure you want to delete the federation <b>%s</b>?\n\nThis will remove all bans, chats, and admins associated with it. This action cannot be undone.',
            tools.escape_html(fed.name)
        ),
        { parse_mode = 'html', reply_markup = keyboard }
    )
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    if not data then return end

    -- Verify the button was pressed by the original command user
    if message.from and callback_query.from.id ~= message.from.id then
        return api.answer_callback_query(callback_query.id, { text = 'This button is not for you.' })
    end

    if data == 'cancel' then
        api.answer_callback_query(callback_query.id, { text = 'Deletion cancelled.' })
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            'Federation deletion cancelled.',
            { parse_mode = 'html' }
        )
    end

    local fed_id = data:match('^confirm:(.+)$')
    if fed_id then
        local fed = ctx.db.call('sp_get_federation_owner', { fed_id })
        if not fed or #fed == 0 then
            api.answer_callback_query(callback_query.id, { text = 'Federation no longer exists.' })
            return api.edit_message_text(
                message.chat.id,
                message.message_id,
                'This federation no longer exists.',
                { parse_mode = 'html' }
            )
        end

        if fed[1].owner_id ~= callback_query.from.id then
            return api.answer_callback_query(callback_query.id, { text = 'Only the federation owner can delete it.' })
        end

        ctx.db.call('sp_delete_federation', { fed_id })

        api.answer_callback_query(callback_query.id, { text = 'Federation deleted.' })
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                'Federation <b>%s</b> has been deleted.',
                tools.escape_html(fed[1].name)
            ),
            { parse_mode = 'html' }
        )
    end
end

return plugin
