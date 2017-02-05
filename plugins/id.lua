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
    local success = mattata.get_chat_pwr(input)
    if not success or not success.result then
        return 'I couldn\'t find any results for that.'
    end
    success = success.result
    if success.id then
        table.insert(
            output,
            '<b>ID:</b> ' .. success.id
        )
    end
    if success.type then
        table.insert(
            output,
            '<b>Chat Type:</b> ' .. success.type
        )
    end
    if success.username then
        table.insert(
            output,
            '<b>Username:</b> ' .. success.username
        )
    end
    if success.first_name then
        table.insert(
            output,
            '<b>First Name:</b> ' .. mattata.escape_html(success.first_name)
        )
    end
    if success.last_name then
        table.insert(
            output,
            '<b>Last Name:</b> ' .. mattata.escape_html(success.last_name)
        )
    end
    if success.verified then
        table.insert(
            output,
            '<b>Official?</b> ' .. success.verified
        )
    end
    if success.phone then
        table.insert(
            output,
            '<b>Phone Number:</b> ' .. success.phone
        )
    end
    if success.restricted then
        table.insert(
            output,
            '<b>Restricted?</b> ' .. success.restricted
        )
    end
    if success.title then
        table.insert(
            output,
            '<b>Chat Title:</b> ' .. mattata.escape_html(success.title)
        )
    end
    if success.bio then
        table.insert(
            output,
            '<b>Bio:</b> ' .. mattata.escape_html(mattata.trim(success.bio))
        )
    end
    return table.concat(
        output,
        '\n'
    )
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