--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local twitch = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local configuration = require('configuration')

function twitch:init()
    twitch.commands = mattata.commands(
        self.info.username
    ):command('twitch').table
    twitch.help = [[/twitch <query> - Searches Twitch for the given search query and returns the most relevant result(s).]]
end

function twitch.get_result_count(input)
    local jstr, res = https.request('https://api.twitch.tv/kraken/search/streams?q=' .. url.escape(input) .. '&client_id=' .. configuration.keys.twitch)
    if res ~= 200 then
        return 0
    end
    local jdat = json.decode(jstr)
    if jdat._total == 0 then
        return 0
    end
    return #jdat.streams
end

function twitch.get_result(input, n)
    n = n or 1
    local jstr, res = https.request('https://api.twitch.tv/kraken/search/streams?q=' .. url.escape(input) .. '&client_id=' .. configuration.keys.twitch)
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat._total == 0 then
        return false
    end
    local output = ''
    if jdat.streams[n].channel.url and jdat.streams[n].channel.display_name then
        output = output .. '<a href="' .. jdat.streams[n].channel.url .. '">' .. mattata.escape_html(jdat.streams[n].channel.display_name) .. '</a>\n'
    end
    if jdat.streams[n].channel.game then
        output = output .. '🎮 ' .. mattata.escape_html(jdat.streams[n].channel.game) .. '\n'
    end
    if jdat.streams[n].viewers then
        output = output .. '👁 ' .. mattata.comma_value(tostring(jdat.streams[n].viewers)) .. '\n'
    end
    if jdat.streams[n].video_height then
        output = output .. '🖥 ' .. jdat.streams[n].video_height .. 'p'
        if jdat.streams[n].average_fps then
            output = output .. ', ' .. mattata.round(jdat.streams[n].average_fps) .. ' FPS'
        end
    end
    return output
end

function twitch:on_callback_query(callback_query, message, configuration)
    if callback_query.data:match('^results:(.-)$') then
        local result = callback_query.data:match('^results:(.-)$')
        local input = mattata.input(message.reply.text)
        local total_results = twitch.get_result_count(input)
        if tonumber(result) > tonumber(total_results) then
            result = 1
        elseif tonumber(result) < 1 then
            result = tonumber(total_results)
        end
        local output = twitch.get_result(
            input,
            tonumber(result)
        )
        if not output then
            return mattata.answer_callback_query(
                callback_query.id,
                'An error occured!'
            )
        end
        local previous_result = 'twitch:results:' .. math.floor(tonumber(result) - 1)
        local next_result = 'twitch:results:' .. math.floor(tonumber(result) + 1)
        local keyboard = {}
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = '← Previous',
                    ['callback_data'] = previous_result
                },
                {
                    ['text'] = result .. '/' .. total_results,
                    ['callback_data'] = 'twitch:pages:' .. result
                },
                {
                    ['text'] = 'Next →️',
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
        local current, total = callback_query.data:match('^pages:(.-):(.-)$')
        return mattata.answer_callback_query(
            callback_query.id,
            string.format(
                'You are on page %s of %s!',
                tostring(current),
                tostring(total)
            )
        )
    end
end

function twitch:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            twitch.help
        )
    end
    local output = twitch.get_result(input)
    if not output then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = '← Previous',
                ['callback_data'] = 'twitch:results:0'
            },
            {
                ['text'] = '1/' .. twitch.get_result_count(input),
                ['callback_data'] = 'twitch:pages:1:' .. twitch.get_result_count(input)
            },
            {
                ['text'] = 'Next →️',
                ['callback_data'] = 'twitch:results:2'
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

return twitch