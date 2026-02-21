--[[
    mattata v2.1 - v1.5 Data Migration
    Detects v1.5 installations and imports data into the v2 schema.
    Handles: config conversion, chat settings, welcome messages, rules,
    warnings, disabled plugins, filters, triggers, and bans.
]]

local migrate = {}

local logger = require('src.core.logger')

-- v1 setting names -> v2 setting names
local SETTING_KEY_MAP = {
    ['antilink'] = 'antilink_enabled',
    ['welcome'] = 'welcome_enabled',
    ['captcha'] = 'captcha_enabled',
    ['antibot'] = 'antibot_enabled',
    ['antiarabic'] = 'antiarabic_enabled',
    ['antiflood'] = 'antiflood_enabled',
    ['antispam'] = 'antispam_enabled',
    ['antiforward'] = 'antiforward_enabled',
    ['rtl'] = 'rtl_enabled',
    ['max warnings'] = 'max_warnings',
    ['delete commands'] = 'delete_commands',
    ['force group language'] = 'force_group_language',
    ['language'] = 'language',
    ['log admin actions'] = 'log_admin_actions',
    ['welcome message'] = 'welcome_enabled',
    ['use administration'] = 'use_administration',
}

-- v1 plugin names -> v2 plugin names (most are identical)
local PLUGIN_NAME_MAP = {
    ['administration'] = 'admin',
    ['antispam'] = 'antispam',
    ['captcha'] = 'captcha',
    ['welcome'] = 'greeting',
    ['lastfm'] = 'lastfm',
    ['translate'] = 'translate',
    ['weather'] = 'weather',
    ['youtube'] = 'youtube',
    ['spotify'] = 'spotify',
    ['wikipedia'] = 'wikipedia',
    ['currency'] = 'currency',
    ['help'] = 'help',
    ['id'] = 'id',
    ['ban'] = 'ban',
    ['kick'] = 'kick',
    ['mute'] = 'mute',
    ['warn'] = 'warn',
    ['pin'] = 'pin',
    ['report'] = 'report',
    ['rules'] = 'rules',
    ['setlang'] = 'setlang',
    ['settings'] = 'settings',
}

-- v1 config key -> .env key mapping
local CONFIG_KEY_MAP = {
    { v1 = 'bot_token', env = 'BOT_TOKEN' },
    { v1 = 'log_channel', env = 'LOG_CHAT' },
    { v1 = 'log_chat', env = 'LOG_CHAT' },
}

local CONFIG_API_KEY_MAP = {
    { v1 = 'lastfm', env = 'LASTFM_API_KEY' },
    { v1 = 'youtube', env = 'YOUTUBE_API_KEY' },
    { v1 = 'weather', env = 'OPENWEATHERMAP_API_KEY' },
    { v1 = 'spotify_client_id', env = 'SPOTIFY_CLIENT_ID' },
    { v1 = 'spotify_client_secret', env = 'SPOTIFY_CLIENT_SECRET' },
    { v1 = 'spamwatch', env = 'SPAMWATCH_TOKEN' },
}

-- v1 Redis key patterns (distinct from v2 patterns)
local V1_KEY_PATTERNS = {
    settings = 'chat:*:settings',
    welcome = 'chat:*:welcome',
    rules = 'chat:*:rules',
    warnings = 'chat:*:warnings:*',
    disabled_plugins = 'chat:*:disabled_plugins',
    filters = 'chat:*:filters',
    triggers = 'chat:*:triggers',
    bans = 'chat:*:bans',
}

-- Extract chat_id from a v1 Redis key like "chat:-100123:settings"
local function extract_chat_id(key)
    local id = key:match('^chat:(%-?%d+):')
    return id and tonumber(id) or nil
end

-- Extract user_id from a warnings key like "chat:-100123:warnings:456"
local function extract_warning_user_id(key)
    local uid = key:match(':warnings:(%d+)$')
    return uid and tonumber(uid) or nil
end

-- Ensure a chat row exists in PostgreSQL
local function ensure_chat(db, chat_id)
    db.call('sp_upsert_chat', { chat_id, 'Imported Chat', 'supergroup', nil })
end

