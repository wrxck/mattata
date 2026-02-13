--[[
    mattata v2.0 - Reactions Plugin
    Tracks karma via message reactions (thumbs up/down).
    Records message authorship so reaction events can attribute karma.
]]

local session = require('src.core.session')

local plugin = {}
plugin.name = 'reactions'
plugin.category = 'fun'
plugin.description = 'Reaction-based karma tracking'
plugin.commands = { 'reactions' }
plugin.help = '/reactions <on|off> - Toggle reaction karma tracking for this group.'
plugin.group_only = true
plugin.admin_only = true

local THUMBS_UP = '\xF0\x9F\x91\x8D'
local THUMBS_DOWN = '\xF0\x9F\x91\x8E'

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        -- Show current status
        local enabled = session.get_cached_setting(message.chat.id, 'reactions_enabled', function()
            local result = ctx.db.call('sp_get_chat_setting', { message.chat.id, 'reactions_enabled' })
            if result and #result > 0 then
                return result[1].value
            end
            return nil
        end)
        local status = (enabled == 'true') and 'enabled' or 'disabled'
        return api.send_message(message.chat.id,
            string.format('Reaction karma is currently <b>%s</b> for this group.\nUse <code>/reactions on</code> or <code>/reactions off</code> to toggle.', status),
            { parse_mode = 'html' }
        )
    end

    local arg = message.args:lower()
    if arg == 'on' or arg == 'enable' then
        local ok, _ = pcall(ctx.db.call, 'sp_upsert_chat_setting', { message.chat.id, 'reactions_enabled', 'true' })
        if not ok then
            return api.send_message(message.chat.id, 'Failed to update setting. Please try again.')
        end
        session.invalidate_setting(message.chat.id, 'reactions_enabled')
        return api.send_message(message.chat.id, 'Reaction karma has been enabled for this group.')
    elseif arg == 'off' or arg == 'disable' then
        local ok, _ = pcall(ctx.db.call, 'sp_upsert_chat_setting', { message.chat.id, 'reactions_enabled', 'false' })
        if not ok then
            return api.send_message(message.chat.id, 'Failed to update setting. Please try again.')
        end
        session.invalidate_setting(message.chat.id, 'reactions_enabled')
    else
        return api.send_message(message.chat.id, 'Usage: /reactions <on|off>')
    end
end

-- Record message authorship for karma attribution
function plugin.on_new_message(api, message, ctx)
    if not ctx.is_group or not message.from then return end
    -- Only track authorship if reactions feature is enabled for this chat
    local enabled = session.get_cached_setting(message.chat.id, 'reactions_enabled', function()
        local ok, result = pcall(ctx.db.call, 'sp_get_chat_setting', { message.chat.id, 'reactions_enabled' })
        if ok and result and #result > 0 then
            return result[1].value
        end
        return nil
    end)
    if enabled ~= 'true' then return end
    ctx.redis.setex(
        string.format('msg_author:%s:%s', message.chat.id, message.message_id),
        172800,
        tostring(message.from.id)
    )
end

-- Build a set of emoji strings from a reaction array
local function reaction_set(reactions)
    local set = {}
    if not reactions then return set end
    for _, r in ipairs(reactions) do
        if r.type == 'emoji' and r.emoji then
            set[r.emoji] = true
        end
    end
    return set
end

function plugin.on_reaction(api, update, ctx)
    -- Anonymous reactions cannot be tracked
    if not update.user then return end
    if not update.chat then return end

    local chat_id = update.chat.id

    -- Check if reactions_enabled for this chat
    local enabled = session.get_cached_setting(chat_id, 'reactions_enabled', function()
        local ok, result = pcall(ctx.db.call, 'sp_get_chat_setting', { chat_id, 'reactions_enabled' })
        if ok and result and #result > 0 then
            return result[1].value
        end
        return nil
    end)
    if enabled ~= 'true' then return end

    -- Look up the author of the reacted message
    local author_id = ctx.redis.get(
        string.format('msg_author:%s:%s', chat_id, update.message_id)
    )
    if not author_id then return end
    author_id = tonumber(author_id)

    -- Prevent self-karma
    if update.user.id == author_id then return end

    local new_set = reaction_set(update.new_reaction)
    local old_set = reaction_set(update.old_reaction)

    local karma_key = 'karma:' .. author_id
    local delta = 0

    -- New reactions that weren't in old (added)
    for emoji, _ in pairs(new_set) do
        if not old_set[emoji] then
            if emoji == THUMBS_UP then
                delta = delta + 1
            elseif emoji == THUMBS_DOWN then
                delta = delta - 1
            end
        end
    end

    -- Old reactions that aren't in new (removed)
    for emoji, _ in pairs(old_set) do
        if not new_set[emoji] then
            if emoji == THUMBS_UP then
                delta = delta - 1
            elseif emoji == THUMBS_DOWN then
                delta = delta + 1
            end
        end
    end

    if delta ~= 0 then
        ctx.redis.incrby(karma_key, delta)
    end
end

return plugin
