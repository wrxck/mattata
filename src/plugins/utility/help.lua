--[[
    mattata v2.0 - Help Plugin
    Displays help menus with inline keyboard navigation.
]]

local plugin = {}
plugin.name = 'help'
plugin.category = 'utility'
plugin.description = 'View bot help and command list'
plugin.commands = { 'help', 'start' }
plugin.help = '/help [command] - View help menu or get usage info for a specific command.'
plugin.permanent = true

local PER_PAGE = 10

local function get_page(items, page)
    local start_idx = (page - 1) * PER_PAGE + 1
    local end_idx = math.min(start_idx + PER_PAGE - 1, #items)
    local result = {}
    for i = start_idx, end_idx do
        table.insert(result, items[i])
    end
    return result, math.ceil(#items / PER_PAGE)
end

local function format_help_list(help_items)
    local lines = {}
    for _, item in ipairs(help_items) do
        local cmd = item.commands[1] and ('/' .. item.commands[1]) or ''
        local desc = item.description or ''
        table.insert(lines, string.format('%s %s - <em>%s</em>', '\xe2\x80\xa2', cmd, desc))
    end
    return table.concat(lines, '\n')
end

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local loader = require('src.core.loader')

    -- If argument given, show help for specific command
    if message.args and message.args ~= '' then
        local input = message.args:match('^/?(%w+)$')
        if input then
            local target = loader.get_by_command(input:lower())
            if target and target.help then
                return api.send_message(message.chat.id, 'Usage:\n' .. target.help .. '\n\nTo see all commands, send /help.')
            end
            return api.send_message(message.chat.id, 'No plugin found matching that command. Send /help to see all available commands.')
        end
    end

    -- Show main help menu
    local name = tools.escape_html(message.from.first_name)
    local output = string.format(
        'Hey %s! I\'m <b>%s</b>, a feature-rich Telegram bot.\n\nUse the buttons below to navigate my commands, or type <code>/help &lt;command&gt;</code> for details on a specific command.',
        name, tools.escape_html(api.info.first_name)
    )

    local keyboard = api.inline_keyboard():row(
        api.row():callback_data_button('Commands', 'help:cmds:1')
            :callback_data_button('Admin Help', 'help:acmds:1')
    ):row(
        api.row():callback_data_button('Links', 'help:links')
            :callback_data_button('Settings', 'help:settings')
    )

    return api.send_message(message.chat.id, output, 'html', true, false, nil, keyboard)
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local loader = require('src.core.loader')
    local data = callback_query.data

    if data:match('^cmds:%d+$') then
        local page = tonumber(data:match('^cmds:(%d+)$'))
        local all_help = loader.get_help(nil)
        -- Filter non-admin
        local items = {}
        for _, h in ipairs(all_help) do
            if h.category ~= 'admin' then
                table.insert(items, h)
            end
        end
        local page_items, total_pages = get_page(items, page)
        if page < 1 then page = total_pages end
        if page > total_pages then page = 1 end
        page_items, total_pages = get_page(items, page)
        local output = format_help_list(page_items)
        local keyboard = api.inline_keyboard():row(
            api.row():callback_data_button('<', 'help:cmds:' .. (page - 1))
                :callback_data_button(page .. '/' .. total_pages, 'help:noop')
                :callback_data_button('>', 'help:cmds:' .. (page + 1))
        ):row(
            api.row():callback_data_button('Back', 'help:back')
        )
        return api.edit_message_text(message.chat.id, message.message_id, output, 'html', true, keyboard)

    elseif data:match('^acmds:%d+$') then
        local page = tonumber(data:match('^acmds:(%d+)$'))
        local items = loader.get_help('admin')
        local page_items, total_pages = get_page(items, page)
        if page < 1 then page = total_pages end
        if page > total_pages then page = 1 end
        page_items, total_pages = get_page(items, page)
        local output = format_help_list(page_items)
        local keyboard = api.inline_keyboard():row(
            api.row():callback_data_button('<', 'help:acmds:' .. (page - 1))
                :callback_data_button(page .. '/' .. total_pages, 'help:noop')
                :callback_data_button('>', 'help:acmds:' .. (page + 1))
        ):row(
            api.row():callback_data_button('Back', 'help:back')
        )
        return api.edit_message_text(message.chat.id, message.message_id, output, 'html', true, keyboard)

    elseif data == 'links' then
        local keyboard = api.inline_keyboard():row(
            api.row():url_button('Development', 'https://t.me/mattataDev')
                :url_button('Channel', 'https://t.me/mattata')
        ):row(
            api.row():url_button('GitHub', 'https://github.com/wrxck/mattata')
                :url_button('Support', 'https://t.me/mattataSupport')
        ):row(
            api.row():callback_data_button('Back', 'help:back')
        )
        return api.edit_message_text(message.chat.id, message.message_id, 'Useful links:', nil, true, keyboard)

    elseif data == 'settings' then
        local permissions = require('src.core.permissions')
        if message.chat.type == 'supergroup' and not permissions.is_group_admin(api, message.chat.id, callback_query.from.id) then
            return api.answer_callback_query(callback_query.id, 'You need to be an admin to change settings.')
        end
        local keyboard = api.inline_keyboard():row(
            api.row():callback_data_button('Administration', 'administration:' .. message.chat.id .. ':page:1')
                :callback_data_button('Plugins', 'plugins:' .. message.chat.id .. ':page:1')
        ):row(
            api.row():callback_data_button('Back', 'help:back')
        )
        return api.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)

    elseif data == 'back' then
        local name = tools.escape_html(callback_query.from.first_name)
        local output = string.format(
            'Hey %s! I\'m <b>%s</b>, a feature-rich Telegram bot.\n\nUse the buttons below to navigate my commands, or type <code>/help &lt;command&gt;</code> for details on a specific command.',
            name, tools.escape_html(api.info.first_name)
        )
        local keyboard = api.inline_keyboard():row(
            api.row():callback_data_button('Commands', 'help:cmds:1')
                :callback_data_button('Admin Help', 'help:acmds:1')
        ):row(
            api.row():callback_data_button('Links', 'help:links')
                :callback_data_button('Settings', 'help:settings')
        )
        return api.edit_message_text(message.chat.id, message.message_id, output, 'html', true, keyboard)

    elseif data == 'noop' then
        return api.answer_callback_query(callback_query.id)
    end
end

return plugin
