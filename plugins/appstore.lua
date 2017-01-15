--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local appstore = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function appstore:init(configuration)
    appstore.arguments = 'appstore <query>'
    appstore.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('appstore')
     :command('app').table
    appstore.help = '/appstore <query> - Returns the first app which iTunes returns for the given search query. Alias: /app.'
end

function appstore.get_app_info(jdat)
    local categories = {}
    for n in pairs(jdat.results[1].genres) do
        table.insert(
            categories,
            jdat.results[1].genres[n]
        )
    end
    local rating = jdat.results[1].userRatingCount
    if rating == 1 then
        rating = '⭐ 1 rating'
    elseif rating > 0 and rating ~= nil then
        rating = '⭐ ' .. mattata.comma_value(tostring(rating)) .. ' ratings (' .. jdat.results[1].averageUserRating .. ')'
    else
        rating = '⭐ ' .. mattata.comma_value(tostring(rating)) .. ' ratings'
    end
    return '<b>' .. mattata.escape_html(jdat.results[1].trackName) .. '</b> - v' .. jdat.results[1].version .. ', ' .. jdat.results[1].currentVersionReleaseDate:sub(9, 10) .. '/' .. jdat.results[1].currentVersionReleaseDate:sub(6, 7) .. '/' .. jdat.results[1].currentVersionReleaseDate:sub(1, 4) .. '\n\n<i>' .. mattata.escape_html(jdat.results[1].description):sub(1, 250) .. '...</i>\n\n' .. table.concat(categories, ' <b>|</b> ') .. '\n' .. rating .. ' <b>|</b> iOS ' .. jdat.results[1].minimumOsVersion .. '+'
end

function appstore:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            appstore.help
        )
    end
    local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input) .. '&lang=' .. configuration.language .. '&entity=software')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jdat.resultCount == 0 then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end    return mattata.send_message(
        message.chat.id,
        appstore.get_app_info(jdat),
        'html',
        true,
        false,
        nil,
        json.encode(
            {
                ['inline_keyboard'] = {
                    {
                        {
                            text = 'View on iTunes',
                            url = jdat.results[1].trackViewUrl
                        }
                    }
                }
            }
        )
    )
end

return appstore