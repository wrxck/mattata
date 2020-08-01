--[[
    Based on a plugin by topkecleon. Licensed under GNU AGPLv3
    https://github.com/topkecleon/otouto/blob/master/LICENSE.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local remind = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('libs.redis')

function remind:init()
    remind.commands = mattata.commands(self.info.username):command('remind'):command('reminders').table
    remind.help = '/remind <duration> <message> - Repeats a message after a duration of time, in the format 2d3h. The maximum number of reminders at one time is 4 per chat, and each reminder must be between 1 hour and 182 days in duration. Reminders cannot be any more than 256 characters in length. Use /reminders to view your current reminders. An example use of this command would be: /remind 21d3h test, which would remind you in 21 days and 3 hours.'
end

function remind.get_reminders(message)
    local reminders = {}
    if redis:get('reminders') then
        reminders = json.decode(
            redis:get('reminders')
        )
    end
    local this_chat = {}
    local count = 0
    for _, v in pairs(reminders) do
        if v.chat and v.chat.id == message.chat.id then
            table.insert(
                this_chat,
                string.format(
                    utf8.char(8226) .. ' %s <code>[Added by %s, expires in approx. %s hour%s]</code>',
                    mattata.escape_html(v.reminder),
                    mattata.escape_html(v.name),
                    mattata.round(
                        (
                            tonumber(v.expires) - os.time()
                        ) / 3600,
                        2
                    ),
                    mattata.round(
                        (
                            tonumber(v.expires) - os.time()
                        ) / 3600,
                        2
                    ) == 1 and '' or 's'
                )
            )
            count = count + 1
        end
    end
    if count == 0 then
        return mattata.send_reply(
            message,
            'You don\'t have any reminders set up in this chat!'
        )
    end
    return mattata.send_reply(
        message,
        string.format(
            'You currently have %s reminder%s set up for %s:\n%s',
            count,
            count == 1 and '' or 's',
            mattata.escape_html(message.chat.title),
            table.concat(
                this_chat,
                '\n'
            )
        ),
        'html'
    )
end

function remind.on_message(_, message)
    if message.text:match('^[%/%!%$%^%?%&%%]reminders') then
        return remind.get_reminders(message)
    end
    local input = mattata.input(message.text)
    if not input or not input:match('^.- .-$') then
        return mattata.send_reply(
            message,
            remind.help
        )
    end
    local duration, reminder = input:match('^(.-) (.-)$')
    -- Convert each unit of time into seconds.
    local weeks = 0
    if duration:match('%d[Ww]') then
        weeks = tonumber(
            duration:match('(%d*)[Ww]')
        ) * 604800
    end
    local days = 0
    if duration:match('%d[Dd]') then
        days = tonumber(
            duration:match('(%d*)[Dd]')
        ) * 86400
    end
    local hours = 0
    if duration:match('%d[Hh]') then
        hours = tonumber(
            duration:match('(%d*)[Hh]')
        ) * 3600
    end
    duration = weeks + days + hours
    if duration <= 0 then
        return mattata.send_reply(
            message,
            'The duration you specified isn\'t in a valid format. The duration of your reminder must be between 1 hour and 6 months, and in the format 5m1w12d3h, which would remind you in 5 months, 1 week, 12 days and 3 hours.'
        )
    elseif duration > 31620000 or duration < 1 then
        return mattata.send_reply(
            message,
            'The duration of your reminder must be between 1 hour and 366 days.'
        )
    end
    if utf8.len(reminder) > 256 then
        return mattata.send_reply(
            message,
            'Your reminder must not be any longer than 256 characters.'
        )
    end
    local reminders = {}
    if redis:get('reminders') then
        reminders = json.decode(
            redis:get('reminders')
        )
    end
    local count = 0
    for k, v in pairs(reminders) do
        if v.chat and v.chat.id == message.chat.id then
            count = count + 1
        end
    end
    if count >= 4 then
        return mattata.send_reply(
            message,
            'You already have 4 reminders set up in this chat. Please wait for one to expire before you add any more!'
        )
    end
    table.insert(
        reminders,
        {
            ['reminder'] = reminder,
            ['expires'] = os.time() + duration,
            ['chat'] = {
                ['id'] = message.chat.id,
                ['title'] = message.chat.title
            },
            ['name'] = message.from.name or message.chat.title
        }
    )
    redis:set(
        'reminders',
        json.encode(reminders)
    )
    duration = duration / 3600 -- Convert back to hours.
    return mattata.send_reply(
        message,
        string.format(
            'I will remind you in %s hour%s!',
            mattata.round(duration),
            tonumber(duration) == 1 and '' or 's'
        )
    )
end

function remind:cron()
    local current_time = os.time()
    local reminders = redis:get('reminders')
    if not reminders then return false end
    reminders = json.decode(reminders)
    if not next(reminders) then return false end
    for k, v in pairs(reminders) do
        if current_time > v.expires then
            mattata.send_message(
                v.chat.id,
                'Reminder: ' .. v.reminder
            )
            table.remove(
                reminders,
                k
            )
        end
    end
    redis:set(
        'reminders',
        json.encode(reminders)
    )
    return
end

return remind