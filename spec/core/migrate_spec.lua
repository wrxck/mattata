--[[
    Tests for src/core/migrate.lua - v1.5 to v2.x data migration
]]

describe('core.migrate', function()
    local migrate
    local mock_db = require('spec.helpers.mock_db')
    local mock_redis = require('spec.helpers.mock_redis')
    local db, redis
    local tmpdir = os.tmpname():match('(.*/)')

    -- Helper: write a temp file and return its path
    local function write_temp(filename, content)
        local path = tmpdir .. filename
        local f = io.open(path, 'w')
        f:write(content)
        f:close()
        return path
    end

    -- Helper: check if a file exists
    local function file_exists(path)
        local f = io.open(path, 'r')
        if f then f:close(); return true end
        return false
    end

    -- Helper: populate v1 Redis keys for scan detection
    -- mock_redis.scan only checks redis.store, so we must set placeholder values there.
    -- The actual data is in redis.hashes / redis.sets / redis.store (for strings).
    local function set_v1_hash(r, key, data)
        r.store[key] = 'hash'  -- placeholder for scan detection
        r.hashes[key] = data
    end

    local function set_v1_string(r, key, value)
        r.store[key] = value
    end

    local function set_v1_set(r, key, members)
        r.store[key] = 'set'  -- placeholder for scan detection
        r.sets[key] = {}
        for _, m in ipairs(members) do
            r.sets[key][tostring(m)] = true
        end
    end

    before_each(function()
        package.loaded['src.core.migrate'] = nil
        package.loaded['src.core.logger'] = {
            info = function() end,
            warn = function() end,
            error = function() end,
            debug = function() end,
        }
        migrate = require('src.core.migrate')
        db = mock_db.new()
        redis = mock_redis.new()
    end)

    after_each(function()
        db.reset()
        redis.reset()
    end)

    -- ================================================================
    -- Detection tests
    -- ================================================================
    describe('check()', function()
        it('returns detected=false on clean install', function()
            local result = migrate.check(redis, { v1_config_path = '/nonexistent/config.lua' })
            assert.is_false(result.detected)
            assert.is_nil(result.config_file)
            assert.are.equal(0, result.key_count)
        end)

        it('detects v1 config file', function()
            local path = write_temp('test_v1_config.lua', 'return { bot_token = "123:ABC", admins = {111} }')
            local result = migrate.check(redis, { v1_config_path = path })
            assert.is_true(result.detected)
            assert.are.equal(path, result.config_file)
            os.remove(path)
        end)

        it('detects v1 Redis keys', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            set_v1_string(redis, 'chat:-100123:welcome', 'Hello!')
            local result = migrate.check(redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_true(result.detected)
            assert.are.equal(2, result.key_count)
        end)

        it('counts keys accurately across categories', function()
            set_v1_hash(redis, 'chat:-100123:settings', {})
            set_v1_string(redis, 'chat:-100123:welcome', 'Hi')
            set_v1_string(redis, 'chat:-100123:rules', 'Rule 1')
            set_v1_string(redis, 'chat:-100123:warnings:456', '3')
            set_v1_hash(redis, 'chat:-100123:filters', {})
            local result = migrate.check(redis, { v1_config_path = '/nonexistent.lua' })
            assert.are.equal(5, result.key_count)
        end)

        it('does not false-positive on v2 Redis key patterns', function()
            -- v2 patterns: cache:setting:*, disabled_plugins:*
            redis.store['cache:setting:-100123:welcome_enabled'] = 'true'
            redis.store['disabled_plugins:-100123'] = 'set'
            local result = migrate.check(redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_false(result.detected)
            assert.are.equal(0, result.key_count)
        end)
    end)

    -- ================================================================
    -- Config detection tests
    -- ================================================================
    describe('detect_v1_config()', function()
        it('parses valid configuration.lua', function()
            local path = write_temp('test_detect_valid.lua',
                'return { bot_token = "123:ABC", admins = {111, 222}, redis = { host = "localhost", port = 6379 } }')
            local config = migrate.detect_v1_config(path)
            assert.is_not_nil(config)
            assert.are.equal('123:ABC', config.bot_token)
            assert.are.equal(2, #config.admins)
            os.remove(path)
        end)

        it('returns nil for missing file', function()
            local config = migrate.detect_v1_config('/nonexistent/config.lua')
            assert.is_nil(config)
        end)

        it('returns nil for malformed Lua', function()
            local path = write_temp('test_detect_malformed.lua', 'this is not valid lua {{{')
            local config = migrate.detect_v1_config(path)
            assert.is_nil(config)
            os.remove(path)
        end)

        it('handles config with nested keys table', function()
            local path = write_temp('test_detect_keys.lua',
                'return { bot_token = "123:ABC", admins = {111}, keys = { lastfm = "abc123", youtube = "xyz789" } }')
            local config = migrate.detect_v1_config(path)
            assert.is_not_nil(config)
            assert.are.equal('abc123', config.keys.lastfm)
            assert.are.equal('xyz789', config.keys.youtube)
            os.remove(path)
        end)
    end)

    -- ================================================================
    -- Config conversion tests
    -- ================================================================
    describe('convert_config()', function()
        it('converts bot_token and admins', function()
            local env = migrate.convert_config({
                bot_token = '123:ABC',
                admins = { 111, 222 },
            })
            assert.matches('BOT_TOKEN=123:ABC', env)
            assert.matches('BOT_ADMINS=111,222', env)
        end)

        it('converts Redis config', function()
            local env = migrate.convert_config({
                bot_token = '123:ABC',
                admins = { 111 },
                redis = { host = '10.0.0.1', port = 6380, password = 'secret' },
            })
            assert.matches('REDIS_HOST=10.0.0.1', env)
            assert.matches('REDIS_PORT=6380', env)
            assert.matches('REDIS_PASSWORD=secret', env)
        end)

        it('converts API keys', function()
            local env = migrate.convert_config({
                bot_token = '123:ABC',
                admins = { 111 },
                keys = {
                    lastfm = 'lf_key',
                    youtube = 'yt_key',
                    weather = 'wx_key',
                    spotify_client_id = 'sp_id',
                    spotify_client_secret = 'sp_secret',
                    spamwatch = 'sw_token',
                },
            })
            assert.matches('LASTFM_API_KEY=lf_key', env)
            assert.matches('YOUTUBE_API_KEY=yt_key', env)
            assert.matches('OPENWEATHERMAP_API_KEY=wx_key', env)
            assert.matches('SPOTIFY_CLIENT_ID=sp_id', env)
            assert.matches('SPOTIFY_CLIENT_SECRET=sp_secret', env)
            assert.matches('SPAMWATCH_TOKEN=sw_token', env)
        end)

        it('handles missing optional keys gracefully', function()
            local env = migrate.convert_config({
                bot_token = '123:ABC',
                admins = { 111 },
            })
            assert.matches('BOT_TOKEN=123:ABC', env)
            assert.is_not.matches('REDIS_HOST', env)
            assert.is_not.matches('LASTFM_API_KEY', env)
        end)

        it('produces valid key=value format', function()
            local env = migrate.convert_config({
                bot_token = '123:ABC',
                admins = { 111 },
                log_chat = '-100999',
            })
            -- Every non-comment non-empty line should be KEY=VALUE
            for line in env:gmatch('[^\n]+') do
                if not line:match('^#') and line ~= '' then
                    assert.matches('^[A-Z_]+=.+$', line)
                end
            end
        end)

        it('skips empty/nil values', function()
            local env = migrate.convert_config({
                bot_token = '123:ABC',
                admins = { 111 },
                redis = { host = '', port = 6379 },
            })
            assert.is_not.matches('REDIS_HOST=\n', env)
        end)
    end)

    -- ================================================================
    -- Import tests: chat settings
    -- ================================================================
    describe('import_chat_settings()', function()
        it('imports hash fields and maps setting names', function()
            set_v1_hash(redis, 'chat:-100123:settings', {
                welcome = 'true',
                antilink = 'true',
                ['max warnings'] = '5',
            })
            local keys = { 'chat:-100123:settings' }
            local count = migrate.import_chat_settings(db, redis, keys)
            assert.are.equal(3, count)
            -- Check that sp_upsert_chat was called (ensure_chat)
            assert.is_true(db.has_query('sp_upsert_chat'))
            -- Check that sp_upsert_chat_setting_if_missing was called
            assert.is_true(db.has_query('sp_upsert_chat_setting_if_missing'))
        end)

        it('maps v1 names to v2 names', function()
            set_v1_hash(redis, 'chat:-100123:settings', { antilink = 'true' })
            migrate.import_chat_settings(db, redis, { 'chat:-100123:settings' })
            -- Find the call with the mapped name
            local found = false
            for _, q in ipairs(db.queries) do
                if q.func_name == 'sp_upsert_chat_setting_if_missing' and q.params then
                    if q.params[2] == 'antilink_enabled' then
                        found = true
                        break
                    end
                end
            end
            assert.is_true(found, 'Expected antilink to be mapped to antilink_enabled')
        end)
    end)

    -- ================================================================
    -- Import tests: welcome messages
    -- ================================================================
    describe('import_welcome_messages()', function()
        it('imports string to welcome_messages table', function()
            set_v1_string(redis, 'chat:-100123:welcome', 'Welcome to the group!')
            local count = migrate.import_welcome_messages(db, redis, { 'chat:-100123:welcome' })
            assert.are.equal(1, count)
            assert.is_true(db.has_query('sp_upsert_welcome_message'))
        end)

        it('skips empty welcome messages', function()
            set_v1_string(redis, 'chat:-100123:welcome', '')
            local count = migrate.import_welcome_messages(db, redis, { 'chat:-100123:welcome' })
            assert.are.equal(0, count)
        end)
    end)

    -- ================================================================
    -- Import tests: rules
    -- ================================================================
    describe('import_rules()', function()
        it('imports string to rules table', function()
            set_v1_string(redis, 'chat:-100123:rules', '1. Be nice\n2. No spam')
            local count = migrate.import_rules(db, redis, { 'chat:-100123:rules' })
            assert.are.equal(1, count)
            assert.is_true(db.has_query('sp_upsert_rules'))
        end)

        it('skips empty rules', function()
            set_v1_string(redis, 'chat:-100123:rules', '')
            local count = migrate.import_rules(db, redis, { 'chat:-100123:rules' })
            assert.are.equal(0, count)
        end)
    end)

    -- ================================================================
    -- Import tests: warnings
    -- ================================================================
    describe('import_warnings()', function()
        it('sets v2 Redis hash and inserts DB rows', function()
            set_v1_string(redis, 'chat:-100123:warnings:456', '3')
            local count = migrate.import_warnings(db, redis, { 'chat:-100123:warnings:456' })
            assert.are.equal(3, count)
            -- Check v2 Redis hash was set
            assert.are.equal('3', redis.hashes['chat:-100123:456'] and redis.hashes['chat:-100123:456']['warnings'])
            -- Check DB calls (sp_insert_warning called 3 times)
            local warning_calls = 0
            for _, q in ipairs(db.queries) do
                if q.func_name == 'sp_insert_warning' then
                    warning_calls = warning_calls + 1
                end
            end
            assert.are.equal(3, warning_calls)
        end)

        it('skips zero warnings', function()
            set_v1_string(redis, 'chat:-100123:warnings:456', '0')
            local count = migrate.import_warnings(db, redis, { 'chat:-100123:warnings:456' })
            assert.are.equal(0, count)
        end)
    end)

    -- ================================================================
    -- Import tests: disabled plugins
    -- ================================================================
    describe('import_disabled_plugins()', function()
        it('inserts to DB table and Redis set', function()
            set_v1_hash(redis, 'chat:-100123:disabled_plugins', {
                welcome = 'true',
                lastfm = 'true',
            })
            local count = migrate.import_disabled_plugins(db, redis, { 'chat:-100123:disabled_plugins' })
            assert.are.equal(2, count)
            -- Check Redis set was populated with v2 mapped names
            assert.are.equal(1, redis.sismember('disabled_plugins:-100123', 'greeting'))
            assert.are.equal(1, redis.sismember('disabled_plugins:-100123', 'lastfm'))
        end)

        it('maps v1 plugin names to v2 names', function()
            set_v1_hash(redis, 'chat:-100123:disabled_plugins', { administration = 'true' })
            migrate.import_disabled_plugins(db, redis, { 'chat:-100123:disabled_plugins' })
            -- "administration" should map to "admin"
            assert.are.equal(1, redis.sismember('disabled_plugins:-100123', 'admin'))
        end)
    end)

    -- ================================================================
    -- Import tests: filters
    -- ================================================================
    describe('import_filters()', function()
        it('imports pattern/action pairs', function()
            set_v1_hash(redis, 'chat:-100123:filters', {
                ['bad word'] = 'delete',
                ['spam link'] = 'ban',
            })
            local count = migrate.import_filters(db, redis, { 'chat:-100123:filters' })
            assert.are.equal(2, count)
            assert.is_true(db.has_query('sp_insert_filter'))
        end)

        it('handles empty filter hash', function()
            set_v1_hash(redis, 'chat:-100123:filters', {})
            local count = migrate.import_filters(db, redis, { 'chat:-100123:filters' })
            assert.are.equal(0, count)
        end)
    end)

    -- ================================================================
    -- Import tests: triggers
    -- ================================================================
    describe('import_triggers()', function()
        it('imports pattern/response pairs', function()
            set_v1_hash(redis, 'chat:-100123:triggers', {
                ['hello'] = 'Hi there!',
                ['bye'] = 'Goodbye!',
            })
            local count = migrate.import_triggers(db, redis, { 'chat:-100123:triggers' })
            assert.are.equal(2, count)
            assert.is_true(db.has_query('sp_insert_trigger'))
        end)

        it('handles empty trigger hash', function()
            set_v1_hash(redis, 'chat:-100123:triggers', {})
            local count = migrate.import_triggers(db, redis, { 'chat:-100123:triggers' })
            assert.are.equal(0, count)
        end)
    end)

    -- ================================================================
    -- Import tests: bans
    -- ================================================================
    describe('import_bans()', function()
        it('imports set members to blocklist', function()
            set_v1_set(redis, 'chat:-100123:bans', { 111, 222, 333 })
            local count = migrate.import_bans(db, redis, { 'chat:-100123:bans' })
            assert.are.equal(3, count)
            assert.is_true(db.has_query('sp_upsert_blocklist_entry'))
        end)

        it('handles empty ban set', function()
            set_v1_set(redis, 'chat:-100123:bans', {})
            local count = migrate.import_bans(db, redis, { 'chat:-100123:bans' })
            assert.are.equal(0, count)
        end)
    end)

    -- ================================================================
    -- Pipeline tests
    -- ================================================================
    describe('run()', function()
        it('succeeds end-to-end with v1 data', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            set_v1_string(redis, 'chat:-100123:welcome', 'Hello!')
            set_v1_string(redis, 'chat:-100123:rules', 'Be nice')
            set_v1_hash(redis, 'chat:-100123:filters', { spam = 'delete' })
            set_v1_hash(redis, 'chat:-100123:triggers', { hi = 'hello' })
            set_v1_set(redis, 'chat:-100123:bans', { 999 })

            local result = migrate.run(db, redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_true(result.success)
            assert.is_false(result.already_migrated)
            assert.is_true(result.records_imported > 0)
        end)

        it('is idempotent via schema_migrations check', function()
            -- Simulate already-migrated state
            db.set_next_result({ { ['?column?'] = 1 } })
            local result = migrate.run(db, redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_true(result.success)
            assert.is_true(result.already_migrated)
        end)

        it('dry_run mode does not write to DB', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            local result = migrate.run(db, redis, {
                dry_run = true,
                v1_config_path = '/nonexistent.lua',
            })
            assert.is_true(result.success)
            -- Should not have any BEGIN/COMMIT queries
            assert.is_false(db.has_query('BEGIN'))
        end)

        it('skip_cleanup preserves v1 keys', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            local result = migrate.run(db, redis, {
                skip_cleanup = true,
                v1_config_path = '/nonexistent.lua',
            })
            assert.is_true(result.success)
            assert.are.equal(0, result.keys_cleaned)
            -- Key should still exist
            assert.is_not_nil(redis.store['chat:-100123:settings'])
        end)

        it('cleans up v1 keys after success', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            set_v1_string(redis, 'chat:-100123:welcome', 'Hello!')
            local result = migrate.run(db, redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_true(result.success)
            assert.are.equal(2, result.keys_cleaned)
            -- Keys should be deleted
            assert.is_nil(redis.store['chat:-100123:settings'])
            assert.is_nil(redis.store['chat:-100123:welcome'])
        end)

        it('rolls back on DB error', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            -- Make db.call throw an error
            local orig_call = db.call
            db.call = function(func_name, params)
                if func_name == 'sp_upsert_chat' then
                    error('simulated DB error')
                end
                return orig_call(func_name, params)
            end
            local result = migrate.run(db, redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_false(result.success)
            assert.is_true(#result.errors > 0)
            assert.matches('simulated DB error', result.errors[1])
            -- ROLLBACK should have been issued
            assert.is_true(db.has_query('ROLLBACK'))
        end)

        it('reports errors without crashing', function()
            set_v1_hash(redis, 'chat:-100123:settings', { welcome = 'true' })
            local orig_call = db.call
            db.call = function(func_name, params)
                if func_name == 'sp_upsert_chat_setting_if_missing' then
                    error('constraint violation')
                end
                return orig_call(func_name, params)
            end
            local result = migrate.run(db, redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_false(result.success)
            assert.is_true(#result.errors > 0)
        end)

        it('is a no-op when no v1 data detected', function()
            local result = migrate.run(db, redis, { v1_config_path = '/nonexistent.lua' })
            assert.is_true(result.success)
            assert.are.equal(0, result.records_imported)
            assert.are.equal(0, result.keys_cleaned)
        end)
    end)

    -- ================================================================
    -- Cleanup tests
    -- ================================================================
    describe('cleanup_v1_keys()', function()
        it('deletes all categorized keys', function()
            local keys = {
                settings = { 'chat:-100123:settings', 'chat:-100456:settings' },
                welcome = { 'chat:-100123:welcome' },
                rules = {},
                _total = 3,
            }
            -- Populate the store so del has something to remove
            redis.store['chat:-100123:settings'] = 'hash'
            redis.store['chat:-100456:settings'] = 'hash'
            redis.store['chat:-100123:welcome'] = 'Hello'

            local count = migrate.cleanup_v1_keys(redis, keys)
            assert.are.equal(3, count)
            assert.is_nil(redis.store['chat:-100123:settings'])
            assert.is_nil(redis.store['chat:-100456:settings'])
            assert.is_nil(redis.store['chat:-100123:welcome'])
        end)

        it('returns accurate count', function()
            local keys = {
                settings = { 'chat:-100123:settings' },
                welcome = { 'chat:-100123:welcome' },
                rules = { 'chat:-100123:rules' },
                warnings = { 'chat:-100123:warnings:456' },
                _total = 4,
            }
            local count = migrate.cleanup_v1_keys(redis, keys)
            assert.are.equal(4, count)
        end)
    end)
end)