--- Detect a v1.5 configuration.lua file
-- @param path string: path to configuration.lua (default: 'configuration.lua')
-- @return table|nil: parsed config table, or nil if not found/invalid
function migrate.detect_v1_config(path)
    path = path or 'configuration.lua'
    local f = io.open(path, 'r')
    if not f then return nil end
    f:close()

    -- Load in a sandboxed environment (no os, io, require)
    local sandbox = {
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        table = { insert = table.insert, concat = table.concat },
        string = { format = string.format, match = string.match },
        math = { floor = math.floor },
    }
    local chunk, err = loadfile(path, 't', sandbox)
    if not chunk then
        logger.warn('Failed to parse v1 config %s: %s', path, tostring(err))
        return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
        logger.warn('Failed to execute v1 config %s: %s', path, tostring(result))
        return nil
    end

    -- Validate: must have bot_token and admins
    if type(result) ~= 'table' then return nil end
    if not result.bot_token and not result['bot_token'] then return nil end
    if not result.admins and not result['admins'] then return nil end

    return result
end

--- Convert a v1 config table to .env format string
-- @param v1_config table: parsed v1 configuration table
-- @return string: .env file content
function migrate.convert_config(v1_config)
    if not v1_config or type(v1_config) ~= 'table' then
        return ''
    end

    local lines = { '# Auto-generated from v1.5 configuration.lua' }

    -- Direct top-level mappings
    for _, mapping in ipairs(CONFIG_KEY_MAP) do
        local val = v1_config[mapping.v1]
        if val and tostring(val) ~= '' then
            table.insert(lines, mapping.env .. '=' .. tostring(val))
        end
    end

    -- Admins (table -> comma-joined)
    if type(v1_config.admins) == 'table' then
        local admin_ids = {}
        for _, id in ipairs(v1_config.admins) do
            table.insert(admin_ids, tostring(id))
        end
        if #admin_ids > 0 then
            table.insert(lines, 'BOT_ADMINS=' .. table.concat(admin_ids, ','))
        end
    end

    -- Redis config
    if type(v1_config.redis) == 'table' then
        if v1_config.redis.host and tostring(v1_config.redis.host) ~= '' then
            table.insert(lines, 'REDIS_HOST=' .. tostring(v1_config.redis.host))
        end
        if v1_config.redis.port then
            table.insert(lines, 'REDIS_PORT=' .. tostring(v1_config.redis.port))
        end
        if v1_config.redis.password and tostring(v1_config.redis.password) ~= '' then
            table.insert(lines, 'REDIS_PASSWORD=' .. tostring(v1_config.redis.password))
        end
    end

    -- API keys from keys subtable
    if type(v1_config.keys) == 'table' then
        for _, mapping in ipairs(CONFIG_API_KEY_MAP) do
            local val = v1_config.keys[mapping.v1]
            if val and tostring(val) ~= '' then
                table.insert(lines, mapping.env .. '=' .. tostring(val))
            end
        end
    end

    table.insert(lines, '')
    return table.concat(lines, '\n')
end

--- Scan Redis for v1-era key patterns
-- @param redis table: Redis connection
-- @return table: categorized keys { settings = {...}, welcome = {...}, ... }
function migrate.scan_v1_keys(redis)
    local result = {}
    local total = 0
    for category, pattern in pairs(V1_KEY_PATTERNS) do
        local keys = redis.scan(pattern)
        result[category] = keys or {}
        total = total + #(keys or {})
    end
    result._total = total
    return result
end

--- Check if v1.5 data is present
-- @param redis table: Redis connection
-- @param opts table: optional { v1_config_path = 'configuration.lua' }
-- @return table: { detected = bool, config_file = path|nil, key_count = number }
function migrate.check(redis, opts)
    opts = opts or {}
    local config_path = opts.v1_config_path or 'configuration.lua'

    local config_detected = false
    local f = io.open(config_path, 'r')
    if f then
        f:close()
        config_detected = true
    end

    local keys = migrate.scan_v1_keys(redis)
    local key_count = keys._total or 0

    return {
        detected = config_detected or key_count > 0,
        config_file = config_detected and config_path or nil,
        key_count = key_count,
    }
end

