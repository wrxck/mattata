--[[
    mattata v2.0 - Schedule Plugin
    Schedule messages to be posted in a group after a delay.
    Admin-only. Stores scheduled messages in Redis with a cron job to send them.
]]

local plugin = {}
plugin.name = 'schedule'
plugin.category = 'utility'
plugin.description = 'Schedule messages to be posted in a group at a later time'
plugin.commands = { 'schedule', 'sched' }
plugin.help = '/schedule <duration> <message> - Schedule a message.\n/schedule list - List pending messages.\n/schedule cancel <id> - Cancel a scheduled message.'
plugin.group_only = true
plugin.admin_only = true

local tools = require('telegram-bot-lua.tools')

local MAX_PER_CHAT = 10
local MAX_DURATION = 7 * 24 * 3600  -- 7 days
local MAX_MESSAGE_LENGTH = 4000
local CRON_SEND_LIMIT = 10

-- Parse a duration string like "2h30m", "1d", "45m", "90s"
local function parse_duration(str)
    if not str or str == '' then
        return nil
    end

    local total = 0
    local found = false

    local d = str:match('(%d+)%s*d')
    if d then
        total = total + tonumber(d) * 86400
        found = true
    end

    local h = str:match('(%d+)%s*h')
    if h then
        total = total + tonumber(h) * 3600
        found = true
    end

    local m = str:match('(%d+)%s*m')
    if m then
        total = total + tonumber(m) * 60
        found = true
    end

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

-- Get the index key for a chat's scheduled messages
local function index_key(chat_id)
    return 'schedule:index:' .. tostring(chat_id)
end

-- Get the hash key for a specific scheduled message
local function hash_key(chat_id, id)
    return 'schedule:' .. tostring(chat_id) .. ':' .. tostring(id)
end

-- Handle /schedule list
local function handle_list(api, message, ctx)
    local redis = ctx.redis
    local members = redis.smembers(index_key(message.chat.id))

    if not members or #members == 0 then
        return api.send_message(message.chat.id, 'No scheduled messages for this chat.')
    end

    local lines = { '<b>Scheduled messages:</b>', '' }
    local now = os.time()
    local found = false

    for _, key in ipairs(members) do
        local data = redis.hgetall(key)
        if data and data.send_at then
            local send_at = tonumber(data.send_at)
            if send_at and send_at > now then
                found = true
                local remaining = send_at - now
                local preview = data.text or ''
                if #preview > 50 then
                    preview = preview:sub(1, 47) .. '...'
                end
                -- Extract the ID from the key
                local id = key:match(':(%d+)$')
                table.insert(lines, string.format(
                    '<b>#%s</b> - in %s\n  <i>%s</i>',
                    id or '?',
                    format_duration(remaining),
                    tools.escape_html(preview)
                ))
            end
        end
    end

    if not found then
        return api.send_message(message.chat.id, 'No scheduled messages for this chat.')
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), { parse_mode = 'html' })
end

-- Handle /schedule cancel <id>
local function handle_cancel(api, message, ctx, id_str)
    local redis = ctx.redis
    local id = tonumber(id_str)

    if not id then
        return api.send_message(message.chat.id, 'Please provide a valid message ID to cancel.\nUsage: <code>/schedule cancel 3</code>', { parse_mode = 'html' })
    end

    local key = hash_key(message.chat.id, id)
    local exists = redis.hget(key, 'chat_id')

    if not exists then
        return api.send_message(message.chat.id, string.format('Scheduled message #%d not found.', id))
    end

    redis.del(key)
    redis.srem(index_key(message.chat.id), key)

    return api.send_message(message.chat.id, string.format('Scheduled message #%d has been cancelled.', id))
end

