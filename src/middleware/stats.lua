--[[
    mattata v2.0 - Stats Middleware
    Increments Redis counters for message and command statistics.
    Counters are flushed to PostgreSQL every 5 minutes via cron.
]]

local stats_mw = {}
stats_mw.name = 'stats'

local logger = require('src.core.logger')

function stats_mw.run(ctx, message)
    if not message.from or not message.chat then
        return ctx, true
    end

    local chat_id = message.chat.id
    local user_id = message.from.id
    local date = os.date('!%Y-%m-%d')

    -- Increment message counter in Redis
    local msg_key = string.format('stats:msg:%s:%s:%s', chat_id, date, user_id)
    pcall(function()
        local count = ctx.redis.incr(msg_key)
        if count == 1 then
            ctx.redis.expire(msg_key, 86400) -- 24h TTL
        end
    end)

    -- Track command usage
    if message.text and message.text:match('^[/!#]') then
        local cmd = message.text:match('^[/!#]([%w_]+)')
        if cmd then
            local cmd_key = string.format('stats:cmd:%s:%s:%s', cmd:lower(), chat_id, date)
            pcall(function()
                local count = ctx.redis.incr(cmd_key)
                if count == 1 then
                    ctx.redis.expire(cmd_key, 86400)
                end
            end)
        end
    end

    return ctx, true
end

-- Cron job: flush Redis stats counters to PostgreSQL
-- Called from the stats flush plugin every 5 minutes
function stats_mw.flush(db, redis)
    -- Flush message stats
    local msg_keys = redis.scan('stats:msg:*')
    local flushed = 0
    for _, key in ipairs(msg_keys) do
        local count = tonumber(redis.get(key))
        if count and count > 0 then
            -- Parse key: stats:msg:{chat_id}:{date}:{user_id}
            local chat_id, date, user_id = key:match('stats:msg:(%-?%d+):(%d%d%d%d%-%d%d%-%d%d):(%d+)')
            if chat_id and date and user_id then
                pcall(function()
                    db.execute(
                        [[INSERT INTO message_stats (chat_id, user_id, date, message_count)
                          VALUES ($1, $2, $3, $4)
                          ON CONFLICT (chat_id, user_id, date) DO UPDATE SET
                          message_count = message_stats.message_count + $4]],
                        { tonumber(chat_id), tonumber(user_id), date, count }
                    )
                end)
                redis.del(key)
                flushed = flushed + 1
            end
        end
    end

    -- Flush command stats
    local cmd_keys = redis.scan('stats:cmd:*')
    for _, key in ipairs(cmd_keys) do
        local count = tonumber(redis.get(key))
        if count and count > 0 then
            -- Parse key: stats:cmd:{command}:{chat_id}:{date}
            local command, chat_id, date = key:match('stats:cmd:([%w_]+):(%-?%d+):(%d%d%d%d%-%d%d%-%d%d)')
            if command and chat_id and date then
                pcall(function()
                    db.execute(
                        [[INSERT INTO command_stats (chat_id, command, date, use_count)
                          VALUES ($1, $2, $3, $4)
                          ON CONFLICT (chat_id, command, date) DO UPDATE SET
                          use_count = command_stats.use_count + $4]],
                        { tonumber(chat_id), command, date, count }
                    )
                end)
                redis.del(key)
                flushed = flushed + 1
            end
        end
    end

    if flushed > 0 then
        logger.info('Flushed %d stats counters to PostgreSQL', flushed)
    end
end

return stats_mw
