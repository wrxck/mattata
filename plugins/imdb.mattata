--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local imdb = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function imdb:init()
    imdb.commands = mattata.commands(self.info.username):command('imdb').table
    imdb.help = '/imdb <query> - Searches IMDb for the given search query and returns the most relevant result(s).'
end

function imdb.get_result_count(input)
    local jstr, res = http.request('http://www.omdbapi.com/?s=' .. url.escape(input) .. '&page=1')
    if res ~= 200
    then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.Response ~= 'True'
    then
        return false
    end
    return #jdat.Search
end

function imdb.get_result(input, n)
    n = n or 1
    local jstr_search, res_search = http.request('http://www.omdbapi.com/?s=' .. url.escape(input) .. '&page=1')
    if res_search ~= 200
    then
        return false
    end
    local jdat_search = json.decode(jstr_search)
    if jdat_search.Response ~= 'True'
    then
        return false
    end
    local jstr, res = http.request('http://www.omdbapi.com/?i=' .. jdat_search.Search[n].imdbID .. '&r=json&tomatoes=true')
    if res ~= 200
    then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.Response ~= 'True'
    then
        return false
    end
    return '<a href="http://imdb.com/title/' .. jdat_search.Search[n].imdbID .. '">' .. mattata.escape_html(jdat.Title) .. '</a> (' .. jdat.Year .. ')\n' .. jdat.imdbRating .. '/10 | ' .. jdat.Runtime .. ' | ' .. jdat.Genre .. '\n' .. '<i>' .. mattata.escape_html(jdat.Plot) .. '</i>'
end

function imdb:on_callback_query(callback_query, message, configuration, language)
    if not message.reply
    then
        return
    elseif callback_query.data:match('^results:(.-)$')
    then
        local result = callback_query.data:match('^results:(.-)$')
        local input = mattata.input(message.reply.text)
        local total_results = imdb.get_result_count(input)
        if tonumber(result) > tonumber(total_results)
        then
            result = 1
        elseif tonumber(result) < 1
        then
            result = tonumber(total_results)
        end
        local output = imdb.get_result(
            input,
            tonumber(result)
        )
        if not output
        then
            return mattata.answer_callback_query(
                callback_query.id,
                language['errors']['generic']
            )
        end
        local previous_result = 'imdb:results:' .. math.floor(tonumber(result) - 1)
        local next_result = 'imdb:results:' .. math.floor(tonumber(result) + 1)
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            output,
            'html',
            true,
            mattata.inline_keyboard():row(
                mattata.row()
                :callback_data_button(
                    mattata.symbols.back .. ' ' .. language['imdb']['1'],
                    previous_result
                )
                :callback_data_button(
                    result .. '/' .. total_results,
                    'imdb:pages:' .. result .. ':' .. total_results
                )
                :callback_data_button(
                    language['imdb']['2'] .. ' ' .. mattata.symbols.next,
                    next_result
                )
            )
        )
    elseif callback_query.data:match('^pages:(.-):(.-)$')
    then
        local current_page, total_pages = callback_query.data:match('^pages:(.-):(.-)$')
        return mattata.answer_callback_query(
            callback_query.id,
            string.format(
                language['imdb']['3'],
                current_page,
                total_pages
            )
        )
    end
end

function imdb:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            imdb.help
        )
    end
    local output = imdb.get_result(input)
    if not output
    then
        return mattata.send_reply(
            message,
            language['errors']['results']
        )
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'html',
        true,
        false,
        message.message_id,
        mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(
                mattata.symbols.back .. ' ' .. language['imdb']['1'],
                'imdb:results:0'
            )
            :callback_data_button(
                '1/' .. imdb.get_result_count(input),
                'imdb:pages:1:' .. imdb.get_result_count(input)
            )
            :callback_data_button(
                language['imdb']['2'] .. ' ' .. mattata.symbols.next,
                'imdb:results:2'
            )
        )
    )
end

return imdb