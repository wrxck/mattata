--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local id = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function id:init()
    id.commands = mattata.commands(self.info.username):command('id'):command('user'):command('whoami').table
    id.help = '/id [chat] - Sends information about the given chat. Input is also accepted via reply. Only /user will display user statistics. Aliases: /user, /whoami.'
end

function id.resolve_chat(input, language, send_chat_action, current_group, show_user_stats, api_mode)
    local output = {}
    if not input then
        return false
    elseif send_chat_action and current_group then
        mattata.send_chat_action(current_group, 'typing')
    end
    local success = mattata.get_user(input, false, true) or mattata.get_chat(input)
    if not success or not success.result then
        if api_mode then
            return false
        end
        return language['id']['1']
    end
    if success.result.type == 'private' then
        local name = success.result.first_name
        if success.result.last_name then
            name = name .. ' ' .. success.result.last_name
        end
        local nickname = redis:hget('user:' .. success.result.id .. ':info', 'nickname')
        if nickname then
            nickname = ', AKA <em>' .. mattata.escape_html(nickname) .. '</em>'
        else
            nickname = ''
        end
        table.insert(output, mattata.get_formatted_user(success.result.id, name, 'html') .. nickname .. ' <code>[' .. success.result.id .. ']</code>')
        if success.result.username then
            table.insert(output, '@' .. success.result.username)
            local previous = redis:smembers('user:' .. success.result.id .. ':usernames')
            if #previous > 1 then
                for pos, usr in pairs(previous) do
                    if usr == success.result.username:lower() then
                        table.remove(previous, pos)
                    else
                        previous[pos] = '@' .. previous[pos]:lower()
                    end
                end
                previous = table.concat(previous, ', ')
                table.insert(output, '<b>Previous Usernames:</b> <code>' .. previous .. '</code>')
            end
        end
        if success.result.bio and success.result.bio ~= '' then
            table.insert(output, '<b>Bio:</b> <code>' .. mattata.escape_html(success.result.bio) .. '</code>')
        end
        local feds = id.get_fed_info(success.result.id)
        for _, line in pairs(feds) do
            table.insert(output, line)
        end
        if current_group and show_user_stats then
            local chat_member = mattata.get_chat_member(current_group, success.result.id)
            if not chat_member or not chat_member.result.status then
                table.insert(output, '\n<em>Not seen in this group!</em>')
            else
                local bans = redis:hget(string.format('chat:%s:%s', current_group, success.result.id), 'bans') or 0
                local kicks = redis:hget(string.format('chat:%s:%s', current_group, success.result.id), 'kicks') or 0
                local warnings = redis:hget(string.format('chat:%s:%s', current_group, success.result.id), 'warnings') or 0
                local unbans = redis:hget(string.format('chat:%s:%s', current_group, success.result.id), 'unbans') or 0
                local messages = redis:get('messages:' .. success.result.id .. ':' .. current_group) or 0
                local seen = #redis:keys('messages:' .. success.result.id .. ':*')
                table.insert(output, '\n<b>Group status:</b> <em>' .. chat_member.result.status .. '</em>')
                table.insert(output, '<b>Bans:</b> <em>' .. bans .. '</em>')
                table.insert(output, '<b>Kicks:</b> <em>' .. kicks .. '</em>')
                table.insert(output, '<b>Warnings:</b> <em>' .. warnings .. '</em>')
                table.insert(output, '<b>Unbans:</b> <em>' .. unbans .. '</em>')
                table.insert(output, '<b>Messages:</b> <em>' .. messages .. '</em>')
                table.insert(output, '<em>Seen in ' .. seen .. ' group(s)</em>')
            end
        end
    else
        table.insert(output, mattata.escape_html(success.result.title) .. ' <code>[' .. success.result.id .. '</code> (' .. success.result.type .. ')')
        if success.result.username then
            table.insert(output, '@' .. success.result.username)
        end
        if current_group ~= success.result.id then
            if success.result.description and success.result.description ~= '' then
                table.insert(output, '<b>Description:</b> <code>' .. mattata.escape_html(success.result.description) .. '</code>')
            end
        end
    end
    return output
end

function id.get_fed_info(user_id)
    local banned_from = redis:keys('fedban:*:' .. user_id)
    local banned_amount = #banned_from
    local output = {}
    table.insert(output, 'Banned from <code>' .. banned_amount .. '</code> Fed(s)')
    if banned_amount > 0 then
        table.insert(output, '<em>Use /fbaninfo to see why you\'ve been banned!</em>')
    end
    return output
end

function id.on_inline_query(_, inline_query, _, language)
    local input = mattata.input(inline_query.query) or inline_query.from.id
    local output = id.resolve_chat(input, language)
    output = type(output) == 'table' and table.concat(output, '\n') or output
    return mattata.answer_inline_query(
        inline_query.id,
        mattata.inline_result()
        :id()
        :type('article')
        :title(tostring(inline_query.query))
        :description(language['id']['4'])
        :input_message_content(
            mattata.input_text_message_content(output, 'html')
        )
    )
end

function id.on_message(_, message, _, language)
   message.text = message.text:lower()
   local is_reply, is_reply_chat, old_chat_object = false, false, message.chat
    if message.reply then
        is_reply = true
        message.from = message.reply.from
        message.chat = message.reply.chat
        if message.reply.forward_from then
            message.from = message.reply.forward_from
        end
        if message.reply.forward_from_chat then
            is_reply_chat = true
            message.chat = message.reply.forward_from_chat
        end
    end
    mattata.send_chat_action(old_chat_object.id)
    local has_input = mattata.input(message.text)
    local input = mattata.input(message.text) or message.from.id
    local current_group = message.chat.type == 'supergroup' and message.chat.id or false
    local show_user_stats = message.text:match('^[!/#]user') and true or false
    local output = id.resolve_chat(input, language, true, current_group, show_user_stats)
    if not has_input and message.chat.type ~= 'private' and ((not is_reply) or is_reply_chat) and not show_user_stats then
        table.insert(output, '')
        local chat = id.resolve_chat(message.chat.id, language, false, current_group)
        for _, v in pairs(chat) do
            table.insert(output, v)
        end
    end
    if is_reply_chat then
        message.chat = old_chat_object
    end
    output = type(output) == 'table' and table.concat(output, '\n') or output
    return mattata.send_message(message.chat.id, output, 'html')
end

return id