# Contributing to mattata

## Plugin Development

### Plugin Contract

Every plugin must export a table with these fields:

```lua
local plugin = {}
plugin.name = 'mycommand'           -- Unique identifier
plugin.category = 'utility'          -- admin, utility, fun, media, ai
plugin.description = 'Short desc'    -- For help text
plugin.commands = { 'cmd', 'alias' } -- Without / prefix
plugin.help = '/cmd [args] - Usage.' -- Full usage text

-- Optional flags
plugin.group_only = false            -- Restrict to groups
plugin.admin_only = false            -- Require group admin
plugin.global_admin_only = false     -- Require bot owner
plugin.permanent = false             -- Cannot be disabled
```

### Handler Functions

```lua
-- Command handler (when /cmd matches)
function plugin.on_message(api, message, ctx) end

-- Callback query handler (buttons with data "pluginname:data")
function plugin.on_callback_query(api, callback_query, message, ctx) end

-- Passive handler (runs on every message, no command needed)
function plugin.on_new_message(api, message, ctx) end

-- New member handler
function plugin.on_member_join(api, message, ctx) end

-- Inline query handler
function plugin.on_inline_query(api, inline_query, ctx) end

-- Reaction changes
function plugin.on_reaction(api, update, ctx) end

-- Member status changes (join, leave, promoted, etc.)
function plugin.on_chat_member_update(api, update, ctx) end

-- Bot's own membership changes
function plugin.on_my_chat_member(api, update, ctx) end

-- Join request received
function plugin.on_chat_join_request(api, update, ctx) end

-- Poll state change
function plugin.on_poll(api, update, ctx) end

-- User voted on poll
function plugin.on_poll_answer(api, update, ctx) end

-- Chat boost received
function plugin.on_chat_boost(api, update, ctx) end

-- Chat boost removed
function plugin.on_removed_chat_boost(api, update, ctx) end

-- Cron job (runs every minute)
function plugin.cron(api, ctx) end
```

### Context Object (`ctx`)

| Field | Type | Description |
|-------|------|-------------|
| `ctx.api` | table | Telegram Bot API |
| `ctx.db` | table | PostgreSQL via stored procedures — use `ctx.db.call('sp_name', {args})` |
| `ctx.http` | table | Async HTTP client — `ctx.http.get(url)`, `ctx.http.post(url, body)` |
| `ctx.redis` | table | Redis client proxy |
| `ctx.session` | table | Session/cache manager |
| `ctx.config` | table | Configuration reader |
| `ctx.i18n` | table | Language manager |
| `ctx.permissions` | table | Permission checks |
| `ctx.lang` | table | Current language strings |
| `ctx.is_group` | bool | Is group chat |
| `ctx.is_admin` | bool | Is user group admin |
| `ctx.is_global_admin` | bool | Is user bot owner |

### Adding a Plugin

1. Create your plugin in the appropriate category directory
2. Add the plugin name to the category's `src/plugins/<category>/init.lua`
3. Test with `/reload` (admin only)

### Database Migrations

If your plugin needs database tables or stored procedures, add a migration file to `src/db/migrations/`:

```lua
local migration = {}
function migration.up()
    return [[
        CREATE TABLE IF NOT EXISTS my_table (
            id SERIAL PRIMARY KEY,
            ...
        );

        CREATE OR REPLACE FUNCTION sp_my_operation(p_id BIGINT, p_value TEXT)
        RETURNS VOID AS $$
        BEGIN
            INSERT INTO my_table (id, value) VALUES (p_id, p_value)
            ON CONFLICT (id) DO UPDATE SET value = p_value;
        END;
        $$ LANGUAGE plpgsql;
    ]]
end
return migration
```

All database operations should use stored procedures via `ctx.db.call()` rather than raw SQL:

```lua
-- Good: stored procedure
ctx.db.call('sp_my_operation', {user_id, value})

-- Avoid: raw SQL
ctx.db.query('INSERT INTO my_table ...')
```

### Code Style

- Use 4 spaces for indentation
- Local variables in `snake_case`
- Module tables as `local plugin = {}`
- Always return the plugin table
- Wrap API calls that might fail in `pcall`
- Use `require('telegram-bot-lua.tools').escape_html()` for user input in HTML messages

## Language Translations

Language files are in `src/languages/`. To add a new language:

1. Copy `en_gb.lua` as a template
2. Translate all string values
3. Add the language code to `src/languages/init.lua`
