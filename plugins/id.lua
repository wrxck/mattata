--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local id = {}
local mattata = require('mattata')
local json = require('dkjson')

function id:init()
    id.commands = mattata.commands(self.info.username)
    :command('id')
    :command('whoami').table
    id.help = '/id [chat] - Sends information about the given chat. Input is also accepted via reply. Alias: /whoami.'
end

function id.resolve_chat(message, language)
    if not message.query
    then
        mattata.send_chat_action(message.chat.id)
    end
    local output = {}
    local input = mattata.input(message.text)
    or message.query
    if not input
    and not message.reply
    then
        input = message.from.username
        or message.fromid
    elseif message.reply
    then
        input = message.reply.from.username
        or message.reply.from.id
    end
    if tonumber(input) == nil
    and not input:match('^%@')
    then
        input = '@' .. input
    end
    local success = mattata.get_user(input)
    if not success
    then
        success = mattata.get_chat(input)
        if not success
        then
            return language['id']['1']
        end
    end
    success = success.result
    if message.chat
    and message.chat.type
    and message.chat.type ~= 'private'
    then
        table.insert(
            output,
            '<b>' .. language['id']['2'] .. '</b>'
        )
    end
    if success.id
    then
        table.insert(
            output,
            utf8.char(127380) .. ' ' .. success.id
        )
    end
    if success.type
    then
        table.insert(
            output,
            utf8.char(10145) .. ' ' .. success.type:gsub('^%l', string.upper)
        )
    end
    if success.username
    then
        table.insert(
            output,
            utf8.char(8505) .. ' @' .. success.username
        )
    end
    if success.type == 'private'
    then
        if success.last_name
        then
            success.first_name = string.format(
                '%s %s',
                success.first_name,
                success.last_name
            )
        end
        table.insert(
            output,
            utf8.char(128101) .. ' ' .. mattata.escape_html(success.first_name)
        )
        if success.language_code
        then
            table.insert(
                output,
                utf8.char(127987) .. ' ' .. success.language_code
            )
        end
    else
        table.insert(
            output,
            utf8.char(128101) .. ' ' .. mattata.escape_html(success.title)
        )
    end
    if message.chat
    and message.chat.type
    and message.chat.type ~= 'private'
    then
        table.insert(
            output,
            '\n<b>' .. language['id']['3'] .. '</b>'
        )
        table.insert(
            output,
            utf8.char(128101) .. ' ' .. mattata.escape_html(message.chat.title)
        )
        table.insert(
            output,
            utf8.char(127380) .. ' ' .. message.chat.id
        )
        if message.chat.username
        then
            table.insert(
                output,
                utf8.char(8505) .. ' @' .. message.chat.username
            )
        end
    end
    return table.concat(
        output,
        '\n'
    )
end

function id:on_inline_query(inline_query, configuration, language)
    inline_query.query = mattata.input(inline_query.query)
    or inline_query.from.username
    or inline_query.from.id
    return mattata.answer_inline_query(
        inline_query.id,
        mattata.inline_result()
        :id()
        :type('article')
        :title(
            tostring(inline_query.query)
        )
        :description(language['id']['4'])
        :input_message_content(
            mattata.input_text_message_content(
                tostring(
                    id.resolve_chat(
                        inline_query,
                        language
                    )
                ),
                'html'
            )
        )
    )
end

function id:on_message(message, configuration, language)
    return mattata.send_message(
        message,
        id.resolve_chat(
            message,
            language
        ),
        'html'
    )
end

return id