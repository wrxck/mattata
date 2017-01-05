--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local itunes = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function itunes:init(configuration)
    itunes.arguments = 'itunes <song>'
    itunes.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('itunes').table
    itunes.help = configuration.command_prefix .. 'itunes <song> - Returns information about the given song, from iTunes.'
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
            '<b>Artist:</b> <a href=\'' .. jdat.results[1].artistViewUrl .. '\'>' .. mattata.escape_html(jdat.results[1].artistName) .. '</a>'
        )
    end
    if jdat.results[1].collectionViewUrl and jdat.results[1].collectionName then
        table.insert(
            output,
            '<b>Album:</b> <a href=\'' .. jdat.results[1].collectionViewUrl .. '\'>' .. mattata.escape_html(jdat.results[1].collectionName) .. '</a>'
        )
    end
    if jdat.results[1].trackNumber and jdat.results[1].trackCount then
        table.insert(
            output,
            '<b>Track:</b> ' .. jdat.results[1].trackNumber .. '/' .. jdat.results[1].trackCount
        )
    end
    if jdat.results[1].discNumber and jdat.results[1].discCount then
        table.insert(
            output,
            '<b>Disc:</b> ' .. jdat.results[1].discNumber .. '/' .. jdat.results[1].discCount
        )
    end
    return table.concat(
        output,
        '\n'
    )
end

function itunes:on_callback_query(callback_query, message, configuration, language)
    local input = mattata.input(message.reply_to_message.text)
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
            local artwork = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
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

function itunes:on_message(message, configuration, language)
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
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.results[1] then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'Get Album Artwork',
                ['callback_data'] = 'itunes:artwork'
            }
        }
    }
    return mattata.send_message(
        message.chat.id,
        itunes.get_output(jdat),
        'html',
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return itunes