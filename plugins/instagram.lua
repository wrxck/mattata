--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local instagram = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')

function instagram:init()
    instagram.commands = mattata.commands(self.info.username)
    :command('instagram')
    :command('ig').table
    instagram.help = '/instagram <Instagram username> - Sends the profile picture of the given Instagram user. Alias: /ig.'
end

function instagram:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
    if not input
    then
        return
    end
    local body = 'instagram_name=' .. input
    local response = {}
    local _, res = http.request(
        {
            ['url'] = 'http://instadp.com/run.php',
            ['method'] = 'POST',
            ['headers'] = {
                ['Host'] = 'instadp.com',
                ['Content-Length'] = body:len(),
                ['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8',
                ['Cookie'] = '_asomcnc=1',
                ['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
                ['X-Requested-With'] = 'XMLHttpRequest'
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    local str = table.concat(response)
    if res ~= 200
    then
        return mattata.send_inline_article(
            inline_query.id,
            language['errors']['generic'],
            language['errors']['connection']
        )
    elseif not str:match('%<a href%=%"%#%" onclick%=%"window%.open%(%\'(https%:%/%/.-%.com%/.-)%\'%, %\'%_blank%\'%)%;%"%>')
    then
        return mattata.send_inline_article(
            inline_query.id,
            language['errors']['generic'],
            language['errors']['results']
        )
    end
    return mattata.send_inline_photo(
        inline_query.id,
        str:match('%<a href%=%"%#%" onclick%=%"window%.open%(%\'(https%:%/%/.-%.com%/.-)%\'%, %\'%_blank%\'%)%;%"%>')
    )
end

function instagram:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            instagram.help
        )
    end
    local body = 'instagram_name=' .. input
    local response = {}
    local _, res = http.request(
        {
            ['url'] = 'http://instadp.com/run.php',
            ['method'] = 'POST',
            ['headers'] = {
                ['Host'] = 'instadp.com',
                ['Content-Length'] = body:len(),
                ['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8',
                ['Cookie'] = '_asomcnc=1',
                ['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
                ['X-Requested-With'] = 'XMLHttpRequest'
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    local str = table.concat(response)
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    elseif not str:match('%<a href%=%"%#%" onclick%=%"window%.open%(%\'(https%:%/%/.-%.com%/.-)%\'%, %\'%_blank%\'%)%;%"%>')
    then
        return mattata.send_reply(
            message,
            language['errors']['results']
        )
    end
    return mattata.send_photo(
        message.chat.id,
        str:match('%<a href%=%"%#%" onclick%=%"window%.open%(%\'(https%:%/%/.-%.com%/.-)%\'%, %\'%_blank%\'%)%;%"%>'),
        nil,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():url_button(
                string.format(
                    language['instagram']['1'],
                    input
                ),
                'https://www.instagram.com/' .. input
            )
        )
    )
end

return instagram