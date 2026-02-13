--[[
    mattata v2.0 - RSS Plugin
    Subscribe groups to RSS/Atom feeds with automatic polling.
    Feeds are checked every 5 minutes via cron (staggered).
    All state stored in Redis — no database procedures needed.
]]

local plugin = {}
plugin.name = 'rss'
plugin.category = 'utility'
plugin.description = 'Subscribe to RSS/Atom feeds in group chats'
plugin.commands = { 'rss' }
plugin.help = '/rss add <url> - Subscribe to a feed\n/rss remove <url> - Unsubscribe\n/rss list - List active subscriptions'
plugin.group_only = true
plugin.admin_only = true

local http = require('src.core.http')
local tools = require('telegram-bot-lua.tools')
local logger = require('src.core.logger')

local MAX_FEEDS_PER_CHAT = 5
local POLL_INTERVAL = 300 -- 5 minutes between checks per feed
local MAX_FEEDS_PER_TICK = 3 -- max feeds to check per cron tick
local MAX_ITEMS = 5 -- only process latest 5 items per fetch
local MAX_SEEN = 200 -- keep last N entry IDs in seen set

local function url_hash(url)
    local h = 0
    for i = 1, #url do
        h = (h * 31 + url:byte(i)) % 2147483647
    end
    return tostring(h)
end

-- Parse RSS 2.0 items
local function parse_rss(body)
    local items = {}
    for item in body:gmatch('<item>(.-)</item>') do
        local title = item:match('<title><!%[CDATA%[(.-)%]%]>') or item:match('<title>(.-)</title>') or 'Untitled'
        local link = item:match('<link>(.-)</link>') or ''
        local guid = item:match('<guid>(.-)</guid>') or link
        title = title:gsub('<[^>]+>', '')
        table.insert(items, { title = title, link = link, guid = guid })
        if #items >= MAX_ITEMS then break end
    end
    return items
end

-- Parse Atom entries
local function parse_atom(body)
    local items = {}
    for entry in body:gmatch('<entry>(.-)</entry>') do
        local title = entry:match('<title>(.-)</title>') or 'Untitled'
        local link = entry:match('<link[^>]*href="([^"]*)"') or entry:match('<link>(.-)</link>') or ''
        local id = entry:match('<id>(.-)</id>') or link
        title = title:gsub('<[^>]+>', '')
        table.insert(items, { title = title, link = link, guid = id })
        if #items >= MAX_ITEMS then break end
    end
    return items
end

local function parse_feed(body)
    if body:match('<feed') then
        return parse_atom(body)
    else
        return parse_rss(body)
    end
end

-- Extract feed title from XML
local function extract_feed_title(body)
    -- Try channel/title for RSS
    local channel = body:match('<channel>(.-)<item')
    if channel then
        local title = channel:match('<title><!%[CDATA%[(.-)%]%]>') or channel:match('<title>(.-)</title>')
        if title then return title:gsub('<[^>]+>', '') end
    end
    -- Try feed/title for Atom
    local title = body:match('<feed[^>]*>.-<title>(.-)</title>')
    if title then return title:gsub('<[^>]+>', '') end
    return 'Untitled Feed'
end

