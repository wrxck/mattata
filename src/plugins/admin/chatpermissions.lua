--[[
    mattata v2.1 - Chat Permissions Plugin
    Manage default chat permissions with inline keyboard toggles.
]]

local plugin = {}
plugin.name = 'chatpermissions'
plugin.category = 'admin'
plugin.description = 'Manage chat permissions'
plugin.commands = { 'permissions', 'perms' }
plugin.help = '/permissions - View and toggle default chat permissions.'
plugin.group_only = true
plugin.admin_only = true

local json = require('dkjson')

local PERMISSION_LABELS = {
    { key = 'can_send_messages', label = 'Send Messages' },
    { key = 'can_send_audios', label = 'Send Audios' },
    { key = 'can_send_documents', label = 'Send Documents' },
    { key = 'can_send_photos', label = 'Send Photos' },
    { key = 'can_send_videos', label = 'Send Videos' },
    { key = 'can_send_video_notes', label = 'Send Video Notes' },
    { key = 'can_send_voice_notes', label = 'Send Voice Notes' },
    { key = 'can_send_polls', label = 'Send Polls' },
    { key = 'can_send_other_messages', label = 'Stickers/GIFs' },
    { key = 'can_add_web_page_previews', label = 'Link Previews' },
    { key = 'can_change_info', label = 'Change Info' },
    { key = 'can_invite_users', label = 'Invite Users' },
    { key = 'can_pin_messages', label = 'Pin Messages' },
    { key = 'can_manage_topics', label = 'Manage Topics' },
}

local function build_keyboard(perms, chat_id)
    local rows = {}
    for _, perm in ipairs(PERMISSION_LABELS) do
        local enabled = perms[perm.key]
        local icon = enabled and '\xe2\x9c\x85' or '\xe2\x9b\x94'
        table.insert(rows, { {
            text = icon .. ' ' .. perm.label,
            callback_data = 'chatpermissions:toggle:' .. chat_id .. ':' .. perm.key
        } })
    end
    table.insert(rows, { { text = 'Done', callback_data = 'chatpermissions:done' } })
    return json.encode({ inline_keyboard = rows })
end

local function get_current_permissions(api, chat_id)
    local chat = api.get_chat(chat_id)
    if chat and chat.result and chat.result.permissions then
        return chat.result.permissions
    end
    -- Default to all enabled
    local defaults = {}
    for _, perm in ipairs(PERMISSION_LABELS) do
        defaults[perm.key] = true
    end
    return defaults
end

function plugin.on_message(api, message, ctx)
    local perms = get_current_permissions(api, message.chat.id)
    local keyboard = build_keyboard(perms, message.chat.id)
    return api.send_message(message.chat.id, '<b>Default Chat Permissions</b>\nTap a permission to toggle it.', 'html', false, false, nil, keyboard)
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    if not data then return end

    if data == 'done' then
        api.delete_message(message.chat.id, message.message_id)
        return api.answer_callback_query(callback_query.id, 'Permissions saved.')
    end

    local chat_id, perm_key = data:match('^toggle:(%-?%d+):(.+)$')
    if not chat_id or not perm_key then return end
    chat_id = tonumber(chat_id)

    -- Only admins can toggle
    local permissions = require('src.core.permissions')
    if not permissions.is_group_admin(api, chat_id, callback_query.from.id) then
        return api.answer_callback_query(callback_query.id, 'Only admins can change permissions.')
    end

    local perms = get_current_permissions(api, chat_id)

    -- Toggle
    perms[perm_key] = not perms[perm_key]

    local result = api.set_chat_permissions(chat_id, perms)
    if not result then
        return api.answer_callback_query(callback_query.id, 'Failed to update permissions.')
    end

    local keyboard = build_keyboard(perms, chat_id)
    api.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
    return api.answer_callback_query(callback_query.id, 'Permission updated.')
end

return plugin
