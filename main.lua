--[[
                   _   _        _
   _ __ ___   __ _| |_| |_ __ _| |_ __ _
  | '_ ` _ \ / _` | __| __/ _` | __/ _` |
  | | | | | | (_| | |_| || (_| | || (_| |
  |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|

  v2.1

  Copyright 2020-2026 Matthew Hesketh <matthew@matthewhesketh.com>
  See LICENSE for details
]]

local config = require('src.core.config')
local logger = require('src.core.logger')
local database = require('src.core.database')
local redis = require('src.core.redis')
local session = require('src.core.session')
local i18n = require('src.core.i18n')
local loader = require('src.core.loader')
local router = require('src.core.router')
local migrations = require('src.db.init')

-- 1. Load configuration
config.load('.env')
logger.init()
logger.info('mattata v%s starting...', config.VERSION)

-- 2. Validate required config
assert(config.bot_token(), 'BOT_TOKEN is required. Set it in .env or as an environment variable.')

-- 3. Configure telegram-bot-lua
local api = require('telegram-bot-lua').configure(config.bot_token())
local tools = require('telegram-bot-lua.tools')
logger.info('Bot: @%s (%s) [%d]', api.info.username, api.info.first_name, api.info.id)

-- 4. Connect to PostgreSQL
local db_ok, db_err = database.connect()
if not db_ok then
    logger.error('Cannot start without PostgreSQL: %s', tostring(db_err))
    os.exit(1)
end

-- 5. Run database migrations
migrations.run(database)

-- 6. Connect to Redis
local redis_ok, redis_err = redis.connect()
if not redis_ok then
    logger.error('Cannot start without Redis: %s', tostring(redis_err))
    os.exit(1)
end
session.init(redis)

-- 7. Load languages
i18n.init()

-- 8. Load all plugins
loader.init(api, database, redis)

-- 9. Build context factory and start router
local ctx_base = {
    api = api,
    tools = tools,
    db = database,
    redis = redis,
    session = session,
    config = config,
    i18n = i18n,
    permissions = require('src.core.permissions'),
    logger = logger
}

router.init(api, tools, loader, ctx_base)

-- 10. Register bot command menu with Telegram
local json = require('dkjson')
local user_commands = {}
local admin_commands = {}
for _, plugin in ipairs(loader.get_plugins()) do
    if plugin.commands and #plugin.commands > 0 and plugin.description and plugin.description ~= '' then
        local entry = { command = plugin.commands[1], description = plugin.description }
        if plugin.admin_only or plugin.global_admin_only then
            table.insert(admin_commands, entry)
        else
            table.insert(user_commands, entry)
        end
    end
end
-- Set default commands (visible to all users)
api.set_my_commands(json.encode(user_commands))
-- Set admin commands (visible to group admins only)
if #admin_commands > 0 then
    -- Merge user + admin so admins see everything
    local all_commands = {}
    for _, cmd in ipairs(user_commands) do table.insert(all_commands, cmd) end
    for _, cmd in ipairs(admin_commands) do table.insert(all_commands, cmd) end
    api.set_my_commands(json.encode(all_commands), { type = 'all_chat_administrators' })
end
logger.info('Registered %d user commands and %d admin commands with Telegram', #user_commands, #admin_commands)

-- 11. Notify admins
local info_msg = string.format(
    '<pre>mattata v%s connected!\n\n  Username: @%s\n  Name: %s\n  ID: %d\n  Plugins: %d</pre>',
    config.VERSION,
    tools.escape_html(api.info.username),
    tools.escape_html(api.info.first_name),
    api.info.id,
    loader.count()
)
if config.log_chat() then
    api.send_message(config.log_chat(), info_msg, 'html')
end
for _, admin_id in ipairs(config.bot_admins()) do
    api.send_message(admin_id, info_msg, 'html')
end

-- 12. Start the bot
logger.info('Starting main loop...')
router.run()