-- Handle /schedule <duration> <message>
local function handle_schedule(api, message, ctx)
    local redis = ctx.redis
    local input = message.args

    if not input or input == '' then
        return api.send_message(
            message.chat.id,
            'Usage:\n'
            .. '<code>/schedule &lt;duration&gt; &lt;message&gt;</code> - Schedule a message\n'
            .. '<code>/schedule list</code> - List pending messages\n'
            .. '<code>/schedule cancel &lt;id&gt;</code> - Cancel a message\n\n'
            .. 'Durations: <code>30m</code>, <code>2h</code>, <code>1d</code>, <code>2h30m</code>\n'
            .. 'Max: 7 days, 10 messages per chat.',
            { parse_mode = 'html' }
        )
    end

    -- Parse duration from the first token
    local duration_str, sched_text = input:match('^(%S+)%s+(.+)$')
    if not duration_str then
        return api.send_message(
            message.chat.id,
            'Please provide both a duration and a message.\nUsage: <code>/schedule 2h Hello everyone!</code>',
            { parse_mode = 'html' }
        )
    end

    local duration = parse_duration(duration_str)
    if not duration then
        return api.send_message(
            message.chat.id,
            'Invalid duration format. Use combinations like: <code>30m</code>, <code>2h</code>, <code>1d</code>, <code>2h30m</code>',
            { parse_mode = 'html' }
        )
    end

    if duration < 60 then
        return api.send_message(message.chat.id, 'Minimum schedule duration is 1 minute.')
    end

    if duration > MAX_DURATION then
        return api.send_message(message.chat.id, 'Maximum schedule duration is 7 days.')
    end

    if #sched_text > MAX_MESSAGE_LENGTH then
        return api.send_message(
            message.chat.id,
            string.format('Message is too long (%d characters). Maximum is %d.', #sched_text, MAX_MESSAGE_LENGTH)
        )
    end

    -- Check per-chat limit
    local members = redis.smembers(index_key(message.chat.id))
    local active_count = 0
    local now = os.time()
    if members then
        for _, key in ipairs(members) do
            local send_at = redis.hget(key, 'send_at')
            if send_at and tonumber(send_at) and tonumber(send_at) > now then
                active_count = active_count + 1
            else
                -- Clean up expired entries from index
                redis.srem(index_key(message.chat.id), key)
                redis.del(key)
            end
        end
    end

    if active_count >= MAX_PER_CHAT then
        return api.send_message(
            message.chat.id,
            string.format('This chat already has %d scheduled messages (max %d). Cancel some first with /schedule cancel <id>.', active_count, MAX_PER_CHAT)
        )
    end

    -- Assign an incremental ID
    local id = redis.incr('schedule:next_id:' .. tostring(message.chat.id))
    local key = hash_key(message.chat.id, id)
    local send_at = now + duration

    -- Store the scheduled message hash
    redis.hset(key, 'chat_id', tostring(message.chat.id))
    redis.hset(key, 'text', sched_text)
    redis.hset(key, 'send_at', tostring(send_at))
    redis.hset(key, 'created_by', tostring(message.from.id))
    redis.hset(key, 'first_name', message.from.first_name or 'Admin')

    -- Add to the chat's index set and global active chats set
    redis.sadd(index_key(message.chat.id), key)
    redis.sadd('schedule:active_chats', tostring(message.chat.id))

    -- Set TTL for auto-cleanup (duration + 5 minutes buffer)
    redis.expire(key, duration + 300)

    return api.send_message(
        message.chat.id,
        string.format(
            'Message #%d scheduled for <b>%s</b> from now.\n\n<i>%s</i>',
            id,
            format_duration(duration),
            tools.escape_html(#sched_text > 100 and sched_text:sub(1, 97) .. '...' or sched_text)
        ),
        { parse_mode = 'html' }
    )
end

function plugin.on_message(api, message, ctx)
    local input = message.args

    if input and input:lower() == 'list' then
        return handle_list(api, message, ctx)
    end

    if input and input:lower():match('^cancel%s') then
        local id_str = input:match('^%S+%s+(.+)$')
        return handle_cancel(api, message, ctx, id_str)
    end

    if input and input:lower() == 'cancel' then
        return api.send_message(
            message.chat.id,
            'Please provide the ID of the message to cancel.\nUsage: <code>/schedule cancel 3</code>',
            { parse_mode = 'html' }
        )
    end

    return handle_schedule(api, message, ctx)
end

-- Cron job: runs every minute, checks for scheduled messages ready to send
function plugin.cron(api, ctx)
    local redis = ctx.redis
    local now = os.time()
    local sent = 0

    -- Get all chats with scheduled messages
    local active_chats = redis.smembers('schedule:active_chats') or {}
    local index_keys = {}
    for _, chat_id in ipairs(active_chats) do
        index_keys[#index_keys + 1] = 'schedule:index:' .. chat_id
    end

    for _, idx_key in ipairs(index_keys) do
        if sent >= CRON_SEND_LIMIT then
            break
        end

        local members = redis.smembers(idx_key)
        if members then
            for _, key in ipairs(members) do
                if sent >= CRON_SEND_LIMIT then
                    break
                end

                local data = redis.hgetall(key)
                if data and data.send_at then
                    local send_at = tonumber(data.send_at)
                    if send_at and send_at <= now then
                        local chat_id = tonumber(data.chat_id)
                        local text = data.text

                        if chat_id and text then
                            pcall(function()
                                api.send_message(chat_id, text)
                            end)
                            sent = sent + 1
                        end

                        -- Clean up
                        redis.del(key)
                        redis.srem(idx_key, key)
                    end
                else
                    -- Orphaned entry, remove from index
                    redis.srem(idx_key, key)
                end
            end
            -- Clean up empty index sets from global tracker
            local remaining = redis.scard(idx_key)
            if tonumber(remaining) == 0 then
                local tracked_chat_id = idx_key:match('schedule:index:(.+)$')
                if tracked_chat_id then
                    redis.srem('schedule:active_chats', tracked_chat_id)
                end
            end
        end
    end
end

return plugin
