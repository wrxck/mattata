--[[
    mattata v2.0 - Test Helper
    Common utilities for busted test setup/teardown and assertion helpers.
]]

local test_helper = {}

local assert = require('luassert')
local mock_api = require('spec.helpers.mock_api')
local mock_db = require('spec.helpers.mock_db')
local mock_redis = require('spec.helpers.mock_redis')

-- Create a fresh set of mocks for each test
function test_helper.setup()
    local env = {
        api = mock_api.new(),
        db = mock_db.new(),
        redis = mock_redis.new(),
    }
    return env
end

-- Reset all mocks between tests
function test_helper.teardown(env)
    if env then
        if env.api and env.api.reset then env.api.reset() end
        if env.db and env.db.reset then env.db.reset() end
        if env.redis and env.redis.reset then env.redis.reset() end
    end
end

-- Build a mock message for testing
function test_helper.make_message(overrides)
    local msg = {
        message_id = 1,
        date = os.time(),
        from = {
            id = 111111,
            is_bot = false,
            first_name = 'Test',
            last_name = 'User',
            username = 'testuser',
            language_code = 'en_gb',
        },
        chat = {
            id = -100123456789,
            title = 'Test Group',
            type = 'supergroup',
        },
        text = '',
    }
    if overrides then
        for k, v in pairs(overrides) do
            if type(v) == 'table' and type(msg[k]) == 'table' then
                for k2, v2 in pairs(v) do
                    msg[k][k2] = v2
                end
            else
                msg[k] = v
            end
        end
    end
    return msg
end

-- Build a mock private message
function test_helper.make_private_message(overrides)
    local defaults = {
        chat = {
            id = 111111,
            type = 'private',
            first_name = 'Test',
            last_name = 'User',
        },
    }
    if overrides then
        for k, v in pairs(overrides) do
            defaults[k] = v
        end
    end
    return test_helper.make_message(defaults)
end

-- Build a mock callback query
function test_helper.make_callback_query(overrides)
    local cb = {
        id = 'callback_123',
        from = {
            id = 111111,
            is_bot = false,
            first_name = 'Test',
            username = 'testuser',
        },
        message = {
            message_id = 1,
            chat = {
                id = -100123456789,
                type = 'supergroup',
                title = 'Test Group',
            },
        },
        data = '',
    }
    if overrides then
        for k, v in pairs(overrides) do
            cb[k] = v
        end
    end
    return cb
end

-- Build a context (ctx) object similar to what the router builds
function test_helper.make_ctx(env, overrides)
    local ctx = {
        api = env.api,
        db = env.db,
        redis = env.redis,
        config = {
            bot_name = function() return 'mattata' end,
            get = function(key, default) return default end,
            get_number = function(key, default) return default end,
            is_enabled = function(key) return false end,
            bot_admins = function() return {} end,
        },
        is_group = true,
        is_supergroup = true,
        is_private = false,
        is_global_admin = false,
        is_admin = false,
        is_mod = false,
        lang = {
            errors = {
                connection = 'Connection error.',
                results = 'No results found.',
                supergroup = 'This command can only be used in supergroups.',
                admin = 'You need to be an admin to use this command.',
                generic = 'An unexpected error occurred.',
            },
        },
        lang_code = 'en_gb',
    }
    if overrides then
        for k, v in pairs(overrides) do
            ctx[k] = v
        end
    end
    return ctx
end

-- Assert a specific API method was called
function test_helper.assert_api_called(api, method)
    local call = api.get_call(method)
    assert.is_not_nil(call, 'Expected API method "' .. method .. '" to be called')
    return call
end

-- Assert a specific API method was NOT called
function test_helper.assert_api_not_called(api, method)
    local call = api.get_call(method)
    assert.is_nil(call, 'Expected API method "' .. method .. '" NOT to be called')
end

-- Assert a send_message was called with text matching a pattern
function test_helper.assert_sent_message_matches(api, pattern)
    local found = false
    for _, call in ipairs(api.calls) do
        if call.method == 'send_message' and call.args[2] and call.args[2]:match(pattern) then
            found = true
            break
        end
    end
    assert.is_true(found, 'Expected send_message with text matching "' .. pattern .. '"')
end

-- Assert a specific DB query was executed
function test_helper.assert_db_query_matches(db, pattern)
    local found = false
    for _, q in ipairs(db.queries) do
        local sql = q.sql or ''
        if sql:match(pattern) then
            found = true
            break
        end
    end
    assert.is_true(found, 'Expected DB query matching "' .. pattern .. '"')
end

-- Assert a specific Redis command was issued
function test_helper.assert_redis_command(redis, cmd)
    local found = false
    for _, c in ipairs(redis.commands) do
        if c.cmd == cmd then
            found = true
            break
        end
    end
    assert.is_true(found, 'Expected Redis command "' .. cmd .. '"')
end

return test_helper
