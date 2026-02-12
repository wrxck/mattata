--[[
    mattata v2.0 - Federation: delfed

    Deletes a federation. Only the federation owner can delete it.
    Requires confirmation via inline callback.
]]

local tools = require('telegram-bot-lua.tools')
local json = require('dkjson')

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
            'html'
        )
    end

    fed_id = fed_id:match('^(%S+)')

    local fed = ctx.db.call('sp_get_federation', { fed_id })
    if not fed or #fed == 0 then
        return api.send_message(
            message.chat.id,
            'Federation not found. Please check the ID and try again.',
            'html'
        )
    end

    fed = fed[1]

    if fed.owner_id ~= message.from.id then
        return api.send_message(
            message.chat.id,
            'Only the federation owner can delete it.',
            'html'
        )
    end

    local callback_data_yes = json.encode({ plugin = 'delfed', action = 'confirm', fed_id = fed.id })
    local callback_data_no = json.encode({ plugin = 'delfed', action = 'cancel' })

    local keyboard = {
        inline_keyboard = { {
            { text = 'Yes, delete it', callback_data = callback_data_yes },
            { text = 'No, cancel', callback_data = callback_data_no }
        } }
    }

    return api.send_message(
        message.chat.id,
        string.format(
            'Are you sure you want to delete the federation <b>%s</b>?\n\nThis will remove all bans, chats, and admins associated with it. This action cannot be undone.',
            tools.escape_html(fed.name)
        ),
        'html',
        nil, nil, nil, nil,
        json.encode(keyboard)
    )
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = json.decode(callback_query.data)
    if not data or data.plugin ~= 'delfed' then
        return
    end

    if callback_query.from.id ~= message.reply_to_message_from_id and callback_query.from.id ~= (message.from and message.from.id) then
        return api.answer_callback_query(callback_query.id, 'This button is not for you.')
    end

    if data.action == 'cancel' then
        api.answer_callback_query(callback_query.id, 'Deletion cancelled.')
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            'Federation deletion cancelled.',
            'html'
        )
    end

    if data.action == 'confirm' then
        local fed = ctx.db.call('sp_get_federation_owner', { data.fed_id })
        if not fed or #fed == 0 then
            api.answer_callback_query(callback_query.id, 'Federation no longer exists.')
            return api.edit_message_text(
                message.chat.id,
                message.message_id,
                'This federation no longer exists.',
                'html'
            )
        end

        if fed[1].owner_id ~= callback_query.from.id then
            return api.answer_callback_query(callback_query.id, 'Only the federation owner can delete it.')
        end

        ctx.db.call('sp_delete_federation', { data.fed_id })

        api.answer_callback_query(callback_query.id, 'Federation deleted.')
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                'Federation <b>%s</b> has been deleted.',
                tools.escape_html(fed[1].name)
            ),
            'html'
        )
    end
end

return plugin
