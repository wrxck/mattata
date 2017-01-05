--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local yify = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function yify:init(configuration)
    yify.arguments = 'yify <query>'
    yify.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('yify').table
    yify.help = configuration.command_prefix .. 'yify <query> - Searches Yify torrents for the given query.'
end

function yify.get_result_count(input)
    local jstr, res = https.request('https://yts.ag/api/v2/list_movies.json?query_term=' .. url.escape(input) .. '&limit=50')
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if not jdat.data.movies then
        return false
    end
    return #jdat.data.movies
end

function yify.get_result(input, n)
    n = n or 1
    local jstr, res = https.request('https://yts.ag/api/v2/list_movies.json?query_term=' .. url.escape(input))
    if res ~= 200 then
        return false, nil
    end
    local jdat = json.decode(jstr)
    if not jdat.data.movies then
        return false, nil
    end
    local buttons = {}
    for n = 1, #jdat.data.movies[n].torrents do
        table.insert(
            buttons,
            {
                ['text'] = jdat.data.movies[n].torrents[n].quality,
                ['url'] = jdat.data.movies[n].torrents[n].url
            }
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        buttons
    }
    local title = mattata.escape_html(jdat.data.movies[result].title_long):gsub(' %(%d%d%d%d%)$', '')
    if jdat.data.movies[result].large_cover_image then
        title = '<a href="' .. jdat.data.movies[result].large_cover_image .. '">' .. title .. '</a>'
    end
    local description = mattata.escape_html(jdat.data.movies[result].synopsis)
    if description:len() > 500 then
        description = description:sub(1, 500) .. '...'
    end
    return title .. '\n' .. jdat.data.movies[result].year .. ' | ' .. jdat.data.movies[result].rating .. '/10 | ' .. jdat.data.movies[result].runtime .. ' min\n\n<i>' .. description .. '</i>', keyboard
end

function yify:on_callback_query(callback_query, message, configuration)
    if callback_query.data:match('^results:(.-)$') then
        local result = callback_query.data:match('^results:(.-)$')
        local input = mattata.input(message.reply_to_message.text)
        local total_results = yify.get_result_count(input)
        if tonumber(result) > tonumber(total_results) then
            result = 1
        elseif tonumber(result) < 1 then
            result = tonumber(total_results)
        end
        local output, keyboard = yify.get_result(
            input,
            tonumber(result)
        )
        if not output then
            return mattata.answer_callback_query(
                callback_query.id,
                'An error occured!'
            )
        end
        local previous_result = 'yify:results:' .. math.floor(tonumber(result) - 1)
        local next_result = 'yify:results:' .. math.floor(tonumber(result) + 1)
        table.insert(
            keyboard.inline_keyboard,
            {
                {
                    ['text'] = '← Previous',
                    ['callback_data'] = previous_result
                },
                {
                    ['text'] = result .. '/' .. total_results,
                    ['callback_data'] = 'yify:pages:' .. result .. ':' .. total_results
                },
                {
                    ['text'] = 'Next →',
                    ['callback_data'] = next_result
                }
            }
        )
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            output,
            'html',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^pages:(.-):(.-)$') then
        local current_page, total_pages = callback_query.data:match('^pages:(.-):(.-)$')
        return mattata.answer_callback_query(
            callback_query.id,
            'You are on page ' .. current_page .. ' of ' .. total_pages .. '!'
        )
    end
end

function yify:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            yify.help
        )
    end
    local output, keyboard = yify.get_result(input)
    if not output then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = '← Previous',
                ['callback_data'] = 'yify:results:0'
            },
            {
                ['text'] =  '1/' .. yify.get_result_count(input),
                ['callback_data'] = 'yify:pages:1:' .. yify.get_result_count(input)
            },
            {
                ['text'] = 'Next →',
                ['callback_data'] = 'yify:results:2'
            }
        }
    )
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

return yify