--[[
    mattata v2.0 - Remind Plugin
    Sets timed reminders stored in Redis with a cron job to check expirations.
    Supports duration parsing (e.g., 2h30m, 1d, 45m, 90s).
    Max 4 active reminders per chat per user.
]]

local plugin = {}
plugin.name = 'remind'
plugin.category = 'utility'
plugin.description = 'Set and manage reminders'
plugin.commands = { 'remind', 'reminders' }
plugin.help = '/remind <duration> <message> - Set a reminder (e.g., /remind 2h30m take out the bins).\n/reminders - List your active reminders.'

local tools = require('telegram-bot-lua.tools')

local MAX_REMINDERS = 4
local MAX_DURATION = 7 * 24 * 3600  -- 7 days
local REDIS_PREFIX = 'reminder:'

-- Parse a duration string like "2h30m", "1d", "45m", "90s", "1h", "2d12h"
local function parse_duration(str)
    if not str or str == '' then
        return nil
    end

    -- Try pure number (assume minutes)
    local pure_num = tonumber(str)
    if pure_num then
        return math.floor(pure_num * 60)
    end

    local total = 0
    local found = false

    -- Days
    local d = str:match('(%d+)%s*d')
    if d then
        total = total + tonumber(d) * 86400
        found = true
    end

    -- Hours
    local h = str:match('(%d+)%s*h')
    if h then
        total = total + tonumber(h) * 3600
        found = true
    end

    -- Minutes
    local m = str:match('(%d+)%s*m')
    if m then
        total = total + tonumber(m) * 60
        found = true
    end

    -- Seconds
    local s = str:match('(%d+)%s*s')
    if s then
        total = total + tonumber(s)
        found = true
    end

    if not found or total <= 0 then
        return nil
    end

    return total
end

-- Format seconds into a human-readable string
local function format_duration(seconds)
    if seconds < 60 then
        return seconds .. ' second' .. (seconds == 1 and '' or 's')
    end
    local parts = {}
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    if days > 0 then
        table.insert(parts, days .. 'd')
    end
    if hours > 0 then
        table.insert(parts, hours .. 'h')
    end
    if mins > 0 then
        table.insert(parts, mins .. 'm')
    end
    if secs > 0 and days == 0 then
        table.insert(parts, secs .. 's')
    end
    return table.concat(parts, ' ')
end

-- Get all reminder keys for a user in a chat
local function get_user_reminders(redis, chat_id, user_id)
    local pattern = string.format('%s%s:%s:*', REDIS_PREFIX, tostring(chat_id), tostring(user_id))
    return redis.keys(pattern) or {}
end

-- Get all reminder keys globally (for cron)
local function get_all_reminders(redis)
    return redis.keys(REDIS_PREFIX .. '*') or {}
end

