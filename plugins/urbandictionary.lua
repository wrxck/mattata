--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local urbandictionary = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function urbandictionary:init(configuration)
    urbandictionary.arguments = 'urbandictionary <query>'
    urbandictionary.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('urbandictionary'):command('urban'):command('ud').table
    urbandictionary.help = '/urbandictionary <query> - Returns the Urban Dictionary\'s definition for the given word. Aliases: ' .. configuration.command_prefix .. 'urban, ' .. configuration.command_prefix .. 'ud.'
end

function urbandictionary:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local jstr, res = http.request('http://api.urbandictionary.com/v0/define?term=' .. url.escape(input))
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    local results = {}
    local id = 1
    for n in pairs(jdat.list) do
        table.insert(
            results,
            {
                ['type'] = 'article',
                ['id'] = tostring(id),
                ['title'] = jdat.list[n].word,
                ['description'] = jdat.list[n].definition,
                ['input_message_content'] = {
                    ['message_text'] = '<b>' .. mattata.escape_html(jdat.list[n].word) .. '</b>\n\n' .. mattata.escape_html(jdat.list[n].definition),
                    ['parse_mode'] = 'html'
                }
            }
        )
        id = id + 1
    end
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(results)
    )
end

function urbandictionary.get_result_count(input)
    local jstr, res = http.request('http://api.urbandictionary.com/v0/define?term=' .. url.escape(input))
    if res ~= 200 then
        return 0
    end
    local jdat = json.decode(jstr)
    if jdat.result_type == 'no_results' then
        return 0
    end
    return #jdat.list
end

function urbandictionary.get_result(input, n)
    n = n or 1
    local jstr, res = http.request('http://api.urbandictionary.com/v0/define?term=' .. url.escape(input))
    if res ~= 200 then
        return false, false
    end
    local jdat = json.decode(jstr)
    if jdat.result_type == 'no_results' then
        return false, false
    end
    if not jdat.list[n].example then
        return false, false
    end
    local definition = mattata.escape_html(jdat.list[n].definition)
    definition = definition:gsub('%[word%](.-)%[%/word%]', '<a href="https://www.urbandictionary.com/define.php?term=%1">%1</a>'):gsub('%[(.-)%]', '<a href="https://www.urbandictionary.com/define.php?term=%1">%1</a>')
    local output = '<b>' .. jdat.list[n].word .. '</b>\n\n' .. mattata.trim(definition)
    local example = mattata.escape_html(jdat.list[n].example):gsub('%[word%]', ''):gsub('%[%/word%]', '')
    local thumbs_up = '👍 ' .. jdat.list[n].thumbs_up
    local thumbs_down = '👎 ' .. jdat.list[n].thumbs_down
    local author = '💁 ' .. '<a href="https://www.urbandictionary.com/author.php?author=' .. url.escape(jdat.list[n].author) .. '">' .. mattata.escape_html(jdat.list[n].author) .. '</a>'
    return output .. '\n\n<i>' .. mattata.trim(example) .. '</i>\n\n' .. thumbs_up .. ' | ' .. thumbs_down .. ' | ' .. author, jdat.list[n].defid
end

function urbandictionary:on_callback_query(callback_query, message, configuration)
    if not message.reply_to_message then
        return
    end
    if callback_query.data:match('^results:(%d*)$') then
        local result = callback_query.data:match('^results:(%d*)$')
        local input = mattata.input(message.reply_to_message.text)
        local total_results = urbandictionary.get_result_count(input)
        if tonumber(result) > tonumber(total_results) then
            result = 1
        elseif tonumber(result) < 1 then
            result = tonumber(total_results)
        end
        local output, def_id = urbandictionary.get_result(
            input,
            tonumber(result)
        )
        if not output then
            return mattata.answer_callback_query(
                callback_query.id,
                'An error occured!'
            )
        end
        local previous_result = 'urbandictionary:results:' .. math.floor(tonumber(result) - 1)
        local next_result = 'urbandictionary:results:' .. math.floor(tonumber(result) + 1)
        local keyboard = {}
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = '← Previous',
                    ['callback_data'] = previous_result
                },
                {
                    ['text'] = result .. '/' .. total_results,
                    ['callback_data'] = 'urbandictionary:pages:' .. result .. ':' .. total_results
                },
                {
                    ['text'] = 'Next →',
                    ['callback_data'] = next_result
                }
            },
            {
                {
                    ['text'] = 'Get this definition on a mug!',
                    ['url'] = 'https://urbandictionary.store/products/mug?defid=' .. def_id
                }
            }
        }
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            output,
            'html',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^pages:(.-):(.-)$') then
        local current, total = callback_query.data:match('^pages:(.-):(.-)$')
        return mattata.answer_callback_query(
            callback_query.id,
            string.format(
                'You are on page %s of %s!',
                tostring(current),
                tostring(total)
            )
        )
    end
end

function urbandictionary:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            urbandictionary.help
        )
    end
    local output, def_id = urbandictionary.get_result(input)
    if not output then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = '← Previous',
                ['callback_data'] = 'urbandictionary:results:0'
            },
            {
                ['text'] = '1/' .. urbandictionary.get_result_count(input),
                ['callback_data'] = 'urbandictionary:pages:1:' .. urbandictionary.get_result_count(input)
            },
            {
                ['text'] = 'Next →',
                ['callback_data'] = 'urbandictionary:results:2'
            },
        },
        {
            {
                ['text'] = 'Get this definition on a mug!',
                ['url'] = 'https://urbandictionary.store/products/mug?defid=' .. def_id
            }
        }
    }
    return mattata.send_message(
        message.chat.id,
        output,
        'html',
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return urbandictionary