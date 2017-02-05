--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local imdb = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function imdb:init(configuration)
    imdb.arguments = 'imdb <query>'
    imdb.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('imdb').table
    imdb.help = '/imdb <query> - Returns an IMDb entry.'
end

function imdb.get_result_count(input)
    local jstr, res = http.request('http://www.omdbapi.com/?s=' .. url.escape(input) .. '&page=1')
    if res ~= 200 then
        return false end
    local jdat = json.decode(jstr)
    if jdat.Response ~= 'True' then
        return false
    end
    return #jdat.Search
end

function imdb.get_result(input, n)
    n = n or 1
    local jstr_search, res_search = http.request('http://www.omdbapi.com/?s=' .. url.escape(input) .. '&page=1')
    if res_search ~= 200 then
        return false
    end
    local jdat_search = json.decode(jstr_search)
    if jdat_search.Response ~= 'True' then
        return false
    end
    local jstr, res = http.request('http://www.omdbapi.com/?i=' .. jdat_search.Search[n].imdbID .. '&r=json&tomatoes=true')
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.Response ~= 'True' then
        return false
    end
    return '<a href="http://imdb.com/title/' .. jdat_search.Search[n].imdbID .. '">' .. mattata.escape_html(jdat.Title) .. '</a> (' .. jdat.Year .. ')\n' .. jdat.imdbRating .. '/10 | ' .. jdat.Runtime .. ' | ' .. jdat.Genre .. '\n' .. '<i>' .. mattata.escape_html(jdat.Plot) .. '</i>'
end

function imdb:on_callback_query(callback_query, message, configuration)
    if callback_query.data:match('^results:(.-)$') then
        local result = callback_query.data:match('^results:(.-)$')
        local input = mattata.input(message.reply_to_message.text)
        local total_results = imdb.get_result_count(input)
        if tonumber(result) > tonumber(total_results) then
            result = 1
        elseif tonumber(result) < 1 then
            result = tonumber(total_results)
        end
        local output = imdb.get_result(
            input,
            tonumber(result)
        )
        if not output then
            return mattata.answer_callback_query(
                callback_query.id,
                'An error occured!'
            )
        end
        local previous_result = 'imdb:results:' .. math.floor(tonumber(result) - 1)
        local next_result = 'imdb:results:' .. math.floor(tonumber(result) + 1)
        local keyboard = {}
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = '← Previous',
                    ['callback_data'] = previous_result
                },
                {
                    ['text'] = result .. '/' .. total_results,
                    ['callback_data'] = 'imdb:pages:' .. result .. ':' .. total_results
                },
                {
                    ['text'] = 'Next →',
                    ['callback_data'] = next_result
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
        local current_page, total_pages = callback_query.data:match('^pages:(.-):(.-)$')
        return mattata.answer_callback_query(
            callback_query.id,
            'You are on page ' .. current_page .. ' of ' .. total_pages .. '!'
        )
    end
end

function imdb:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            imdb.help
        )
    end
    local output = imdb.get_result(input)
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
                ['callback_data'] = 'imdb:results:0'
            },
            {
                ['text'] =  '1/' .. imdb.get_result_count(input),
                ['callback_data'] = 'imdb:pages:1:' .. imdb.get_result_count(input)
            },
            {
                ['text'] = 'Next →',
                ['callback_data'] = 'imdb:results:2'
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

return imdb