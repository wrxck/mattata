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
    ):command('id')
     :command('whois').table
    id.help = '/id <user> - Sends the name, ID, and (if applicable) username for the given user, group, channel or bot. Input is also accepted via reply. Alias: /whois.'
end

function id.resolve_chat(message)
    local output = {}
    local input = message.text or message.query
    input = mattata.input(input)
    if not input and not message.reply_to_message then
        input = message.from.id
    elseif message.reply_to_message then
        input = message.reply_to_message.from.id
    end
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    local success = mattata.get_user(input)
    if not success then
        success = mattata.get_chat(input)
        if not success then
            return 'I\'m sorry, but I don\'t recognise that user. To teach me who they are, forward a message from them to me or get them to send me a message.'
        end
    end
    success = success.result
    if message.chat and message.chat.type and message.chat.type ~= 'private' then
        table.insert(
            output,
            '<b>Queried Chat:</b>'
        )
    end
    if success.id then
        table.insert(
            output,
            '🆔 ' .. success.id
        )
    end
    if success.type then
        table.insert(
            output,
            '➡️ ' .. success.type:gsub('^%l', string.upper)
        )
    end
    if success.username then
        table.insert(
            output,
            'ℹ️ @' .. success.username
        )
    end
    if success.type == 'private' then
        if success.last_name then
            success.first_name = string.format(
                '%s %s',
                success.first_name,
                success.last_name
            )
        end
        table.insert(
            output,
            '👤 ' .. mattata.escape_html(success.first_name)
        )
    else
        table.insert(
            output,
            '👤 ' .. mattata.escape_html(success.title)
        )
    end
    if message.chat and message.chat.type and message.chat.type ~= 'private' then
        table.insert(
            output,
            '\n<b>This Chat:</b>'
        )
        table.insert(
            output,
            '👥 ' .. mattata.escape_html(message.chat.title)
        )
        table.insert(
            output,
            '🆔 ' .. message.chat.id
        )
        if message.chat.username then
            table.insert(
                output,
                'ℹ️ @' .. message.chat.username
            )
        end
    end
    return table.concat(
        output,
        '\n'
    )
end

function id:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        input = inline_query.from.id
    end
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