--[[
    mattata v2.1 - Event Router
    Dispatches Telegram updates through middleware pipeline to plugins.
    Uses copas coroutines via telegram-bot-lua's async system for concurrent
    update processing — each update runs in its own coroutine.
]]

local router = {}

local json = require('dkjson')
local copas = require('copas')
local config = require('src.core.config')
local logger = require('src.core.logger')
local middleware_pipeline = require('src.core.middleware')
local session = require('src.core.session')
local permissions = require('src.core.permissions')
local i18n = require('src.core.i18n')
local tools

local api, loader, ctx_base

-- Import middleware modules
local mw_blocklist = require('src.middleware.blocklist')
local mw_rate_limit = require('src.middleware.rate_limit')
local mw_user_tracker = require('src.middleware.user_tracker')
local mw_language = require('src.middleware.language')
local mw_federation = require('src.middleware.federation')
local mw_captcha = require('src.middleware.captcha')
local mw_stats = require('src.middleware.stats')

function router.init(api_ref, tools_ref, loader_ref, ctx_base_ref)
    api = api_ref
    tools = tools_ref
    loader = loader_ref
    ctx_base = ctx_base_ref

    -- Register middleware in order
    middleware_pipeline.use(mw_blocklist)
    middleware_pipeline.use(mw_rate_limit)
    middleware_pipeline.use(mw_federation)
    middleware_pipeline.use(mw_captcha)
    middleware_pipeline.use(mw_user_tracker)
    middleware_pipeline.use(mw_language)
    middleware_pipeline.use(mw_stats)
end

-- Build a fresh context for each update
-- Admin check is lazy — only resolved when ctx:check_admin() is called
local function build_ctx(message)
    local ctx = {}
    for k, v in pairs(ctx_base) do
        ctx[k] = v
    end
    ctx.is_group = message.chat and message.chat.type ~= 'private'
    ctx.is_supergroup = message.chat and message.chat.type == 'supergroup'
    ctx.is_private = message.chat and message.chat.type == 'private'
    ctx.is_global_admin = message.from and permissions.is_global_admin(message.from.id) or false

    -- Lazy admin check: only makes API call when first accessed
    -- Caches result for the lifetime of this context
    local admin_resolved = false
    local admin_value = false
    ctx.is_admin = false -- default for non-admin reads

    function ctx:check_admin()
        if admin_resolved then
            return admin_value
        end
        admin_resolved = true
        if ctx.is_global_admin then
            admin_value = true
        elseif ctx.is_group and message.from then
            admin_value = permissions.is_group_admin(api, message.chat.id, message.from.id)
        end
        ctx.is_admin = admin_value
        return admin_value
    end

    -- For backward compat: admin plugins that check ctx.is_admin will still
    -- need to call ctx:check_admin() first. The router does this for admin_only plugins.
    ctx.is_mod = false
    return ctx
end

-- Sort/normalise a message object (ported from v1 mattata.sort_message)
local function sort_message(message)
    message.text = message.text or message.caption or ''
    -- Normalise /command_arg to /command arg
    message.text = message.text:gsub('^(/[%a]+)_', '%1 ')
    -- Deep-link support
    if message.text:match('^[/!#]start .-$') then
        message.text = '/' .. message.text:match('^[/!#]start (.-)$')
    end
    -- Shorthand reply alias
    if message.reply_to_message then
        message.reply = message.reply_to_message
        message.reply_to_message = nil
    end
    -- Normalise language code
    if message.from and message.from.language_code then
        local lc = message.from.language_code:lower():gsub('%-', '_')
        if #lc == 2 and lc ~= 'en' then
            lc = lc .. '_' .. lc
        elseif #lc == 2 or lc == 'root' then
            lc = 'en_us'
        end
        message.from.language_code = lc
    end
    -- Detect media
    message.is_media = message.photo or message.video or message.audio or message.voice
        or message.document or message.sticker or message.animation or message.video_note or false
    -- Detect service messages
    message.is_service_message = (message.new_chat_members or message.left_chat_member
        or message.new_chat_title or message.new_chat_photo or message.pinned_message
        or message.group_chat_created or message.supergroup_chat_created) and true or false
    -- Entity-based text mentions -> ID substitution
    if message.entities then
        for _, entity in ipairs(message.entities) do
            if entity.type == 'text_mention' and entity.user then
                local name = message.text:sub(entity.offset + 1, entity.offset + entity.length)
                message.text = message.text:gsub(name, tostring(entity.user.id), 1)
            end
        end
    end
    -- Process caption entities as entities
    if message.caption_entities then
        message.entities = message.caption_entities
        message.caption_entities = nil
    end
    -- Sort reply recursively
    if message.reply then
        message.reply = sort_message(message.reply)
    end
    return message
