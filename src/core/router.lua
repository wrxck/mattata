--[[
    mattata v2.1 - Event Router
    Dispatches Telegram updates through middleware pipeline to plugins.
    Uses copas coroutines via telegram-bot-lua's async system for concurrent
    update processing — each update runs in its own coroutine.
]]

local router = {}

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
-- Uses metatable __index to inherit ctx_base without copying.
-- Admin check is lazy — only resolved when ctx:check_admin() is called.
local function build_ctx(message)
    local ctx = setmetatable({}, { __index = ctx_base })
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

    ctx.is_mod = false
    return ctx
end

-- Generic event dispatcher: iterates pre-indexed plugins for a given event
local function dispatch_event(event_name, update, ctx)
    for _, plugin in ipairs(loader.get_by_event(event_name)) do
        local ok, err = pcall(plugin[event_name], api, update, ctx)
        if not ok then
            logger.error('Plugin %s.%s error: %s', plugin.name, event_name, tostring(err))
        end
    end
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
        or message.group_chat_created or message.supergroup_chat_created
        or message.forum_topic_created or message.forum_topic_closed
        or message.forum_topic_reopened or message.forum_topic_edited
        or message.video_chat_started or message.video_chat_ended
        or message.video_chat_participants_invited
        or message.message_auto_delete_timer_changed
        or message.write_access_allowed) and true or false
    -- Detect forum topics
    message.is_topic = message.is_topic_message or false
    message.thread_id = message.message_thread_id
    -- Entity-based text mentions -> ID substitution
    if message.entities then
        for _, entity in ipairs(message.entities) do
            if entity.type == 'text_mention' and entity.user then
                local name = message.text:sub(entity.offset + 1, entity.offset + entity.length)
                -- Escape Lua pattern special characters in the display name
                local escaped = name:gsub('([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')
                message.text = message.text:gsub(escaped, tostring(entity.user.id), 1)
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

-- Resolve aliases for a chat (single HGET lookup per command)
local function resolve_alias(message, redis_mod)
    if not message.text:match('^[/!#][%w_]+') then return message end
    if not message.chat or message.chat.type == 'private' then return message end

    local command, rest = message.text:lower():match('^[/!#]([%w_]+)(.*)')
    if not command then return message end

    -- Direct lookup: O(1) hash field access instead of decode-all + iterate
    local original = redis_mod.hget('chat:' .. message.chat.id .. ':aliases', command)
    if original then
        message.text = '/' .. original .. (rest or '')
        message.is_alias = true
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

-- Build a lightweight context for non-message updates (no full middleware pipeline)
local function build_lightweight_ctx(chat, user)
    local ctx = {}
    for k, v in pairs(ctx_base) do
        ctx[k] = v
    end
    if chat then
        ctx.is_group = chat.type ~= 'private'
        ctx.is_supergroup = chat.type == 'supergroup'
        ctx.is_private = chat.type == 'private'
    else
        ctx.is_group = false
        ctx.is_supergroup = false
        ctx.is_private = true
    end
    ctx.is_global_admin = user and permissions.is_global_admin(user.id) or false
    ctx.is_admin = false
    ctx.is_mod = false
    if user then
        local lang_code = session.get_setting(user.id, 'language') or 'en_gb'
        ctx.lang = i18n.get(lang_code)
    end
    return ctx
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
                        ), { parse_mode = 'html' })
                    end
                end
            end
        end
    end

    -- Build disabled set once for this chat (1 SMEMBERS vs N SISMEMBER calls)
    local disabled_set = {}
    local disabled_list = session.get_disabled_plugins(message.chat.id)
    for _, name in ipairs(disabled_list) do
        disabled_set[name] = true
    end

    -- Run passive handlers using pre-built event index (only plugins with on_new_message)
    for _, plugin in ipairs(loader.get_by_event('on_new_message')) do
        if not disabled_set[plugin.name] then
            local ok, err = pcall(plugin.on_new_message, api, message, ctx)
            if not ok then
                logger.error('Plugin %s.on_new_message error: %s', plugin.name, tostring(err))
            end
        end
    end

    -- Handle member join events (only check if message has new_chat_members)
    if message.new_chat_members then
        for _, plugin in ipairs(loader.get_by_event('on_member_join')) do
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

    local message = callback_query.message
    if not message then
        message = {
            chat = { id = callback_query.from.id, type = 'private' },
            message_id = callback_query.inline_message_id,
            from = callback_query.from
        }
        callback_query.is_inline = true
    end

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
    ctx.lang = i18n.get(session.get_setting(inline_query.from.id, 'language') or 'en_gb')
    dispatch_event('on_inline_query', inline_query, ctx)