function plugin.on_message(api, message, ctx)
    local redis = ctx.redis

    -- /reminders - list active reminders
    if message.command == 'reminders' then
        local keys = get_user_reminders(redis, message.chat.id, message.from.id)
        if #keys == 0 then
            return api.send_message(message.chat.id, 'You have no active reminders in this chat.')
        end

        local lines = { '<b>Your active reminders:</b>', '' }
        for i, key in ipairs(keys) do
            local data = redis.hgetall(key)
            if data and data.text then
                local expires = tonumber(data.expires) or 0
                local remaining = expires - os.time()
                if remaining > 0 then
                    table.insert(lines, string.format(
                        '%d. %s <i>(in %s)</i>',
                        i,
                        tools.escape_html(data.text),
                        format_duration(remaining)
                    ))
                end
            end
        end

        if #lines <= 2 then
            return api.send_message(message.chat.id, 'You have no active reminders in this chat.')
        end

        return api.send_message(message.chat.id, table.concat(lines, '\n'), { parse_mode = 'html' })
    end

    -- /remind <duration> <message>
    local input = message.args
    if not input or input == '' then
        return api.send_message(
            message.chat.id,
            'Usage: <code>/remind &lt;duration&gt; &lt;message&gt;</code>\n\n'
            .. 'Durations: <code>30m</code>, <code>2h</code>, <code>1d</code>, '
            .. '<code>2h30m</code>\n'
            .. 'Max: 7 days. Max 4 reminders per chat.\n\n'
            .. 'Examples:\n'
            .. '<code>/remind 30m check the oven</code>\n'
            .. '<code>/remind 2h30m meeting with John</code>\n'
            .. '<code>/remind 1d renew subscription</code>',
            { parse_mode = 'html' }
        )
    end

    -- Parse duration from the first token
    local duration_str, reminder_text = input:match('^(%S+)%s+(.+)$')
    if not duration_str then
        -- Maybe just a duration with no text
        duration_str = input
        reminder_text = nil
    end

    local duration = parse_duration(duration_str)
    if not duration then
        return api.send_message(
            message.chat.id,
            'Invalid duration format. Use combinations like: <code>30m</code>, <code>2h</code>, <code>1d</code>, <code>2h30m</code>',
            { parse_mode = 'html' }
        )
    end

    if not reminder_text or reminder_text == '' then
        return api.send_message(message.chat.id, 'Please include a reminder message after the duration.')
    end

    if duration < 30 then
        return api.send_message(message.chat.id, 'Minimum reminder duration is 30 seconds.')
    end

    if duration > MAX_DURATION then
        return api.send_message(message.chat.id, 'Maximum reminder duration is 7 days.')
    end

    -- Check reminder limit
    local existing = get_user_reminders(redis, message.chat.id, message.from.id)
    -- Filter to only count non-expired ones
    local active_count = 0
    for _, key in ipairs(existing) do
        local expires = redis.hget(key, 'expires')
        if expires and tonumber(expires) > os.time() then
            active_count = active_count + 1
        else
            -- Clean up expired entry
            redis.del(key)
        end
    end
    if active_count >= MAX_REMINDERS then
        return api.send_message(
            message.chat.id,
            string.format('You already have %d active reminders in this chat (max %d). Wait for one to expire or use /reminders to check them.', active_count, MAX_REMINDERS)
        )
    end

    -- Truncate long reminder text
    if #reminder_text > 500 then
        reminder_text = reminder_text:sub(1, 497) .. '...'
    end

    -- Store reminder
    local expires_at = os.time() + duration
    local reminder_id = string.format('%s%s:%s:%d',
        REDIS_PREFIX,
        tostring(message.chat.id),
        tostring(message.from.id),
        expires_at
    )

    redis.hset(reminder_id, 'chat_id', tostring(message.chat.id))
    redis.hset(reminder_id, 'user_id', tostring(message.from.id))
    redis.hset(reminder_id, 'text', reminder_text)
    redis.hset(reminder_id, 'expires', tostring(expires_at))
    redis.hset(reminder_id, 'first_name', message.from.first_name or 'User')
    -- Set Redis TTL slightly beyond expiry for auto-cleanup
    local key_ttl = duration + 300
    redis.expire(reminder_id, key_ttl)

    return api.send_message(
        message.chat.id,
        string.format(
            'Reminder set for <b>%s</b> from now.\n\n<i>%s</i>',
            format_duration(duration),
            tools.escape_html(reminder_text)
        ),
        { parse_mode = 'html' }
    )
end

-- Cron job: runs every minute, checks for expired reminders
function plugin.cron(api, ctx)
    local redis = ctx.redis
    local keys = get_all_reminders(redis)
    local now = os.time()

    for _, key in ipairs(keys) do
        local data = redis.hgetall(key)
        if data and data.expires then
            local expires = tonumber(data.expires)
            if expires and expires <= now then
                -- Send the reminder
                local chat_id = data.chat_id
                local user_id = data.user_id
                local text = data.text or 'Reminder!'
                local first_name = data.first_name or 'User'

                if chat_id then
                    local output = string.format(
                        '<a href="tg://user?id=%s">%s</a>, here is your reminder:\n\n<i>%s</i>',
                        tostring(user_id),
                        tools.escape_html(first_name),
                        tools.escape_html(text)
                    )
                    pcall(function()
                        api.send_message(tonumber(chat_id), output, { parse_mode = 'html' })
                    end)
                end

                -- Delete the reminder
                redis.del(key)
            end
        end
    end
end

return plugin