end

-- Extract command from message text
local function extract_command(text, bot_username)
    if not text then return nil, nil end
    local cmd, args = text:match('^[/!#]([%w_]+)@?' .. (bot_username or '') .. '%s*(.*)')
    if not cmd then
        cmd, args = text:match('^[/!#]([%w_]+)%s*(.*)')
    end
    if cmd then
        cmd = cmd:lower()
        args = args ~= '' and args or nil
    end
    return cmd, args
end

-- Resolve aliases for a chat (with Redis caching)
local function resolve_alias(message, redis_mod)
    if not message.text:match('^[/!#][%w_]+') then return message end
    if not message.chat or message.chat.type == 'private' then return message end

    local command, rest = message.text:lower():match('^[/!#]([%w_]+)(.*)')
    if not command then return message end

    -- Cache alias lookups with TTL instead of hgetall on every message
    local cache_key = 'cache:aliases:' .. message.chat.id
    local cached_aliases = redis_mod.get(cache_key)
    local aliases
    if cached_aliases then
        local ok, decoded = pcall(json.decode, cached_aliases)
        if ok and decoded then
            aliases = decoded
        end
    end

    if not aliases then
        aliases = redis_mod.hgetall('chat:' .. message.chat.id .. ':aliases')
        if type(aliases) == 'table' then
            pcall(function()
                redis_mod.setex(cache_key, 300, json.encode(aliases))
            end)
        end
    end

    if type(aliases) == 'table' then
        for alias, original in pairs(aliases) do
            if command == alias then
                message.text = '/' .. original .. (rest or '')
                message.is_alias = true
                break
            end
        end
    end
    return message
end

-- Process action state (multi-step commands)
-- Fixed: save message_id before nil'ing message.reply
local function process_action(message, ctx)
    if message.text and message.chat and message.reply
        and message.reply.from and message.reply.from.id == api.info.id then
        local reply_message_id = message.reply.message_id
        local action = session.get_action(message.chat.id, reply_message_id)
        if action then
            message.text = action .. ' ' .. message.text
            message.reply = nil
            session.del_action(message.chat.id, reply_message_id)
        end
    end
    return message
end

