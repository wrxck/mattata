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
    appstore.help = '/appstore <query> - Returns the first app that iTunes returns for the given search query. Alias: /app.'
end

function appstore.get_app_info(jdat)
    local categories = {}
    for n in pairs(jdat.results[1].genres) do
        table.insert(
            categories,
            jdat.results[1].genres[n]
        )
    end
    local rating = tonumber(jdat.results[1].userRatingCount)
    if rating ~= nil then
        if rating == 1 then
            rating = '⭐ 1 rating'
        elseif rating > 0 and rating ~= nil then
            rating = string.format(
                '⭐ %s ratings (%s)',
                mattata.comma_value(tostring(rating)),
                jdat.results[1].averageUserRating
            )
        else
            rating = string.format(
                '⭐ %s ratings',
                mattata.comma_value(tostring(rating))
            )
        end
    else
        rating = 'N/A'
    end
    if jdat.results[1].description:len() > 250 then
        jdat.results[1].description = jdat.results[1].description:sub(1, 250) .. '...'
    end
    return string.format(
        '<b>%s</b> - v%s, %s/%s/%s\n\n<i>%s</i>\n\n%s\n%s <b>|</b> iOS %s+',
        mattata.escape_html(jdat.results[1].trackName),
        jdat.results[1].version,
        jdat.results[1].currentVersionReleaseDate:sub(9, 10),
        jdat.results[1].currentVersionReleaseDate:sub(6, 7),
        jdat.results[1].currentVersionReleaseDate:sub(1, 4),
        mattata.escape_html(jdat.results[1].description),
        table.concat(
            categories,
            ' <b>|</b> '
        ),
        rating,
        jdat.results[1].minimumOsVersion
    )
end

function appstore:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            appstore.help
        )
    end
    local jstr, res = https.request(
        string.format(
            'https://itunes.apple.com/search?term=%s&lang=%s&entity=software',
            url.escape(input),
            language.locale
        )
    )
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
    end
    return mattata.send_message(
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
                            ['text'] = 'View on iTunes',
                            ['url'] = jdat.results[1].trackViewUrl
                        }
                    }
                }
            }
        )
    )
end

return appstore