end

-- Handle chat join request
local function on_chat_join_request(request)
    if not request or not request.from then return end
    if session.is_globally_blocklisted(request.from.id) then return end
    dispatch_event('on_chat_join_request', request, build_ctx({ from = request.from, chat = request.chat }))
end

-- Handle chat member status change (not the bot itself)
local function on_chat_member(update)
    if not update or not update.from then return end
    dispatch_event('on_chat_member_update', update, build_ctx({ from = update.from, chat = update.chat }))
end

-- Handle bot's own chat member status change
local function on_my_chat_member(update)
    if not update or not update.from then return end
    dispatch_event('on_my_chat_member', update, build_ctx({ from = update.from, chat = update.chat }))
end

-- Handle message reaction updates
local function on_message_reaction(update)
    if not update then return end
    dispatch_event('on_reaction', update, build_ctx({ from = update.user or update.actor_chat, chat = update.chat }))
end

-- Handle anonymous reaction count updates (no user info)
local function on_message_reaction_count(update)
    if not update then return end
    dispatch_event('on_reaction_count', update, build_ctx({ from = nil, chat = update.chat }))
end

-- Handle chat boost updates
local function on_chat_boost(update)
    if not update or not update.chat then return end
    dispatch_event('on_chat_boost', update, build_ctx({ from = nil, chat = update.chat }))
end

-- Handle removed chat boost updates
local function on_removed_chat_boost(update)
    if not update or not update.chat then return end
    dispatch_event('on_removed_chat_boost', update, build_ctx({ from = nil, chat = update.chat }))
end

-- Handle poll state updates
local function on_poll(poll)
    if not poll then return end
    dispatch_event('on_poll', poll, build_ctx({ from = nil, chat = { type = 'private' } }))
end

-- Handle poll answer updates
local function on_poll_answer(poll_answer)
    if not poll_answer then return end
    dispatch_event('on_poll_answer', poll_answer, build_ctx({ from = poll_answer.user, chat = { type = 'private' } }))
end

