--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local id = {}

local mattata = require('mattata')
local json = require('dkjson')

function id:init(configuration)
    id.arguments = 'id <user>'
    id.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('id').table
    id.help = configuration.command_prefix .. 'id <user> - Sends the name, ID, and (if applicable) username for the given user, group, channel or bot. Input is also accepted via reply. This command can also be used inline!'
end

function id.resolve_chat(message)
    local input = message.text or message.query
    input = mattata.input(input)
    local name = ''
    local id = ''
    local username = ''
    local chat_title = ''
    local chat_id = ''
    local chat_username = ''
    local chat_type = ''
    local admin_count = ''
    local user_count = ''
    local last_seen = ''
    if message.reply_to_message then
        if message.reply_to_message.forward_from then
            message.reply_to_message.from = message.reply_to_message.forward_from
        end
        name = '<b>Name:</b> ' .. mattata.escape_html(message.reply_to_message.from.first_name)
        if message.reply_to_message.from.last_name then
            name = name .. ' ' .. mattata.escape_html(message.reply_to_message.from.last_name)
        end
        name = name .. '\n'
        id = '<b>User ID:</b> ' .. message.reply_to_message.from.id .. '\n'
        if message.reply_to_message.from.username then
            username = '<b>Username:</b> @' .. message.reply_to_message.from.username .. '\n'
        end
        if message.reply_to_message.forward_from_chat then
            message.reply_to_message.chat = message.reply_to_message.forward_from_chat
        end
        chat_title = '<b>Chat title:</b> ' .. mattata.escape_html(message.reply_to_message.chat.title) .. '\n'
        chat_id = '<b>Chat ID:</b> ' .. message.reply_to_message.chat.id .. '\n'
        if message.reply_to_message.chat.username then
            chat_username = '<b>Chat username:</b> @' .. message.reply_to_message.chat.username .. '\n'
        end
        chat_type = '<b>Chat type:</b> ' .. message.reply_to_message.chat.type .. '\n'
        return name .. id .. username .. chat_title .. chat_id .. chat_username
    elseif input then
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local res = mattata.request(
            'getChat',
            {
                chat_id = input
            },
            nil,
            'https://api.pwrtelegram.xyz/bot'
        )
        if not res then
            return '\'' .. mattata.escape_html(input) .. '\' is an invalid username/ID.'
        end
        res = res.result
        if res.type == 'private' then
            name = '<b>Name:</b> ' .. mattata.escape_html(res.first_name)
            if res.last_name then
                name = name .. ' ' .. mattata.escape_html(res.last_name)
            end
            name = name .. '\n'
            if res.when then
                last_seen = '<b>Last seen:</b> ' .. res.when .. '\n'
            end
            if res.username then username = '<b>Username:</b> @' .. res.username .. '\n' end
            id = '<b>ID:</b> ' .. res.id .. '\n'
        else
            chat_type = '<b>Type:</b> ' .. res.type .. '\n'
            chat_title = '<b>Title:</b> ' .. mattata.escape_html(res.title) .. '\n'
            if res.admins_count and res.admins_count ~= 0 then
                admin_count = '<b>Admin count:</b> ' .. res.admins_count .. '\n'
            end
            if res.participants_count then
                user_count = '<b>User count:</b> ' .. res.participants_count .. '\n'
            end
            if res.username then
                chat_username = '<b>Username:</b> @' .. res.username .. '\n'
            end
            id = '<b>ID:</b> ' .. res.id .. '\n'
        end
        return name .. chat_title .. chat_type .. id .. chat_id .. username .. last_seen .. user_count .. admin_count
    elseif message.chat then
        return '<b>Your ID:</b> ' .. message.from.id .. '\n<b>This chat\'s ID:</b> ' .. message.chat.id
    else
        return 'Please specify a user, group or channel by stating their username or numerical ID as a command argument. Alternatively, you can reply to a message from, or forwarded from, the user, group or channel you\'d like to target.'
    end
end

function id:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    local output = id.resolve_chat(inline_query)
    local results = json.encode(
        {
            {
                ['type'] = 'article',
                ['id'] = '1',
                ['title'] = tostring(input),
                ['description'] = 'Click to send the result!',
                ['input_message_content'] = {
                    ['message_text'] = tostring(output),
                    ['parse_mode'] = 'html'
                }
            }
        }
    )
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function id:on_message(message)
    return mattata.send_message(
        message.chat.id,
        id.resolve_chat(message),
        'html'
    )
end

return id