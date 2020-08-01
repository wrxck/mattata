--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local movies = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function movies:init(configuration)
    movies.commands = mattata.commands(self.info.username):command('movies?'):command('imdb'):command('films?').table
    movies.help = '/movie <query> - Searches IMDb for the given search query and returns the most relevant result(s). Aliases: /imdb, /film.'
    movies.key = configuration.keys.movies
    movies.url = string.format('http://www.omdbapi.com/?apikey=%s&page=1&s=', movies.key.omdb)
end

function movies.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, movies.help)
    end
    local jstr_search, res_search = http.request(movies.url .. url.escape(input))
    if res_search ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat_search = json.decode(jstr_search)
    if jdat_search.Response ~= 'True' then
        return mattata.send_reply(message, language.errors.results)
    end
    local jstr, res = http.request('http://www.omdbapi.com/?i=' .. jdat_search.Search[1].imdbID .. '&r=json&tomatoes=true&apikey=' .. movies.key.omdb)
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.Response ~= 'True' then
        return false
    end
    local poster
    poster, res = https.request('https://www.myapifilms.com/imdb/idIMDB?idIMDB=' .. jdat.imdbID .. '&token=' .. movies.key.poster)
    if res == 200 then
        poster = json.decode(poster)
        if not poster.error and poster.data.movies[1].urlPoster then
            poster = poster.data.movies[1].urlPoster:gsub('(U%a%d*)(_%a%a%d,%d,%d*)(,%d*)', '%10%20%30')
        end
    else -- We'll set it to a placeholder image I've already got stored on Telegram's servers, we can always update this.
        poster = 'AgACAgQAAx0CVClmWQACHGNe-VQxIvsfNMOn5jJceOVhfc4llQACpLAxG0qiyFNNvPCVaco5ZKoWdiNdAAMBAAMCAAN5AAOqagEAARoE'
    end
    local output = string.format('<a href="https://imdb.com/title/%s">%s</a> (%s)\n%s/10 | %s | %s\n\n<em>%s</em>', jdat_search.Search[1].imdbID, mattata.escape_html(jdat.Title), jdat.Year, jdat.imdbRating, jdat.Runtime, jdat.Genre, mattata.escape_html(jdat.Plot))
    if not poster or not output then
        return mattata.send_reply(message, language.errors.results)
    end
    return mattata.send_photo(message.chat.id, poster, output, 'html', false)
end

return movies