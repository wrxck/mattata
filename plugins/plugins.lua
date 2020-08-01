--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local plugins = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('libs.redis')
local configuration = require('configuration')

function plugins:init()
    plugins.commands = mattata.commands(self.info.username):command('plugins').table
    plugins.help = '/plugins - Toggle the plugins you want to use in your chat with a slick inline keyboard, paginated and neatly formatted.'
end

function plugins:refresh(chat_id)
    local new = redis:smembers('disabled_plugins:' .. chat_id)
    if #new == 0 then
        new = nil
    end
    if not self.chats[tostring(chat_id)] then
        self.chats[tostring(chat_id)] = {}
    end
    self.chats[tostring(chat_id)].disabled_plugins = new
end

function plugins.get_toggleable_plugins()
    local toggleable = {}
    for _, v in pairs(configuration.plugins) do
        if v ~= 'plugins' and v ~= 'about' and v ~= 'bash' and v ~= 'lua' and v ~= 'reboot'  and v ~= 'administration' then
            v = v:gsub('_', ' ')
            table.insert(toggleable, v)
        end
    end
    table.sort(toggleable)
    return toggleable
end

function plugins:get_keyboard(chat, page, columns, per_page)
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
    for _, v in pairs(toggleable) do
        v = v:lower()
        plugin = plugin + 1
        if plugin >= start_res and plugin <= end_res then
            local status
            if not redis:sismember('disabled_plugins:' .. chat, v) then
                status = utf8.char(9989)
            else
                status = utf8.char(10060)
            end
            table.insert(output, {
                ['plugin'] = v,
                ['status'] = status
            })
        end
    end
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local rows_per_page = math.floor(#output / columns)
    if rows_per_page < (#output / columns) then
        rows_per_page = rows_per_page + 1
    end
    local columns_per_page = math.floor(#output / rows_per_page)
    if columns_per_page < (#output / rows_per_page) then
        columns_per_page = columns_per_page + 1
    end
    local current_row = 1
    local count = 0
    for n in pairs(output) do
        count = count + 1
        if count == (columns_per_page * current_row) + 1 then
            current_row = current_row + 1
            table.insert(
                keyboard.inline_keyboard,
                {}
            )
        end
        table.insert(
            keyboard.inline_keyboard[current_row],
            {
                ['text'] = output[n].plugin:gsub('^%l', string.upper),
                ['callback_data'] = string.format(
                    'plugins:%s:%s:%s',
                    chat,
                    output[n].plugin,
                    page
                )
            }
        )
        table.insert(
            keyboard.inline_keyboard[current_row],
            {
                ['text'] = output[n].status,
                ['callback_data'] = string.format(
                    'plugins:%s:%s:%s',
                    chat,
                    output[n].plugin,
                    page
                )
            }
        )
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = utf8.char(8592) .. ' Previous',
                ['callback_data'] = string.format(
                    'plugins:%s:page:%s',
                    chat,
                    page - 1
                )
            },
            {
                ['text'] = string.format(
                    '%s/%s',
                    page,
                    page_count
                ),
                ['callback_data'] = 'plugins:nil'
            },
            {
                ['text'] = 'Next ' .. utf8.char(8594),
                ['callback_data'] = string.format(
                    'plugins:%s:page:%s',
                    chat,
                    page + 1
                )
            }
        }
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Disable All',
                ['callback_data'] = string.format(
                    'plugins:%s:disable_all:%s',
                    chat,
                    page
                )
            },
            {
                ['text'] = 'Enable All',
                ['callback_data'] = string.format(
                    'plugins:%s:enable_all:%s',
                    chat,
                    page
                )
            }
        }
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Back',
                ['callback_data'] = 'help:settings'
            }
        }
    )
    return keyboard
end

