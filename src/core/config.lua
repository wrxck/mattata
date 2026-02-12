--[[
    mattata v2.0 - Configuration Module
    Reads configuration from .env file with os.getenv() fallback.
    Provides typed access to all configuration values.
]]

local config = {}

local env_values = {}
local loaded = false

-- Parse a .env file into a table
local function parse_env_file(path)
    local values = {}
    local file = io.open(path, 'r')
    if not file then
        return values
    end
    for line in file:lines() do
        line = line:match('^%s*(.-)%s*$') -- trim
        if line ~= '' and not line:match('^#') then
            local key, value = line:match('^([%w_]+)%s*=%s*(.*)$')
            if key then
                -- Strip surrounding quotes
                value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value
                -- Strip inline comments (only for unquoted values)
                value = value:match('^(.-)%s+#') or value
                values[key] = value
            end
        end
    end
    file:close()
    return values
end

-- Load .env file (called once)
function config.load(path)
    path = path or '.env'
    env_values = parse_env_file(path)
    loaded = true
end

-- Get a string value with optional default
function config.get(key, default)
    if not loaded then
        config.load()
    end
    local value = env_values[key]
    if value == nil or value == '' then
        value = os.getenv(key)
    end
    if value == nil or value == '' then
        return default
    end
    return value
end

-- Get a numeric value
function config.get_number(key, default)
    local value = config.get(key)
    if value == nil then
        return default
    end
    return tonumber(value) or default
end

-- Get a boolean value
function config.is_enabled(key)
    local value = config.get(key)
    if value == nil then
        return false
    end
    value = value:lower()
    return value == 'true' or value == '1' or value == 'yes'
end

-- Get a comma-separated list as a table
function config.get_list(key)
    local value = config.get(key)
    if not value or value == '' then
        return {}
    end
    local list = {}
    for item in value:gmatch('[^,]+') do
        item = item:match('^%s*(.-)%s*$')
        if item ~= '' then
            local num = tonumber(item)
            table.insert(list, num or item)
        end
    end
    return list
end

-- Convenience accessors for common config groups
function config.bot_token()
    return config.get('BOT_TOKEN')
end

function config.bot_admins()
    return config.get_list('BOT_ADMINS')
end

function config.bot_name()
    return config.get('BOT_NAME', 'mattata')
end

function config.database()
    return {
        host = config.get('DATABASE_HOST', 'postgres'),
        port = config.get_number('DATABASE_PORT', 5432),
        database = config.get('DATABASE_NAME', 'mattata'),
        user = config.get('DATABASE_USER', 'mattata'),
        password = config.get('DATABASE_PASSWORD', 'changeme')
    }
end

function config.redis_config()
    return {
        host = config.get('REDIS_HOST', 'redis'),
        port = config.get_number('REDIS_PORT', 6379),
        password = config.get('REDIS_PASSWORD'),
        db = config.get_number('REDIS_DB', 0)
    }
end

function config.polling()
    return {
        timeout = config.get_number('POLLING_TIMEOUT', 60),
        limit = config.get_number('POLLING_LIMIT', 100)
    }
end

function config.webhook()
    return {
        enabled = config.is_enabled('WEBHOOK_ENABLED'),
        url = config.get('WEBHOOK_URL'),
        port = config.get_number('WEBHOOK_PORT', 8443),
        secret = config.get('WEBHOOK_SECRET')
    }
end

function config.ai()
    return {
        enabled = config.is_enabled('AI_ENABLED'),
        openai_key = config.get('OPENAI_API_KEY'),
        openai_model = config.get('OPENAI_MODEL', 'gpt-4o'),
        anthropic_key = config.get('ANTHROPIC_API_KEY'),
        anthropic_model = config.get('ANTHROPIC_MODEL', 'claude-sonnet-4-5-20250929')
    }
end

function config.debug()
    return config.is_enabled('DEBUG')
end

function config.log_chat()
    return config.get_number('LOG_CHAT')
end

-- Version constant
config.VERSION = '2.1'

return config
