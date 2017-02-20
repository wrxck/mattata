--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local remind = {}

local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function remind:init()
    remind.commands = mattata.commands(
        self.info.username
    ):command('remind')
     :command('reminders').table
    remind.help = '/remind <duration> <message> - Repeats a message after a duration of time, in the format 1w2d3h4m. The maximum number of reminders at one time is 4 per chat, and each reminder must be between 1 minute and 4 weeks in duration. Reminders cannot be any more than 256 characters in length. Use /reminders to view your current reminders. An example use of this command would be: /remind 1w2d3h4m test, which would remind you in 1 week, 2 days, 3 hours and 4 minutes.'
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
    for k, v in pairs(reminders) do
        if v.chat and v.chat.id == message.chat.id then
            table.insert(
                this_chat,
                string.format(
                    utf8.char(8226) .. ' %s <code>[Added by %s, expires in approx. %s second%s]</code>',
                    mattata.escape_html(v.reminder),
                    mattata.escape_html(v.from),
                    mattata.round(v.expires - os.time()),
                    mattata.round(
                        (v.expires - os.time())
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

function remind:on_message(message)
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
    local weeks = 0
    if duration:match('%d[Ww]') then
        weeks = tonumber(
            duration:match('(%d*)[Ww]')
        ) * 10080
    end
    local days = 0
    if duration:match('%d[Dd]') then
        days = tonumber(
            duration:match('(%d*)[Dd]')
        ) * 1440
    end
    local hours = 0
    if duration:match('%d[Hh]') then
        hours = tonumber(
            duration:match('(%d*)[Hh]')
        ) * 60
    end
    local minutes = 0
    if duration:match('%d[Mm]') then
        minutes = tonumber(
            duration:match('(%d*)[Mm]')
        )
    end
    duration = weeks + days + hours + minutes
    if duration == 0 then
        return mattata.send_reply(
            message,
            'The duration you specified isn\'t in a valid format. The duration of your reminder must be between 1 minute and 4 weeks, and in the format 1w2d3h4m, which would remind you in 1 week, 2 days, 3 hours and 4 minutes.'
        )
    elseif duration > 40320 or duration < 1 then
        return mattata.send_reply(
            message,
            'The duration of your reminder must be between 1 and 10080 minutes.'
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
            ['expires'] = os.time() + (duration * 60),
            ['chat'] = {
                ['id'] = message.chat.id,
                ['title'] = message.chat.title
            },
            ['from'] = message.from.name or message.chat.title
        }
    )
    redis:set(
        'reminders',
        json.encode(reminders)
    )
    return mattata.send_reply(
        message,
        string.format(
            'I will remind you in %s minute%s!',
            duration,
            tonumber(duration) == 1 and '' or 's'
        )
    )
end

function remind:m_cron()
    local current_time = os.time()
    local reminders = redis:get('reminders')
    if not reminders then
        return
    end
    reminders = json.decode(reminders)
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