local function handle_add(api, message, ctx)
    local url = message.args and message.args:match('^add%s+(.+)$')
    if not url then
        return api.send_message(message.chat.id, 'Usage: <code>/rss add https://example.com/feed.xml</code>', { parse_mode = 'html' })
    end

    url = url:match('^%s*(.-)%s*$') -- trim whitespace

    if not url:match('^https?://') then
        return api.send_message(message.chat.id, 'Invalid URL. Must start with http:// or https://')
    end

    -- Block internal/private IP ranges to prevent SSRF
    local host = url:match('^https?://([^/:]+)')
    if host then
        local h = host:lower()
        if h == 'localhost' or h:match('^127%.') or h:match('^10%.') or h:match('^192%.168%.')
            or h:match('^172%.1[6-9]%.') or h:match('^172%.2%d%.') or h:match('^172%.3[01]%.')
            or h:match('^0%.') or h:match('^%[') or h:match('^169%.254%.') then
            return api.send_message(message.chat.id, 'Invalid URL. Internal addresses are not allowed.')
        end
    end

    local feed_key = 'rss:feeds:' .. message.chat.id
    local count = ctx.redis.scard(feed_key)
    if tonumber(count) >= MAX_FEEDS_PER_CHAT then
        return api.send_message(
            message.chat.id,
            string.format('This chat already has %d subscriptions (max %d). Remove one first.', count, MAX_FEEDS_PER_CHAT)
        )
    end

    -- Check if already subscribed
    local is_member = ctx.redis.sismember(feed_key, url)
    if tonumber(is_member) == 1 then
        return api.send_message(message.chat.id, 'This chat is already subscribed to that feed.')
    end

    -- Fetch and validate the feed
    local body, code = http.get(url)
    if not body or code ~= 200 then
        return api.send_message(
            message.chat.id,
            string.format('Failed to fetch feed (HTTP %s). Check the URL and try again.', tostring(code))
        )
    end

    local items = parse_feed(body)
    if #items == 0 then
        return api.send_message(message.chat.id, 'No feed items found at that URL. Make sure it is a valid RSS or Atom feed.')
    end

    local feed_title = extract_feed_title(body)
    local hash = url_hash(url)

    -- Store subscription
    ctx.redis.sadd(feed_key, url)
    ctx.redis.sadd('rss:subs:' .. hash, tostring(message.chat.id))
    ctx.redis.sadd('rss:active_feeds', hash)

    -- Store metadata
    local meta_key = 'rss:meta:' .. hash
    ctx.redis.hset(meta_key, 'title', feed_title)
    ctx.redis.hset(meta_key, 'url', url)
    ctx.redis.hset(meta_key, 'last_checked', tostring(os.time()))

    -- Mark all current entries as seen so we don't flood on first add
    local seen_key = 'rss:seen:' .. hash
    for _, item in ipairs(items) do
        if item.guid and item.guid ~= '' then
            ctx.redis.sadd(seen_key, item.guid)
        end
    end

    return api.send_message(
        message.chat.id,
        string.format('Subscribed to <b>%s</b>.', tools.escape_html(feed_title)),
        { parse_mode = 'html' }
    )
end

local function handle_remove(api, message, ctx)
    local url = message.args and message.args:match('^remove%s+(.+)$')
    if not url then
        return api.send_message(message.chat.id, 'Usage: <code>/rss remove https://example.com/feed.xml</code>', { parse_mode = 'html' })
    end

    url = url:match('^%s*(.-)%s*$') -- trim whitespace

    local feed_key = 'rss:feeds:' .. message.chat.id
    local removed = ctx.redis.srem(feed_key, url)
    if tonumber(removed) == 0 then
        return api.send_message(message.chat.id, 'This chat is not subscribed to that feed.')
    end

    local hash = url_hash(url)
    ctx.redis.srem('rss:subs:' .. hash, tostring(message.chat.id))

    -- If no more subscribers, clean up
    local remaining = ctx.redis.scard('rss:subs:' .. hash)
    if tonumber(remaining) == 0 then
        ctx.redis.del('rss:meta:' .. hash)
        ctx.redis.del('rss:seen:' .. hash)
        ctx.redis.srem('rss:active_feeds', hash)
    end

    return api.send_message(message.chat.id, 'Unsubscribed from feed.')
end

local function handle_list(api, message, ctx)
    local feed_key = 'rss:feeds:' .. message.chat.id
    local urls = ctx.redis.smembers(feed_key)

    if not urls or #urls == 0 then
        return api.send_message(message.chat.id, 'No active feed subscriptions for this chat.')
    end

    local lines = { '<b>RSS Subscriptions</b>' }
    for i, feed_url in ipairs(urls) do
        local hash = url_hash(feed_url)
        local title = ctx.redis.hget('rss:meta:' .. hash, 'title') or 'Unknown'
        table.insert(lines, string.format('%d. <b>%s</b>\n   <code>%s</code>', i, tools.escape_html(title), tools.escape_html(feed_url)))
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), { parse_mode = 'html', link_preview_options = { is_disabled = true } })
end

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        return api.send_message(
            message.chat.id,
            '<b>RSS Feed Subscriptions</b>\n\n'
            .. '<code>/rss add &lt;url&gt;</code> - Subscribe to a feed\n'
            .. '<code>/rss remove &lt;url&gt;</code> - Unsubscribe\n'
            .. '<code>/rss list</code> - List active subscriptions\n\n'
            .. string.format('Max %d feeds per chat. Feeds are checked every %d minutes.', MAX_FEEDS_PER_CHAT, POLL_INTERVAL / 60),
            { parse_mode = 'html' }
        )
    end

    local subcommand = message.args:match('^(%S+)')
    if not subcommand then
        return api.send_message(message.chat.id, 'Unknown subcommand. Use /rss for help.')
    end

    subcommand = subcommand:lower()

    if subcommand == 'add' then
        return handle_add(api, message, ctx)
    elseif subcommand == 'remove' or subcommand == 'del' or subcommand == 'delete' then
        return handle_remove(api, message, ctx)
    elseif subcommand == 'list' then
        return handle_list(api, message, ctx)
    else
        return api.send_message(message.chat.id, 'Unknown subcommand. Use /rss for help.')
    end
