--[[
    mattata v2.0 - AFK Plugin
    Tracks AFK status for users. Notifies when an AFK user is mentioned.
    Automatically marks users as returned when they send a message.
    Uses ctx.session for AFK state management (backed by Redis).
]]

local plugin = {}
plugin.name = 'afk'
plugin.category = 'utility'
plugin.description = 'Set and track AFK status'
plugin.commands = { 'afk' }
plugin.help = '/afk [reason] - Mark yourself as AFK. Send any message to return.'

local tools = require('telegram-bot-lua.tools')

-- Format a time difference into a human-readable string
local function format_time_ago(seconds)
    if seconds < 60 then
        return 'just now'
    elseif seconds < 3600 then
        local mins = math.floor(seconds / 60)
        return mins .. ' minute' .. (mins == 1 and '' or 's') .. ' ago'
    elseif seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        local result = hours .. ' hour' .. (hours == 1 and '' or 's')
        if mins > 0 then
            result = result .. ', ' .. mins .. ' min'
        end
        return result .. ' ago'
    else
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        local result = days .. ' day' .. (days == 1 and '' or 's')
        if hours > 0 then
            result = result .. ', ' .. hours .. 'h'
        end
        return result .. ' ago'
    end
end

-- Check if a user is mentioned in the message (by @username or text_mention entity)
local function get_mentioned_user_ids(message, redis)
    local mentioned = {}
    if not message.entities then
        return mentioned
    end
    for _, entity in ipairs(message.entities) do
        if entity.type == 'mention' and message.text then
            -- Extract @username
            local username = message.text:sub(entity.offset + 1, entity.offset + entity.length)
            username = username:gsub('^@', ''):lower()
            -- Look up user ID from username cache
            local user_id = redis.get('username:' .. username)
            if user_id then
                table.insert(mentioned, tonumber(user_id))
            end
        elseif entity.type == 'text_mention' and entity.user then
            table.insert(mentioned, entity.user.id)
        end
    end
    return mentioned
end

-- /afk command handler
function plugin.on_message(api, message, ctx)
    local note = message.args
    if note and note == '' then
        note = nil
    end

    ctx.session.set_afk(message.from.id, note)

    local output
    if note then
        output = string.format(
            '<b>%s</b> is now AFK: <i>%s</i>',
            tools.escape_html(message.from.first_name),
            tools.escape_html(note)
        )
    else
        output = string.format(
            '<b>%s</b> is now AFK.',
            tools.escape_html(message.from.first_name)
        )
    end

    return api.send_message(message.chat.id, output, 'html')
end

-- Passive handler: runs on every message (not just commands)
function plugin.on_new_message(api, message, ctx)
    if not message.from then return end

    local session = ctx.session
    local redis = ctx.redis

    -- Check if the sender was AFK and auto-return them
    -- Skip if they just sent the /afk command itself
    if not (message.command == 'afk') then
        local afk_data = session.get_afk(message.from.id)
        if afk_data then
            session.clear_afk(message.from.id)
            local elapsed = os.time() - (afk_data.since or os.time())
            local output = string.format(
                '<b>%s</b> is no longer AFK (was away for %s).',
                tools.escape_html(message.from.first_name),
                format_time_ago(elapsed)
            )
            api.send_message(message.chat.id, output, 'html')
        end
    end

    -- Check if any mentioned user is AFK
    local mentioned_ids = get_mentioned_user_ids(message, redis)
    for _, user_id in ipairs(mentioned_ids) do
        -- Don't notify about yourself
        if user_id ~= message.from.id then
            local afk_data = session.get_afk(user_id)
            if afk_data then
                -- Rate-limit: only notify once per AFK user per chat per conversation
                local replied_key = string.format('afk:%d:replied:%d:%d', user_id, message.chat.id, message.from.id)
                local already_replied = redis.get(replied_key)
                if not already_replied then
                    redis.setex(replied_key, 300, '1') -- 5 minute cooldown

                    local elapsed = os.time() - (afk_data.since or os.time())
                    local output
                    if afk_data.note then
                        output = string.format(
                            'That user is currently AFK (%s): <i>%s</i>',
                            format_time_ago(elapsed),
                            tools.escape_html(afk_data.note)
                        )
                    else
                        output = string.format(
                            'That user is currently AFK (%s).',
                            format_time_ago(elapsed)
                        )
                    end
                    api.send_message(message.chat.id, output, 'html')
                end
            end
        end
    end
end

return plugin