--- Import chat settings from v1 Redis hashes to PostgreSQL
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 setting keys
-- @return number: count of imported records
function migrate.import_chat_settings(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            ensure_chat(db, chat_id)
            local settings = redis.hgetall(key)
            for field, value in pairs(settings) do
                local mapped = SETTING_KEY_MAP[field] or field
                db.call('sp_upsert_chat_setting_if_missing', { chat_id, mapped, value })
                count = count + 1
            end
        end
    end
    return count
end

--- Import welcome messages from v1 Redis strings to PostgreSQL
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 welcome keys
-- @return number: count of imported records
function migrate.import_welcome_messages(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            local message = redis.get(key)
            if message and message ~= '' then
                ensure_chat(db, chat_id)
                db.call('sp_upsert_welcome_message', { chat_id, message })
                count = count + 1
            end
        end
    end
    return count
end

--- Import rules from v1 Redis strings to PostgreSQL
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 rules keys
-- @return number: count of imported records
function migrate.import_rules(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            local rules_text = redis.get(key)
            if rules_text and rules_text ~= '' then
                ensure_chat(db, chat_id)
                db.call('sp_upsert_rules', { chat_id, rules_text })
                count = count + 1
            end
        end
    end
    return count
end

--- Import warnings from v1 Redis strings to v2 Redis hashes + PostgreSQL
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 warning keys
-- @return number: count of imported records
function migrate.import_warnings(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        local user_id = extract_warning_user_id(key)
        if chat_id and user_id then
            local warn_count = tonumber(redis.get(key)) or 0
            if warn_count > 0 then
                ensure_chat(db, chat_id)
                -- Set v2 Redis hash (matches warn plugin pattern)
                local v2_key = 'chat:' .. chat_id .. ':' .. user_id
                redis.hset(v2_key, 'warnings', tostring(warn_count))
                -- Insert warning rows in DB
                for _ = 1, warn_count do
                    db.call('sp_insert_warning', { chat_id, user_id, 0, 'Imported from v1.5' })
                end
                count = count + warn_count
            end
        end
    end
    return count
end

--- Import disabled plugins from v1 Redis hashes to PostgreSQL + v2 Redis sets
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 disabled_plugins keys
-- @return number: count of imported records
function migrate.import_disabled_plugins(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            ensure_chat(db, chat_id)
            local plugins = redis.hgetall(key)
            for name in pairs(plugins) do
                local mapped = PLUGIN_NAME_MAP[name] or name
                -- Insert into PostgreSQL disabled_plugins table
                db.execute(
                    'INSERT INTO disabled_plugins (chat_id, plugin_name) VALUES ($1, $2) ON CONFLICT DO NOTHING',
                    { chat_id, mapped }
                )
                -- Also set v2 Redis set (matches session.lua pattern)
                redis.sadd('disabled_plugins:' .. chat_id, mapped)
                count = count + 1
            end
        end
    end
    return count
end

--- Import filters from v1 Redis hashes to PostgreSQL
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 filter keys
-- @return number: count of imported records
function migrate.import_filters(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            ensure_chat(db, chat_id)
            local filters = redis.hgetall(key)
            for pattern, action in pairs(filters) do
                db.call('sp_insert_filter', { chat_id, pattern, action, nil })
                count = count + 1
            end
        end
    end
    return count
end

--- Import triggers from v1 Redis hashes to PostgreSQL
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 trigger keys
-- @return number: count of imported records
function migrate.import_triggers(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            ensure_chat(db, chat_id)
            local triggers = redis.hgetall(key)
            for pattern, response in pairs(triggers) do
                db.call('sp_insert_trigger', { chat_id, pattern, response, nil })
                count = count + 1
            end
        end
    end
    return count
end

--- Import bans from v1 Redis sets to PostgreSQL group_blocklist
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param keys table: array of v1 ban keys
-- @return number: count of imported records
function migrate.import_bans(db, redis, keys)
    local count = 0
    for _, key in ipairs(keys) do
        local chat_id = extract_chat_id(key)
        if chat_id then
            ensure_chat(db, chat_id)
            local members = redis.smembers(key)
            for _, user_id_str in ipairs(members) do
                local user_id = tonumber(user_id_str)
                if user_id then
                    db.call('sp_upsert_blocklist_entry', { chat_id, user_id, 'Imported from v1.5' })
                    count = count + 1
                end
            end
        end
    end
    return count
end

--- Clean up all v1 Redis keys after successful migration
-- @param redis table: Redis connection
-- @param keys table: categorized key map from scan_v1_keys
-- @return number: count of deleted keys
function migrate.cleanup_v1_keys(redis, keys)
    local count = 0
    for category, key_list in pairs(keys) do
        if category ~= '_total' then
            for _, key in ipairs(key_list) do
                redis.del(key)
                count = count + 1
            end
        end
    end
    return count
end

--- Run the full v1.5 -> v2.x migration pipeline
-- @param db table: database connection
-- @param redis table: Redis connection
-- @param opts table: { dry_run = false, skip_cleanup = false, v1_config_path = 'configuration.lua' }
-- @return table: { success, already_migrated, config_migrated, records_imported, keys_cleaned, errors }
function migrate.run(db, redis, opts)
    opts = opts or {}
    local dry_run = opts.dry_run or false
    local skip_cleanup = opts.skip_cleanup or false
    local config_path = opts.v1_config_path or 'configuration.lua'

    local result = {
        success = false,
        already_migrated = false,
        config_migrated = false,
        records_imported = 0,
        keys_cleaned = 0,
        errors = {},
    }

    -- 1. Check if already migrated
    local applied = db.execute(
        'SELECT 1 FROM schema_migrations WHERE name = $1',
        { 'v1_data_import' }
    )
    if applied and #applied > 0 then
        result.success = true
        result.already_migrated = true
        return result
    end

    -- 2. Detect and convert v1 config
    local v1_config = migrate.detect_v1_config(config_path)
    if v1_config and not dry_run then
        local env_file = io.open('.env', 'r')
        if not env_file then
            local env_content = migrate.convert_config(v1_config)
            local out = io.open('.env', 'w')
            if out then
                out:write(env_content)
                out:close()
                result.config_migrated = true
                logger.info('Converted v1 configuration.lua to .env')
            end
        else
            env_file:close()
            logger.info('Skipping config conversion: .env already exists')
        end
    end

    -- 3. Scan v1 Redis keys
    local keys = migrate.scan_v1_keys(redis)
    if keys._total == 0 and not v1_config then
        result.success = true
        return result
    end

    if dry_run then
        result.success = true
        result.records_imported = keys._total
        return result
    end

    -- 4-7. Run imports inside a transaction
    local import_count = 0
    local tx_ok, tx_err = pcall(function()
        db.query('BEGIN')

        -- 5. Import all categories
        if keys.settings and #keys.settings > 0 then
            import_count = import_count + migrate.import_chat_settings(db, redis, keys.settings)
        end
        if keys.welcome and #keys.welcome > 0 then
            import_count = import_count + migrate.import_welcome_messages(db, redis, keys.welcome)
        end
        if keys.rules and #keys.rules > 0 then
            import_count = import_count + migrate.import_rules(db, redis, keys.rules)
        end
        if keys.warnings and #keys.warnings > 0 then
            import_count = import_count + migrate.import_warnings(db, redis, keys.warnings)
        end
        if keys.disabled_plugins and #keys.disabled_plugins > 0 then
            import_count = import_count + migrate.import_disabled_plugins(db, redis, keys.disabled_plugins)
        end
        if keys.filters and #keys.filters > 0 then
            import_count = import_count + migrate.import_filters(db, redis, keys.filters)
        end
        if keys.triggers and #keys.triggers > 0 then
            import_count = import_count + migrate.import_triggers(db, redis, keys.triggers)
        end
        if keys.bans and #keys.bans > 0 then
            import_count = import_count + migrate.import_bans(db, redis, keys.bans)
        end

        -- 6. Record migration
        db.execute(
            'INSERT INTO schema_migrations (name) VALUES ($1)',
            { 'v1_data_import' }
        )

        -- 7. Commit
        db.query('COMMIT')
    end)

    if not tx_ok then
        db.query('ROLLBACK')
        table.insert(result.errors, tostring(tx_err))
        logger.error('v1.5 migration failed, rolled back: %s', tostring(tx_err))
        return result
    end

    result.records_imported = import_count

    -- 8. Cleanup v1 keys
    if not skip_cleanup then
        result.keys_cleaned = migrate.cleanup_v1_keys(redis, keys)
    end

    -- 9. Rename configuration.lua
    local config_exists = io.open(config_path, 'r')
    if config_exists then
        config_exists:close()
        os.rename(config_path, config_path .. '.v1.bak')
    end

    result.success = true
    return result
end

return migrate
