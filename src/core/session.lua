--[[
    mattata v2.0 - Session Manager
    Redis wrapper for transient/cached data with TTL management.
]]

local session = {}

local redis

-- Initialise with redis module reference (avoids circular require)
function session.init(redis_mod)
    redis = redis_mod
end

-- Settings cache (5 min TTL, fallback to PostgreSQL)
function session.get_setting(chat_id, key)
    local cache_key = string.format('cache:setting:%s:%s', tostring(chat_id), tostring(key))
    return redis.get(cache_key)
end

function session.set_setting(chat_id, key, value, ttl)
    ttl = ttl or 300
    local cache_key = string.format('cache:setting:%s:%s', tostring(chat_id), tostring(key))
    return redis.setex(cache_key, ttl, tostring(value))
end

function session.invalidate_setting(chat_id, key)
    local cache_key = string.format('cache:setting:%s:%s', tostring(chat_id), tostring(key))
    return redis.del(cache_key)
end

-- Generic cached setting helper: check Redis first, fallback to fetch_fn, cache result
-- Used by on_new_message handlers to avoid DB queries on every message
function session.get_cached_setting(chat_id, key, fetch_fn, ttl)
    ttl = ttl or 300
    local cache_key = string.format('cache:setting:%s:%s', tostring(chat_id), tostring(key))
    local cached = redis.get(cache_key)
    if cached ~= nil then
        if cached == '__nil__' then
            return nil
        end
        return cached
    end
    local value = fetch_fn()
    if value ~= nil then
        redis.setex(cache_key, ttl, tostring(value))
    else
        -- Cache the nil result to avoid repeated DB queries
        redis.setex(cache_key, ttl, '__nil__')
    end
    return value
end

-- Cache a JSON-serialisable table (for filter/trigger lists)
function session.get_cached_list(chat_id, key, fetch_fn, ttl)
    ttl = ttl or 300
    local json = require('dkjson')
    local cache_key = string.format('cache:list:%s:%s', tostring(chat_id), tostring(key))
    local cached = redis.get(cache_key)
    if cached ~= nil then
        if cached == '[]' then
            return {}
        end
        local decoded = json.decode(cached)
        if decoded then return decoded end
    end
    local value = fetch_fn()
    if value then
        redis.setex(cache_key, ttl, json.encode(value))
    else
        redis.setex(cache_key, ttl, '[]')
    end
    return value or {}
end

-- Invalidate a cached list
function session.invalidate_cached_list(chat_id, key)
    local cache_key = string.format('cache:list:%s:%s', tostring(chat_id), tostring(key))
    return redis.del(cache_key)
end

-- Admin cache (5 min TTL — increased from 2 min for performance)
function session.get_admin_status(chat_id, user_id)
    local cache_key = string.format('cache:admin:%s:%s', tostring(chat_id), tostring(user_id))
    local val = redis.get(cache_key)
    if val == nil then
        return nil
    end
    return val == '1'
end

function session.set_admin_status(chat_id, user_id, is_admin)
    local cache_key = string.format('cache:admin:%s:%s', tostring(chat_id), tostring(user_id))
    return redis.setex(cache_key, 300, is_admin and '1' or '0')
end

function session.invalidate_admin_status(chat_id, user_id)
    local cache_key = string.format('cache:admin:%s:%s', tostring(chat_id), tostring(user_id))
    return redis.del(cache_key)
end

-- Action state (multi-step commands, 5 min TTL)
function session.set_action(chat_id, message_id, command)
    local key = string.format('action:%s:%s', tostring(chat_id), tostring(message_id))
    return redis.setex(key, 300, command)
end

function session.get_action(chat_id, message_id)
    local key = string.format('action:%s:%s', tostring(chat_id), tostring(message_id))
    return redis.get(key)
end

function session.del_action(chat_id, message_id)
    local key = string.format('action:%s:%s', tostring(chat_id), tostring(message_id))
    return redis.del(key)
end

-- AFK status (persistent until return)
function session.set_afk(user_id, note)
    redis.hset('afk:' .. tostring(user_id), 'since', tostring(os.time()))
    if note and note ~= '' then
        redis.hset('afk:' .. tostring(user_id), 'note', note)
    end
end

function session.get_afk(user_id)
    local since = redis.hget('afk:' .. tostring(user_id), 'since')
    if not since then
        return nil
    end
    return {
        since = tonumber(since),
        note = redis.hget('afk:' .. tostring(user_id), 'note')
    }
end

function session.clear_afk(user_id)
    redis.hdel('afk:' .. tostring(user_id), 'since')
    redis.hdel('afk:' .. tostring(user_id), 'note')
    -- Use SCAN instead of KEYS to clean up replied keys
    local replied_keys = redis.scan('afk:' .. tostring(user_id) .. ':replied:*')
    for _, key in ipairs(replied_keys) do
        redis.del(key)
    end
end

-- Captcha state (configurable TTL)
function session.set_captcha(chat_id, user_id, text, message_id, timeout)
    timeout = timeout or 300
    local hash = string.format('chat:%s:captcha:%s', tostring(chat_id), tostring(user_id))
    redis.hset(hash, 'text', text)
    redis.hset(hash, 'id', tostring(message_id))
    redis.expire(hash, timeout)
    redis.setex('captcha:' .. chat_id .. ':' .. user_id, timeout, '1')
end

function session.get_captcha(chat_id, user_id)
    local hash = string.format('chat:%s:captcha:%s', tostring(chat_id), tostring(user_id))
    local text = redis.hget(hash, 'text')
    local id = redis.hget(hash, 'id')
    if not text then
        return nil
    end
    return { text = text, message_id = id }
end

function session.clear_captcha(chat_id, user_id)
    local hash = string.format('chat:%s:captcha:%s', tostring(chat_id), tostring(user_id))
    redis.hdel(hash, 'text')
    redis.hdel(hash, 'id')
    redis.del('captcha:' .. chat_id .. ':' .. user_id)
end

-- Rate limiting (short TTL counters)
function session.increment_rate(chat_id, user_id, ttl)
    ttl = ttl or 5
    local key = string.format('antispam:%s:%s', tostring(chat_id), tostring(user_id))
    local count = redis.incr(key)
    if count == 1 then
        redis.expire(key, ttl)
    end
    return tonumber(count)
end

function session.get_rate(chat_id, user_id)
    local key = string.format('antispam:%s:%s', tostring(chat_id), tostring(user_id))
    return tonumber(redis.get(key)) or 0
end

-- Global blocklist (single exists check — fixed from double call)
function session.is_globally_blocklisted(user_id)
    local result = redis.exists('global_blocklist:' .. tostring(user_id))
    return result == 1 or result == true
end

function session.set_global_blocklist(user_id, ttl)
    ttl = ttl or 604800  -- default 7 days
    redis.setex('global_blocklist:' .. tostring(user_id), ttl, '1')
end

-- Disabled plugins cache
function session.get_disabled_plugins(chat_id)
    return redis.smembers('disabled_plugins:' .. tostring(chat_id)) or {}
end

function session.is_plugin_disabled(chat_id, plugin_name)
    local val = redis.sismember('disabled_plugins:' .. tostring(chat_id), plugin_name)
    return val and val ~= false and val ~= 0
end

function session.disable_plugin(chat_id, plugin_name)
    return redis.sadd('disabled_plugins:' .. tostring(chat_id), plugin_name)
end

function session.enable_plugin(chat_id, plugin_name)
    return redis.srem('disabled_plugins:' .. tostring(chat_id), plugin_name)
end

return session