end

function plugin.cron(api, ctx)
    -- Get all active feed hashes
    local active_feeds = ctx.redis.smembers('rss:active_feeds')
    if not active_feeds or #active_feeds == 0 then
        return
    end

    -- Find feeds due for checking (not checked in last POLL_INTERVAL seconds)
    local now = os.time()
    local due = {}
    for _, hash in ipairs(active_feeds) do
        local last_checked = ctx.redis.hget('rss:meta:' .. hash, 'last_checked')
        last_checked = tonumber(last_checked) or 0
        if now - last_checked >= POLL_INTERVAL then
            table.insert(due, hash)
        end
        if #due >= MAX_FEEDS_PER_TICK then break end
    end

    for _, hash in ipairs(due) do
        local feed_url = ctx.redis.hget('rss:meta:' .. hash, 'url')
        if not feed_url then
            -- Orphaned metadata, remove from active set
            ctx.redis.srem('rss:active_feeds', hash)
        else
            -- Update last_checked immediately to avoid double-polling
            ctx.redis.hset('rss:meta:' .. hash, 'last_checked', tostring(now))

            local ok, err = pcall(function()
                local body, code = http.get(feed_url)
                if not body or code ~= 200 then
                    logger.warn('RSS: failed to fetch %s (HTTP %s)', feed_url, tostring(code))
                    return
                end

                local items = parse_feed(body)
                if #items == 0 then return end

                local feed_title = ctx.redis.hget('rss:meta:' .. hash, 'title') or extract_feed_title(body)
                local seen_key = 'rss:seen:' .. hash

                -- Check items in reverse order so oldest new items are posted first
                local new_items = {}
                for _, item in ipairs(items) do
                    if item.guid and item.guid ~= '' then
                        local already_seen = ctx.redis.sismember(seen_key, item.guid)
                        if tonumber(already_seen) == 0 then
                            table.insert(new_items, item)
                        end
                    end
                end

                if #new_items == 0 then return end

                -- Mark new items as seen
                for _, item in ipairs(new_items) do
                    ctx.redis.sadd(seen_key, item.guid)
                end

                -- Get all subscriber chats
                local subscribers = ctx.redis.smembers('rss:subs:' .. hash)
                if not subscribers or #subscribers == 0 then return end

                -- Send new items to all subscribers (oldest first)
                for i = #new_items, 1, -1 do
                    local item = new_items[i]
                    local text
                    if item.link and item.link ~= '' then
                        text = string.format(
                            '<b>%s</b>\n<a href="%s">%s</a>',
                            tools.escape_html(feed_title),
                            tools.escape_html(item.link),
                            tools.escape_html(item.title)
                        )
                    else
                        text = string.format(
                            '<b>%s</b>\n%s',
                            tools.escape_html(feed_title),
                            tools.escape_html(item.title)
                        )
                    end

                    for _, chat_id in ipairs(subscribers) do
                        local send_ok, send_err = pcall(
                            api.send_message, chat_id, text,
                            { parse_mode = 'html', link_preview_options = { is_disabled = true } }
                        )
                        if not send_ok then
                            logger.warn('RSS: failed to send to chat %s: %s', tostring(chat_id), tostring(send_err))
                        end
                    end
                end

                -- Trim seen set if it grows too large by using a TTL
                -- This avoids the data loss issue of rebuilding from current items only
                local seen_count = ctx.redis.scard(seen_key)
                if tonumber(seen_count) > MAX_SEEN * 2 then
                    -- Set a 7-day TTL on the seen set to let it naturally expire
                    -- rather than deleting entries that might cause re-posts
                    ctx.redis.expire(seen_key, 604800)
                end
            end)

            if not ok then
                logger.error('RSS: error processing feed %s: %s', feed_url, tostring(err))
            end
        end
    end
end

return plugin
