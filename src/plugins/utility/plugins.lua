--[[
    mattata v2.0 - Plugins Management Plugin
    Allows admins to enable or disable plugins per chat.
]]

local plugin = {}
plugin.name = 'plugins'
plugin.category = 'utility'
plugin.description = 'Enable or disable plugins in this chat'
plugin.commands = { 'plugins', 'enableplugin', 'disableplugin' }
plugin.help = '/plugins - View and toggle plugins for this chat.\n/enableplugin <name> - Enable a plugin.\n/disableplugin <name> - Disable a plugin.'
plugin.admin_only = true
plugin.group_only = true

local PER_PAGE = 10

function plugin.on_message(api, message, ctx)
    local loader = require('src.core.loader')
    local tools = require('telegram-bot-lua.tools')

    -- Direct enable/disable commands
    if message.command == 'enableplugin' or message.command == 'disableplugin' then
        local name = message.args
        if not name or name == '' then
            return api.send_message(message.chat.id, 'Please specify a plugin name.')
        end
        name = name:lower()
        local target = loader.get_by_name(name)
        if not target then
            return api.send_message(message.chat.id, 'Plugin "' .. tools.escape_html(name) .. '" not found.')
        end
        if loader.is_permanent(name) then
            return api.send_message(message.chat.id, 'The "' .. name .. '" plugin cannot be toggled.')
        end
        if message.command == 'enableplugin' then
            ctx.session.enable_plugin(message.chat.id, name)
            return api.send_message(message.chat.id, 'The "' .. name .. '" plugin has been enabled.')
        else
            ctx.session.disable_plugin(message.chat.id, name)
            return api.send_message(message.chat.id, 'The "' .. name .. '" plugin has been disabled.')
        end
    end

    -- Show plugin list with toggle keyboard
    return plugin.send_plugin_page(api, message.chat.id, nil, 1, ctx)
end

function plugin.send_plugin_page(api, chat_id, message_id, page, ctx)
    local loader = require('src.core.loader')
    local all_plugins = loader.get_plugins()

    -- Filter toggleable plugins
    local toggleable = {}
    for _, p in ipairs(all_plugins) do
        if not loader.is_permanent(p.name) then
            table.insert(toggleable, p)
        end
    end

    local total_pages = math.max(1, math.ceil(#toggleable / PER_PAGE))
    if page < 1 then page = total_pages end
    if page > total_pages then page = 1 end

    local start_idx = (page - 1) * PER_PAGE + 1
    local end_idx = math.min(start_idx + PER_PAGE - 1, #toggleable)

    local keyboard = api.inline_keyboard()

    for i = start_idx, end_idx do
        local p = toggleable[i]
        local is_disabled = ctx.session.is_plugin_disabled(chat_id, p.name)
        local status = is_disabled and 'OFF' or 'ON'
        local label = string.format('%s [%s]', p.name, status)
        keyboard:row(
            api.row():callback_data_button(label, 'plugins:toggle:' .. p.name .. ':' .. page)
        )
    end

    -- Navigation row
    keyboard:row(
        api.row()
            :callback_data_button('<', 'plugins:page:' .. (page - 1))
            :callback_data_button(page .. '/' .. total_pages, 'plugins:noop')
            :callback_data_button('>', 'plugins:page:' .. (page + 1))
    )

    local text = 'Toggle plugins on or off for this chat. Permanent plugins (help, about, plugins) cannot be disabled.'

    if message_id then
        return api.edit_message_text(chat_id, message_id, text, nil, true, keyboard)
    else
        return api.send_message(chat_id, text, nil, true, false, nil, keyboard)
    end
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    local loader = require('src.core.loader')
    local permissions = require('src.core.permissions')

    -- Check admin permission
    if not permissions.is_group_admin(api, message.chat.id, callback_query.from.id) then
        return api.answer_callback_query(callback_query.id, 'You need to be an admin to manage plugins.')
    end

    if data == 'noop' then
        return api.answer_callback_query(callback_query.id)
    end

    -- Page navigation
    local page = data:match('^page:(%d+)$')
    if page then
        page = tonumber(page)
        plugin.send_plugin_page(api, message.chat.id, message.message_id, page, ctx)
        return api.answer_callback_query(callback_query.id)
    end

    -- Toggle plugin
    local plugin_name, return_page = data:match('^toggle:([%w_]+):(%d+)$')
    if plugin_name then
        return_page = tonumber(return_page)
        if loader.is_permanent(plugin_name) then
            return api.answer_callback_query(callback_query.id, 'This plugin cannot be toggled.')
        end
        local target = loader.get_by_name(plugin_name)
        if not target then
            return api.answer_callback_query(callback_query.id, 'Plugin not found.')
        end
        local is_disabled = ctx.session.is_plugin_disabled(message.chat.id, plugin_name)
        if is_disabled then
            ctx.session.enable_plugin(message.chat.id, plugin_name)
            api.answer_callback_query(callback_query.id, plugin_name .. ' has been enabled.')
        else
            ctx.session.disable_plugin(message.chat.id, plugin_name)
            api.answer_callback_query(callback_query.id, plugin_name .. ' has been disabled.')
        end
        return plugin.send_plugin_page(api, message.chat.id, message.message_id, return_page, ctx)
    end
end

return plugin
