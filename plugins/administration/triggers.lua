--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local triggers = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function triggers:init()
    triggers.commands = mattata.commands(self.info.username):command('triggers'):command('trigger'):command('custom').table
    triggers.help = '/triggers - Allows admins to view and delete existing word triggers. Aliases: /trigger, /custom.'
end

function triggers:on_new_message(message)
    if message.command or message.is_media or self.is_ai then
        return false
    end
    local matches = redis:hgetall('triggers:' .. message.chat.id)
    if not next(matches) == 0 then
        return false
    end
    for trigger, value in pairs(matches) do
        if message.text:lower():match(trigger:lower()) then
            local trail
            if trigger:lower() == 'ayy' and value:lower() == 'lmao' then
                trail = message.text:lower():match('(ayy+)'):gsub('^ay', '')
                value = 'lma' .. string.rep('o', trail:len())
            elseif trigger:lower() == 'lmao' and value:lower() == 'ayy' then
                trail = message.text:lower():match('(lmao+)'):gsub('^lma', '')
                value = 'ay' .. string.rep('y', trail:len())
            end
            if value:len() > 4096 then
                value = value:sub(1, 4093) .. '...'
            end
            if value:match('%b{}') then
                for k, v in pairs(message.from) do
                    if type(v) == 'string' then
                        message.from[k] = v:gsub('%%', '%%%%')
                    end
                end
                for k, v in pairs(message.chat) do
                    if type(v) == 'string' then
                        message.chat[k] = v:gsub('%%', '%%%%')
                    end
                end
                local last_name = message.from.last_name or ''
                local username = message.from.username and '@' .. message.from.username or ''
                value = value:gsub('{name}', message.from.name):gsub('{firstname}', message.from.first_name):gsub('{userid}', message.from.id):gsub('{lastname}', last_name):gsub('{username}', username)
                if message.chat.type == 'supergroup' then
                    value = value:gsub('{title}', message.chat.title):gsub('{chatid}', message.chat.id)
                    local user_count = ''
                    if value:match('{usercount}') then
                        user_count = mattata.get_chat_members_count(message.chat.id).result
                    end
                    local invite_link = redis:hget('chat:' .. message.chat.id .. ':info', 'link') or ''
                    local chat_username = message.chat.username and '@' .. message.chat.username or ''
                    value = value:gsub('{usercount}', user_count):gsub('{invitelink}', invite_link):gsub('{chatusername}', chat_username)
                end
            end
            if not message.is_edited then
                local success = mattata.send_message(message.chat.id, value)
                if success then
                    redis:set('bot:' .. message.chat.id .. ':' .. message.message_id, success.result.message_id)
                end
                return success
            else
                local message_id = redis:get('bot:' .. message.chat.id .. ':' .. message.message_id)
                if message_id then
                    return mattata.edit_message_text(message.chat.id, message_id, value)
                end
            end
        end
    end
    return
end

function triggers.get_trigger(chat_id, trigger)
    local get = redis:hget('triggers:' .. chat_id, trigger)
    if not get then
        return 'This trigger doesn\'t exist!'
    end
    return get
end

function triggers.get_confirmation_keyboard(chat_id, trigger, page)
    if not redis:hget('triggers:' .. chat_id, trigger) then
        return false
    end
    return mattata.inline_keyboard():row(
        mattata.row()
        :callback_data_button(
            mattata.symbols.back .. ' Back',
            'triggers:' .. chat_id .. ':back:' .. page
        )
        :callback_data_button(
            'Delete',
            'triggers:' .. chat_id .. ':delete:' .. trigger
        )
    )
end

function triggers.get_triggers(chat_id)
    local all = redis:hgetall('triggers:' .. chat_id)
    if not next(all) then
        return false
    end
    local output = {}
    for trigger, _ in pairs(all) do
        table.insert(output, trigger)
    end
    return output
end

function triggers.get_keyboard(chat_id, page, columns, per_page)
    page = page or 1
    local toggleable = triggers.get_triggers(chat_id)
    if not toggleable then
        return false
    end
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
    local trigger_pos = 0
    local output = {}
    for _, v in pairs(toggleable) do
        trigger_pos = trigger_pos + 1
        if trigger_pos >= start_res and trigger_pos <= end_res then
            table.insert(output, v)
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
            table.insert(keyboard.inline_keyboard, {})
        end
        table.insert(keyboard.inline_keyboard[current_row], {
            ['text'] = output[n],
            ['callback_data'] = string.format(
                'triggers:%s:%s:%s', chat_id,
                output[n], page
            )
        })
    end
    if page_count > 1 then
        table.insert(keyboard.inline_keyboard, {{
            ['text'] = mattata.symbols.back .. ' Previous',
            ['callback_data'] = string.format(
                'triggers:%s:page:%s',
                chat_id,
                page - 1
            )
        }, {
            ['text'] = string.format(
                '%s/%s',
                page,
                page_count
            ),
            ['callback_data'] = 'triggers:nil'
        }, {
            ['text'] = 'Next ' .. mattata.symbols.next,
            ['callback_data'] = string.format(
                'triggers:%s:page:%s',
                chat_id,
                page + 1
            )
        }})
    end
    if count <= 0 then
        return false
    end
    return keyboard
end

function triggers.on_callback_query(_, callback_query, message)
    if not callback_query.data:match('^.-:.-:.-$') then
        return
    end
    local chat_id, callback_type, page = callback_query.data:match('^(.-):(.-):(.-)$')
    if not mattata.is_group_admin(chat_id, callback_query.from.id) then
        return mattata.answer_callback_query(callback_query.id, 'You are not allowed to use this!')
    end
    if callback_type == 'back' or callback_type == 'page' then
        local success = mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select a trigger:',
            nil, false,
            triggers.get_keyboard(
                chat_id,
                tonumber(page), 2, 10
            )
        )
        if not success then
            return mattata.edit_message_text(
                message.chat.id,
                message.message_id,
                'All triggers saved for this chat have already been deleted!'
            )
        end
        return mattata.answer_callback_query(callback_query.id)
    elseif callback_type == 'delete' then
        local all = redis:hgetall('triggers:' .. chat_id)
        if not next(all) then
            return mattata.answer_callback_query(callback_query.id, 'All triggers saved for this chat have already been deleted!')
        end
        local selected = all[page]
        if not selected then
            return mattata.answer_callback_query(callback_query.id, 'This trigger no longer exists!')
        end
        redis:hdel('triggers:' .. chat_id, page)
        return mattata.answer_callback_query(callback_query.id, 'That trigger has been deleted from my database!')
    elseif callback_type == 'back' then
        return mattata.edit_message_reply_markup(
            message.chat.id,
            message.message_id,
            nil,
            triggers.get_keyboard(
                chat_id,
                tonumber(page), 2, 10
            )
        )
    end
    local keyboard = triggers.get_confirmation_keyboard(
        chat_id,
        callback_type,
        page
    )
    local value = triggers.get_trigger(chat_id, callback_type)
    value = mattata.escape_html(value)
    local success = mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        '<b>' .. callback_type .. '</b> is set to trigger <em>' .. value .. '</em>', 'html', false,
        keyboard
    )
    if not success then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'All triggers saved for this chat have already been deleted!'
        )
    end
end

function triggers.on_message(_, message)
    local keyboard = triggers.get_keyboard(message.chat.id, 1, 2, 10)
    if not keyboard then
        return mattata.send_reply(message, 'This chat does\'t have any triggers saved in my database! Use /addtrigger <trigger> <value> to add one!')
    end
    return mattata.send_message(message.chat.id, 'Please select a trigger:', nil, true, false, nil, keyboard)
end

return triggers