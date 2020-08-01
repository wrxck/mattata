--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local todo = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function todo:init()
    todo.commands = mattata.commands(self.info.username):command('todo').table
    todo.help = '/todo [text] - If no arguments are given, allows you to view your to-do list. Otherwise, it adds the given'
end

function todo.get_keyboard(all)
    if not all or #all == 0 then
        return false
    end
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    for pos, item in pairs(all) do
        if item:len() > 69 then -- Max text for buttons is 69.
            item = item:sub(1, 69)
        end
        table.insert(keyboard.inline_keyboard, {{
            ['text'] = item,
            ['callback_data'] = 'todo:' .. pos .. ':view'
        }, {
            ['text'] = utf8.char(9989),
            ['callback_data'] = 'todo:' .. pos .. ':done'
        }})
    end
    return keyboard
end

function todo.on_callback_query(_, callback_query, message, _, language)
    if message.chat.type == 'supergroup' and not mattata.is_group_admin(message.chat.id, callback_query.from.id) then
        return mattata.answer_callback_query(callback_query.id, language.errors.admin)
    end
    local existing = redis:smembers('todo:' .. message.chat.id)
    if not next(existing) then
        return mattata.edit_message_text(message.chat.id, message.message_id, 'You\'ve got nothing to-do! For now...')
    end
    local pos, action = callback_query.data:match('^(%d*):(%a+)$')
    pos = math.floor(tonumber(pos))
    if not existing[pos] then
        mattata.answer_callback_query(callback_query.id, 'It appears this to-do has already been completed!')
        local keyboard = todo.get_keyboard(existing)
        return mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
    end
    if action == 'view' then
        return mattata.answer_callback_query(callback_query.id, existing[pos], true)
    elseif action == 'done' then
        redis:srem('todo:' .. (message.chat.id or message.from.id), existing[pos])
        mattata.answer_callback_query(callback_query.id, 'I\'ve marked that to-do as completed!')
        if #existing == 1 then
            return mattata.edit_message_text(message.chat.id, message.message_id, 'You don\'t have any to-dos at the moment. Add one using /todo [text].')
        end
        existing = redis:smembers('todo:' .. message.chat.id)
        local keyboard = todo.get_keyboard(existing)
        return mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
    end
    return false
end


function todo.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if input then
        input = { input }
    end
    if input and input[1]:match('\n') then
        local new = {}
        for line in input[1]:gmatch('([^\n]*)\n?') do
            if line:gsub('%s', '') ~= '' then
                table.insert(new, line)
            end
        end
        if #new >= 1 then
            input = new
        end
    end
    if message.chat.type == 'supergroup' and not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local existing = redis:smembers('todo:' .. message.chat.id)
    if not input then
        if not next(existing) then
            return mattata.send_reply(message, 'You don\'t have any to-dos at the moment. Add one using /todo [text].')
        end
        local keyboard = todo.get_keyboard(existing)
        local output = 'Here is your current to-do list'
        if message.chat.type == 'supergroup' then
            output = output .. ' for ' .. message.chat.title .. '. To view your personal to-do list, send this command to me in private chat!'
        else output = output .. ':' end
        return mattata.send_message(message.chat.id, output, nil, true, false, nil, keyboard)
    end
    for _, line in pairs(input) do
        if #existing == 50 then
            return mattata.send_reply(message, 'Wow, you\'ve got a lot to do! But I\'m afraid you can\'t have more than 50 to-dos! Mark one as done and try this command again.')
        elseif line:len() > 200 then
            return mattata.send_reply(message, 'To-dos can\'t be longer than 200 characters!')
        end
        redis:sadd('todo:' .. message.chat.id, line)
        existing = redis:smembers('todo:' .. message.chat.id)
    end
    return mattata.send_reply(message, 'I\'ve added that on your to-do list!')
end

return todo