-- Handle chat join request updates
local function on_chat_join_request(request)
    if not request or not request.from or not request.chat then return end
    if session.is_globally_blocklisted(request.from.id) then return end

    local ctx = build_lightweight_ctx(request.chat, request.from)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_chat_join_request then
            local ok, err = pcall(plugin.on_chat_join_request, api, request, ctx)
            if not ok then
                logger.error('Plugin %s.on_chat_join_request error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle chat member status changes
local function on_chat_member(update)
    if not update or not update.chat then return end
    local user = update.from or (update.new_chat_member and update.new_chat_member.user)
    if not user then return end

    local ctx = build_lightweight_ctx(update.chat, user)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_chat_member_update then
            local ok, err = pcall(plugin.on_chat_member_update, api, update, ctx)
            if not ok then
                logger.error('Plugin %s.on_chat_member_update error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle bot's own chat member status changes (added/removed/promoted)
local function on_my_chat_member(update)
    if not update or not update.chat then return end

    local ctx = build_lightweight_ctx(update.chat, update.from)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_my_chat_member then
            local ok, err = pcall(plugin.on_my_chat_member, api, update, ctx)
            if not ok then
                logger.error('Plugin %s.on_my_chat_member error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle message reaction changes
local function on_message_reaction(reaction)
    if not reaction or not reaction.chat then return end
    local user = reaction.user or reaction.actor_chat
    if not user then return end

    local ctx = build_lightweight_ctx(reaction.chat, user)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_reaction then
            local ok, err = pcall(plugin.on_reaction, api, reaction, ctx)
            if not ok then
                logger.error('Plugin %s.on_reaction error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle poll state changes
local function on_poll(poll)
    if not poll then return end

    -- Polls have no chat context, use a minimal ctx
    local ctx = build_lightweight_ctx(nil, nil)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_poll then
            local ok, err = pcall(plugin.on_poll, api, poll, ctx)
            if not ok then
                logger.error('Plugin %s.on_poll error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle poll answer (user votes)
local function on_poll_answer(answer)
    if not answer or not answer.user then return end

    local ctx = build_lightweight_ctx(nil, answer.user)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_poll_answer then
            local ok, err = pcall(plugin.on_poll_answer, api, answer, ctx)
            if not ok then
                logger.error('Plugin %s.on_poll_answer error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle chat boost events
local function on_chat_boost(boost)
    if not boost or not boost.chat then return end

    local ctx = build_lightweight_ctx(boost.chat, nil)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_chat_boost then
            local ok, err = pcall(plugin.on_chat_boost, api, boost, ctx)
            if not ok then
                logger.error('Plugin %s.on_chat_boost error: %s', plugin.name, tostring(err))
            end
        end
    end
end

-- Handle removed chat boost events
local function on_removed_chat_boost(boost)
    if not boost or not boost.chat then return end

    local ctx = build_lightweight_ctx(boost.chat, nil)

    for _, plugin in ipairs(loader.get_plugins()) do
        if plugin.on_removed_chat_boost then
            local ok, err = pcall(plugin.on_removed_chat_boost, api, boost, ctx)
            if not ok then
                logger.error('Plugin %s.on_removed_chat_boost error: %s', plugin.name, tostring(err))
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

    -- Table-driven registration for simple event handlers
    local event_handlers = {
        on_callback_query = on_callback_query,
        on_inline_query = on_inline_query,
        on_chat_join_request = on_chat_join_request,
        on_chat_member = on_chat_member,
        on_my_chat_member = on_my_chat_member,
        on_message_reaction = on_message_reaction,
        on_message_reaction_count = on_message_reaction_count,
        on_chat_boost = on_chat_boost,
        on_removed_chat_boost = on_removed_chat_boost,
        on_poll = on_poll,
        on_poll_answer = on_poll_answer,
    }

    for event_name, handler in pairs(event_handlers) do
        api[event_name] = function(data)
            local ok, err = pcall(handler, data)
            if not ok then logger.error('%s error: %s', event_name, tostring(err)) end
        end
    end

    api.on_inline_query = function(iq)
        local ok, err = pcall(on_inline_query, iq)
        if not ok then logger.error('on_inline_query error: %s', tostring(err)) end
    end

    api.on_chat_join_request = function(req)
        local ok, err = pcall(on_chat_join_request, req)
        if not ok then logger.error('on_chat_join_request error: %s', tostring(err)) end
    end

    api.on_chat_member = function(update)
        local ok, err = pcall(on_chat_member, update)
        if not ok then logger.error('on_chat_member error: %s', tostring(err)) end
    end

    api.on_my_chat_member = function(update)
        local ok, err = pcall(on_my_chat_member, update)
        if not ok then logger.error('on_my_chat_member error: %s', tostring(err)) end
    end

    api.on_message_reaction = function(reaction)
        local ok, err = pcall(on_message_reaction, reaction)
        if not ok then logger.error('on_message_reaction error: %s', tostring(err)) end
    end

    api.on_poll = function(poll)
        local ok, err = pcall(on_poll, poll)
        if not ok then logger.error('on_poll error: %s', tostring(err)) end
    end

    api.on_poll_answer = function(answer)
        local ok, err = pcall(on_poll_answer, answer)
        if not ok then logger.error('on_poll_answer error: %s', tostring(err)) end
    end

    api.on_chat_boost = function(boost)
        local ok, err = pcall(on_chat_boost, boost)
        if not ok then logger.error('on_chat_boost error: %s', tostring(err)) end
    end

    api.on_removed_chat_boost = function(boost)
        local ok, err = pcall(on_removed_chat_boost, boost)
        if not ok then logger.error('on_removed_chat_boost error: %s', tostring(err)) end
    end

    -- Cron: copas background thread, runs every 60s (uses event index)
    copas.addthread(function()
        while true do
            copas.pause(60)
            for _, plugin in ipairs(loader.get_by_event('cron')) do
                copas.addthread(function()
                    local ok, err = pcall(plugin.cron, api, ctx_base)
                    if not ok then
                        logger.error('Plugin %s cron error: %s', plugin.name, tostring(err))
                    end
                end)
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
            'message_reaction', 'message_reaction_count',
            'poll', 'poll_answer',
            'chat_boost', 'removed_chat_boost'
        }
    })
end

return router