-- Handle a message update
local function on_message(message)
    -- Validate
    if not message or not message.from then return end
    if message.date and message.date < os.time() - 10 then return end

    -- Sort/normalise
    message = sort_message(message)
    message = process_action(message, ctx_base)
    message = resolve_alias(message, ctx_base.redis)

    -- Build context and run middleware
    local ctx = build_ctx(message)
    local should_continue
    ctx, should_continue = middleware_pipeline.run(ctx, message)
    if not should_continue then return end

    -- Dispatch command to matching plugin
    local cmd, args = extract_command(message.text, api.info.username)

    if cmd then
        local plugin = loader.get_by_command(cmd)
        if plugin and plugin.on_message then
            if not session.is_plugin_disabled(message.chat.id, plugin.name) or loader.is_permanent(plugin.name) then
                -- Check permission requirements
                if plugin.global_admin_only and not ctx.is_global_admin then
                    return
                end
                -- Resolve admin status only for admin_only plugins (lazy check)
                if plugin.admin_only then
                    ctx:check_admin()
                    if not ctx.is_admin and not ctx.is_global_admin then
                        return api.send_message(message.chat.id, ctx.lang and ctx.lang.errors and ctx.lang.errors.admin or 'You need to be an admin to use this command.')
                    end
                end
                if plugin.group_only and ctx.is_private then
                    return api.send_message(message.chat.id, ctx.lang and ctx.lang.errors and ctx.lang.errors.supergroup or 'This command can only be used in groups.')
                end

                message.command = cmd
                message.args = args
                local ok, err = pcall(plugin.on_message, api, message, ctx)
                if not ok then
                    logger.error('Plugin %s.on_message error: %s', plugin.name, tostring(err))
                    if config.log_chat() then
                        api.send_message(config.log_chat(), string.format(
                            '<pre>[%s] %s error:\n%s\nFrom: %s\nText: %s</pre>',
                            os.date('%X'), plugin.name,
                            tools.escape_html(tostring(err)),
                            message.from.id,
                            tools.escape_html(message.text or '')
                        ), 'html')
                    end
                end
            end
        end
    end

    -- Run passive handlers (on_new_message) for all non-disabled plugins
    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_new_message and not session.is_plugin_disabled(message.chat.id, plugin.name) then
            local ok, err = pcall(plugin.on_new_message, api, message, ctx)
            if not ok then
                logger.error('Plugin %s.on_new_message error: %s', plugin.name, tostring(err))
            end
        end
        -- Handle member join events
        if message.new_chat_members and plugin.on_member_join then
            local ok, err = pcall(plugin.on_member_join, api, message, ctx)
            if not ok then
                logger.error('Plugin %s.on_member_join error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle callback query (routed through middleware for blocklist + rate limit)
local function on_callback_query(callback_query)
    if not callback_query or not callback_query.from then return end
    if not callback_query.data then return end

    local message = callback_query.message or {
        chat = {},
        message_id = callback_query.inline_message_id,
        from = callback_query.from
    }

    -- Parse plugin_name:data format
    local plugin_name, cb_data = callback_query.data:match('^(.-):(.*)$')
    if not plugin_name then return end

    local plugin = loader.get_by_name(plugin_name)
    if not plugin or not plugin.on_callback_query then return end

    callback_query.data = cb_data

    -- Build context and run basic middleware (blocklist + rate limit)
    local ctx = build_ctx(message)

    -- Check blocklist for callback user
    if session.is_globally_blocklisted(callback_query.from.id) then
        return
    end

    -- Load language for callback user
    local lang_code = session.get_setting(callback_query.from.id, 'language') or 'en_gb'
    ctx.lang = i18n.get(lang_code)

    local ok, err = pcall(plugin.on_callback_query, api, callback_query, message, ctx)
    if not ok then
        logger.error('Plugin %s.on_callback_query error: %s', plugin_name, tostring(err))
    end
end

-- Handle inline query
local function on_inline_query(inline_query)
    if not inline_query or not inline_query.from then return end
    if session.is_globally_blocklisted(inline_query.from.id) then return end

    local ctx = build_ctx({ from = inline_query.from, chat = { type = 'private' } })
    local lang_code = session.get_setting(inline_query.from.id, 'language') or 'en_gb'
    ctx.lang = i18n.get(lang_code)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_inline_query then
            local ok, err = pcall(plugin.on_inline_query, api, inline_query, ctx)
            if not ok then
                logger.error('Plugin %s.on_inline_query error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Concurrent polling loop using telegram-bot-lua's async system
function router.run()
    local polling = config.polling()

    -- Register telegram-bot-lua handler callbacks
    -- api.process_update() dispatches to these inside per-update copas coroutines
    api.on_message = function(msg)
        local ok, err = pcall(on_message, msg)
        if not ok then logger.error('on_message error: %s', tostring(err)) end
    end

    api.on_edited_message = function(msg)
        msg.is_edited = true
        local ok, err = pcall(on_message, msg)
        if not ok then logger.error('on_edited_message error: %s', tostring(err)) end
    end

    api.on_callback_query = function(cb)
        local ok, err = pcall(on_callback_query, cb)
        if not ok then logger.error('on_callback_query error: %s', tostring(err)) end
    end

    api.on_inline_query = function(iq)
        local ok, err = pcall(on_inline_query, iq)
        if not ok then logger.error('on_inline_query error: %s', tostring(err)) end
    end

    -- Cron: copas background thread, runs every 60s
    copas.addthread(function()
        while true do
            copas.pause(60)
            for _, plugin in ipairs(loader.get_plugins()) do
                if plugin.cron then
                    copas.addthread(function()
                        local ok, err = pcall(plugin.cron, api, ctx_base)
                        if not ok then
                            logger.error('Plugin %s cron error: %s', plugin.name, tostring(err))
                        end
                    end)
                end
            end
        end
    end)

    -- Stats flush: copas background thread, runs every 300s
    copas.addthread(function()
        while true do
            copas.pause(300)
            local ok, err = pcall(mw_stats.flush, ctx_base.db, ctx_base.redis)
            if not ok then logger.error('Stats flush error: %s', tostring(err)) end
        end
    end)

    -- Start concurrent polling loop
    -- api.run() -> api.async.run() which:
    --   1. Swaps api.request to copas-based api.async.request
    --   2. Spawns polling coroutine calling get_updates in a loop
    --   3. For each update, spawns NEW coroutine -> api.process_update -> handlers above
    --   4. Calls copas.loop()
    api.run({
        timeout = polling.timeout,
        limit = polling.limit,
        allowed_updates = {
            'message', 'edited_message', 'callback_query', 'inline_query',
            'chat_join_request', 'chat_member', 'my_chat_member',
            'message_reaction'
        }
    })
end

return router
