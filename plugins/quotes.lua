--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local quotes = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('libs.redis')

function quotes:init()
    quotes.commands = mattata.commands(self.info.username):command('quotes').table
    quotes.help = '/quotes - Edit which quotes are saved in the database under your name.'
end

function quotes.get_quote(user, quote_number)
    quote_number = tonumber(quote_number)
    local quotes = redis:get('quotes:' .. user)
    if not quotes
    then
        return 'You don\'t have any quotes!'
    end
    quotes = json.decode(quotes)
    if #quotes < quote_number
    then
        return 'Invalid quote number!'
    end
    return quotes[quote_number]
end

function quotes.get_confirmation_keyboard(user, quote_number, page)
    quote_number = tonumber(quote_number)
    local all = redis:get('quotes:' .. user)
    if not all
    then
        return {}
    end
    all = json.decode(all)
    if not all[quote_number]
    then
        return {}
    end
    return mattata.inline_keyboard():row(
        mattata.row()
        :callback_data_button(
            'Delete',
            'quotes:' .. user .. ':delete:' .. quote_number
        )
        :callback_data_button(
            'Back',
            'quotes:' .. user .. ':back:' .. page
        )
    )
end

function quotes.get_quotes(user)
    local all = redis:get('quotes:' .. user)
    if not all
    then
        return false
    end
    return json.decode(all)
end

function quotes.get_keyboard(user, page, columns, per_page)
    page = page
    or 1
    local toggleable = quotes.get_quotes(user)
    if not toggleable
    then
        return false
    end
    local page_count = math.floor(#toggleable / per_page)
    if page_count < #toggleable / per_page
    then
        page_count = page_count + 1
    end
    if page < 1
    then
        page = page_count
    elseif page > page_count
    then
        page = 1
    end
    local start_res = (page * per_page) - (per_page - 1)
    local end_res = start_res + (per_page - 1)
    if end_res > #toggleable
    then
        end_res = #toggleable
    end
    local quote = 0
    local output = {}
    for k, v in pairs(toggleable)
    do
        quote = quote + 1
        if quote >= start_res
        and quote <= end_res
        then
            table.insert(
                output,
                {
                    ['quote_number'] = k,
                    ['quote_text'] = v
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
    if columns_per_page < (#output / columns)
    then
        columns_per_page = columns_per_page + 1
    end
    local rows_per_page = math.floor(#output / columns_per_page)
    if rows_per_page < (#output / columns_per_page)
    then
        rows_per_page = rows_per_page + 1
    end
    local current_row = 1
    local count = 0
    for n in pairs(output)
    do
        count = count + 1
        if count == (rows_per_page * current_row) + 1
        then
            current_row = current_row + 1
            table.insert(
                keyboard.inline_keyboard,
                {}
            )
        end
        table.insert(
            keyboard.inline_keyboard[current_row],
            {
                ['text'] = tostring(output[n].quote_number) .. ': ' .. output[n].quote_text,
                ['callback_data'] = string.format(
                    'quotes:%s:%s:%s',
                    user,
                    output[n].quote_number,
                    page
                )
            }
        )
    end
    if page_count > 1
    then
        table.insert(
            keyboard.inline_keyboard,
            {
                {
                    ['text'] = utf8.char(8592) .. ' Previous',
                    ['callback_data'] = string.format(
                        'quotes:%s:page:%s',
                        user,
                        page - 1
                    )
                },
                {
                    ['text'] = string.format(
                        '%s/%s',
                        page,
                        page_count
                    ),
                    ['callback_data'] = 'quotes:nil'
                },
                {
                    ['text'] = 'Next ' .. utf8.char(8594),
                    ['callback_data'] = string.format(
                        'quotes:%s:page:%s',
                        user,
                        page + 1
                    )
                }
            }
        )
    end
    if count <= 0
    then
        return false
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Delete All',
                ['callback_data'] = string.format(
                    'quotes:%s:delete_all:%s',
                    user,
                    page
                )
            }
        }
    )
    return keyboard
end

function quotes:on_callback_query(callback_query, message, configuration)
    if not callback_query.data:match('^.-:.-:.-$')
    then
        return
    end
    local user, callback_type, page = callback_query.data:match('^(.-):(.-):(.-)$')
    if tostring(callback_query.from.id) ~= tostring(user)
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'You are not allowed to use this!'
        )
    end
    if callback_type == 'delete_all'
    then
        if redis:get('quotes:' .. callback_query.from.id)
        then
            redis:del('quotes:' .. callback_query.from.id)
        end
    elseif callback_type == 'back' or callback_type == 'page'
    then
        local success = mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select a quote:',
            nil,
            false,
            quotes.get_keyboard(
                callback_query.from.id,
                tonumber(page),
                2,
                10
            )
        )
        if not success
        then
            return mattata.edit_message_text(
                message.chat.id,
                message.message_id,
                'All quotes saved under your database entry have already been deleted!'
            )
        end
        return
    elseif callback_type == 'delete'
    then
        if not redis:get('quotes:' .. callback_query.from.id)
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'All quotes saved under your database entry have already been deleted!'
            )
        end
        local all = json.decode(
            redis:get('quotes:' .. callback_query.from.id)
        )
        page = tonumber(page)
        if not all[page]
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'This quote no longer exists!'
            )
        end
        all[page] = nil
        redis:set(
            'quotes:' .. callback_query.from.id,
            json.encode(all)
        )
        return mattata.answer_callback_query(
            callback_query.id,
            'That quote has been deleted from my database!'
        )
    elseif callback_type == 'back'
    then
        return mattata.edit_message_reply_markup(
            message.chat.id,
            message.message_id,
            nil,
            quotes.get_keyboard(
                callback_query.from.id,
                tonumber(page),
                2,
                10
            )
        )
    end
    local keyboard = quotes.get_confirmation_keyboard(
        callback_query.from.id,
        callback_type,
        page
    )
    local success = mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        quotes.get_quote(
            callback_query.from.id,
            callback_type
        ),
        nil,
        false,
        json.encode(keyboard)
    )
    if not success
    then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'All quotes saved under your database entry have been deleted!'
        )
    end
end

function quotes:on_message(message, configuration)
    local keyboard = quotes.get_keyboard(
        message.from.id,
        1,
        2,
        10
    )
    if not keyboard
    then
        return mattata.send_reply(
            message,
            'You don\'t have any quotes saved in my database! Use /save in reply to one of your messages to save it!'
        )
    end
    return mattata.send_message(
        message.chat.id,
        'Please select a quote:',
        nil,
        true,
        false,
        nil,
        json.encode(keyboard)
    )
end

return quotes