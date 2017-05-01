--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local paste = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')
local configuration = require('configuration')

function paste:init()
    paste.commands = mattata.commands(self.info.username):command('paste').table
    paste.help = '/paste <text> - Uploads the given text to a pasting service and returns the result URL.'
end

function paste.get_keyboard()
    return mattata.inline_keyboard()
    :row(
        mattata.row()
        :callback_data_button(
            'paste.ee',
            'paste:pasteee'
        )
        :callback_data_button(
            'pastebin.com',
            'paste:pastebin'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'hastebin.com',
            'paste:hastebin'
        )
        :callback_data_button(
            'pasta.cf',
            'paste:pastacf'
        )
    )
end

function paste.pasteee(input, id)
    input = 'key=' .. configuration.keys.pasteee .. '&description=' .. id .. '%20via%20mattata&paste=' .. url.escape(input) .. '&format=simple&return=download'
    local response = {}
    local _, res = http.request(
        {
            ['url'] = 'http://paste.ee/api',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'application/x-www-form-urlencoded',
                ['Content-Length'] = input:len()
            },
            ['source'] = ltn12.source.string(input),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200
    then
        return false
    end
    return table.concat(response)
end

function paste.pastebin(input)
    local parameters = {
        ['api_dev_key'] = configuration.keys.pastebin,
        ['api_option'] = 'paste',
        ['api_paste_code'] = input
    }
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local _, res = http.request(
        {
            ['url'] = 'http://pastebin.com/api/api_post.php',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
                ['Content-Length'] = #body
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200
    then
        return false
    end
    return table.concat(response)
end

function paste.hastebin(input)
    local parameters = {
        ['data'] = input
    }
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local _, res, head = http.request(
        {
            ['url'] = 'http://hastebin.com/documents',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
                ['Content-Length'] = #body
            },
            ['redirect'] = false,
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200
    then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat
    or not jdat.key
    then
        return false
    end
    return 'http://hastebin.com/' .. jdat.key
end

function paste.pastacf(input)
    input = 'filename=&content=' .. url.escape(input) .. '&pasta_type=standard'
    local _, res, headers = https.request({
        ['url'] = 'https://pasta.cf/pasta/create',
        ['method'] = 'POST',
        ['headers'] = {
            ['Content-Type'] = 'application/x-www-form-urlencoded',
            ['Content-Length'] = input:len()
        },
        ['source'] = ltn12.source.string(input)
    })
    if res ~= 302
    or not headers['location']
    then
        return false
    end
    return headers['location']
end

function paste:on_callback_query(callback_query, message, configuration, language)
    local input = mattata.input(message.reply.text)
    if not input
    then
        return false
    end
    local output
    if callback_query.data == 'pasteee'
    then
        output = paste.pasteee(
            input,
            callback_query.from.id
        )
    elseif callback_query.data == 'pastebin'
    then
        output = paste.pastebin(input)
    elseif callback_query.data == 'hastebin'
    then
        output = paste.hastebin(input)
    elseif callback_query.data == 'pastacf'
    then
        output = paste.pastacf(input)
    end
    if not output
    then
        return mattata.answer_callback_query(
            callback_query.id,
            language['errors']['generic']
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        nil,
        true,
        paste.get_keyboard()
    )
end

function paste:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            paste.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        language['paste']['1'],
        nil,
        true,
        false,
        message.message_id,
        paste.get_keyboard()
    )
end

return paste