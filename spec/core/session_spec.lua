--[[
    Tests for src/core/session.lua
    Tests settings cache, admin status cache, AFK, captcha, rate limiting,
    blocklist, disabled plugins, get_cached_setting, get_cached_list.
]]

describe('core.session', function()
    local session
    local mock_redis = require('spec.helpers.mock_redis')
    local redis

    before_each(function()
        package.loaded['src.core.session'] = nil
        session = require('src.core.session')
        redis = mock_redis.new()
        session.init(redis)
    end)

    after_each(function()
        redis.reset()
    end)

    describe('settings cache', function()
        it('should set and get a setting', function()
            session.set_setting(123, 'antilink', 'true')
            local val = session.get_setting(123, 'antilink')
            assert.are.equal('true', val)
        end)

        it('should return nil for unset setting', function()
            local val = session.get_setting(123, 'nonexistent')
            assert.is_nil(val)
        end)

        it('should use correct cache key format', function()
            session.set_setting(-100123, 'key', 'val')
            assert.is_true(redis.has_command('setex'))
            assert.is_not_nil(redis.store['cache:setting:-100123:key'])
        end)

        it('should use custom TTL', function()
            session.set_setting(123, 'key', 'val', 600)
            assert.are.equal(600, redis.ttls['cache:setting:123:key'])
        end)

        it('should use default TTL of 300', function()
            session.set_setting(123, 'key', 'val')
            assert.are.equal(300, redis.ttls['cache:setting:123:key'])
        end)

        it('should invalidate a setting', function()
            session.set_setting(123, 'key', 'val')
            session.invalidate_setting(123, 'key')
            assert.is_nil(session.get_setting(123, 'key'))
        end)
    end)

    describe('get_cached_setting()', function()
        it('should return cached value without calling fetch_fn', function()
            redis.setex('cache:setting:123:mykey', 300, 'cached_value')
            local fetch_called = false
            local val = session.get_cached_setting(123, 'mykey', function()
                fetch_called = true
                return 'db_value'
            end)
            assert.are.equal('cached_value', val)
            assert.is_false(fetch_called)
        end)

        it('should call fetch_fn and cache on cache miss', function()
            local fetch_called = false
            local val = session.get_cached_setting(123, 'mykey', function()
                fetch_called = true
                return 'db_value'
            end)
            assert.are.equal('db_value', val)
            assert.is_true(fetch_called)
            -- Should now be cached
            assert.is_not_nil(redis.store['cache:setting:123:mykey'])
        end)

        it('should cache nil results as __nil__', function()
            local val = session.get_cached_setting(123, 'mykey', function()
                return nil
            end)
            assert.is_nil(val)
            assert.are.equal('__nil__', redis.store['cache:setting:123:mykey'])
        end)

        it('should return nil for cached __nil__ values', function()
            redis.setex('cache:setting:123:mykey', 300, '__nil__')
            local fetch_called = false
            local val = session.get_cached_setting(123, 'mykey', function()
                fetch_called = true
                return 'should_not_reach'
            end)
            assert.is_nil(val)
            assert.is_false(fetch_called)
        end)

        it('should respect custom TTL', function()
            session.get_cached_setting(123, 'mykey', function()
                return 'val'
            end, 600)
            assert.are.equal(600, redis.ttls['cache:setting:123:mykey'])
        end)
    end)

    describe('get_cached_list()', function()
        it('should return cached list without calling fetch_fn', function()
            -- We need dkjson for this. Mock it.
            package.loaded['dkjson'] = {
                encode = function(t)
                    -- Simple JSON array encoding for tests
                    local items = {}
                    for _, v in ipairs(t) do
                        if type(v) == 'string' then
                            table.insert(items, '"' .. v .. '"')
                        else
                            table.insert(items, tostring(v))
                        end
                    end
                    return '[' .. table.concat(items, ',') .. ']'
                end,
                decode = function(s)
                    if s == '[]' then return {} end
                    -- Simple decoder for string arrays
                    local result = {}
                    for item in s:gmatch('"([^"]+)"') do
                        table.insert(result, item)
                    end
                    return result
                end,
            }

            redis.setex('cache:list:123:filters', 300, '["hello","world"]')
            local fetch_called = false
            local val = session.get_cached_list(123, 'filters', function()
                fetch_called = true
                return { 'from_db' }
            end)
            assert.is_false(fetch_called)
            assert.are.equal(2, #val)
        end)

        it('should call fetch_fn and cache on miss', function()
            package.loaded['dkjson'] = {
                encode = function(t) return '["a","b"]' end,
                decode = function(s) return { 'a', 'b' } end,
            }

            local fetch_called = false
            local val = session.get_cached_list(123, 'filters', function()
                fetch_called = true
                return { 'a', 'b' }
            end)
            assert.is_true(fetch_called)
            assert.is_not_nil(redis.store['cache:list:123:filters'])
        end)

        it('should cache empty results as []', function()
            package.loaded['dkjson'] = {
                encode = function(t) return '[]' end,
                decode = function(s) return {} end,
            }

            local val = session.get_cached_list(123, 'filters', function()
                return nil
            end)
            assert.are.same({}, val)
            assert.are.equal('[]', redis.store['cache:list:123:filters'])
        end)

        it('should invalidate cached list', function()
            redis.setex('cache:list:123:filters', 300, '["hello"]')
            session.invalidate_cached_list(123, 'filters')
            assert.is_nil(redis.store['cache:list:123:filters'])
        end)
    end)

    describe('admin status cache', function()
        it('should return nil when not cached', function()
            local val = session.get_admin_status(123, 456)
            assert.is_nil(val)
        end)

        it('should cache admin=true as "1"', function()
            session.set_admin_status(123, 456, true)
            local val = session.get_admin_status(123, 456)
            assert.is_true(val)
        end)

        it('should cache admin=false as "0"', function()
            session.set_admin_status(123, 456, false)
            local val = session.get_admin_status(123, 456)
            assert.is_false(val)
        end)

        it('should use correct key format', function()
            session.set_admin_status(-100123, 456, true)
            assert.is_not_nil(redis.store['cache:admin:-100123:456'])
        end)

        it('should use 300s TTL', function()
            session.set_admin_status(123, 456, true)
            assert.are.equal(300, redis.ttls['cache:admin:123:456'])
        end)
    end)

    describe('action state', function()
        it('should set and get an action', function()
            session.set_action(123, 100, '/ban')
            local val = session.get_action(123, 100)
            assert.are.equal('/ban', val)
        end)

        it('should return nil for non-existent action', function()
            assert.is_nil(session.get_action(123, 999))
        end)

        it('should delete an action', function()
            session.set_action(123, 100, '/ban')
            session.del_action(123, 100)
            assert.is_nil(session.get_action(123, 100))
        end)

        it('should use 300s TTL for actions', function()
            session.set_action(123, 100, '/ban')
            assert.are.equal(300, redis.ttls['action:123:100'])
        end)
    end)

    describe('AFK status', function()
        it('should set AFK status with timestamp', function()
            session.set_afk(456)
            local afk = session.get_afk(456)
            assert.is_not_nil(afk)
            assert.is_not_nil(afk.since)
            assert.is_nil(afk.note)
        end)

        it('should set AFK status with note', function()
            session.set_afk(456, 'gone fishing')
            local afk = session.get_afk(456)
            assert.is_not_nil(afk)
            assert.are.equal('gone fishing', afk.note)
        end)

        it('should return nil for non-AFK user', function()
            assert.is_nil(session.get_afk(456))
        end)

        it('should clear AFK status', function()
            session.set_afk(456, 'brb')
            session.clear_afk(456)
            assert.is_nil(session.get_afk(456))
        end)

        it('should not set note when note is empty string', function()
            session.set_afk(456, '')
            local afk = session.get_afk(456)
            assert.is_not_nil(afk)
            assert.is_nil(afk.note)
        end)
    end)

    describe('captcha state', function()
        it('should set and get captcha', function()
            session.set_captcha(-100123, 456, 'ABCD', 42)
            local captcha = session.get_captcha(-100123, 456)
            assert.is_not_nil(captcha)
            assert.are.equal('ABCD', captcha.text)
            assert.are.equal('42', captcha.message_id)
        end)

        it('should return nil for non-existent captcha', function()
            assert.is_nil(session.get_captcha(-100123, 456))
        end)

        it('should clear captcha', function()
            session.set_captcha(-100123, 456, 'ABCD', 42)
            session.clear_captcha(-100123, 456)
            assert.is_nil(session.get_captcha(-100123, 456))
        end)

        it('should use custom timeout', function()
            session.set_captcha(-100123, 456, 'ABCD', 42, 120)
            assert.are.equal(120, redis.ttls['captcha:-100123:456'])
        end)

        it('should use default 300s timeout', function()
            session.set_captcha(-100123, 456, 'ABCD', 42)
            assert.are.equal(300, redis.ttls['captcha:-100123:456'])
        end)
    end)

    describe('rate limiting', function()
        it('should increment rate counter', function()
            local count = session.increment_rate(-100123, 456)
            assert.are.equal(1, count)
        end)

        it('should increment counter on subsequent calls', function()
            session.increment_rate(-100123, 456)
            local count = session.increment_rate(-100123, 456)
            assert.are.equal(2, count)
        end)

        it('should set expire on first increment', function()
            session.increment_rate(-100123, 456, 10)
            assert.are.equal(10, redis.ttls['antispam:-100123:456'])
        end)

        it('should use default 5s TTL', function()
            session.increment_rate(-100123, 456)
            assert.are.equal(5, redis.ttls['antispam:-100123:456'])
        end)

        it('should get current rate', function()
            session.increment_rate(-100123, 456)
            session.increment_rate(-100123, 456)
            session.increment_rate(-100123, 456)
            local rate = session.get_rate(-100123, 456)
            assert.are.equal(3, rate)
        end)

        it('should return 0 for no-rate user', function()
            local rate = session.get_rate(-100123, 789)
            assert.are.equal(0, rate)
        end)
    end)

    describe('global blocklist', function()
        it('should check blocklist status (not blocked)', function()
            assert.is_false(session.is_globally_blocklisted(456))
        end)

        it('should set and check blocklist', function()
            session.set_global_blocklist(456)
            assert.is_true(session.is_globally_blocklisted(456))
        end)

        it('should set blocklist with TTL', function()
            session.set_global_blocklist(456, 86400)
            assert.is_true(session.is_globally_blocklisted(456))
            assert.are.equal(86400, redis.ttls['global_blocklist:456'])
        end)

        it('should use single exists call (not double)', function()
            session.is_globally_blocklisted(456)
            -- Should only have one exists command
            local exists_count = redis.count_commands('exists')
            assert.are.equal(1, exists_count)
        end)
    end)

    describe('disabled plugins', function()
        it('should return empty list when no plugins disabled', function()
            local disabled = session.get_disabled_plugins(123)
            assert.are.same({}, disabled)
        end)

        it('should disable a plugin', function()
            session.disable_plugin(123, 'weather')
            assert.is_true(session.is_plugin_disabled(123, 'weather'))
        end)

        it('should not report non-disabled plugin as disabled', function()
            assert.is_false(session.is_plugin_disabled(123, 'weather'))
        end)

        it('should enable a previously disabled plugin', function()
            session.disable_plugin(123, 'weather')
            session.enable_plugin(123, 'weather')
            assert.is_false(session.is_plugin_disabled(123, 'weather'))
        end)

        it('should return list of disabled plugins', function()
            session.disable_plugin(123, 'weather')
            session.disable_plugin(123, 'translate')
            local disabled = session.get_disabled_plugins(123)
            assert.are.equal(2, #disabled)
        end)
    end)
end)
