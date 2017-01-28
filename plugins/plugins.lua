--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local plugins = {}

local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function plugins:init(configuration)
    plugins.arguments = 'plugins'
    plugins.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('plugins').table
    plugins.help = '/plugins - Toggle the plugins you want to use in your chat with a slick inline keyboard, paginated and neatly formatted.'
end

function plugins.get_toggleable_plugins()
    local toggleable = {}
    for k, v in pairs(configuration.plugins) do
        if v ~= 'plugins' and v ~= 'administration' and v ~= 'control' and v ~= 'bash' and v ~= 'lua' and v ~= 'gwhitelist' and v ~= 'gblacklist' then
            table.insert(
                toggleable,
                v
            )
        end
    end
    local extra_plugins = {
        'ai',
        'captionbotai'
    }
    for k, v in pairs(extra_plugins) do
        table.insert(
            toggleable,
            v
        )
    end
    table.sort(toggleable)
    return toggleable
end

function plugins.get_keyboard(user_id, chat, page, columns, per_page)
    page = page or 1
    local toggleable = plugins.get_toggleable_plugins()
    local page_count = math.floor(#toggleable / per_page)
    if page_count < #toggleable / per_page then
        page_count = page_count + 1
    end
    if page < 1 then
        page = page_count
    elseif page > page_count then
        page = 1
    end
    local start_res = (page * per_page) - (per_page - 1)
    local end_res = start_res + (per_page - 1)
    if end_res > #toggleable then
        end_res = #toggleable
    end
    local plugin = 0
    local output = {}
    for k, v in pairs(toggleable) do
        plugin = plugin + 1
        if plugin >= start_res and plugin <= end_res then
            local status = ''
            if not mattata.is_plugin_disabled(
                v,
                chat
            ) then
                status = '✅'
            else
                status = '❌'
            end
            table.insert(
                output,
                {
                    ['plugin'] = v,
                    ['status'] = status
                }
            )
        end
    end
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local columns_per_page = math.floor(#output / columns)
    if columns_per_page < (#output / columns) then
        columns_per_page = columns_per_page + 1
    end
    local rows_per_page = math.floor(#output / columns_per_page)
    if rows_per_page < (#output / columns_per_page) then
        rows_per_page = rows_per_page + 1
    end
    local current_row = 1
    local count = 0
    for n in pairs(output) do
        count = count + 1
        if count == (rows_per_page * current_row) + 1 then
            current_row = current_row + 1
            table.insert(
                keyboard.inline_keyboard,
                {}
            )
        end
        table.insert(
            keyboard.inline_keyboard[current_row],
            {
                ['text'] = output[n].plugin,
                ['callback_data'] = 'plugins:' .. chat .. ':' .. output[n].plugin .. ':' .. page
            }
        )
        table.insert(
            keyboard.inline_keyboard[current_row],
            {
                ['text'] = output[n].status,
                ['callback_data'] = 'plugins:' .. chat .. ':' .. output[n].plugin .. ':' .. page
            }
        )
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = '← Previous',
                ['callback_data'] = 'plugins:' .. chat .. ':page:' .. page - 1
            },
            {
                ['text'] = page .. '/' .. page_count,
                ['callback_data'] = 'plugins:nil'
            },
            {
                ['text'] = 'Next →',
                ['callback_data'] = 'plugins:' .. chat .. ':page:' .. page + 1
            }
        }
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Disable All',
                ['callback_data'] = 'plugins:' .. chat .. ':disable_all:' .. page
            },
            {
                ['text'] = 'Enable All',
                ['callback_data'] = 'plugins:' .. chat .. ':enable_all:' .. page
            }
        }
    )
    return keyboard
end

function plugins:on_callback_query(callback_query, message, configuration)
    if not callback_query.data:match('^.-%:.-%:.-$') then
        return
    end
    local chat, callback_type, page = callback_query.data:match('^(.-)%:(.-)%:(.-)$')
    if not mattata.is_group_admin(
        chat,
        callback_query.from.id
    ) then
        return mattata.answer_callback_query(
            callback_query.id,
            'You must be an administrator to use this!'
        )
    end
    local toggle_status = 'toggled!'
    if callback_type ~= 'page' then
        local toggleable = plugins.get_toggleable_plugins()
        if callback_type == 'enable_all' then
            for k, v in pairs(toggleable) do
                redis:hset(
                    'chat:' .. chat .. ':disabled_plugins',
                    v,
                    false
                )
            end
            toggle_status = 'enabled!'
        elseif callback_type == 'disable_all' then
            for k, v in pairs(toggleable) do
                redis:hset(
                    'chat:' .. chat .. ':disabled_plugins',
                    v,
                    true
                )
            end
            toggle_status = 'disabled!'
        elseif callback_type == 'enable_via_message' then
            redis:hset(
                'chat:' .. chat .. ':disabled_plugins',
                page,
                false
            )
            return mattata.answer_callback_query(
                callback_query.id,
                page:gsub('^%l', string.upper) .. ' has been enabled!'
            )
        elseif callback_type == 'dismiss_disabled_message' then
            redis:set(
                'chat:' .. chat .. ':dismiss_disabled_message:' .. page,
                true
            )
            return mattata.answer_callback_query(
                callback_query.id,
                'You will no longer be notified about this plugin!'
            )
        else
            if mattata.is_plugin_disabled(
                callback_type,
                chat
            ) then
                redis:hset(
                    'chat:' .. chat .. ':disabled_plugins',
                    callback_type,
                    false
                )
            else
                redis:hset(
                    'chat:' .. chat .. ':disabled_plugins',
                    callback_type,
                    true
                )
            end
        end
    end
    local keyboard = plugins.get_keyboard(callback_query.from.id, chat, tonumber(page), 2, 20)
    local success = mattata.edit_message_reply_markup(
        message.chat.id,
        message.message_id,
        nil,
        json.encode(keyboard)
    )
    if not success then
        return mattata.answer_callback_query(
            callback_query.id,
            'All plugins have already been ' .. toggle_status
        )
    end
end

function plugins:on_message(message, configuration)
    if message.chat.type == 'private' then
        return
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator to use this!'
        )
    end
    local keyboard = plugins.get_keyboard(message.from.id, message.chat.id, 1, 2, 20)
    local success = mattata.send_message(
        message.from.id,
        'Toggle the plugins for <b>' .. mattata.escape_html(message.chat.title) .. '</b> using the keyboard below:',
        'html',
        true,
        false,
        nil,
        json.encode(keyboard)
    )
    if not success then
        return mattata.send_reply(
            message,
            'I couldn\'t send you the plugin management menu, you need to send me a [private message](https://t.me/' .. configuration.info.username .. ') first, then try using /plugins again.',
            'markdown'
        )
    end
    return mattata.send_reply(
        message,
        'I have sent you the plugin management menu via private chat.'
    )
end

return plugins