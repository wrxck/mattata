--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local itunes = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function itunes:init()
    itunes.commands = mattata.commands(
        self.info.username
    ):command('itunes').table
    itunes.help = [[/itunes <query> - Searches iTunes for the given search query and returns the most relevant result.]]
end

function itunes.get_output(jdat)
    local output = {}
    if jdat.results[1].trackViewUrl and jdat.results[1].trackName then
        table.insert(
            output,
            '<b>Name:</b> <a href=\'' .. jdat.results[1].trackViewUrl .. '\'>' .. mattata.escape_html(jdat.results[1].trackName) .. '</a>'
        )
    end
    if jdat.results[1].artistViewUrl and jdat.results[1].artistName then
        table.insert(
            output,
            string.format(
                '<b>Artist:</b> <a href="%s">%s</a>',
                jdat.results[1].artistViewUrl,
                mattata.escape_html(jdat.results[1].artistName)
            )
        )
    end
    if jdat.results[1].collectionViewUrl and jdat.results[1].collectionName then
        table.insert(
            output,
            string.format(
                '<b>Album:</b> <a href="%s">%s</a>',
                jdat.results[1].collectionViewUrl,
                mattata.escape_html(jdat.results[1].collectionName)
            )
        )
    end
    if jdat.results[1].trackNumber and jdat.results[1].trackCount then
        table.insert(
            output,
            string.format(
                '<b>Track:</b> %s/%s',
                jdat.results[1].trackNumber,
                jdat.results[1].trackCount
            )
        )
    end
    if jdat.results[1].discNumber and jdat.results[1].discCount then
        table.insert(
            output,
            string.format(
                '<b>Disc:</b> %s/%s',
                jdat.results[1].discNumber,
                jdat.results[1].discCount
            )
        )
    end
    return table.concat(
        output,
        '\n'
    )
end

function itunes:on_inline_query(inline_query)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input))
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    if not jdat.results[1] then
        return
    end
    local count = 0
    local results = {}
    local temp = {}
    for k, v in pairs(jdat.results) do
        if v.artworkUrl100 and not temp[v.collectionId] then
            count = count + 1
            table.insert(
                results,
                mattata.inline_result():type('photo'):id(count):photo_url(
                    v.artworkUrl100:gsub('%/100x100bb%.jpg', '/10000x10000bb.jpg')
                ):thumb_url(v.artworkUrl100)
            )
            table.insert(
                temp,
                v.collectionId
            )
        end
    end
    temp = nil
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function itunes:on_callback_query(callback_query, message, configuration)
    if not message.reply then
        return mattata.answer_callback_query(
            callback_query.id,
            'The original query could not be found, you\'ve probably deleted the original message.',
            true
        )
    end
    local input = mattata.input(message.reply.text)
    if callback_query.data == 'artwork' then
        local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input))
        if res ~= 200 then
            return false
        end
        local jdat = json.decode(jstr)
        if not jdat.results[1] then
            return false
        end
        if jdat.results[1].artworkUrl100 then
            local artwork = jdat.results[1].artworkUrl100:gsub('%/100x100bb%.jpg', '/10000x10000bb.jpg') -- Get the highest quality artwork available
            mattata.send_photo(
                message.chat.id,
                artwork
            )
            return mattata.edit_message_text(
                message.chat.id,
                message.message_id,
                'The artwork can be found below:'
            )
        end
    end
end

function itunes:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            itunes.help
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.results[1] then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
        itunes.get_output(jdat),
        'html',
        true,
        false,
        message.message_id,
        mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                'Get Album Artwork',
                'itunes:artwork'
            )
        )
    )
end

return itunes