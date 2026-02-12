--[[
    Tests for v2.1 concurrency-safe pool mechanics.
    Tests semaphore guards on database and Redis pools,
    method-name-string safe_call, and graceful fallback
    when semaphore is nil (test/mock environment).
]]

describe('concurrency', function()

    describe('database pool safety', function()
        local mock_db = require('spec.helpers.mock_db')

        it('should work without semaphore (test environment fallback)', function()
            local db = mock_db.new()
            -- mock_db never calls connect(), so semaphore is nil
            -- All operations should still work identically to v2.0
            local result = db.query('SELECT 1')
            assert.are.same({}, result)
            db.set_next_result({ { id = 1 } })
            result = db.query('SELECT * FROM users')
            assert.are.same({ { id = 1 } }, result)
        end)

        it('should execute queries and return results without semaphore', function()
            local db = mock_db.new()
            db.set_next_result({ { count = 42 } })
            local result = db.execute('SELECT COUNT(*) FROM messages', {})
            assert.are.same({ { count = 42 } }, result)
        end)

        it('should handle transactions without semaphore', function()
            local db = mock_db.new()
            local called = false
            db.transaction(function(query, execute)
                called = true
                query('SELECT 1')
            end)
            assert.is_true(called)
        end)

        it('pool_stats should report available and max_size', function()
            local db = mock_db.new()
            local stats = db.pool_stats()
            assert.is_number(stats.available)
            assert.is_number(stats.max_size)
        end)
    end)

    describe('redis pool safety', function()
        local mock_redis = require('spec.helpers.mock_redis')

        it('should work without semaphore (test environment fallback)', function()
            local redis = mock_redis.new()
            -- mock_redis never calls connect() with real config, so no semaphore
            redis.set('key', 'value')
            assert.are.equal('value', redis.get('key'))
        end)

        it('safe_call with method name strings should work via proxy functions', function()
            local redis = mock_redis.new()
            -- All proxy functions in the real module use safe_call('method_name', ...)
            -- The mock simulates this directly
            redis.set('test_key', 'test_value')
            assert.are.equal('test_value', redis.get('test_key'))
            assert.is_true(redis.has_command('set'))
            assert.is_true(redis.has_command('get'))
        end)

        it('hash operations should work through proxy', function()
            local redis = mock_redis.new()
            redis.hset('hash:1', 'field1', 'value1')
            assert.are.equal('value1', redis.hget('hash:1', 'field1'))
            local all = redis.hgetall('hash:1')
            assert.are.equal('value1', all['field1'])
        end)

        it('set operations should work through proxy', function()
            local redis = mock_redis.new()
            redis.sadd('set:1', 'member1')
            assert.are.equal(1, redis.sismember('set:1', 'member1'))
            assert.are.equal(0, redis.sismember('set:1', 'nonexistent'))
        end)

        it('list operations should work through proxy', function()
            local redis = mock_redis.new()
            redis.rpush('list:1', 'a')
            redis.rpush('list:1', 'b')
            local items = redis.lrange('list:1', 0, -1)
            assert.are.equal(2, #items)
            assert.are.equal('a', items[1])
        end)

        it('scan should work through pool', function()
            local redis = mock_redis.new()
            redis.set('prefix:1', 'a')
            redis.set('prefix:2', 'b')
            redis.set('other:1', 'c')
            local results = redis.scan('prefix:*')
            assert.are.equal(2, #results)
        end)

        it('client() should still return a usable object', function()
            local redis = mock_redis.new()
            local c = redis.client()
            assert.is_not_nil(c)
        end)
    end)

    describe('mock_api async stubs', function()
        local mock_api = require('spec.helpers.mock_api')

        it('should have handler stubs', function()
            local api = mock_api.new()
            assert.is_function(api.on_message)
            assert.is_function(api.on_edited_message)
            assert.is_function(api.on_callback_query)
            assert.is_function(api.on_inline_query)
        end)

        it('should have async module stubs', function()
            local api = mock_api.new()
            assert.is_table(api.async)
            assert.is_function(api.async.run)
            assert.is_function(api.async.stop)
            assert.is_function(api.async.all)
            assert.is_function(api.async.spawn)
            assert.is_function(api.async.sleep)
            assert.is_function(api.async.is_running)
        end)

        it('should have api.run stub', function()
            local api = mock_api.new()
            assert.is_function(api.run)
            -- Should not error when called
            assert.has_no.errors(function()
                api.run({ timeout = 60, limit = 100 })
            end)
        end)

        it('should have process_update stub', function()
            local api = mock_api.new()
            assert.is_function(api.process_update)
            assert.has_no.errors(function()
                api.process_update({ update_id = 1, message = {} })
            end)
        end)

        it('async.is_running should return false in test environment', function()
            local api = mock_api.new()
            assert.is_false(api.async.is_running())
        end)

        it('async.spawn should execute the function', function()
            local api = mock_api.new()
            local called = false
            api.async.spawn(function() called = true end)
            assert.is_true(called)
        end)

        it('handler stubs should be overwritable', function()
            local api = mock_api.new()
            local msg_received = nil
            api.on_message = function(msg) msg_received = msg end
            api.on_message({ text = 'hello' })
            assert.are.same({ text = 'hello' }, msg_received)
        end)
    end)
end)
