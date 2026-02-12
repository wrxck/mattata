--[[
    mattata v2.0 - Administration Plugin
    Main settings panel with inline keyboard for toggling settings.
]]

local plugin = {}
plugin.name = 'administration'
plugin.category = 'admin'
plugin.description = 'Main administration settings panel'
plugin.commands = { 'administration', 'settings' }
plugin.help = '/administration - Opens the administration settings panel. Alias: /settings'
plugin.group_only = true
plugin.admin_only = true

local json = require('dkjson')

-- Toggleable settings with display names and keys
local SETTINGS = {
    { key = 'antilink_enabled', name = 'Anti-Link', description = 'Delete Telegram invite links from non-admins' },
    { key = 'wordfilter_enabled', name = 'Word Filter', description = 'Filter messages matching patterns' },
    { key = 'captcha_enabled', name = 'Join Captcha', description = 'Require captcha for new members' },
    { key = 'antibot', name = 'Anti-Bot', description = 'Kick bots added by non-admins' },
    { key = 'delete_commands', name = 'Delete Commands', description = 'Auto-delete command messages' },
    { key = 'force_group_language', name = 'Force Group Language', description = 'Force all users to use group language' },
    { key = 'welcome_enabled', name = 'Welcome Message', description = 'Send welcome message for new members' },
    { key = 'log_admin_actions', name = 'Log Admin Actions', description = 'Log admin actions to log chat' },
    { key = 'anonymous_admin', name = 'Anonymous Admin', description = 'Hide admin names in action messages' },
    { key = 'lock_stickers', name = 'Lock Stickers', description = 'Prevent non-admins from sending stickers' },
    { key = 'lock_gifs', name = 'Lock GIFs', description = 'Prevent non-admins from sending GIFs' },
    { key = 'lock_forwards', name = 'Lock Forwards', description = 'Prevent non-admins from forwarding messages' }
}

local function is_setting_enabled(ctx, chat_id, key)
    local result = ctx.db.execute(
        "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = $2",
        { chat_id, key }
    )
    return result and #result > 0 and result[1].value == 'true'
end

local function build_keyboard(ctx, chat_id, page)
    page = page or 1
    local per_page = 6
    local start_idx = (page - 1) * per_page + 1
    local end_idx = math.min(start_idx + per_page - 1, #SETTINGS)
    local total_pages = math.ceil(#SETTINGS / per_page)

    local keyboard = { inline_keyboard = {} }

    for i = start_idx, end_idx do
        local s = SETTINGS[i]
        local enabled = is_setting_enabled(ctx, chat_id, s.key)
        local status_icon = enabled and '[ON]' or '[OFF]'
        table.insert(keyboard.inline_keyboard, {
            {
                text = string.format('%s %s', s.name, status_icon),
                callback_data = string.format('administration:toggle:%s:%d', s.key, page)
            }
        })
    end

    -- Navigation row
    if total_pages > 1 then
        local nav_row = {}
        if page > 1 then
            table.insert(nav_row, {
                text = '<< Previous',
                callback_data = 'administration:page:' .. (page - 1)
            })
        end
        table.insert(nav_row, {
            text = string.format('%d/%d', page, total_pages),
            callback_data = 'administration:noop'
        })
        if page < total_pages then
            table.insert(nav_row, {
                text = 'Next >>',
                callback_data = 'administration:page:' .. (page + 1)
            })
        end
        table.insert(keyboard.inline_keyboard, nav_row)
    end

    -- Close button
    table.insert(keyboard.inline_keyboard, {
        {
            text = 'Close',
            callback_data = 'administration:close'
        }
    })

    return keyboard
end

local function build_message(ctx, chat_id)
    local tools = require('telegram-bot-lua.tools')
    local chat_info = ''
    local chat = ctx.api and ctx.api.get_chat(chat_id) or nil
    if chat and chat.result then
        chat_info = tools.escape_html(chat.result.title or 'this group')
    else
        chat_info = 'this group'
    end
    return string.format(
        '<b>Administration settings for %s</b>\n\nTap a setting to toggle it on or off.',
        chat_info
    )
end

function plugin.on_message(api, message, ctx)
    local text = build_message(ctx, message.chat.id)
    local keyboard = build_keyboard(ctx, message.chat.id, 1)
    api.send_message(message.chat.id, text, 'html', false, false, nil, json.encode(keyboard))
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local permissions = require('src.core.permissions')
    local data = callback_query.data

    if not data then return end

    -- Only admins can change settings
    if not permissions.is_group_admin(api, message.chat.id, callback_query.from.id) then
        return api.answer_callback_query(callback_query.id, 'Only admins can change settings.')
    end

    if data == 'noop' then
        return api.answer_callback_query(callback_query.id)
    end

    if data == 'close' then
        return api.delete_message(message.chat.id, message.message_id)
    end

    if data:match('^page:%d+$') then
        local page = tonumber(data:match('^page:(%d+)$'))
        local text = build_message(ctx, message.chat.id)
        local keyboard = build_keyboard(ctx, message.chat.id, page)
        api.edit_message_text(message.chat.id, message.message_id, text, 'html', false, json.encode(keyboard))
        return api.answer_callback_query(callback_query.id)
    end

    if data:match('^toggle:') then
        local key, page = data:match('^toggle:(%S+):(%d+)$')
        if not key then
            key = data:match('^toggle:(%S+)$')
            page = 1
        end
        page = tonumber(page) or 1

        -- Toggle the setting
        local currently_enabled = is_setting_enabled(ctx, message.chat.id, key)
        if currently_enabled then
            ctx.db.execute(
                "UPDATE chat_settings SET value = 'false' WHERE chat_id = $1 AND key = $2",
                { message.chat.id, key }
            )
        else
            ctx.db.upsert('chat_settings', {
                chat_id = message.chat.id,
                key = key,
                value = 'true'
            }, { 'chat_id', 'key' }, { 'value' })
        end

        -- Invalidate cache for the toggled setting
        require('src.core.session').invalidate_setting(message.chat.id, key)

        -- Find the setting name for the callback response
        local setting_name = key
        for _, s in ipairs(SETTINGS) do
            if s.key == key then
                setting_name = s.name
                break
            end
        end
        local new_state = not currently_enabled

        -- Rebuild keyboard with updated state
        local text = build_message(ctx, message.chat.id)
        local keyboard = build_keyboard(ctx, message.chat.id, page)
        api.edit_message_text(message.chat.id, message.message_id, text, 'html', false, json.encode(keyboard))

        return api.answer_callback_query(callback_query.id, string.format(
            '%s is now %s.', setting_name, new_state and 'enabled' or 'disabled'
        ))
    end
end

return plugin