function plugins:on_callback_query(callback_query, message, configuration)
    if not callback_query.data:match('^.-:.-:.-$') then
        return
    end
    local chat, callback_type, page = callback_query.data:match('^(.-):(.-):(.-)$')
    if (
        mattata.get_chat(chat) and mattata.get_chat(chat).result.type ~= 'private'
    ) and not mattata.is_group_admin(
        chat,
        callback_query.from.id
    ) then
        return mattata.answer_callback_query(
            callback_query.id,
            'You must be an administrator to use this!'
        )
    end
    local toggle_status
    if callback_type ~= 'page' then
        local toggleable = plugins.get_toggleable_plugins()
        if callback_type == 'enable_all' then
            for _, v in pairs(toggleable) do
                redis:srem('disabled_plugins:' .. chat, v)
            end
            toggle_status = 'All plugins enabled!'
        elseif callback_type == 'disable_all' then
            for _, v in pairs(toggleable) do
                redis:sadd('disabled_plugins:' .. chat, v)
            end
            toggle_status = 'All plugins disabled!'
        elseif callback_type == 'enable_via_message' or callback_type == 'enable' then
            redis:srem('disabled_plugins:' .. chat, page)
            return mattata.answer_callback_query(
                callback_query.id,
                page:gsub('^%l', string.upper) .. ' has been enabled!'
            )
        elseif callback_type == 'dismiss_disabled_message' then
            redis:set(
                string.format(
                    'chat:%s:dismiss_disabled_message:%s',
                    chat,
                    page
                ),
                true
            )
            return mattata.answer_callback_query(
                callback_query.id,
                'You will no longer be notified about this plugin!'
            )
        else
            if redis:sismember('disabled_plugins:' .. chat, callback_type) then
                redis:srem('disabled_plugins:' .. chat, callback_type)
                toggle_status = callback_type:gsub('^%l', string.upper) .. ' enabled!'
            else
                redis:sadd('disabled_plugins:' .. chat, callback_type)
                toggle_status = callback_type:gsub('^%l', string.upper) .. ' disabled!'
            end
        end
    end
    local keyboard = plugins.get_keyboard(self, chat, tonumber(page), configuration.limits.plugins.columns, configuration.limits.plugins.per_page)
    mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
    plugins.refresh(self, chat)
    return mattata.answer_callback_query(callback_query.id, toggle_status)
end

function plugins:on_message(message, configuration)
    if message.chat.type ~= 'private' and not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator to use this!'
        )
    elseif message.chat.type == 'private' then
        local input = mattata.input(message.text)
        if input then
            if tonumber(input) == nil and not input:match('^%@') then
                input = '@' .. input
            end
            local resolved = mattata.get_chat(input)
            if resolved and mattata.is_group_admin(
                resolved.result.id,
                message.from.id
            ) then
                message.chat = resolved.result
            elseif not resolved then
                return mattata.send_reply(
                    message,
                    'That\'s not a valid chat!'
                )
            else
                return mattata.send_reply(
                    message,
                    'You don\'t appear to be an administrator in that chat!'
                )
            end
        end
    end
    local keyboard = plugins.get_keyboard(self, message.chat.id, 1, configuration.limits.plugins.columns, configuration.limits.plugins.per_page)
    local success = mattata.send_message(
        message.from.id,
        string.format(
            'Toggle the plugins for <b>%s</b> using the keyboard below:',
            message.chat.title and mattata.escape_html(message.chat.title) or mattata.escape_html(message.chat.first_name)
        ),
        'html',
        true,
        false,
        nil,
        json.encode(keyboard)
    )
    if message.chat.type == 'private' then
        return
    elseif not success then
        return mattata.send_reply(
            message,
            string.format(
                'I couldn\'t send you the plugin management menu, you need to send me a [private message](https://t.me/%s?start=plugins%%20' .. message.chat.id .. ') first, then try using /plugins again.',
                self.info.username:lower()
            ),
            'markdown',
            true
        )
    end
    return mattata.send_reply(
        message,
        'I have sent you the plugin management menu via private chat.'
    )
end

return plugins