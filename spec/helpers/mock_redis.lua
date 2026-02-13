--[[
    mattata v2.0 - Mock Redis
    In-memory implementation of Redis operations for testing.
]]

local mock_redis = {}

function mock_redis.new()
    local redis = {
        store = {},
        sets = {},
        hashes = {},
        ttls = {},
        commands = {},
    }

    local function record(cmd, ...) table.insert(redis.commands, { cmd = cmd, args = {...} }) end

    function redis.get(key) record('get', key); return redis.store[key] end
    function redis.set(key, value) record('set', key, value); redis.store[key] = tostring(value) end
    function redis.setex(key, ttl, value) record('setex', key, ttl, value); redis.store[key] = tostring(value); redis.ttls[key] = ttl end
    function redis.setnx(key, value)
        record('setnx', key, value)
        if redis.store[key] == nil then redis.store[key] = tostring(value); return 1 end
        return 0
    end
    function redis.del(key) record('del', key); redis.store[key] = nil; redis.sets[key] = nil; redis.hashes[key] = nil end
    function redis.exists(key) record('exists', key); return redis.store[key] ~= nil and 1 or 0 end
    function redis.expire(key, ttl) record('expire', key, ttl); redis.ttls[key] = ttl end
    function redis.incr(key)
        record('incr', key)
        redis.store[key] = (tonumber(redis.store[key]) or 0) + 1
        return redis.store[key]
    end
    function redis.incrby(key, n)
        record('incrby', key, n)
        redis.store[key] = (tonumber(redis.store[key]) or 0) + n
        return redis.store[key]
    end
    function redis.getset(key, value)
        record('getset', key, value)
        local old = redis.store[key]
        redis.store[key] = tostring(value)
        return old
    end

    function redis.hget(key, field) record('hget', key, field); return redis.hashes[key] and redis.hashes[key][field] end
    function redis.hset(key, field, value)
        record('hset', key, field, value)
        if not redis.hashes[key] then redis.hashes[key] = {} end
        redis.hashes[key][field] = tostring(value)
    end
    function redis.hdel(key, field) record('hdel', key, field); if redis.hashes[key] then redis.hashes[key][field] = nil end end
    function redis.hgetall(key) record('hgetall', key); return redis.hashes[key] or {} end
    function redis.hexists(key, field) record('hexists', key, field); return redis.hashes[key] and redis.hashes[key][field] ~= nil end
    function redis.hincrby(key, field, n)
        record('hincrby', key, field, n)
        if not redis.hashes[key] then redis.hashes[key] = {} end
        redis.hashes[key][field] = (tonumber(redis.hashes[key][field]) or 0) + n
        return redis.hashes[key][field]
    end

    function redis.sadd(key, value)
        record('sadd', key, value)
        if not redis.sets[key] then redis.sets[key] = {} end
        redis.sets[key][tostring(value)] = true
    end
    function redis.srem(key, value) record('srem', key, value); if redis.sets[key] then redis.sets[key][tostring(value)] = nil end end
    function redis.sismember(key, value) record('sismember', key, value); return redis.sets[key] and redis.sets[key][tostring(value)] and 1 or 0 end
    function redis.smembers(key)
        record('smembers', key)
        local result = {}
        if redis.sets[key] then
            for v in pairs(redis.sets[key]) do table.insert(result, v) end
        end
        return result
    end
    function redis.scard(key)
        record('scard', key)
        local count = 0
        if redis.sets[key] then
            for _ in pairs(redis.sets[key]) do count = count + 1 end
        end
        return count
    end

    function redis.rpush(key, value)
        record('rpush', key, value)
        if not redis.store[key] then redis.store[key] = {} end
        if type(redis.store[key]) == 'table' then table.insert(redis.store[key], value) end
    end
    function redis.lrange(key, start, stop)
        record('lrange', key, start, stop)
        local data = redis.store[key]
        if type(data) ~= 'table' then return {} end
        local result = {}
        -- Redis uses 0-based index, -1 means end
        local len = #data
        if start < 0 then start = len + start end
        if stop < 0 then stop = len + stop end
        for i = start + 1, math.min(stop + 1, len) do
            table.insert(result, data[i])
        end
        return result
    end
    function redis.ltrim(key, start, stop) record('ltrim', key, start, stop) end

    function redis.scan(pattern)
        record('scan', pattern)
        local results = {}
        -- Convert Redis glob pattern to Lua pattern
        local lua_pattern = '^' .. pattern:gsub('([%.%+%(%)%[%]%%])', '%%%1'):gsub('%*', '.*'):gsub('%?', '.') .. '$'
        for key in pairs(redis.store) do
            if type(key) == 'string' and key:match(lua_pattern) then
                table.insert(results, key)
            end
        end
        return results
    end

    function redis.keys(pattern) return redis.scan(pattern) end

    function redis.pipeline(fn) record('pipeline'); return nil end

    function redis.client() return redis end
    function redis.connect() return true end
    function redis.disconnect() end

    function redis.reset()
        redis.store = {}
        redis.sets = {}
        redis.hashes = {}
        redis.ttls = {}
        redis.commands = {}
    end

    -- Helper: check if a specific command was issued
    function redis.has_command(cmd)
        for _, c in ipairs(redis.commands) do
            if c.cmd == cmd then return true end
        end
        return false
    end

    -- Helper: count occurrences of a command
    function redis.count_commands(cmd)
        local count = 0
        for _, c in ipairs(redis.commands) do
            if c.cmd == cmd then count = count + 1 end
        end
        return count
    end

    return redis
end

return mock_redis
